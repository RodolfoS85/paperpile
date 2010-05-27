# Copyright 2009, 2010 Paperpile
#
# This file is part of Paperpile
#
# Paperpile is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Paperpile is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.  You should have received a
# copy of the GNU General Public License along with Paperpile.  If
# not, see http://www.gnu.org/licenses.

package Paperpile::Controller::Ajax::CRUD;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Paperpile::Library::Publication;
use Paperpile::Job;
use Paperpile::Queue;
use Data::Dumper;
use HTML::TreeBuilder;
use HTML::FormatText;
use File::Path;
use File::Spec;
use File::Copy;
use File::stat;
use URI::file;


use 5.010;

sub insert_entry : Local {
  my ( $self, $c ) = @_;

  my $grid_id   = $c->request->params->{grid_id};
  my $plugin    = $self->_get_plugin($c);
  my $selection = $self->_get_selection($c);
  my %output    = ();

  # Go through and complete publication details if necessary.
  my @pub_array = ();
  foreach my $pub (@$selection) {
    if ( $plugin->needs_completing($pub) ) {
      my $new_pub  = $plugin->complete_details($pub);
      push @pub_array, $new_pub;
    } else {
      push @pub_array, $pub;
    }
  }

  # In case a pdf is present but not imported (e.g. in bibtex file
  # plugin with attachments) we set _pdf_tmp to make sure the PDF is
  # imported
  foreach my $pub (@pub_array){
    if ($pub->pdf_name and !$pub->_imported){
      $pub->_pdf_tmp($pub->pdf_name);
    }
  }


  $c->model('Library')->insert_pubs( \@pub_array, 1);

  my $pubs = {};
  foreach my $pub (@pub_array) {
    $pub->_imported(1);
    my $pub_hash = $pub->as_hash;
    $pubs->{ $pub_hash->{guid} } = $pub_hash;
  }

  # If the number of imported pubs is reasonable, we return the updated pub data
  # directly and don't reload the entire grid that triggered the import.
  if ( scalar( keys %$pubs ) < 50 ) {
    $c->stash->{data} = { pubs => $pubs };
    $c->stash->{data}->{pub_delta_ignore} = $grid_id;
  }

  # Trigger a complete reload
  $c->stash->{data}->{pub_delta} = 1;

  $self->_update_counts($c);

}

sub complete_entry : Local {

  my ( $self, $c ) = @_;
  my $plugin = $self->_get_plugin($c);
  my $selection = $self->_get_selection($c);

  my $cancel_handle = $c->request->params->{cancel_handle};

  Paperpile::Utils->register_cancel_handle($cancel_handle);

  my @new_pubs = ();
  my $results = {};
  foreach my $pub (@$selection) {
    my $pub_hash;
    if ($plugin->needs_completing($pub)) {
      my $new_pub = $plugin->complete_details($pub);
      $pub_hash = $new_pub->as_hash;
    }
    $results->{$pub_hash->{guid}} = $pub_hash;
  }

  $c->stash->{data} = {pubs => $results};

  Paperpile::Utils->clear_cancel($$);

}

sub new_entry : Local {

  my ( $self, $c ) = @_;

  my $match_job = $c->request->params->{match_job};

  my %fields = ();

  foreach my $key ( %{ $c->request->params } ) {
    next if $key =~ /^_/;
    $fields{$key} = $c->request->params->{$key};
  }

  my $pub = Paperpile::Library::Publication->new( {%fields} );

  $c->model('Library')->insert_pubs( [$pub], 1 );

  $self->_update_counts($c);

  # That's handled as form on the front-end so we have to explicitly
  # indicate success
  $c->stash->{success}=\1;

  $c->stash->{data}->{pub_delta} = 1;

  # Inserting a PDF that failed to match automatically and that has a
  # jobid in the queue. We update the job entry here.
  if ($match_job) {
    my $job = Paperpile::Job->new( { id => $match_job } );
    $job->update_status('DONE');
    $job->error('');
    $job->update_info('msg',"Data inserted manually.");
    $job->pub($pub);
    $job->save;
    $c->stash->{data}->{jobs}->{$match_job} = $job->as_hash;
  }
}

sub delete_entry : Local {
  my ( $self, $c ) = @_;
  my $plugin  = $self->_get_plugin($c);
  my $mode    = $c->request->params->{mode};

  my $data = $self->_get_selection($c);

  # ignore all entries that are not imported
  my @imported = ();
  foreach my $pub (@$data) {
    next if not $pub->_imported;
    push @imported, $pub;
  }

  $data = [@imported];

  $c->model('Library')->delete_pubs($data) if $mode eq 'DELETE';
  $c->model('Library')->trash_pubs( $data, 'RESTORE' ) if $mode eq 'RESTORE';

  if ( $mode eq 'TRASH' ) {
    $c->model('Library')->trash_pubs( $data, 'TRASH' );
    $c->session->{"undo_trash"} = $data;
  }

  $self->_collect_update_data($c,$data,['_imported','trashed']);

  $c->stash->{data}->{pub_delta} = 1;
  $c->stash->{num_deleted} = scalar @$data;

  $plugin->total_entries( $plugin->total_entries - scalar(@$data) );

  $self->_update_counts($c);

}

