#!perl

use strict;
use warnings;

use Test::More tests => 5 + 2 * 5;

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

my $translate = eval {
 Tikz->functor(
  'LaTeX::TikZ::Set::Point' => sub {
   my ($functor, $set, $v) = @_;

   $set->new(
    point => [
     $set->x + $v->x,
     $set->y + $v->y,
    ],
    label => $set->label,
    pos   => $set->pos,
   );
  },
 );
};
is $@, '', 'creating a translator doesn\'t croak';

my $seq = Tikz->seq(
                 Tikz->point,
                 Tikz->raw('foo'),
                 Tikz->point(2),
                 Tikz->line(-1 => 3)
                     ->clip(Tikz->circle(1, 1))
                )
              ->clip(Tikz->rectangle([0, -1] => [2, 3]));

my $seq2 = eval {
 $seq->$translate(Tikz->point(-1, 1));
};
is $@, '', 'translating a sequence doesn\'t croak';

check $seq, 'the original sequence', <<'RES';
\begin{scope}
\clip (0cm,-1cm) rectangle (2cm,3cm) ;
\draw (0cm,0cm) ;
\draw foo ;
\draw (2cm,0cm) ;
\begin{scope}
\clip (1cm,0cm) circle (1cm) ;
\draw (-1cm,0cm) -- (3cm,0cm) ;
\end{scope}
\end{scope}
RES

check $seq2, 'the translated sequence', <<'RES';
\begin{scope}
\clip (-1cm,0cm) rectangle (1cm,4cm) ;
\draw (-1cm,1cm) ;
\draw foo ;
\draw (1cm,1cm) ;
\begin{scope}
\clip (0cm,1cm) circle (1cm) ;
\draw (-2cm,1cm) -- (2cm,1cm) ;
\end{scope}
\end{scope}
RES

my $strip = eval {
 Tikz->functor(
  'LaTeX::TikZ::Mod' => sub { return },
 );
};
is $@, '', 'creating a stripper doesn\'t croak';

$_->mod(Tikz->color('red')) for $seq2->kids;

my $seq3 = eval {
 $seq2->$strip;
};
is $@, '', 'stripping a sequence doesn\'t croak';

check $seq2, 'the original sequence', <<'RES';
\begin{scope} [color=red]
\clip (-1cm,0cm) rectangle (1cm,4cm) ;
\draw (-1cm,1cm) ;
\draw foo ;
\draw (1cm,1cm) ;
\begin{scope}
\clip (0cm,1cm) circle (1cm) ;
\draw (-2cm,1cm) -- (2cm,1cm) ;
\end{scope}
\end{scope}
RES

check $seq3, 'the stripped sequence', <<'RES';
\draw (-1cm,1cm) ;
\draw foo ;
\draw (1cm,1cm) ;
\draw (-2cm,1cm) -- (2cm,1cm) ;
RES

$tikz = eval {
 Tikz->formatter(
  origin => [ -1, 1 ],
 );
};
is $@, '', 'creating a formatter object with an origin doesn\'t croak';

check $seq, 'a sequence translated by an origin', <<'RES';
\begin{scope}
\clip (-1cm,0cm) rectangle (1cm,4cm) ;
\draw (-1cm,1cm) ;
\draw foo ;
\draw (1cm,1cm) ;
\begin{scope}
\clip (0cm,1cm) circle (1cm) ;
\draw (-2cm,1cm) -- (2cm,1cm) ;
\end{scope}
\end{scope}
RES

