#!/usr/bin/perl -T
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

	# sanitize variables to make Taint mode happy
	($root) = $root =~ m{   ([\w/-]+)  }x;
	if ($ENV{PERL5LIB}) {
		my ($path) = $ENV{PERL5LIB} =~ m{   ([\w/:-]+)  }x;
		unshift @INC, split /:/, $path;
	}
}
use lib File::Spec->catdir($root, 'lib');
use CPAN::Digger;

my %opt;
GetOptions(\%opt,
	'cpan=s',
	'output=s',
	'dropdb',
) or usage();

if ($opt{dropdb}) {
	my $db = CPAN::Digger::DB->db;
	$db->drop;
	exit;
}

usage() if not $opt{cpan} or not -d $opt{cpan};
usage() if not $opt{output} or not -d $opt{output};
$opt{root} = $root;

my $cpan = CPAN::Digger->new(%opt);
$cpan->run_index;
$cpan->generate_central_files;
$cpan->copy_static_files;



sub usage {
	die <<"END_USAGE";
Usage: $0 --cpan PATH_TO_CPAN_MIRROR --output PATH_TO_OUTPUT_DIRECTORY
   or
   --dropdb   to drop the whole database

END_USAGE
}

