package LaTeX::TikZ::Set::Op;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Op - A role for set objects that can be part of a path.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

Ops are the components of a path.
They can be built together to form a path.
Thus, they are all the elements against which we can call the C<path> method.

=cut

use Any::Moose 'Role';

=head1 RELATIONSHIPS

This role consumes the L<LaTeX::TikZ::Set> role, and as such implements the L</draw> method.

=cut

with 'LaTeX::TikZ::Set';

=head1 METHODS

This method is required by the interface :

=over 4

=item *

C<path $formatter>

Returns the TikZ code that builds a path out of the current set object as a string formatted by the L<LaTeX::TikZ::Formatter> object C<$formatter>.

=back

=cut

requires qw(
 path
);

=head2 C<draw>

=cut

sub draw {
 my $set = shift;

 [ "\\draw " . $set->path(@_) . ' ;' ];
}

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set>.

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

1; # End of LaTeX::TikZ::Set::Op;
