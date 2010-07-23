package LaTeX::TikZ::Set::Polyline;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Polyline - A set object representing a possibly closed path composed of contiguous lines.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use LaTeX::TikZ::Set::Point;

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use Any::Moose;
use Any::Moose 'Util::TypeConstraints';

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set::Op> role, and as such implements the L</path> method.

=cut

with 'LaTeX::TikZ::Set::Op';

subtype 'LaTeX::TikZ::Set::Polyline::Vertices'
     => as 'ArrayRef[LaTeX::TikZ::Set::Point]'
     => where { @$_ >= 2 }
     => message { 'at least two LaTeX::TikZ::Set::Point objects are needed in order to build a polyline' };

coerce 'LaTeX::TikZ::Set::Polyline::Vertices'
    => from 'ArrayRef[Any]'
    => via { [ map LaTeX::TikZ::Set::Point->new(point => $_), @$_ ] };

=head1 ATTRIBUTES

=head2 C<points>

The list of the successive vertices of the path.

=cut

has '_points' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Set::Polyline::Vertices',
 init_arg => 'points',
 required => 1,
 coerce   => 1,
);

sub points { @{$_[0]->_points} }

=head2 C<closed>

A boolean that indicates whether the path is closed or not.

=cut

has 'closed' => (
 is      => 'ro',
 isa     => 'Bool',
 default => 0,
);

=head1 METHODS

=head2 C<path>

=cut

sub path {
 my $set = shift;

 join ' -- ', map($_->path(@_), $set->points),
              ($set->closed ? 'cycle' : ());
}

LaTeX::TikZ::Interface->register(
 polyline => sub {
  shift;

  __PACKAGE__->new(points => \@_);
 },
 closed_polyline => sub {
  shift;

  __PACKAGE__->new(points => \@_, closed => 1);
 },
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $set, @args) = @_;
  $set->new(
   points => [ map $_->$functor(@args), $set->points ],
   closed => $set->closed,
  );
 }
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set::Op>.

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

1; # End of LaTeX::TikZ::Set::Polyline
