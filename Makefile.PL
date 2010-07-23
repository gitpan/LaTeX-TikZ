use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'LaTeX-TikZ';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'Any::Moose'    => 0,
 'Carp'          => 0,
 'List::Util'    => 0,
 'Math::Complex' => 0,
 'Math::Trig'    => 0,
 'Mouse'         => '0.63', # register_type_constraint
 'Scalar::Util'  => 0,
 'Scope::Guard'  => 0,
 'Sub::Name'     => 0,
 'Task::Weaken'  => 0,
 'constant'      => 0,
);

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'ExtUtils::MakeMaker' => 0,
  'Test::More'          => 0,
  %PREREQ_PM,
 },
 dynamic_config => 0,
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => 5.006,
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
 }
);
