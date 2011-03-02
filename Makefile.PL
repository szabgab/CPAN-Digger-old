use 5.008008;
use strict;
use inc::Module::Install 0.94;

# Workaround for the fact that Module::Install loads the modules
# into memory and when Test::NoWarnings is loaded it will hide
# the warnings generated from that point.
eval {
	require Test::NoWarnings;
	$SIG{__WARN__} = 'DEFAULT';
};

#####################################################################
# Normal Boring Commands

# NOTE: Core modules that aren't dual-life should always have a version of 0

name 'CPAN-Digger';
license 'perl';
author 'Gabor Szabo';
all_from 'lib/CPAN/Digger.pm';

requires 'perl'                  => '5.008008';

requires 'autodie';
requires 'Archive::Any';
requires 'Archive::Zip';
requires 'Archive::Tar';
requires 'Carp';
requires 'Cwd';
requires 'Capture::Tiny';
requires 'Data::Dumper';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Copy::Recursive';
requires 'File::Find::Rule';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'JSON';
requires 'MongoDB'                 => '0.39';
requires 'Moose';
requires 'Parse::CPAN::Packages';
requires 'Parse::CPAN::Authors';
requires 'Pod::Simple';
requires 'PPI::Document';
requires 'PPI::Find';
requires 'Template';
requires 'YAML::Any';

requires 'Plack::Runner';

requires 'YAML';
requires 'Dancer'     => '1.1901';

test_requires 'Test::More'         => '0.88';
test_requires 'Test::NoWarnings'   => '0.084';

no_index 'directory' => qw{ t xt eg share inc privinc };

#install_script 'script/cpan_digger_index.pl';

#install_share;

WriteAll;
