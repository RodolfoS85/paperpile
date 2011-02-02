
# Copyright 2009-2011 Paperpile
#
# This file is part of Paperpile
#
# Paperpile is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

# Paperpile is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.  You should have
# received a copy of the GNU Affero General Public License along with
# Paperpile.  If not, see http://www.gnu.org/licenses.



package Paperpile::MetaCrawler::Targets::Ris;
use Moose;
extends 'Paperpile::MetaCrawler::Targets';

use Paperpile::Formats;

sub convert {

  my ($self, $content) = @_;

  my $f = Paperpile::Formats->new(format=>'RIS');
  my $pub = $f->read_string($content);

  return $pub->[0];

}