sub undo_trash : Local {

  my ( $self, $c ) = @_;

  my $data = $c->session->{"undo_trash"};

  $c->model('Library')->trash_pubs( $data, 'RESTORE' );

  delete( $c->session->{undo_trash} );

  $self->_update_counts($c);

  $c->stash->{data}->{pub_delta} = 1;

}

sub update_entry : Local {
  my ( $self, $c ) = @_;

  my $plugin  = $self->_get_plugin($c);
  my $guid = $c->request->params->{guid};

  my $new_data = {};
  foreach my $field ( keys %{ $c->request->params } ) {
    next if $field =~ /grid_id/;
    $new_data->{$field} = $c->request->params->{$field};
  }

  my $new_pub = $c->model('Library')->update_pub( $guid, $new_data );

  foreach my $var ( keys %{ $c->session } ) {
    next if !( $var =~ /^grid_/ );
    my $plugin = $c->session->{$var};
    if ( $plugin->plugin_name eq 'DB' or $plugin->plugin_name eq 'Trash' ) {
      if ( $plugin->_hash->{ $guid } ) {
        delete( $plugin->_hash->{ $guid } );
        $plugin->_hash->{ $new_pub->guid } = $new_pub;
      }
    }
  }

  # That's handled as form on the front-end so we have to explicitly
  # indicate success
  $c->stash->{success} = \1;

  my $hash = $new_pub->as_hash;

  $c->stash->{data} = { pubs => { $guid => $hash } };

}

sub update_notes : Local {
  my ( $self, $c ) = @_;

  my $rowid = $c->request->params->{rowid};
  my $guid  = $c->request->params->{guid};
  my $html  = $c->request->params->{html};

  my $dbh = $c->model('Library')->dbh;

  my $value = $dbh->quote($html);
  $dbh->do("UPDATE Publications SET annote=$value WHERE rowid=$rowid");

  my $tree      = HTML::TreeBuilder->new->parse($html);
  my $formatter = HTML::FormatText->new( leftmargin => 0, rightmargin => 72 );
  my $text      = $formatter->format($tree);

  $value = $dbh->quote($text);

  $dbh->do("UPDATE Fulltext SET notes=$value WHERE rowid=$rowid");

  $c->stash->{data} = { pubs => { $guid => { annote => $html } } };

}


sub new_collection : Local {
  my ( $self, $c ) = @_;

  my $guid   = $c->request->params->{node_id};
  my $parent = $c->request->params->{parent_id};
  my $name   = $c->request->params->{text};
  my $type   = $c->request->params->{type};
  my $style  = $c->request->params->{style} || '0';

  $c->model('Library')->new_collection( $guid, $name, $type, $parent, $style );
}

sub move_in_collection : Local {
  my ( $self, $c ) = @_;

  my $grid_id = $c->request->params->{grid_id};
  my $guid    = $c->request->params->{guid};
  my $type    = $c->request->params->{type};
  my $data    = $self->_get_selection($c);

  my $what = $type eq 'FOLDER' ? 'folders' : 'tags';

  # First import entries that are not already in the database
  my @to_be_imported = ();
  foreach my $pub (@$data) {
    push @to_be_imported, $pub if !$pub->_imported;
  }

  $c->model('Library')->insert_pubs( \@to_be_imported, 1 );

  my $dbh = $c->model('Library')->dbh;


  if ( $guid ne 'FOLDER_ROOT' ) {
    my $new_guid = $guid;

    foreach my $pub (@$data) {
      my @guids = split( /,/, $pub->$what );
      push @guids, $new_guid;
      my %seen = ();
      @guids = grep { !$seen{$_}++ } @guids;
      my $new_guids = join( ',', @guids );
      $pub->$what($new_guids);
    }
    $c->model('Library')->update_collections( $data, $type );
  }


  if (@to_be_imported) {
    $self->_update_counts($c);
    $self->_collect_update_data( $c, $data, [ $what, '_imported', 'citekey', 'created', 'pdf' ] );
    $c->stash->{data}->{pub_delta}        = 1;
    $c->stash->{data}->{pub_delta_ignore} = $grid_id;
  } else {
    $self->_collect_update_data( $c, $data, [ $what ] );
  }
}

