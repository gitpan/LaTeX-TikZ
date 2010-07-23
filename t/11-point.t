#!perl -T

use strict;
use warnings;

use Test::More tests => 8 + 2 * 8;

use Math::Complex;

use LaTeX::TikZ;

my $tikz = Tikz->formatter(
 format => '%d',
);

sub check {
 my ($set, $desc, $exp) = @_;

 local $Test::Builder::Level = $Test::Builder::Level + 1;

 my ($head, $decl, $body) = eval {
  $tikz->render(ref $set eq 'ARRAY' ? @$set : $set);
 };
 is $@, '', "$desc: no error";

 unless (ref $exp eq 'ARRAY') {
  $exp = [ split /\n/, $exp ];
 }
 unshift @$exp, '\begin{tikzpicture}';
 push    @$exp, '\end{tikzpicture}';

 is_deeply $body, $exp, $desc;
}

my $z = Math::Complex->make(1, 2);

my $p = eval {
 Tikz->point($z);
};
is $@, '', 'creating a point from a Math::Complex object doesn\'t croak';

check $p, 'a point from a Math::Complex object', <<'RES';
\draw (1cm,2cm) ;
RES

$p = eval {
 Tikz->point(1-2*i);
};
is $@, '', 'creating a point from a Math::Complex constant object doesn\'t croak';

check $p, 'a point from a constant Math::Complex object', <<'RES';
\draw (1cm,-2cm) ;
RES

$p = eval {
 Tikz->point;
};
is $@, '', 'creating a point from nothing doesn\'t croak';

check $p, 'a point from nothing', <<'RES';
\draw (0cm,0cm) ;
RES

$p = eval {
 Tikz->point(-7);
};
is $@, '', 'creating a point from a numish constant doesn\'t croak';

check $p, 'a point from a numish constant', <<'RES';
\draw (-7cm,0cm) ;
RES

$p = eval {
 Tikz->point(5,-1);
};
is $@, '', 'creating a point from two numish constants doesn\'t croak';

check $p, 'a point from two numish constants', <<'RES';
\draw (5cm,-1cm) ;
RES

$p = eval {
 Tikz->point([-3, 2]);
};
is $@, '', 'creating a point from an array ref doesn\'t croak';

check $p, 'a point from an array ref', <<'RES';
\draw (-3cm,2cm) ;
RES

$p = eval {
 Tikz->point(
  [1,-1],
  label => 'foo',
 );
};
is $@, '', 'creating a labeled point from an array ref doesn\'t croak';

check $p, 'a labeled point', <<'RES';
\draw (1cm,-1cm) [fill] circle (0.4pt) node[scale=0.20,above] {foo} ;
RES

$p = eval {
 Tikz->point(
  [2,-2],
  label => 'bar',
  pos   => 'below right',
 );
};
is $@, '',
         'creating a labeled positioned point from an array ref doesn\'t croak';

check $p, 'a labeled positioned point', <<'RES';
\draw (2cm,-2cm) [fill] circle (0.4pt) node[scale=0.20,below right] {bar} ;
RES
