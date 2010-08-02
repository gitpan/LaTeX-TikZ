package LaTeX::TikZ::Meta::TypeConstraint::Autocoerce;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Meta::TypeConstraint::Autocoerce - Type constraint metaclass that autoloads type coercions.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    # The target class of the autocoercion (cannot be changed)
    {
     package X;
     use Any::Moose;
     has 'id' => (
      is  => 'ro',
      isa => 'Int',
     );
     use LaTeX::TikZ::Meta::TypeConstraint::Autocoerce;
     use Any::Moose 'Util::TypeConstraints';
     register_type_constraint(
      LaTeX::TikZ::Meta::TypeConstraint::Autocoerce->new(
       name   => 'X::Autocoerce',
       parent => find_type_constraint(__PACKAGE__),
       mapper => sub { join '::', __PACKAGE__, 'From', $_[1] },
      );
     );
     __PACKAGE__->meta->make_immutable;
    }

    # The class that does the coercion (cannot be changed)
    {
     package Y;
     use Any::Moose;
     has 'x' => (
      is      => 'ro',
      isa     => 'X::Autocoerce',
      coerce  => 1,
      handles => [ 'id' ],
     );
     __PACKAGE__->meta->make_immutable;
    }

    # Another class the user wants to use instead of X (cannot be changed)
    {
     package Z;
     use Any::Moose;
     has 'id' => (
      is  => 'ro',
      isa => 'Num',
     );
     __PACKAGE__->meta->make_immutable;
    }

    # The autocoercion class, defined by the user in X/From/Z.pm
    {
     package X::From::Z;
     use Any::Moose 'Util::TypeConstraints';
     coerce 'X::Autocoerce'
         => from 'Z'
         => via { X->new(id => int $_->id) };
    }

    my $z = Z->new(id => 123);
    my $y = Y->new(x => $z);
    print $y->id; # 123

=head1 DESCRIPTION

This type constraint metaclass tries to autoload a specific module when a type coercion is attempted, which is supposed to contain the actual coercion code.
This allows you to declare types that can be replaced (through coercion) at the end user's discretion.

It works with both L<Moose> and L<Mouse> by using L<Any::Moose>.

Note that you will need L<Moose::Util::TypeConstraints/register_type_constraint> or L<Mouse::Util::TypeConstraints/register_type_constraint> to install this type constraint, and that the latter is only available starting L<Mouse> C<0.63>.

=cut

use Scalar::Util qw/blessed/;

use Sub::Name ();

use Any::Moose;
use Any::Moose 'Util' => [ 'find_meta' ];

=head1 RELATIONSHIPS

This class inherits from L<Moose::Meta::TypeConstraint> or L<Mouse::Meta::TypeConstraint>, depending on which mode L<Any::Moose> runs.

=cut

extends any_moose('Meta::TypeConstraint');

=head1 ATTRIBUTES

=head2 C<name>

The name of the type constraint.
This must be the target of both the classes that want to use the autocoercion feature and the user defined coercions in the autoloaded classes.

This attribute is inherited from the L<Moose> or L<Mouse> type constraint metaclass.

=head2 C<mapper>

A code reference that maps an object class name to the name of the package in which the coercion can be found, or C<undef> to disable coercion for this class name.
It is called with the type constraint object as first argument, followed by the class name.

=cut

has 'mapper' => (
 is       => 'ro',
 isa      => 'CodeRef',
 required => 1,
);

=head2 C<parent>

A type constraint that defines which objects are already valid and do not need to be coerced.
This is somewhat different from L<Moose::Meta::TypeConstraint/parent>.
If it is given as a plain string, then a type constraint with the same name is searched for in the global type constraint registry.

=cut

has 'parent' => (
 is       => 'ro',
 isa      => any_moose('Meta::TypeConstraint'),
 required => 1,
);

=head2 C<user_constraint>

An optional user defined code reference which predates checking the parent for validity.

=cut

has 'user_constraint' => (
 is  => 'ro',
 isa => 'Maybe[CodeRef]',
);

=head1 METHODS

=head2 C<< new name => $name, mapper => $mapper, parent => $parent, [ user_constraint => sub { ... } ] >>

Constructs a type constraint object that will attempt to autocoerce objects that are not valid according to C<$parent> by loading the class returned by C<$mapper>.

=cut

around 'new' => sub {
 my ($orig, $class, %args) = @_;

 unless (exists $args{mapper}) {
  $args{mapper} = sub { join '::', $_[0]->parent->name, $_[1] };
 }

 my $parent = delete $args{parent};
 unless (defined $parent and blessed $parent) {
  $parent = find_meta($parent);
  Carp::confess("No meta object for parent $parent");
  $parent = $parent->type_constraint;
 }
 __PACKAGE__->meta->find_attribute_by_name('parent')
                  ->type_constraint->assert_valid($parent);
 $args{parent} = $parent;

 if (any_moose() eq 'Moose') {
  $args{coercion} = Moose::Meta::TypeCoercion->new;
 }

 my $tc;
 $args{constraint} = Sub::Name::subname('_constraint' => sub {
  my ($thing) = @_;

  # Remember that when ->check is called inside coerce, a return value of 0
  # means that coercion should take place, while 1 signifies that the value is
  # already OK.

  # First, try a possible user defined constraint
  my $user = $tc->user_constraint;
  if (defined $user) {
   my $ok = $user->($thing);
   return 1 if $ok;
  }

  # Then, it's valid if and only if it passes the parent type constraint
  return $tc->parent->check($thing);
 });

 $tc = $class->$orig(%args);
};

=head2 C<coerce $thing>

Tries to coerce C<$thing> by first loading a class that might contain a type coercion for it.

=cut

around 'coerce' => sub {
 my ($orig, $tc, $thing) = @_;

 # The original coerce gets an hold onto the type coercions *before* calling
 # the constraint. Thus, we have to force the loading before recalling into
 # $orig.

 # First, check whether $thing is already of the right kind.
 return $thing if $tc->check($thing);

 # If $thing isn't even an object, don't bother trying to autoload a coercion
 my $class = blessed($thing);
 if (defined $class) {
  $class = $tc->mapper->($tc, $class);

  if (defined $class) {
   # Find the file to autoload
   (my $pm = $class) =~ s{::}{/}g;
   $pm .= '.pm';

   unless ($INC{$pm}) { # Not loaded yet
    local $@;
    eval {
     # We die often here, even though we're not really interested in the error.
     # However, if a die handler is set (e.g. to \&Carp::confess), this can get
     # very slow. Resetting the handler shows a 10% total time improvement for
     # the geodyn app.
     local $SIG{__DIE__};
     require $pm;
    };
   }
  }
 }

 $tc->$orig($thing);
};

__PACKAGE__->meta->make_immutable(
 inline_constructor => 0,
);

=head1 SEE ALSO

L<Moose::Meta::TypeConstraint>, L<Mouse::Meta::TypeConstraint>.

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
