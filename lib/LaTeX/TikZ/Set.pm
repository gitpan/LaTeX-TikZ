package LaTeX::TikZ::Set;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set - Base role for LaTeX::TikZ set objects.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Scope::Guard ();

use LaTeX::TikZ::Scope;

use LaTeX::TikZ::Tools;

use Any::Moose 'Role';

=head1 ATTRIBUTES

=head2 C<mods>

Returns the list of the L<LaTeX::TikZ::Mod> objects associated with the current set.

=cut

has '_mods' => (
 is       => 'ro',
 isa      => 'Maybe[ArrayRef[LaTeX::TikZ::Mod]]',
 init_arg => 'mods',
 default  => sub { [ ] },
 lazy     => 1,
);

sub mods { @{$_[0]->_mods} }

=head1 METHODS

This method is required by the interface :

=over 4

=item *

C<draw>

=back

=cut

requires qw(
 draw
);

=head2 C<mod @mods>

Apply the given list of L<LaTeX::TikZ::Mod> objects to the current set.

=cut

my $ltm_tc  = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod');
my $ltml_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod::Layer');
my $ltmc_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod::Clip');

sub mod {
 my $set = shift;

 my @mods = map $ltm_tc->coerce($_), @_;
 $ltm_tc->assert_valid($_) for @mods;

 push @{$set->_mods}, @mods;

 $set;
}

{
 our %mods;
 our $last_mod = 0;

 around 'draw' => sub {
  my ($orig, $set, $tikz) = @_;

  local $last_mod = $last_mod;

  # Save a deep copy
  my %saved_idx = map { $_ => $#{$mods{$_}} } keys %mods;
  my $guard     = Scope::Guard->new(sub {
   for (keys %mods) {
    if (exists $saved_idx{$_}) {
     $#{$mods{$_}} = $saved_idx{$_};
    } else {
     delete $mods{$_};
    }
   }
  });

  my (@mods, $last_layer);
MOD:
  for my $mod ($set->mods) {
   my $is_layer = $ltml_tc->check($mod);
   $last_layer  = $mod if $is_layer;
   my $tag = $mod->tag;
   my $old = $mods{$tag} || [];
   for (@$old) {
    next MOD if $_->[0]->cover($mod);
   }
   push @{$mods{$tag}}, [ $mod, $last_mod++, $is_layer ];
   push @mods,          $mod;
  }

  if ($last_layer) {
   # Clips and mods don't propagate through layers. Hence if a layer is set,
   # force their reuse.
   @mods = $last_layer;
   push @mods, map $_->[0],
                sort { $a->[1] <=> $b->[1] }
                 grep !$_->[2],
                  map @$_,
                   values %mods;
  }

  my $body = $set->$orig($tikz);

  if (@mods) {
   $body = LaTeX::TikZ::Scope->new
                             ->mod(map $_->apply($tikz), @mods)
                             ->body($body);
  }

  $body;
 };
}

=head2 C<layer $layer>

Puts the current set in the corresponding layer.
This is a shortcut for C<< $set->mod(Tikz->layer($layer)) >>.

=cut

sub layer {
 return $_[0] unless @_ > 1;

 my $layer = $_[1];

 $_[0]->mod(
  $ltml_tc->check($layer) ? $layer
                          : LaTeX::TikZ::Mod::Layer->new(name => $layer)
 )
}

=head2 C<clip $path>

Clips the current set by the path given by C<$path>.
This is a shortcut for C<< $set->mod(Tikz->clip($path)) >>.

=cut

sub clip {
 return $_[0] unless @_ > 1;

 $_[0]->mod(
  map {
   $ltmc_tc->check($_) ? $_ : LaTeX::TikZ::Mod::Clip->new(clip => $_)
  } @_[1 .. $#_]
 )
}

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

1; # End of LaTeX::TikZ::Set