sub remove_from_collection : Local {
  my ( $self, $c ) = @_;

  my $collection_guid = $c->request->params->{collection_guid};
  my $type            = $c->request->params->{type};

  my $data = $self->_get_selection($c);

  my $what = $type eq 'FOLDER' ? 'folders' : 'tags';

  $c->model('Library')->remove_from_collection( $data, $collection_guid, $type );

  $self->_collect_update_data( $c, $data, [$what] );
}

sub delete_collection : Local {
  my ( $self, $c ) = @_;

  my $guid   = $c->request->params->{guid};
  my $type   = $c->request->params->{type};

  $c->model('Library')->delete_collection( $guid, $type );

  # Not sure if we need to update the tree structure in the
  # backend in some way here.

  my $what = $type eq 'FOLDER' ? 'folders' : 'tags';

  my $pubs = $self->_get_cached_data($c);
  foreach my $pub ( @$pubs ) {
    my $new_list = $pub->$what;
    $new_list =~ s/^$guid,//g;
    $new_list =~ s/^$guid$//g;
    $new_list =~ s/,$guid$//g;
    $new_list =~ s/,$guid,/,/g;
    $pub->$what($new_list);
  }

  $self->_collect_update_data($c, $pubs,[$what]);
}

sub rename_collection : Local {
  my ( $self, $c ) = @_;

  my $guid     = $c->request->params->{guid};
  my $new_name = $c->request->params->{new_name};

  $c->model('Library')->rename_collection( $guid, $new_name );

}

sub move_collection : Local {
  my ( $self, $c ) = @_;

  # The node that was moved
  my $drop_guid = $c->request->params->{drop_node};

  # The node to which it was moved
  my $target_guid = $c->request->params->{target_node};

  my $type = $c->request->params->{type};

  $drop_guid   =~ s/(FOLDER_|TAGS_)ROOT/ROOT/;
  $target_guid =~ s/(FOLDER_|TAGS_)ROOT/ROOT/;

  # Either 'append' for dropping into the node, or 'below' or 'above'
  # for moving nodes on the same level
  my $position = $c->request->params->{point};

  $c->model('Library')->move_collection( $target_guid, $drop_guid, $position, $type );

}

sub style_collection : Local {
  my ( $self, $c ) = @_;

  my $guid   = $c->request->params->{guid};
  my $style = $c->request->params->{style};

  $c->model('Library')->set_collection_style( $guid, $style );
}


sub list_labels : Local {

  my ( $self, $c ) = @_;

  my $sth = $c->model('Library')->dbh->prepare("SELECT * FROM Collections WHERE type='LABEL'");

  my @data = ();

  $sth->execute;
  while ( my $row = $sth->fetchrow_hashref() ) {
    push @data, {
      name   => $row->{name},
      style => $row->{style},
      guid  => $row->{guid},
      };
  }

  my %metaData = (
    root   => 'data',
    fields => [ 'name', 'style', 'guid' ],
  );

  $c->stash->{data} = [@data];

  $c->stash->{metaData} = {%metaData};

}

sub list_labels_sorted : Local {
  my ( $self, $c ) = @_;

  my $hist = $c->model('Library')->histogram('tags');
  my @data = ();

  foreach
    my $key ( sort { $hist->{$b}->{count} <=> $hist->{$a}->{count} || $a <=> $b } keys %$hist ) {
	my $tag = $hist->{$key};
    push @data, $tag;
  }

  $c->stash->{data} = \@data;
}


sub batch_download : Local {
  my ( $self, $c ) = @_;
  my $plugin  = $self->_get_plugin($c);

  my $data = $self->_get_selection($c);

  my $q = Paperpile::Queue->new();

  my @jobs = ();

  foreach my $pub (@$data) {
    my $j = Paperpile::Job->new(
      type => 'PDF_SEARCH',
      pub  => $pub,
    );

    $j->pub->_search_job( { id => $j->id, status => $j->status, msg => $j->info->{msg} } );

    push @jobs, $j;
  }

  $q->submit( \@jobs );
  $q->save;
  $q->run;
  $self->_collect_update_data($c, $data, ['_search_job'] );

  $c->stash->{data}->{job_delta} = 1;

  $c->detach('Paperpile::View::JSON');

}


sub attach_file : Local {
  my ( $self, $c ) = @_;

  my $guid  = $c->request->params->{guid};
  my $file   = $c->request->params->{file};
  my $is_pdf = $c->request->params->{is_pdf};

  my $grid_id = $c->request->params->{grid_id};
  my $plugin  = $c->session->{"grid_$grid_id"};

  my $pub = $plugin->find_guid($guid);

  $c->model('Library')->attach_file( $file, $is_pdf, $pub );

  $self->_collect_update_data($c,  [$pub], [ 'pdf', 'pdf_name', 'attachments', '_attachments_list' ] );

}

