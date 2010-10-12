#!/usr/bin/perl
use 5.010;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

my $root;
BEGIN {
	$root = dirname dirname abs_path $0;
}
use lib File::Spec->catdir($root, 'lib');
use CPAN::Digger;

my %opt;
GetOptions(\%opt,
	'cpan=s',
	'output=s',
) or usage();
usage() if not $opt{cpan} or not -d $opt{cpan};
usage() if not $opt{output} or not -d $opt{output};

my $cpan = CPAN::Digger->new(%opt);
$cpan->run_index;





sub usage {
	die <<"END_USAGE";
Usage: $0 --cpan PATH_TO_CPAN_MIRROR --output PATH_TO_OUTPUT_DIRECTORY
END_USAGE
}

