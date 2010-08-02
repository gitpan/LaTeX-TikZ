#!perl -T

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage" if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage" if $@;

plan tests => 34;

my $moose_private = { also_private => [ qr/^BUILD$/, qr/^DEMOLISH$/ ] };

# First load the interface so that no keywords are registered.
pod_coverage_ok( 'LaTeX::TikZ::Interface' );

pod_coverage_ok( 'LaTeX::TikZ' );
pod_coverage_ok( 'LaTeX::TikZ::Formatter' );
pod_coverage_ok( 'LaTeX::TikZ::Functor' );
pod_coverage_ok( 'LaTeX::TikZ::Functor::Rule' );
pod_coverage_ok( 'LaTeX::TikZ::Meta::TypeConstraint::Autocoerce' );
pod_coverage_ok( 'LaTeX::TikZ::Mod' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Clip' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Color' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Fill' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Formatted' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Layer', $moose_private);
pod_coverage_ok( 'LaTeX::TikZ::Mod::Pattern' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Pattern::Dots' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Pattern::Lines' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Raw' );
pod_coverage_ok( 'LaTeX::TikZ::Mod::Width' );
pod_coverage_ok( 'LaTeX::TikZ::Point' );
pod_coverage_ok( 'LaTeX::TikZ::Point::Math::Complex' );
pod_coverage_ok( 'LaTeX::TikZ::Scope' );
pod_coverage_ok( 'LaTeX::TikZ::Set' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Arc' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Arrow' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Circle' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Line' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Mutable' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Op' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Path' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Point' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Polyline' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Raw' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Rectangle' );
pod_coverage_ok( 'LaTeX::TikZ::Set::Sequence' );
pod_coverage_ok( 'LaTeX::TikZ::Tools' );
