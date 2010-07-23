package LaTeX::TikZ::Functor;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Functor - Build functor methods that recursively visit nodes of a LaTeX::TikZ::Set tree.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

A functor takes a L<LaTeX::TikZ::Set> tree and clones it according to certain rules.

=cut

use Carp ();

use Sub::Name ();

use LaTeX::TikZ::Interface;

use LaTeX::TikZ::Tools;

use Any::Moose 'Util' => [ 'does_role' ];

my $lts_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Set');

my @default_set_rules;
my @default_mod_rules;

my ($validate_rule, $insert_rule);
BEGIN {
 $validate_rule = Sub::Name::subname('validate_rule' => sub {
  my ($target, $handler) = @_;

  unless (defined $target and ref $target eq ''
          and $target =~ /[A-Za-z][A-Za-z0-9_]*(?:::[A-Za-z][A-Za-z0-9_]*)*/) {
   Carp::confess("Invalid target $target");
  }

  (my $pm = $target) =~ s{::}{/}g;
  $pm .= '.pm';
  require $pm;

  my $is_set;
  if (does_role($target, 'LaTeX::TikZ::Set')) {
   $is_set = 1;
  } elsif (does_role($target, 'LaTeX::TikZ::Mod')) {
   $is_set = 0;
  } else {
   Carp::confess("Target $target is neither a set nor a mod");
  }

  Carp::confess("Invalid handler for target $target")
                                                  unless ref $handler eq 'CODE';

  return [ $target, $handler, $is_set ];
 });

 $insert_rule = Sub::Name::subname('insert_rule' => sub {
  my ($rule, $list) = @_;

  my $spec = $rule->[0];
  for my $i (0 .. $#$list) {
   my $old_spec = $list->[$i]->[0];
   if ($old_spec->isa($spec) or does_role($old_spec, $spec)) {
    splice @$list, $i, 1, $rule;
    return 1;
   }
  }

  push @$list, $rule;
  return $#$list;
 });
}

=head1 METHODS

=head2 C<default_rule>

=cut

sub default_rule {
 shift;

 my $rule = $validate_rule->(@_);

 $insert_rule->($rule, $rule->[2] ? \@default_set_rules : \@default_mod_rules);
}

=head2 C<< new rules => [ $class_name => sub { ... }, ... ] >>

=cut

sub new {
 my ($class, %args) = @_;

 my @set_rules = @default_set_rules;
 my @mod_rules = @default_mod_rules;

 my @user_rules = @{$args{rules} || []};
 while (@user_rules) {
  my ($target, $handler) = splice @user_rules, 0, 2;

  my $rule = $validate_rule->($target, $handler);

  $insert_rule->($rule, $rule->[2] ? \@set_rules : \@mod_rules);
 }

 my %dispatch  = map { $_->[0] => $_ } @set_rules, @mod_rules;

 my $self;

 $self = bless sub {
  my $set = shift;

  $lts_tc->assert_valid($set);

  my $rule = $dispatch{ref($set)};
  unless ($rule) {
   ($set->isa($_->[0]) or $set->does($_->[0])) and $rule = $_ for @set_rules;
   $rule = [ undef, sub { $_[1] } ] unless $rule;
  }
  my $new_set = $rule->[1]->($self, $set, @_);
  my $is_new  = $new_set ne $set;

  my @new_mods;
MOD:
  for my $mod ($set->mods) {
   my $rule = $dispatch{ref($mod)};
   unless ($rule) {
    ($mod->isa($_->[0]) or $mod->does($_->[0])) and $rule = $_ for @mod_rules;
    unless ($rule) {
     push @new_mods, $mod;
     next MOD;
    }
   }
   push @new_mods, $rule->[1]->($self, $mod, @_);
  }

  $new_set->mod(@new_mods) if $is_new;

  return $new_set;
 }, $class;
}

LaTeX::TikZ::Interface->register(
 functor => sub {
  shift;

  __PACKAGE__->new(rules => \@_);
 },
);

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

1; # End of LaTeX::TikZ::Functor
