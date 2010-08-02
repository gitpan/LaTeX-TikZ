#!perl -T

use strict;
use warnings;

use Test::More tests => 7 * 4;

use lib 't/lib';

use LaTeX::TikZ::Meta::TypeConstraint::Autocoerce;

{
 package LaTeX::TikZ::TestX;

 use Any::Moose;
 use Any::Moose 'Util::TypeConstraints' => [ qw/
  coerce
  from
  via
  find_type_constraint
  register_type_constraint
 / ];

 has 'id' => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
 );

 register_type_constraint(
  LaTeX::TikZ::Meta::TypeConstraint::Autocoerce->new(
   name   => 'LaTeX::TikZ::TestX::Autocoerce',
   parent => find_type_constraint(__PACKAGE__),
   mapper => sub {
    shift;
    my ($last) = $_[0] =~ /::([^:]+)$/;
    join '::', __PACKAGE__, "From$last";
   },
  ),
 );

 coerce 'LaTeX::TikZ::TestX::Autocoerce'
     => from 'LaTeX::TikZ::TestX'
     => via { $_ };

 coerce 'LaTeX::TikZ::TestX::Autocoerce'
     => from 'Int'
     => via { __PACKAGE__->new(id => $_) };

 __PACKAGE__->meta->make_immutable;

 sub main::X () { __PACKAGE__ }
}

{
 package LaTeX::TikZ::TestY;

 use Any::Moose;

 has 'num' => (
  is       => 'ro',
  isa      => 'Num',
  required => 1,
 );

 __PACKAGE__->meta->make_immutable;

 sub main::Y () { __PACKAGE__ }
}

{
 package LaTeX::TikZ::TestZ;

 use Any::Moose;

 has 'x' => (
  is       => 'ro',
  isa      => 'LaTeX::TikZ::TestX::Autocoerce',
  required => 1,
  coerce   => 1,
 );

 __PACKAGE__->meta->make_immutable;

 sub main::Z () { __PACKAGE__ }
}

{
 package LaTeX::TikZ::TestW;

 use Any::Moose;
 use Any::Moose 'Util::TypeConstraints';

 has 'x' => (
  is       => 'ro',
  isa      => 'LaTeX::TikZ::TestX',
  required => 1,
 );

 coerce 'LaTeX::TikZ::TestX::Autocoerce'
     => from __PACKAGE__
     => via { $_->x };

 __PACKAGE__->meta->make_immutable;

 sub main::W () { __PACKAGE__ }
}

my $y = Y->new(
 num => '3.14159',
);

my $y2 = Y->new(
 num => exp(1),
);

my $time = time;
my $x0 = X->new(
 id => $time,
);

my $w = W->new(
 x => $x0,
);

my @tests = (
 [ 123, 123,   'autocoerce X from int'       ],
 [ $x0, $time, 'autocoerce X from X'         ],
 [ $x0, $time, 'autocoerce X from X twice'   ],
 [ $y,  3,     'autocoerce X from Y'         ],
 [ $y2, 2,     'autocoerce X from another Y' ],
 [ $w,  $time, 'autocoerce X from W'         ],
 [ $w,  $time, 'autocoerce X from W twice'   ],
);

for my $test (@tests) {
 my ($x, $exp, $desc) = @$test;
 my $z = eval {
  Z->new(x => $x);
 };
 my $err = $@;
 if (ref $exp eq 'Regexp') {
  like $err, $exp, "could not $desc";
  fail "$desc placeholder $_" for 1 .. 3;
 } else {
  is     $err,   '',   "$desc doesn't croak";
  isa_ok $z,     Z(),  "$desc returns a Z object";
  $x = $z->x;
  isa_ok $x,     X(),  "$desc stores an X into the Z object";
  is     $x->id, $exp, "$desc correctly";
 }
}
