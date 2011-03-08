#!/usr/bin/perl
use 5.008008;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper          qw(Dumper);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

use CPAN::Digger::Pod;

my %opt;
GetOptions(\%opt,
	'podfile=s',
	'output=s',
	'help',
) or usage();
usage() if $opt{help};

usage() if not $opt{podfile} or not -f $opt{podfile};
usage() if not $opt{output};
# or not -d $opt{output};

my $pod = CPAN::Digger::Pod->new();
$pod->process($opt{podfile}, $opt{output});

sub usage {
	die <<"END_USAGE";
Usage: $0
   --podfile PATH_TO_FILE_WITH_POD
   --output PATH_TO_OUTPUT_FILE

   --help

Take a single perl script or module and send through the POD2HTML processor
generating an html file. It is mostly here to be able to process a single
file during development. 

END_USAGE
}

