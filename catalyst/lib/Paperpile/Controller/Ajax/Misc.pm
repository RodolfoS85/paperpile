package Paperpile::Controller::Ajax::Misc;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Paperpile::Library::Publication;
use Paperpile::Utils;
use Data::Dumper;
use File::Spec;
use File::Path;
use File::Copy;
use 5.010;

sub reset_db : Local {

  my ( $self, $c ) = @_;

  $c->model('User')->init_db( $c->config->{pub_fields}, $c->config->{user_settings} );

  $c->stash->{success} = 'true';
  $c->forward('Paperpile::View::JSON');

}

sub tag_list : Local {

  my ( $self, $c ) = @_;

  my $tags=$c->model('User')->get_tags;

  my @data=();

  foreach my $row (@$tags){
    push @data, {tag  =>$row->{tag},
                 style=> $row->{style},
                };
  }

  my %metaData = (
   root          => 'data',
   fields        => ['tag', 'style'],
  );

  $c->stash->{data}          = [@data];

  $c->stash->{metaData}      = {%metaData};

  $c->forward('Paperpile::View::JSON');

}

sub journal_list : Local {

  my ( $self, $c ) = @_;
  my $query = $c->request->params->{query};

  my $model = $c->model('App');

  $query = $model->dbh->quote("$query*");

  my $sth = $model->dbh->prepare(
    "SELECT Journals.short, Journals.long FROM Journals 
     JOIN Journals_lookup ON Journals.rowid=Journals_lookup.rowid 
     WHERE Journals_lookup MATCH $query
     ORDER BY Journals.short LIMIT 100;"
  );

  my ( $short, $long );
  $sth->bind_columns( \$short, \$long );
  $sth->execute;

  my @data = ();
  while ( $sth->fetch ) {
    push @data, { long => $long, short => $short };
  }

  $c->stash->{data} = [@data];
  $c->forward('Paperpile::View::JSON');

}

sub get_settings : Local {

  my ( $self, $c ) = @_;

  my $tags=$c->model('User')->get_tags;

  my $user_settings=$c->model('User')->settings;
  my $app_settings=$c->model('App')->settings;

  my @list1=%$user_settings;
  my @list2=%$app_settings;

  my %merged=(@list1,@list2);

  $merged{pub_types}=$c->config->{pub_types};

  $c->stash->{data}  = {%merged};

  $c->forward('Paperpile::View::JSON');

}



sub import_journals : Local {
  my ( $self, $c ) = @_;

  my $file="/home/wash/play/Paperpile/data/jabref.txt";

  my $sth=$c->model('User')->dbh->prepare("INSERT INTO Journals (key,name) VALUES(?,?)");

  open( TMP, "<$file" );

  my %alreadySeen = ();

  while (<TMP>) {
    next if /^\s*\#/;
    ( my $long, my $short ) = split /=/, $_;
    $short =~ s/;.*$//;
    $short =~ s/[.,-]/ /g;
    $short =~ s/(^\s+|\s+$)//g;
    $long  =~ s/(^\s+|\s+$)//g;

    if ( not $alreadySeen{$short} ) {
      $alreadySeen{$short} = 1;
      next;
    }

    $sth->execute($short,$long);

  }

  $c->stash->{success} = 'true';
  $c->forward('Paperpile::View::JSON');

}

sub init_session : Local {

  my ( $self, $c ) = @_;

  # Clear session variables
  foreach my $key ( keys %{ $c->session } ) {
    delete( $c->session->{$key} ) if $key =~ /^(grid|viewer|tree|user_db|pdfextract)/;
  }

  # The path for the user database is given in the application database
  my $user_db;

  eval {
    ($user_db) = $c->model('App')->dbh->selectrow_array("SELECT value FROM Settings WHERE key='user_db' ");
  };

  # If we encounter an error while reading we stop here.
  if ($@){
    die("Could not read application database");
  };

  # If we get and empty value this shows us that our database has not been initialized yet after install.
  # We initialize it now.
  if ( not $user_db ) {
    $c->model('App')->init_db( $c->config->{app_settings} );
    $user_db=$c->model('App')->get_setting('user_db');
  }

  # If user_db does not exist, we initialize it with an empty db-file from the catalyst directory
  if ( not -e $user_db ) {
    $c->log->info("Created user database $user_db.");
    my ( $volume, $dir, $file ) = File::Spec->splitpath($user_db);
    mkpath($dir);
    copy( $c->path_to('db/user.db')->stringify, $user_db ) or die "Copy failed: $!";
    $c->session->{user_db} = $user_db;
    $c->model('User')->init_db( $c->config->{pub_fields}, $c->config->{user_settings} );

    # Copy the newly created database back to have an empty version
    # with all tables and fields which will be used as export template
    copy( $user_db, $c->path_to('db/local-user.db')->stringify ) or die "Copy failed: $!";
  } else {
    $c->session->{user_db} = $user_db;
  }

  $c->stash->{success} = 'true';
  $c->forward('Paperpile::View::JSON');

}


1;