sub delete_file : Local {
  my ( $self, $c ) = @_;

  my $file_guid  = $c->request->params->{file_guid};
  my $pub_guid  = $c->request->params->{pub_guid};
  my $is_pdf = $c->request->params->{is_pdf};

  my $grid_id = $c->request->params->{grid_id};
  my $plugin  = $c->session->{"grid_$grid_id"};

  my $pub = $plugin->find_guid($pub_guid);

  my $undo_path = $c->model('Library')->delete_attachment( $file_guid, $is_pdf, $pub, 1 );

  $c->session->{"undo_delete_attachment"} = {
    file    => $undo_path,
    is_pdf  => $is_pdf,
    grid_id => $grid_id,
    pub_guid    => $pub_guid,
    file_guid => $file_guid
  };

  # Kind of a hack: delete the _search_job info before sending back our JSON update.
  if ($is_pdf) {
      delete $pub->{_search_job};
  }

  $self->_collect_update_data($c, [$pub], [ 'attachments', '_attachments_list', 'pdf', '_search_job' ] );

}

sub undo_delete : Local {
  my ( $self, $c ) = @_;

  my $undo_data = $c->session->{"undo_delete_attachment"};

  delete( $c->session->{undo_delete_attachment} );

  my $file   = $undo_data->{file};
  my $is_pdf = $undo_data->{is_pdf};

  my $grid_id = $undo_data->{grid_id};
  my $pub_guid    = $undo_data->{pub_guid};
  my $file_guid    = $undo_data->{file_guid};

  my $plugin  = $c->session->{"grid_$grid_id"};

  my $pub = $plugin->find_guid($pub_guid);

  my $attached_file = $c->model('Library')->attach_file( $file, $is_pdf, $pub, $file_guid );

  $self->_collect_update_data( $c, [$pub], [ 'pdf', 'attachments', '_attachments_list' ] );

}


# Returns the plugin object in the backend corresponding to an AJAX
# request from the frontend
sub _get_plugin {
  my ( $self, $c ) = @_;
  my $grid_id = $c->request->params->{grid_id};
  return $c->session->{"grid_$grid_id"};
}

# Gets data for a selection in the frontend from the plugin object cache
sub _get_selection {

  my ( $self, $c, $light_objects ) = @_;

  my $grid_id   = $c->request->params->{grid_id};
  my $selection = $c->request->params->{selection};
  my $plugin    = $self->_get_plugin($c);

  $plugin->light_objects($light_objects? 1 : 0);

  my @data = ();

  if ( $selection eq 'ALL' ) {
    @data = @{ $plugin->all };
  } else {
    my @tmp;
    if ( ref($selection) eq 'ARRAY' ) {
      @tmp = @$selection;
    } else {
      push @tmp, $selection;
    }
    for my $guid (@tmp) {
      my $pub = $plugin->find_guid($guid);
      if ( defined $pub ) {
        push @data, $pub;
      }
    }
  }

  return [@data];
}

# Returns a list of all publications objects from all current plugin
# objects (i.e. all open grid tabs in the frontend)
sub _get_cached_data {

  my ( $self, $c ) = @_;

  my @list = ();

  foreach my $var ( keys %{ $c->session } ) {
    next if !( $var =~ /^grid_/ );
    my $plugin = $c->session->{$var};
    foreach my $pub ( values %{ $plugin->_hash } ) {
      push @list, $pub;
    }
  }

  return [@list];
}

# If we add or delete items we need to update the overall count in the
# database plugins to make sure the number is up-to-date when it is
# reloaded the next time by the frontend.

sub _update_counts {

  my ( $self, $c ) = @_;

  foreach my $var ( keys %{ $c->session } ) {
    next if !( $var =~ /^grid_/ );
    my $plugin = $c->session->{$var};
    if ( $plugin->plugin_name eq 'DB' or $plugin->plugin_name eq 'Trash' ) {
      $plugin->update_count();
    }
  }
}

sub _collect_update_data {
  my ( $self, $c, $pubs, $fields ) = @_;

  $c->stash->{data} = {} unless ( defined $c->stash->{data} );

  my $max_output_size = 50;
  if ( scalar(@$pubs) > $max_output_size ) {
    $c->stash->{data}->{pub_delta} = 1;
    return ();
  }

  my %output = ();
  foreach my $pub (@$pubs) {
    my $hash = $pub->as_hash;

    my $pub_fields = {};
    if ($fields) {
      map { $pub_fields->{$_} = $hash->{$_} } @$fields;
    } else {
      $pub_fields = $hash;
    }
    $output{ $hash->{guid} } = $pub_fields;
  }

  $c->stash->{data}->{pubs} = \%output;
}


1;
