package Paperpile::Controller::Ajax::Attachments;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Paperpile::Utils;
use Paperpile::Library::Publication;
use Data::Dumper;
use File::Path;
use File::Spec;
use File::Copy;
use URI::file;

use File::stat;
use 5.010;

sub attach_file : Local {
  my ( $self, $c ) = @_;

  my $rowid  = $c->request->params->{rowid};
  my $file   = $c->request->params->{file};
  my $is_pdf = $c->request->params->{is_pdf};

  my $grid_id = $c->request->params->{grid_id};
  my $sha1    = $c->request->params->{sha1};
  my $plugin  = $c->session->{"grid_$grid_id"};

  my $settings = $c->model('User')->settings;
  my $pub      = $plugin->find_sha1($sha1);

  my $source = Paperpile::Utils->adjust_root($file);

  if ($is_pdf){

    # File name relative to [paper_root] is [pdf_pattern].pdf
    my $relative_dest = $pub->format_pattern( $settings->{pdf_pattern}, { key => $pub->citekey } );

    # Absolute  path is [paper_root]/[pdf_pattern].pdf
    my $absolute_dest = File::Spec->catfile( $settings->{paper_root}, $relative_dest ) . ".pdf";

    $self->_copy_file($source, $absolute_dest);

    $c->model('User')->update_field('Publications', $rowid, 'pdf', $relative_dest);
    $c->stash->{pdf_file} = $relative_dest;

  } else {

    # Get file_name without dir
    my ($volume,$dirs,$file_name) = File::Spec->splitpath( $source );

    # Path relative to [paper_root] is [attachment_pattern]/$file_name
    my $relative_dest = $pub->format_pattern( $settings->{attachment_pattern}, { key => $pub->citekey } );
    $relative_dest = File::Spec->catfile( $relative_dest, $file_name);

    # Absolute  path is [paper_root]/[attachment_pattern]/$file_name
    my $absolute_dest = File::Spec->catfile( $settings->{paper_root}, $relative_dest );

    $self->_copy_file($source, $absolute_dest);

    $c->model('User')->add_attachment($relative_dest, $rowid);

  }

  $c->stash->{success} = 'true';
  $c->forward('Paperpile::View::JSON');

}

sub list_files : Local {
  my ( $self, $c ) = @_;

  my $rowid  = $c->request->params->{rowid};

  my $sth = $c->model('User')->dbh->prepare("SELECT rowid, file_name FROM Attachments WHERE publication_id=$rowid;");
  my ( $attachment_rowid, $file_name );
  $sth->bind_columns( \$attachment_rowid, \$file_name );
  $sth->execute;

  my $paper_root=$c->model('User')->get_setting('paper_root');

  my @output=();
  while ( $sth->fetch ) {

    my $abs=File::Spec->catfile( $paper_root, $file_name );

    # TODO: serve file via Catalyst
    my $link=URI::file->new($abs)->as_string;

    my ($volume,$dirs,$base_name) = File::Spec->splitpath( $abs );

    push @output, {file=>$base_name, link=>$link, rowid=> $attachment_rowid};

  }

  $c->stash->{list}=[@output];

  $c->stash->{success} = 'true';
  $c->forward('Paperpile::View::JSON');

}


sub _copy_file{

  my ( $self, $source, $dest ) = @_;

  # Create directory if not already exists
  my ($volume,$dirs,$file_name) = File::Spec->splitpath( $dest );
  mkpath($dirs);

  ## Todo check if unique

  # copy the file
  copy($source, $dest);

}



1;