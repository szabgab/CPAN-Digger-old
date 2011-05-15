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

requires 'perl'                        => '5.008008';

requires 'autodie'                     => '2.10';
requires 'Archive::Any'                => '0.0932';
requires 'Archive::Zip'                => '1.30';
requires 'Archive::Tar'                => '1.76';
requires 'Capture::Tiny'               => '0.10';
requires 'Carp';
requires 'Cwd';
requires 'Dancer'                      => '1.3040';
requires 'Data::Dumper';
requires 'DBI'                         => '1.611';
requires 'Encode'                      => '2.38';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Copy::Recursive'       => '0.38';
requires 'File::Find::Rule'            => '0.32';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'JSON::XS'                    => '2.3';
requires 'JSON'                        => '2.51';
requires 'List::Util';
requires 'Moose'                       => '2.0006';
requires 'MooseX::StrictConstructor'   => '0.16';
#requires 'Parse::CPAN::Authors';
requires 'Parse::CPAN::Packages'       => '2.33';
requires 'Parse::CPAN::Whois'          => '0.02';
requires 'Perl::Critic'                => '1.106';
requires 'Perl::MinimumVersion'        => '1.28';
requires 'POSIX';
requires 'PPI::Document';
requires 'PPI::Find'                   => '1.215';
requires 'PPIx::EditorTools'           => '0.12';
requires 'Template'                    => '2.22' ;
requires 'Time::HiRes';
requires 'YAML::Any'                   => '0.72';
requires 'YAML'                        => '0.73';

requires 'Pod::Simple'                 => '3.16';
requires 'Pod::Simple::HTML';
requires 'Plack'                       => '0.9978';
requires 'Plack::Runner';              # no version ?
requires 'Plack::Handler::FCGI';
requires 'Plack::Util';


test_requires 'Test::Deep'             => '0.108';
test_requires 'Test::More'             => '0.98';
test_requires 'Test::NoWarnings'       => '1.02';

no_index 'directory' => qw{ t xt eg share inc privinc };

#install_script 'script/cpan_digger_index.pl';

#install_share;

WriteAll;
