#!/usr/bin/perl -T
use 5.010;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper          qw(Dumper);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

my $root;
BEGIN {
	$root = dirname dirname abs_path $0;

	# sanitize variables to make Taint mode happy
	($root) = $root =~ m{   ([\w/:\\-]+)  }x;
	if ($ENV{PERL5LIB}) {
		my ($path) = $ENV{PERL5LIB} =~ m{   ([\w/:-]+)  }x;
		unshift @INC, split /:/, $path;
	}
}
use lib File::Spec->catdir($root, 'lib');
use CPAN::Digger::Pod;

my %opt;
GetOptions(\%opt,
	'podfile=s',
	'output=s',
) or usage();

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
END_USAGE
}

