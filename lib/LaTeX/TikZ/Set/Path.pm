package LaTeX::TikZ::Set::Path;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Path - A set object representing a path.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use Any::Moose;
use Any::Moose 'Util::TypeConstraints'
               => [ qw/subtype as where find_type_constraint/ ];

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set::Op> and L<LaTeX::TikZ::Set::Mutable> roles, and as such implements the L</path> and L</add> methods.

=cut

with qw(
 LaTeX::TikZ::Set::Op
 LaTeX::TikZ::Set::Mutable
);

=head1 ATTRIBUTES

=head2 C<ops>

The L<LaTeX::TikZ::Set::Op> objects that from the path.

=cut

subtype 'LaTeX::TikZ::Set::Path::Elements'
     => as 'Object'
     => where { $_->does('LaTeX::TikZ::Set::Op') };

has '_ops' => (
 is       => 'ro',
 isa      => 'Maybe[ArrayRef[LaTeX::TikZ::Set::Path::Elements]]',
 init_arg => 'ops',
 default  => sub { [ ] },
);

sub ops { @{$_[0]->_ops} }

=head1 METHODS

=head2 C<add>

=cut

my $ltspe_tc = find_type_constraint('LaTeX::TikZ::Set::Path::Elements');

sub add {
 my $set = shift;

 $ltspe_tc->assert_valid($_) for @_;

 push @{$set->_ops}, @_;

 $set;
}

=head2 C<path>

=cut

sub path {
 my $set = shift;

 join ' ', map $_->path(@_), $set->ops;
}

LaTeX::TikZ::Interface->register(
 path => sub {
  shift;

  __PACKAGE__->new(ops => \@_);
 },
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $set, @args) = @_;
  $set->new(ops => [ map $_->$functor(@args), $set->ops ])
 }
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set::Op>, L<LaTeX::TikZ::Set::Mutable>.

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

1; # End of LaTeX::TikZ::Set::Path
