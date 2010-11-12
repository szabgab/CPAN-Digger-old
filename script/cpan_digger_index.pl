#!/usr/bin/perl
# remove tain mode till we know how to use Archive::Any
# -T
use 5.008008;
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
use CPAN::Digger::Index;

my %opt;
GetOptions(\%opt,
	'cpan=s',
	'output=s',
	'filter=s',
	'dir=s',
	'prefix=s',
	'pod',
	'dropdb',
) or usage();

if ($opt{dropdb}) {
	require CPAN::Digger::DB;
	my $db = CPAN::Digger::DB->db;
	$db->drop;
	exit;
}

usage("--cpan or --dir required")
	if (not $opt{cpan} or not -d $opt{cpan}) and not $opt{dir};
usage("if --dir is given then --prefix also need to be supplied")
	if $opt{dir} and not $opt{prefix};
usage("--output required") if not $opt{output};
usage("--output must be given an existing directory") if not -d $opt{output};

$opt{root} = $root;


my $cpan = CPAN::Digger::Index->new(%opt);

$cpan->generate_central_files;

if ($cpan->cpan) {
	eval {
		$cpan->run_index;
	};
	if ($@) {
		warn "Exception in run_index: $@";
		print $cpan->counter_distro, "\n";
	}
}
if ($cpan->dir) {
	eval {
		$cpan->index_dir;
	};
	if ($@) {
		warn "Exception in index_dir: $@";
	}
}





sub usage {
	my $msg = shift;
	if ($msg) {
		print "\n*** $msg\n\n";
	}
	die <<"END_USAGE";
Usage: perl -T $0
   --output PATH_TO_OUTPUT_DIRECTORY    (required)

At least one of these is required:
   --cpan PATH_TO_CPAN_MIRROR
   --dir PATH_TO_SOURCE_DIR
   --prefix USERNAME/Module-Name-1.00  (prefix is required if --dir is given)

Optional:
   --filter REGEX   only packages that match the regex will be indexed
   --pod            generate HTML pages from POD

Or:
   --dropdb         to drop the whole database

END_USAGE
}

