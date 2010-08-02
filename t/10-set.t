#!perl -T

use strict;
use warnings;

use Test::More tests => 12 + 2 * 7;

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

my $foo = eval {
 Tikz->raw('foo');
};
is $@, '', 'creating a raw set doesn\'t croak';

check $foo, 'one raw set', <<'RES';
\draw foo ;
RES

my $seq2 = eval {
 Tikz->seq($foo, $foo);
};
is $@, '', 'creating a 2-sequence doesn\'t croak';

check $seq2, 'two identical raw sets', <<'RES';
\draw foo ;
\draw foo ;
RES

my $bar = eval {
 Tikz->raw('bar');
};
is $@, '', 'creating another raw set doesn\'t croak';

$seq2 = eval {
 Tikz->seq($foo, $bar);
};
is $@, '', 'creating another 2-sequence doesn\'t croak';

check $seq2, 'two different raw sets', <<'RES';
\draw foo ;
\draw bar ;
RES

my $seq3 = eval {
 Tikz->seq($bar, $seq2, $foo);
};
is $@, '', 'creating a complex sequence doesn\'t croak';

check $seq3, 'two different raw sets and a sequence', <<'RES';
\draw bar ;
\draw foo ;
\draw bar ;
\draw foo ;
RES

my $baz = eval {
 Tikz->raw('baz');
};
is $@, '', 'creating yet another raw set doesn\'t croak';

eval {
 $foo->add($baz);
};
like $@, qr/Can't locate object method "add"/,
                                         'adding something to a raw set croaks';

eval {
 $seq2->add($baz, $baz);
};
is $@, '', 'adding something to a sequence set doesn\'t croak';

check $seq3, 'two different raw sets and an extended sequence', <<'RES';
\draw bar ;
\draw foo ;
\draw bar ;
\draw baz ;
\draw baz ;
\draw foo ;
RES

sub failed_valid {
 my ($tc) = @_;
 qr/Validation failed for '\Q$tc\E'/;
}

eval {
 Tikz->path($foo, $seq2);
};
like $@, failed_valid('Maybe[ArrayRef[LaTeX::TikZ::Set::Op]]'),
         'creating a path that contains a sequence croaks';

my $path = eval {
 Tikz->path($foo, $bar, $baz);
};
is $@, '', 'creating a path set doesn\'t croak';

check $path, 'one path set', <<'RES';
\draw foo bar baz ;
RES

eval {
 $path->add($foo);
};
is $@, '', 'adding something to a path set doesn\'t croak';

check Tikz->seq($path, $path), 'two identical path sets', <<'RES';
\draw foo bar baz foo ;
\draw foo bar baz foo ;
RES

eval {
 $path->add($seq2);
};
like $@, failed_valid('LaTeX::TikZ::Set::Op'),
         'adding a sequence to a path croaks';
