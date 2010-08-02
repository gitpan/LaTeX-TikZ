package LaTeX::TikZ::Functor::Rule;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Functor::Rule - An object that specifies how functors should handle a certain kind of set or mod.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

A rule specifies how functors (L<LaTeX::TikZ::Functor> objects) should handle a certain kind of set or mod.
A functor is basically an ordered collection of rules.

=cut

use Carp ();

use Any::Moose;
use Any::Moose 'Util' => [ qw[find_meta does_role] ];
use Any::Moose 'Util::TypeConstraints';

=head1 ATTRIBUTES

=head2 C<target>

A class or role name against which set or mod candidates will be matched.
It must consume either L<LaTeX::TikZ::Set> or L<LaTeX::TikZ::Mod>, directly or through inheritance.

=cut

has 'target' => (
 is       => 'ro',
 isa      => 'ClassName|RoleName',
 required => 1,
);

=head2 C<handler>

The code reference executed when the rule handles a given set or mod object.
It is called with the L<LaTeX::TikZ::Functor> object as its first argument, the set/mod object as its second, and then the arguments passed to the functor itself.

=cut

has 'handler' => (
 is       => 'ro',
 isa      => 'CodeRef',
 required => 1,
);

=head2 C<is_role>

True if and only if the target is a role.

=cut

has 'is_role' => (
 is       => 'ro',
 isa      => 'Bool',
 required => 1,
);

=head2 C<is_set>

True when the target does the L<LaTeX::TikZ::Set> role, and false when it does L<LaTeX::TikZ::Mod>.

=cut

has 'is_set' => (
 is       => 'ro',
 isa      => 'Bool',
 required => 1,
);

my $ltfrl_tc = subtype 'LaTeX::TikZ::Functor::RuleList'
                    => as 'ArrayRef[LaTeX::TikZ::Functor::Rule]';

=head1 METHODS

=head2 C<< new target => $target, handler => $handler >>

Constructs a new rule object with target C<$target> and handler C<$handler>.

=cut

around 'BUILDARGS' => sub {
 my ($orig, $class, %args) = @_;

 my $target = $args{target};
 __PACKAGE__->meta->find_attribute_by_name('target')
                  ->type_constraint->assert_valid($target);

 (my $pm = $target) =~ s{::}{/}g;
 $pm .= '.pm';
 require $pm;

 my $meta = find_meta($target);
 Carp::confess("No meta object associated with target $target")
                                                           unless defined $meta;
 $args{is_role} = $meta->isa(any_moose('Meta::Role'));

 my $is_set;
 if (does_role($target, 'LaTeX::TikZ::Set')) {
  $is_set = 1;
 } elsif (does_role($target, 'LaTeX::TikZ::Mod')) {
  $is_set = 0;
 } else {
  Carp::confess("Target $target is neither a set nor a mod");
 }
 $args{is_set} = $is_set;

 $class->$orig(%args);
};

=head2 C<< insert into => \@list, overwrite => $overwrite, replace => $replace >>

Inserts the current rule into the list of rules C<@list>.

If C<$replace> is false, then the rule will be appended to the C<@list> ; except if there already is an existent entry for the same target, in which case it will be overwritten if C<$overwrite> is true, or an exception will be thrown if it is false.

If C<$replace> is true, then the rule will replace the first rule in the list that is a subclass or that consumes the role denoted by the target.
All the subsequent rules in the list that inherit or consume the target will be removed.

=cut

sub insert {
 my ($rule, %args) = @_;

 my $list = $args{into};
 $ltfrl_tc->assert_valid($list);

 my $overwrite = $args{overwrite};
 my $replace   = $args{replace};

 my $target  = $rule->target;
 my $is_role = $rule->is_role;

 if ($replace) {
  my @remove;

  for my $i (0 .. $#$list) {
   my $old_target = $list->[$i]->target;
   if ($rule->handles($old_target)) {
    if (defined $rule) {
     splice @$list, $i, 1, $rule;
     $rule = undef;
    } else {
     push @remove, $i;
    }
   }
  }

  my $shift;
  for (@remove) {
   splice @$list, $_ - $shift, 1;
   ++$shift;
  }
  return 1 unless defined $rule;

 } else { # Replace only an existent rule

  for my $i (0 .. $#$list) {
   my $old_target = $list->[$i]->target;
   if ($old_target eq $target) {
    Carp::confess("Default rule already defined for target $target")
                                                              unless $overwrite;
    splice @$list, $i, 1, $rule;
    return 1;
   }
  }
 }

 push @$list, $rule;
 return 0;
}

=head2 C<handles $obj>

Returns true if and only if the current rule can handle the object or class/role name C<$obj>.

=cut

sub handles {
 my ($rule, $obj) = @_;

 $rule->is_role ? does_role($obj, $rule->target) : $obj->isa($rule->target);
}

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Functor>.

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

1; # End of LaTeX::TikZ::Functor::Rule
