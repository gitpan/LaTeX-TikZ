package LaTeX::TikZ;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ - Perl object model for generating PGF/TikZ code.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use LaTeX::TikZ;

    # A couple of lines
    my $hline = Tikz->line(-1 => 1);
    my $vline = Tikz->line([ 0, -1 ] => [ 0, -1 ]);

    # Paint them in red
    $_->mod(Tikz->color('red')) for $hline, $vline;

    # An octogon
    use Math::Complex;
    my $octo = Tikz->closed_polyline(
     map Math::Complex->emake(1, ($_ * pi)/4), 0 .. 7
    );

    # Only keep a portion of it
    $octo->clip(Tikz->rectangle(-0.5*(1+i), 2*(1+i)));

    # Fill it with dots
    $octo->mod(Tikz->pattern(class => 'Dots'));

    # Create a formatter object
    my $tikz = Tikz->formatter;

    # Put those objects all together and print them
    my $seq = Tikz->seq($octo, $hline, $vline);
    my ($head, $decl, $body) = $tikz->render($seq);
    print "$_\n" for map @$_, $head, $decl, $body;

=head1 DESCRIPTION

This module provides an object model for TikZ, a graphical tookit for LaTeX.
It allows you to build structures representing geometrical figures, apply a wide set of modifiers on them, transform them globally with functors, and print them in the context of an existing TeX document.

=head1 CONCEPTS

Traditionnaly, in TikZ, there are two ways of grouping elements, or I<ops>, together :

=over 4

=item *

either as a I<sequence>, where each element is drawn in its own line :

    \draw (0cm,0cm) -- (0cm,1cm) ;
    \draw (0cm,0cm) -- (1cm,0cm) ;

=item *

or as a I<path>, where elements are all drawn as one line :

    \draw (0cm,0cm) -- (0cm,1cm) (0cm,0cm) -- (1cm,0cm) ;

=back

This distinction is important because there are some primitves that only apply to paths but not to sequences, and vice versa.

Figures are made of ops, path or sequence I<sets> assembled together in a tree.

I<Modifiers> can be applied onto any set to alter the way in which it is generated.
The two TikZ concepts of I<clips> and I<layers> have been unified with the modifiers.

=head1 INTERFACE

=head2 Containers

=head3 C<< Tikz->path(@ops) >>

Creates a L<LaTeX::TikZ::Set::Path> object out of the ops C<@ops>.

    # A path made of two circles
    Tikz->path(
           Tikz->circle(0, 1),
           Tikz->circle(1, 1),
          )
        ->mod(
           Tikz->fill('red'),
           'even odd rule',
          );

=head3 C<< Tikz->seq(@kids) >>

Creates a L<LaTeX::TikZ::Set::Sequence> object out of the sequences, paths or ops C<@kids>.

    my $bag = Tikz->seq($sequence, $path, $circle, $raw, $point);

=head2 Elements

Those are the building blocks of your geometrical figure.

=head3 C<< Tikz->point($point) >>

Creates a L<LaTeX::TikZ::Set::Point> object by coercing C<$point> into a L<LaTeX::TikZ::Point>.
The following rules are available :

=over 4

=item *

If C<$point> isn't given, the point defaults to C<(0, 0)>.

    my $origin = Tikz->point;

=item *

If C<$point> is a numish Perl scalar, it is treated as C<($point, 0)>.

    my $unit = Tikz->point(1);

=item *

If two numish scalars C<$x> and C<$y> are given, they result in the point C<($x, $y)>.

    my $one_plus_i = Tikz->point(1, 1);

=item *

If C<$point> is an array reference, it is parsed as C<< ($point->[0], $point->[1]) >>.

    my $i = Tikz->point([ 0, 1 ]);

=item *

If C<$point> is a L<Math::Complex> object, the L<LaTeX::TikZ::Point::Math::Complex>  class is automatically loaded and the point is coerced into C<< ($point->Re, $point->Im) >>.

    my $j = Tikz->point(Math::Complex->emake(1, 2*pi/3));

=back

