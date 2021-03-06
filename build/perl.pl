#!/usr/bin/perl -w

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



use Config;

# Small wrapper to ensure the right perl is called

my $platform='';
my $arch_string=$Config{archname};

if ( $arch_string =~ /linux/i ) {
  $platform = ($arch_string =~ /64/) ? 'linux64' : 'linux32';
}

if ( $arch_string =~ /(darwin|osx)/i ) {
  $platform = 'osx';
}

# On windows we start this with some perl that comes with mysysgit
if ( $arch_string eq 'msys' ) {
  $platform = 'win32';
}


if ($ENV{PERL5LIB}){
  $ENV{PERL5LIB}=undef;
}

$ENV{BUILD_PLATFORM}=$platform;

exec("../plack/perl5/$platform/bin/paperperl " . join(" ",@ARGV));

