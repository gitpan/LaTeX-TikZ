package LaTeX::TikZ::Meta::TypeConstraint::Autocoerce;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Meta::TypeConstraint::Autocoerce - Type constraint metaclass that autoloads type coercions.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Sub::Name ();

use Any::Moose;

extends any_moose('Meta::TypeConstraint');

=head1 ATTRIBUTES

=head2 C<mapper>

=cut

has 'mapper' => (
 is  => 'ro',
 isa => 'CodeRef',
);

=head2 C<parent_name>

=cut

has 'parent_name' => (
 is       => 'ro',
 isa      => 'ClassName',
 required => 1,
);

=head2 C<user_constraint>

=cut

has 'user_constraint' => (
 is       => 'ro',
 isa      => 'Maybe[CodeRef]',
 required => 1,
);

=head1 METHODS

=cut

around 'new' => sub {
 my ($orig, $class, %args) = @_;

 unless (exists $args{mapper}) {
  $args{mapper} = sub { join '::', $_[0]->parent_name, $_[1] };
 }

 my $parent = delete $args{parent};
 $args{parent_name} = defined $parent
                      ? (blessed($parent) ? $parent->name : $parent)
                      : '__ANON__';

 $args{user_constraint} = $args{constraint};

 if (any_moose() eq 'Moose') {
  $args{coercion} = Moose::Meta::TypeCoercion->new;
 }

 my $parent_name = $args{parent_name};
 $parent_name =~ s/::+/_/g;

 my $tc;
 $args{constraint} = Sub::Name::subname('_load' => sub {
  $tc->load(@_);
 });

 $tc = $class->$orig(%args);
};

=head2 C<load>

=cut

sub load {
 my ($tc, $thing) = @_;

 # First, try a possible user defined constraint
 my $user = $tc->user_constraint;
 if (defined $user) {
  my $ok = $user->($thing);
  return 1 if $ok;
 }

 # When ->check is called inside coerce, a return value of 0 means that
 # coercion should take place, while 1 signifies that the value is already
 # OK.

 my $class = blessed($thing);
 return 0 unless $class;
 return 1 if     $class->isa($tc->parent_name);

 my $mapper = $tc->mapper;
 my $pm = $class = $tc->$mapper($class);

 $pm =~ s{::}{/}g;
 $pm .= '.pm';
 return 0 if $INC{$pm}; # already loaded

 local $@;
 eval { require $pm; 1 };

 return 0;
}

around 'coerce' => sub {
 my ($orig, $tc, $thing) = @_;

 # The original coerce gets an hold onto the type coercions *before* calling
 # the constraint. Thus, we have to force the loading before recalling into
 # $orig. This is achieved by calling ->load.
 return $thing if $tc->load($thing);

 $tc->$orig($thing);
};

__PACKAGE__->meta->make_immutable(
 inline_constructor => 0,
);

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

1; # End of LaTeX::TikZ::Meta::TypeConstraint::Autocoerce