You can define automatic coercions from your user point types to L<LaTeX::TikZ::Point> by writing your own L<LaTeX::TikZ::Point::My::User::Point> class.
See L<LaTeX::TikZ::Meta::TypeConstraint::Autocoerce> for the rationale and L<LaTeX::TikZ::Point::Math::Complex> for an example.

=head3 C<< Tikz->line($from => $to) >>

Creates a L<LaTeX::TikZ::Set::Line> object between the points C<$from> and C<$to>.

    my $x_axis = Tikz->line(-5 => 5);
    my $y_axis = Tikz->line([ 0, -5 ] => [ 0, 5 ]);

=head3 C<< Tikz->polyline(@points) >>

Creates a L<LaTeX::TikZ::Set::Polyline> object that links the successive elements of C<@points> by segments.

    my $U = Tikz->polyline(
     Tikz->point(0, 1),
     Tikz->point(0, 0),
     Tikz->point(1, 0),
     Tikz->point(1, 1),
    );

=head3 C<< Tikz->closed_polyline(@points) >>

Creates a L<LaTeX::TikZ::Set::Polyline> object that cycles through successive eleemnts of C<@points>.

    my $diamond = Tikz->closed_polyline(
     Tikz->point(0, 1),
     Tikz->point(-1, 0),
     Tikz->point(0, -2),
     Tikz->point(1, 0),
    );

=head3 C<< Tikz->rectangle($from => $to), Tikz->rectangle($from => { width => $width, height => $height }) >>

Creates a L<LaTeX::TikZ::Set::Rectangle> object with opposite corners C<$from> and C<$to>, or with anchor point C<$from> and dimensions C<$width> and C<$height>.

    my $square = Tikz->rectangle(
     Tikz->point,
     Tikz->point(2, 1),
    );

=head3 C<< Tikz->circle($center, $radius) >>

Creates a L<LaTeX::TikZ::Set::Circle> object of center C<$center> and radius C<$radius>.

    my $unit_circle = Tikz->circle(0, 1);

=head3 C<< Tikz->arc($from => $to, $center) >>

Creates a L<LaTeX::TikZ::Set> structure that represents an arc going from C<$from> to C<$to> with center C<$center>.

    # An arc. The points are automatically coerced into LaTeX::TikZ::Set::Point objects
    my $quarter = Tikz->arc(
     [ 1, 0 ] => [ 0, 1 ],
     [ 0, 0 ]
    );

=head3 C<< Tikz->arrow($from => $to), Tikz->arrow($from => dir => $dir) >>

Creates a L<LaTeX::TikZ::Set> structure that represents an arrow going from C<$from> towards C<$to>, or starting at C<$from> in direction C<$dir>.

    # An horizontal arrow
    my $arrow = Tikz->arrow(0 => 1);

=head3 C<< Tikz->raw($content) >>

Creates a L<LaTeX::TikZ::Set::Raw> object that will instantiate to the raw TikZ code C<$content>.

=head2 Modifiers

Modifiers are applied onto sets by calling the C<< ->mod >> method, like in C<< $set->mod($mod) >>.
This method returns the C<$set> object, so it can be chained.

=head3 C<< Tikz->clip($path) >>

Creates a L<LaTeX::TikZ::Mod::Clip> object that can be used to clip a given sequence by the (closed) path C<$path>.

    my $box = Tikz->clip(
     Tikz->rectangle(0 => [ 1, 1 ]),
    );

Clips can also be directly applied to sets with the C<< ->clip >> method.

    my $set = Tikz->circle(0, 1.5)
                  ->clip(Tikz->rectangle([-1, -1] => [1, 1]));

=head3 C<< Tikz->layer($name, above => \@above, below => \@below) >>

Creates a L<LaTeX::TikZ::Mod::Layer> object with name C<$name> and optional relative positions C<@above> and C<@below>.

    my $layer = Tikz->layer(
     'top'
     above => [ 'main' ],
    );

The default layer is C<main>.

Layers are stored into a global hash, so that when you refer to them by their name, you get the existing layer object. 

Layers can also be directly applied to sets with the C<< ->layer >> method.

    my $dots = Tikz->rectangle(0 => [ 1, 1 ])
                   ->mod(Tikz->pattern(class => 'Dots'))
                   ->layer('top');

