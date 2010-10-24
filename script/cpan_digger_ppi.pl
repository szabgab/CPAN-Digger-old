#!/usr/bin/perl -T
use 5.010;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper       qw(Dumper);
use File::Basename qw(dirname);
use File::Spec;
#use Getopt::Long qw(GetOptions);

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

use CPAN::Digger::PPI;

my $file = shift or die "Usage: $0 FILENAME";

my $ppi = CPAN::Digger::PPI->new(infile => $file);
my $outline = $ppi->process;

print Dumper $outline;
