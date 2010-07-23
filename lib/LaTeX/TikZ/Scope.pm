package LaTeX::TikZ::Scope;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Scope - An object modeling a TikZ scope or layer.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Sub::Name ();

use LaTeX::TikZ::Tools;

use Any::Moose;

=head1 ATTRIBUTES

=head2 C<mods>

=cut

has '_mods' => (
 is       => 'ro',
 isa      => 'Maybe[ArrayRef[LaTeX::TikZ::Mod::Formatted]]',
 init_arg => undef,
 default  => sub { [ ] },
);

sub mods { @{$_[0]->_mods} }

has '_mods_cache' => (
 is       => 'ro',
 isa      => 'Maybe[HashRef[LaTeX::TikZ::Mod::Formatted]]',
 init_arg => undef,
 default  => sub { +{ } },
);

=head2 C<body>

=cut

has '_body' => (
 is       => 'rw',
 isa      => 'LaTeX::TikZ::Scope|ArrayRef[Str]',
 init_arg => 'body',
);

my $my_tc    = LaTeX::TikZ::Tools::type_constraint(__PACKAGE__);
my $ltmf_tc  = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod::Formatted');
my $_body_tc = __PACKAGE__->meta->find_attribute_by_name('_body')
                                ->type_constraint;

=head1 METHODS

=head2 C<mod>

=cut

sub mod {
 my $scope = shift;

 my $cache = $scope->_mods_cache;

 for (@_) {
  my $mod = $ltmf_tc->coerce($_);
  $ltmf_tc->assert_valid($mod);
  my $tag = $mod->tag;
  next if exists $cache->{$tag};
  $cache->{$tag} = $mod;
  push @{$scope->_mods}, $mod;
 }

 $scope;
}

=head2 C<body>

=cut

sub body {
 my $scope = shift;

 if (@_) {
  $scope->_body($_[0]);
  $scope;
 } else {
  @{$scope->_body};
 }
}

use overload (
 '@{}' => 'dereference',
);

=head2 C<flatten>

=cut

sub flatten {
 my ($scope) = @_;

 do {
  my $body = $scope->_body;
  return $scope unless $my_tc->check($body);
  $scope = $scope->new
                 ->mod ($scope->mods, $body->mods)
                 ->body($body->_body)
 } while (1);
}

my $inter = Sub::Name::subname('inter' => sub {
 my ($lh, $rh) = @_;

 my (@left, @common, @right);
 my %where;

 --$where{$_} for keys %$lh;
 ++$where{$_} for keys %$rh;

 while (my ($key, $where) = each %where) {
  if ($where < 0) {
   push @left,   $lh->{$key};
  } elsif ($where > 0) {
   push @right,  $rh->{$key};
  } else {
   push @common, $rh->{$key};
  }
 }

 return \@left, \@common, \@right;
});

=head2 C<instantiate>

=cut

sub instantiate {
 my ($scope) = @_;

 $scope = $scope->flatten;

 my ($layer, @clips, @raw_mods);
 for ($scope->mods) {
  my $type = $_->type;
  if ($type eq 'clip') {
   unshift @clips, $_->content;
  } elsif ($type eq 'layer') {
   confess("Can't apply two layers in a row") if defined $layer;
   $layer = $_->content;
  } else { # raw
   push @raw_mods, $_->content;
  }
 }

 my @body = $scope->body;

 my $mods_string = @raw_mods ? ' [' . join(',', @raw_mods) . ']' : undef;

 if (@raw_mods and @body == 1 and $body[0] =~ /^\s*\\draw\b\s*([^\[].*)\s*$/) {
  $body[0]     = "\\draw$mods_string $1"; # Has trailing semicolon
  $mods_string = undef;                   # Done with mods
 }

 for (0 .. $#clips) {
  my $clip        = $clips[$_];
  my $clip_string = "\\clip $clip ;";
  my $mods_string = ($_ == $#clips and defined $mods_string)
                     ? $mods_string : '';
  unshift @body, "\\begin{scope}$mods_string",
                 $clip_string;
  push    @body, "\\end{scope}",
 }

 if (not @clips and defined $mods_string) {
  unshift @body, "\\begin{scope}$mods_string";
  push    @body, "\\end{scope}";
 }

 if (defined $layer) {
  unshift @body, "\\begin{pgfonlayer}{$layer}";
  push    @body, "\\end{pgfonlayer}";
 }

 return @body;
}

=head2 C<dereference>

=cut

sub dereference { [ $_[0]->instantiate ] }

=head2 C<fold>

=cut

sub fold {
 my ($left, $right, $rev) = @_;

 my (@left, @right);

 if ($my_tc->check($left)) {
  $left = $left->flatten;

  if ($my_tc->check($right)) {
   $right = $right->flatten;

   my ($only_left, $common, $only_right) = $inter->(
    $left->_mods_cache,
    $right->_mods_cache,
   );

   my $has_different_layers;
   for (@$only_left) {
    if ($_->type eq 'layer') {
     $has_different_layers = 1;
     last;
    }
   }
   unless ($has_different_layers) {
    for (@$only_right) {
     if ($_->type eq 'layer') {
      $has_different_layers = 1;
      last;
     }
    }
   }

   if (!$has_different_layers and @$common) {
    my $x = $left->new
                 ->mod(@$only_left)
                 ->body($left->_body);
    my $y = $left->new
                 ->mod(@$only_right)
                 ->body($right->_body);
    return $left->new
                ->mod(@$common)
                ->body(fold($x, $y, $rev));
   } else {
    @right = $right->instantiate;
   }
  } else {
   $_body_tc->assert_valid($right);
   @right = @$right;
  }

  @left = $left->instantiate;
 } else {
  if ($my_tc->check($right)) {
   return fold($right, $left, 1);
  } else {
   $_body_tc->assert_valid($_) for $left, $right;
   @left  = @$left;
   @right = @$right;
  }
 }

 $rev ? [ @right, @left ] : [ @left, @right ];
}

__PACKAGE__->meta->make_immutable;

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

1; # End of LaTeX::TikZ::Scope
