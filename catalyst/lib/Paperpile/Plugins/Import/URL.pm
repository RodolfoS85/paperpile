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

package Paperpile::Plugins::Import::URL;

use Moose;
use Moose::Util::TypeConstraints;
use 5.010;

use Paperpile::Utils;
use Paperpile::MetaCrawler;
use Data::Dumper;

extends 'Paperpile::Plugins::Import';

sub BUILD {
  my $self = shift;
  $self->plugin_name('URL');
}


sub match {

  ( my $self, my $pub ) = @_;

  if ( $pub->best_link eq '' or $pub->best_link =~ m/(\.doc|\.pdf)$/ ) {
    NetMatchError->throw( error => 'No match found resolving URL.' )
  }

  print STDERR "\n\n===================================================\n";
  print STDERR $pub->best_link,"\n";

  my $crawler = Paperpile::MetaCrawler->new;
  $crawler->debug(0);
  $crawler->driver_file( Paperpile::Utils->path_to( 'data', 'meta-crawler.xml' )->stringify );
  $crawler->load_driver();

  my $fullpub = undef;
  eval { $fullpub = $crawler->search_file( $pub->best_link ) };

  print STDERR $fullpub->title(),"\n\n\n";

  NetMatchError->throw( error => 'No match found resolving URL.' ) if ( !$fullpub );

  return $fullpub;
}

1;