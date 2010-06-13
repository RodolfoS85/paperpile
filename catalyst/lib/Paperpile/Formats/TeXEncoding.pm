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

package Paperpile::Formats::TeXEncoding;

use strict;
use warnings;

our %encoding_table = (

  # Characters in the range 0xA0-0xFF of the ISO 8859-1 character set.
  chr(0x0023) => '\#',
  chr(0x0024) => '\\$',
  chr(0x0025) => '\\%',
  chr(0x0026) => '\&',
  chr(0x003c) => '$<$',
  chr(0x003e) => '$>$',
  chr(0x005c) => '\\textbackslash',
  chr(0x005e) => '\\^{}',
  chr(0x005f) => '\\_',
  chr(0x007b) => '\\{',
  chr(0x007d) => '\\}',
  chr(0x007e) => '\\~{}',
  #chr(0x00a0) => '~',
  chr(0x00a1) => '!`',
  #chr(0x00a2) => '\\textcent',
  chr(0x00a3) => '\\pounds',
  chr(0x00a7) => '\\S',
  chr(0x00a8) => '\\"{}',
  chr(0x00a9) => '\\copyright',
  chr(0x00af) => '\\={}',
  chr(0x00ac) => '$\\neg$',
  chr(0x00ad) => '\\-',
  chr(0x00ae) => '\\textregistered',
  #chr(0x00af) => '\\textasciimacron',
  chr(0x00b0) => '\\mbox{$^\\circ$}',
  chr(0x00b1) => '\\mbox{$\\pm$}',
  chr(0x00b2) => '\\mbox{$^2$}',
  chr(0x00b3) => '\\mbox{$^3$}',
  chr(0x00b4) => "\\'{}",
  chr(0x00b5) => '\\mbox{$\\mu$}',
  chr(0x00b6) => '\\P',
  chr(0x00b7) => '\\mbox{$\\cdot$}',
  chr(0x00b8) => '\\c{}',
  chr(0x00b9) => '\\mbox{$^1$}',
  chr(0x00bf) => '?`',
  chr(0x00c0) => '\\`A',
  chr(0x00c1) => "\\'A",
  chr(0x00c2) => '\\^A',
  chr(0x00c3) => '\\~A',
  chr(0x00c4) => '\\"A',
  chr(0x00c5) => '\\AA',
  chr(0x00c6) => '\\AE',
  chr(0x00c7) => '\\c{C}',
  chr(0x00c8) => '\\`E',
  chr(0x00c9) => "\\'E",
  chr(0x00ca) => '\\^E',
  chr(0x00cb) => '\\"E',
  chr(0x00cc) => '\\`I',
  chr(0x00cd) => "\\'I",
  chr(0x00ce) => '\\^I',
  chr(0x00cf) => '\\"I',
  chr(0x00d1) => '\\~N',
  chr(0x00d2) => '\\`O',
  chr(0x00d3) => "\\'O",
  chr(0x00d4) => '\\^O',
  chr(0x00d5) => '\\~O',
  chr(0x00d6) => '\\"O',
  chr(0x00d7) => '\\mbox{$\\times$}',
  chr(0x00d8) => '\\O',
  chr(0x00d9) => '\\`U',
  chr(0x00da) => "\\'U",
  chr(0x00db) => '\\^U',
  chr(0x00dc) => '\\"U',
  chr(0x00dd) => "\\'Y",
  chr(0x00df) => '\\ss',
  chr(0x00e0) => '\\`a',
  chr(0x00e1) => "\\'a",
  chr(0x00e2) => '\\^a',
  chr(0x00e3) => '\\~a',
  chr(0x00e4) => '\\"a',
  chr(0x00e5) => '\\aa',
  chr(0x00e6) => '\\ae',
  chr(0x00e7) => '\\c{c}',
  chr(0x00e8) => '\\`e',
  chr(0x00e9) => "\\'e",
  chr(0x00ea) => '\\^e',
  chr(0x00eb) => '\\"e',
  chr(0x00ec) => '\\`\\i',
  chr(0x00ed) => "\\'\\i",
  chr(0x00ee) => '\\^\\i',
  chr(0x00ef) => '\\"\\i',
  chr(0x00f1) => '\\~n',
  chr(0x00f2) => '\\`o',
  chr(0x00f3) => "\\'o",
  chr(0x00f4) => '\\^o',
  chr(0x00f5) => '\\~o',
  chr(0x00f6) => '\\"o',
  chr(0x00f7) => '\\mbox{$\\div$}',
  chr(0x00f8) => '\\o',
  chr(0x00f9) => '\\`u',
  chr(0x00fa) => "\\'u",
  chr(0x00fb) => '\\^u',
  chr(0x00fc) => '\\"u',
  chr(0x00fd) => "\\'y",
  chr(0x00ff) => '\\"y',

  chr(0x0100) => '\\=A',
  chr(0x0101) => '\\=a',
  chr(0x0102) => '\\u{A}',
  chr(0x0103) => '\\u{a}',
  chr(0x0104) => '\\c{A}',
  chr(0x0105) => '\\c{a}',
  chr(0x0106) => "\\'C",
  chr(0x0107) => "\\'c",
  chr(0x0108) => "\\^C",
  chr(0x0109) => "\\^c",
  chr(0x010a) => "\\.C",
  chr(0x010b) => "\\.c",
  chr(0x010c) => "\\v{C}",
  chr(0x010d) => "\\v{c}",
  chr(0x010e) => "\\v{D}",
  chr(0x010f) => "\\v{d}",
  chr(0x0112) => '\\=E',
  chr(0x0113) => '\\=e',
  chr(0x0114) => '\\u{E}',
  chr(0x0115) => '\\u{e}',
  chr(0x0116) => '\\.E',
  chr(0x0117) => '\\.e',
  chr(0x0118) => '\\c{E}',
  chr(0x0119) => '\\c{e}',
  chr(0x011a) => "\\v{E}",
  chr(0x011b) => "\\v{e}",
  chr(0x011c) => '\\^G',
  chr(0x011d) => '\\^g',
  chr(0x011e) => '\\u{G}',
  chr(0x011f) => '\\u{g}',
  chr(0x0120) => '\\.G',
  chr(0x0121) => '\\.g',
  chr(0x0122) => '\\c{G}',
  chr(0x0123) => '\\c{g}',
  chr(0x0124) => '\\^H',
  chr(0x0125) => '\\^h',
  chr(0x0128) => '\\~I',
  chr(0x0129) => '\\~\\i',
  chr(0x012a) => '\\=I',
  chr(0x012b) => '\\=\\i',
  chr(0x012c) => '\\u{I}',
  chr(0x012d) => '\\u\\i',
  chr(0x012e) => '\\c{I}',
  chr(0x012f) => '\\c{i}',
  chr(0x0130) => '\\.I',
  chr(0x0131) => '\\i',
  chr(0x0134) => '\\^J',
  chr(0x0135) => '\\^\\j',
  chr(0x0136) => '\\c{K}',
  chr(0x0137) => '\\c{k}',
  chr(0x0139) => "\\'L",
  chr(0x013a) => "\\'l",
  chr(0x013b) => "\\c{L}",
  chr(0x013c) => "\\c{l}",
  chr(0x013d) => "\\v{L}",
  chr(0x013e) => "\\v{l}",
  chr(0x0141) => '\\L',
  chr(0x0142) => '\\l',
  chr(0x0143) => "\\'N",
  chr(0x0144) => "\\'n",
  chr(0x0145) => "\\c{N}",
  chr(0x0146) => "\\c{n}",
  chr(0x0147) => "\\v{N}",
  chr(0x0148) => "\\v{n}",
  chr(0x014c) => '\\=O',
  chr(0x014d) => '\\=o',
  chr(0x014e) => '\\u{O}',
  chr(0x014f) => '\\u{o}',
  chr(0x0150) => '\\H{O}',
  chr(0x0151) => '\\H{o}',
  chr(0x0152) => '\\OE',
  chr(0x0153) => '\\oe',
  chr(0x0154) => "\\'R",
  chr(0x0155) => "\\'r",
  chr(0x0156) => "\\c{R}",
  chr(0x0157) => "\\c{r}",
  chr(0x0158) => "\\v{R}",
  chr(0x0159) => "\\v{r}",
  chr(0x015a) => "\\'S",
  chr(0x015b) => "\\'s",
  chr(0x015c) => "\\^S",
  chr(0x015d) => "\\^s",
  chr(0x015e) => "\\c{S}",
  chr(0x015f) => "\\c{s}",
  chr(0x0160) => "\\v{S}",
  chr(0x0161) => "\\v{s}",
  chr(0x0162) => "\\c{T}",
  chr(0x0163) => "\\c{t}",
  chr(0x0164) => "\\v{T}",
  chr(0x0165) => "\\v{t}",
  chr(0x0168) => "\\~U",
  chr(0x0169) => "\\~u",
  chr(0x016a) => "\\=U",
  chr(0x016b) => "\\=u",
  chr(0x016c) => "\\u{U}",
  chr(0x016d) => "\\u{u}",
  chr(0x016e) => "\\r{U}",
  chr(0x016f) => "\\r{u}",
  chr(0x0170) => "\\H{U}",
  chr(0x0171) => "\\H{u}",
  chr(0x0172) => "\\c{U}",
  chr(0x0173) => "\\c{u}",
  chr(0x0174) => "\\^W",
  chr(0x0175) => "\\^w",
  chr(0x0176) => "\\^Y",
  chr(0x0177) => "\\^y",
  chr(0x0178) => '\\"Y',
  chr(0x0179) => "\\'Z",
  chr(0x017a) => "\\'Z",
  chr(0x017b) => "\\.Z",
  chr(0x017c) => "\\.Z",
  chr(0x017d) => "\\v{Z}",
  chr(0x017e) => "\\v{z}",

  chr(0x01cd) => "\\v{A}",
  chr(0x01ce) => "\\v{a}",
  chr(0x01cf) => "\\v{I}",
  chr(0x01d0) => "\\v\\i",
  chr(0x01d1) => "\\v{O}",
  chr(0x01d2) => "\\v{o}",
  chr(0x01d3) => "\\v{U}",
  chr(0x01d4) => "\\v{u}",

  chr(0x01e6) => "\\v{G}",
  chr(0x01e7) => "\\v{g}",
  chr(0x01e8) => "\\v{K}",
  chr(0x01e9) => "\\v{k}",
  chr(0x01ea) => "\\c{O}",
  chr(0x01eb) => "\\c{o}",
  chr(0x01f0) => "\\v\\j",
  chr(0x01f4) => "\\'G",
  chr(0x01f5) => "\\'g",
  chr(0x01fc) => "\\'\\AE",
  chr(0x01fd) => "\\'\\ae",
  chr(0x01fe) => "\\'\\O",
  chr(0x01ff) => "\\'\\o",

  chr(0x02c6) => '\\^{}',
  chr(0x02dc) => '\\~{}',
  chr(0x02d8) => '\\u{}',
  chr(0x02d9) => '\\.{}',
  chr(0x02da) => "\\r{}",
  chr(0x02dd) => '\\H{}',
  chr(0x02db) => '\\c{}',
  chr(0x02c7) => '\\v{}',

  # Greek letters
  chr(0x0391) => '$\\mathrm{A}$',
  chr(0x0392) => '$\\mathrm{B}$',
  chr(0x0393) => '$\\Gamma$',
  chr(0x0394) => '$\\Delta$',
  chr(0x0395) => '$\\mathrm{E}$',
  chr(0x0396) => '$\\mathrm{Z}$',
  chr(0x0397) => '$\\mathrm{H}$',
  chr(0x0398) => '$\\Theta$',
  chr(0x0399) => '$\\mathrm{I}$',
  chr(0x039a) => '$\\mathrm{K}$',
  chr(0x039b) => '$\\Lambda$',
  chr(0x039c) => '$\\mathrm{M}$',
  chr(0x039d) => '$\\mathrm{N}$',
  chr(0x039e) => '$\\Xi$',
  chr(0x039f) => '$\\mathrm{O}$',
  chr(0x03a0) => '$\\Pi$',
  chr(0x03a1) => '$\\mathrm{R}$',
  chr(0x03a3) => '$\\Sigma$',
  chr(0x03a4) => '$\\mathrm{T}$',
  chr(0x03a5) => '$\\Upsilon$',
  chr(0x03a6) => '$\\Phi$',
  chr(0x03a7) => '$\\mathrm{X}$',
  chr(0x03a8) => '$\\Psi$',
  chr(0x03a9) => '$\\Omega$',
  chr(0x03b1) => '$\\alpha$',
  chr(0x03b2) => '$\\beta$',
  chr(0x03b3) => '$\\gamma$',
  chr(0x03b4) => '$\\delta$',
  chr(0x03b5) => '$\\epsilon$',
  chr(0x03b6) => '$\\zeta$',
  chr(0x03b7) => '$\\eta$',
  chr(0x03b8) => '$\\theta$',
  chr(0x03b9) => '$\\iota$',
  chr(0x03ba) => '$\\kappa$',
  chr(0x03bb) => '$\\lambda$',
  chr(0x03bc) => '$\\mu$',
  chr(0x03bd) => '$\\nu$',
  chr(0x03be) => '$\\xi$',
  chr(0x03bf) => '$o$',
  chr(0x03c0) => '$\\pi$',
  chr(0x03c1) => '$\\rho$',
  chr(0x03c3) => '$\\sigma$',
  chr(0x03c4) => '$\\tau$',
  chr(0x03c5) => '$\\upsilon$',
  chr(0x03c6) => '$\\phi$',
  chr(0x03c7) => '$\\chi$',
  chr(0x03c8) => '$\\psi$',
  chr(0x03c9) => '$\\omega$',

  chr(0xfb00) => 'ff',
  chr(0xfb01) => 'fi',
  chr(0xfb02) => 'fl',
  chr(0xfb03) => 'ffi',
  chr(0xfb04) => 'ffl',

  chr(0x2013) => '--',
  chr(0x2014) => '---',
  chr(0x2018) => "`",
  chr(0x2019) => "'",
  chr(0x201c) => "``",
  chr(0x201d) => "''",
  chr(0x2020) => "\\dag",
  chr(0x2021) => '\\ddag',
  chr(0x2122) => '\\mbox{$^\\mbox{TM}$}',
  chr(0x2022) => '\\mbox{$\\bullet$}',
  chr(0x2026) => '\\ldots',
  chr(0x2202) => '\\mbox{$\\partial$}',
  chr(0x220f) => '\\mbox{$\\prod$}',
  chr(0x2211) => '\\mbox{$\\sum$}',
  chr(0x221a) => '\\mbox{$\\surd$}',
  chr(0x221e) => '\\mbox{$\\infty$}',
  chr(0x222b) => '\\mbox{$\\int$}',
  chr(0x2248) => '\\mbox{$\\approx$}',
  chr(0x2260) => '\\mbox{$\\neq$}',
  chr(0x2264) => '\\mbox{$\\leq$}',
  chr(0x2265) => '\\mbox{$\\geq$}',

);

our $encoded_chars = join( '', sort keys %encoding_table );
$encoded_chars =~ s/\\/\\\\/;
$encoded_chars = qr{ [$encoded_chars] }x;
