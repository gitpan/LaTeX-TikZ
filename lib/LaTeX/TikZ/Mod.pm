package LaTeX::TikZ::Mod;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Mod - Base role for LaTeX::TikZ modifiers.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This role should be consumed by all the modifier classes.

=cut

use Any::Moose 'Role';
use Any::Moose 'Util::TypeConstraints';

=head1 METHODS

These methods are required by the interface :

=over 4

=item *

C<tag>

=item *

C<cover>

=item *

C<declare>

=item *

C<apply>

=back

=cut

requires qw(
 tag
 cover
 declare
 apply
);

coerce 'LaTeX::TikZ::Mod'
    => from 'Str'
    => via { LaTeX::TikZ::Mod::Raw->new(content => $_) };

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

1; # End of LaTeX::TikZ::Mod
