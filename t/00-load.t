#!perl -T

use strict;
use warnings;

use Test::More tests => 33;

BEGIN {
 use_ok( 'LaTeX::TikZ' );
 use_ok( 'LaTeX::TikZ::Formatter' );
 use_ok( 'LaTeX::TikZ::Functor' );
 use_ok( 'LaTeX::TikZ::Interface' );
 use_ok(' LaTeX::TikZ::Meta::TypeConstraint::Autocoerce' );
 use_ok( 'LaTeX::TikZ::Mod' );
 use_ok( 'LaTeX::TikZ::Mod::Clip' );
 use_ok( 'LaTeX::TikZ::Mod::Color' );
 use_ok( 'LaTeX::TikZ::Mod::Fill' );
 use_ok( 'LaTeX::TikZ::Mod::Formatted' );
 use_ok( 'LaTeX::TikZ::Mod::Layer' );
 use_ok( 'LaTeX::TikZ::Mod::Pattern' );
 use_ok( 'LaTeX::TikZ::Mod::Pattern::Dots' );
 use_ok( 'LaTeX::TikZ::Mod::Pattern::Lines' );
 use_ok( 'LaTeX::TikZ::Mod::Raw' );
 use_ok( 'LaTeX::TikZ::Mod::Width' );
 use_ok( 'LaTeX::TikZ::Point' );
 use_ok( 'LaTeX::TikZ::Point::Math::Complex' );
 use_ok( 'LaTeX::TikZ::Scope' );
 use_ok( 'LaTeX::TikZ::Set' );
 use_ok( 'LaTeX::TikZ::Set::Arc' );
 use_ok( 'LaTeX::TikZ::Set::Arrow' );
 use_ok( 'LaTeX::TikZ::Set::Circle' );
 use_ok( 'LaTeX::TikZ::Set::Line' );
 use_ok( 'LaTeX::TikZ::Set::Mutable' );
 use_ok( 'LaTeX::TikZ::Set::Op' );
 use_ok( 'LaTeX::TikZ::Set::Path' );
 use_ok( 'LaTeX::TikZ::Set::Point' );
 use_ok( 'LaTeX::TikZ::Set::Polyline' );
 use_ok( 'LaTeX::TikZ::Set::Raw' );
 use_ok( 'LaTeX::TikZ::Set::Rectangle' );
 use_ok( 'LaTeX::TikZ::Set::Sequence' );
 use_ok( 'LaTeX::TikZ::Tools' );
}

diag( "Testing LaTeX::TikZ $LaTeX::TikZ::VERSION, Perl $], $^X" );

use Any::Moose;

my $moose   = any_moose();
my $version = do { no strict 'refs'; ${$moose . '::VERSION'} };

diag( "Any::Moose uses $moose $version" );