=head3 C<< Tikz->width($line_width) >>

Creates a L<LaTeX::TikZ::Mod::Width> object that sets the line width to C<$line_width> when applied.

    my $thick_arrow = Tikz->arrow(0 => 1)
                          ->mod(Tikz->width(5));

=head3 C<< Tikz->color($color) >>

Creates a L<LaTeX::TikZ::Mod::Color>object that sets the line color to C<$color> (given in the C<xcolor> syntax).

    # Paint the previous $thick_arrow in red.
    $thick_arrow->mod(Tikz->color('red'));

=head3 C<< Tikz->fill($color) >>

Creates a L<LaTeX::TikZ::Mod::Fill> object that fills the interior of a path with the solid color C<$color> (given in the C<xcolor> syntax).

    my $red_box = Tikz->rectangle(0 => { width => 1, height => 1 })
                      ->mod(Tikz->fill('red'));

=head3 C<< Tikz->pattern(class => $class, %args) >>

Creates a L<LaTeX::TikZ::Mod::Pattern> object of class C<$class> and arguments C<%args> that fills the interior of a path with the specified pattern.
C<$class> is prepended with C<LaTeX::TikZ::Mod::Pattern> when it doesn't contain C<::>.
See L<LaTeX::TikZ::Mod::Pattern::Dots> and L<LaTeX::TikZ::Mod::Pattern::Lines> for two examples of pattern classes.

    my $hatched_circle = Tikz->circle(0 => 1)
                             ->mod(Tikz->pattern(class => 'Lines'));

=head3 C<< Tikz->raw_mod($content) >>

Creates a L<LaTeX::TikZ::Mod::Raw> object that will instantiate to the raw TikZ mod code C<$content>.

    my $homemade_arrow = Tikz->line(0 => 1)
                             ->mod(Tikz->raw_mod('->')) # or just ->mod('->')

=head2 Helpers

=head3 C<< Tikz->formatter(%args) >>

Creates a L<LaTeX::TikZ::Formatter> object that can render a L<LaTeX::TikZ::Set> tree.

    my $tikz = Tikz->formatter;
    my ($header, $declarations, $seq1_body, $seq2_body) = $tikz->render($set1, $set2);

=head3 C<< Tikz->functor(@rules) >>

Creates a L<LaTeX::TikZ::Functor> anonymous subroutine that can be called against L<LaTeX::TikZ::Set> trees to clone them according to the given rules.
C<@rules> should be made of array references whose first element is the class/role to match against and the second the handler to run.

    # The default is a clone method
    my $clone = Tikz->functor;
    my $dup = $set->$clone;

    # A translator
    my $translate = Tikz->functor(
     'LaTeX::TikZ::Set::Point' => sub {
      my ($functor, $set, $x, $y) = @_;

      $set->new(
       point => [
        $set->x + $x,
        $set->y + $y,
       ],
       label => $set->label,
       pos   => $set->pos,
      );
     },
    );
    my $shifted = $set->$translate(1, 1);

    # A mod stripper
    my $strip = Tikz->functor(
     'LaTeX::TikZ::Mod' => sub { return },
    );
    my $naked = $set->$strip;

=cut

use LaTeX::TikZ::Interface;

sub import {
 shift;

 my %args = @_;
 my $name = $args{as};
 $name = 'Tikz' unless defined $name;
 unless ($name =~ /^[a-z_][a-z0-9_]*$/i) {
  require Carp;
  Carp::confess('Invalid name');
 }

 my $pkg   = caller;
 my $const = sub () { 'LaTeX::TikZ::Interface' };
 {
  no strict 'refs';
  *{$pkg . '::' . $name} = $const;
 }

 LaTeX::TikZ::Interface->load;

 return;
}

=head1 DEPENDENCIES

L<Any::Moose> with L<Mouse> 0.63 or greater.

L<Sub::Name>.

L<Scope::Guard>.

L<Math::Complex>, L<Math::Trig>.

L<Scalar::Util>, L<List::Util>, L<Task::Weaken>.

=head1 SEE ALSO

PGF/TikZ - L<http://pgf.sourceforge.net>.

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

1; # End of LaTeX::TikZ
