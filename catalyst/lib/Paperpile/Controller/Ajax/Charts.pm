package Paperpile::Controller::Ajax::Charts;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Paperpile::Library::Publication;
use Data::Dumper;
use 5.010;

sub test : Local {

  my ( $self, $c ) = @_;

  my $sth =
    $c->model('Library')
    ->dbh->prepare(
    'SELECT author_id, first, last FROM Authors, Author_Publication WHERE author_id == Authors.rowid;'
    );
  my ( $author_id, $first, $last );
  $sth->bind_columns( \$author_id, \$first, \$last );
  $sth->execute;

  my %hist = ();

  while ( $sth->fetch ) {
    my $name = $last . ", " . $first;
    if ( exists $hist{$name} ) {
      $hist{$name}++;
    } else {
      $hist{$name} = 1;
    }
  }

  my @values = ();
  my @labels = ();

  my $counter = 0;

  foreach my $name ( sort { $hist{$b} <=> $hist{$a} } keys %hist ) {
    push @values, $hist{$name};
    push @labels, $name;
    $counter++;
    last if $counter >= 10;
  }

  my $chart = {
    "bg_colour" => "#FFFEEB",
    elements    => [ {
        type   => 'bar_glass',
        alpha  => 0.5,
        colour => "#006AFF",
        values => [@values],
       "on-show" => { "type" => "grow-up",
                       "cascade" => 0,
                       "delay" => 0 }
      },
    ],
    y_axis => {
      'min'         => 0,
      'max'         => $values[0] + 10,
      steps         => 5,
      "grid-colour" => "#FFFFFF",
      "colour"      => "#000000",
      "font-size"   => 26
    },

    #y_legend => { text => 'Number of Publications' },
    x_axis => {
      "grid-colour" => "#FFFFFF",
      labels        => {
        rotate => 315,
        labels => [@labels]
      },
      "colour" => "#000000"
    },
  };

  foreach my $key ( keys %$chart ) {
    $c->stash->{$key} = $chart->{$key};
  }

}

1;
