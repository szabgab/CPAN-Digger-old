#!/usr/bin/perl
use 5.008008;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper       qw(Dumper);
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


my %opt;
GetOptions(\%opt, "infile=s", "outfile=s", 'help') or usage();
usage() if not $opt{infile} or not $opt{outfile};
usage() if $opt{help};


#use CPAN::Digger::PPI;
use CPAN::Digger::Syntax;

# my $ppi = CPAN::Digger::PPI->new(infile => $in);
# my $outline = $ppi->process;
# print Dumper $outline;

my $ppi = CPAN::Digger::Syntax->new(root => $root);
$ppi->process(%opt);

sub usage {
	print <<"END_USAGE";
Usage: $0
      --infile SOME_PM_FILE
      --outfile SOME_HTML_FILE

      --help

Take a single perl script or module and send through the PPI processor
generating an html file. It is mostly here to be able to process a single
file during development. 

END_USAGE
	exit;
}
