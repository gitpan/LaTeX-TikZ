package LaTeX::TikZ::Formatter;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Formatter - LaTeX::TikZ formatter object.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

A formatter object turns a L<LaTeX::TikZ::Set> tree into the actual TikZ code, depending on some parameters such as the scale, the unit or the origin.

=cut

use Sub::Name ();

use LaTeX::TikZ::Point;

use LaTeX::TikZ::Interface;

use LaTeX::TikZ::Tools;

use Any::Moose;
use Any::Moose 'Util::TypeConstraints';

=head1 ATTRIBUTES

=head2 C<unit>

=cut

has 'unit' => (
 is      => 'ro',
 isa     => enum([ qw/cm pt/ ]),
 default => 'cm',
);

=head2 C<format>

=cut

has 'format' => (
 is      => 'ro',
 isa     => 'Str',
 default => '%s',
);

=head2 C<scale>

=cut

has 'scale' => (
 is      => 'rw',
 isa     => 'Num',
 default => 1,
);

=head2 C<width>

=cut

has 'width' => (
 is  => 'rw',
 isa => 'Maybe[Num]',
);

=head2 C<height>

=cut

has 'height' => (
 is  => 'rw',
 isa => 'Maybe[Num]',
);

=head2 C<origin>

=cut

has 'origin' => (
 is     => 'rw',
 isa    => 'LaTeX::TikZ::Point::Autocoerce',
 coerce => 1,
);

=head1 METHODS

=head2 C<id>

=cut

sub id {
 my $tikz = shift;

 my $origin = $tikz->origin;
 if (defined $origin) {
  my ($x, $y) = map $origin->$_, qw/x y/;
  $origin = "($x;$y)";
 } else {
  $origin = "(0;0)";
 }

 join $;, map {
  defined() ? "$_" : '(undef)';
 } map($tikz->$_, qw/unit format scale width height/), $origin;
}

=head2 C<render>

=cut

my $find_mods = do {
 our %seen;

 my $find_mods_rec;
 $find_mods_rec = do {
  no warnings 'recursion';

  Sub::Name::subname('find_mods_rec' => sub {
   my ($set, $layers, $others) = @_;

   for ($set->mods) {
    my $tag = $_->tag;
    next if $seen{$tag}++;

    if ($_->isa('LaTeX::TikZ::Mod::Layer')) {
     push @$layers, $_;
    } else {
     push @$others, $_;
    }
   }

   my @subsets = $set->isa('LaTeX::TikZ::Set::Sequence')
                 ? $set->kids
                 : $set->isa('LaTeX::TikZ::Set::Path')
                   ? $set->ops
                   : ();

   $find_mods_rec->($_, $layers, $others) for @subsets;
  });
 };

 Sub::Name::subname('find_mods' => sub {
  local %seen = ();

  $find_mods_rec->(@_);
 });
};

my $translate;

sub render {
 my ($tikz, @sets) = @_;

 unless ($translate) {
  require LaTeX::TikZ::Functor;
  $translate = LaTeX::TikZ::Functor->new(
   rules => [
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
   ],
  );
 }

 my $origin = $tikz->origin;
 if (defined $origin) {
  @sets = map $_->$translate($origin), @sets;
 }

 my (@layers, @other_mods);
 my $seq = LaTeX::TikZ::Set::Sequence->new(kids => \@sets);
 $find_mods->($seq, \@layers, \@other_mods);

 my $w = $tikz->width;
 my $h = $tikz->height;
 my $canvas = '';
 if (defined $w and defined $h) {
  require LaTeX::TikZ::Set::Rectangle;
  for (@sets) {
   $_->clip(LaTeX::TikZ::Set::Rectangle->new(
    from   => 0,
    width  => $w,
    height => $h,
   ));
  }
  $_ = $tikz->len($_) for $w, $h;
  $canvas = ",papersize={$w,$h},body={$w,$h}";
 }

 my @header = (
  "\\usepackage[pdftex,hcentering,vcentering$canvas]{geometry}",
  "\\usepackage{tikz}",
  "\\usetikzlibrary{patterns}",
 );

 my @decls;
 push @decls, LaTeX::TikZ::Mod::Layer->declare(@layers) if  @layers;
 push @decls, $_->declare($tikz)                        for @other_mods;

 my @bodies = map [
  "\\begin{tikzpicture}",
  @{ $_->draw($tikz) },
  "\\end{tikzpicture}",
 ], @sets;

 return \@header, \@decls, @bodies;
}

=head2 C<len>

=cut

sub len {
 my ($tikz, $len) = @_;

 $len = 0 if LaTeX::TikZ::Tools::numeq($len, 0);

 sprintf $tikz->format . $tikz->unit, $len * $tikz->scale;
}

=head2 C<angle>

=cut

sub angle {
 my ($tikz, $a) = @_;

 $a = ($a * 180) / CORE::atan2(0, -1);
 $a += 360 if LaTeX::TikZ::Tools::numcmp($a, 0) < 0;

 require POSIX;
 sprintf $tikz->format, POSIX::ceil($a);
}

=head2 C<label>

=cut

sub label {
 my ($tikz, $name, $pos) = @_;

 my $scale = sprintf '%0.2f', $tikz->scale / 5;

 "node[scale=$scale,$pos] {$name}";
}

=head2 C<thickness>

=cut

sub thickness {
 my ($tikz, $width) = @_;

 # width=1 is 0.4 points for a scale of 2.5
 0.8 * $width * ($tikz->scale / 5);
}

LaTeX::TikZ::Interface->register(
 formatter => sub {
  shift;

  __PACKAGE__->new(@_);
 },
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-tikz at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-TikZ>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::TikZ

=head1 COPYRIGHT & LICENSE

Copyright 2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of LaTeX::TikZ::Formatter
