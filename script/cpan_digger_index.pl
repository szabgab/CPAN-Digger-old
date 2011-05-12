#!/usr/bin/perl
use 5.008008;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper          qw(Dumper);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

my $root = dirname dirname abs_path $0;
use CPAN::Digger::Index;

my %opt;
GetOptions(\%opt,
	'cpan=s',
	'output=s',
	'dbfile=s',
	'filter=s',
	'dir=s',
	'prefix=s',
	'pod',
	'syn',
	'process',
	'all',

	'distro=s',

	'whois',
	'collect',
#	'authors',
) or usage();


usage('--dbfile required') if not $opt{dbfile};
usage('--cpan or --dir required') if not $opt{cpan} and not $opt{dir};
usage("Directory '$opt{cpan}' not found") if $opt{cpan} and not -d $opt{cpan};
usage('if --dir is given then --prefix also need to be supplied')
	if $opt{dir} and not $opt{prefix};
usage('--output required') if not $opt{output};
usage('--output must be given an existing directory') if not -d $opt{output};
usage('--prefix should similar to AUTHOR/Module-Name-1.00')
	if $opt{prefix} and $opt{prefix} !~ m{^[A-Z]+  /  \w+(-\w+)*  -\d+\.\d+$}x;

$opt{root} = $root;

my %run;
$run{$_} = delete $opt{$_} for qw(collect whois distro process all);
my $cpan = CPAN::Digger::Index->new(%opt);

if ($run{all}) {
	$run{$_} = 1 for qw(collect whois process);
}


if ($run{collect}) {
	$cpan->collect_distributions;
}

if ($run{whois}) {
	$cpan->update_from_whois;
}

# if ($run{authors}) {
	# $cpan->generate_author_pages;
# }

if ($run{distro}) {
	$cpan->process_distro($run{distro});
}

if ($run{process}) {
	$cpan->process_all_distros();
}

# $cpan->generate_central_files;

# if ($cpan->dir) {
	# eval {
		# $cpan->index_dir;
	# };
	# if ($@) {
		# warn "Exception in index_dir: $@";
	# }
# }

exit;

sub usage {
	my $msg = shift;
	if ($msg) {
		print "\n*** $msg\n\n";
	}
	die <<"END_USAGE";
Usage: perl $0
   --output PATH_TO_OUTPUT_DIRECTORY    (required)
   --dbfile path/to/database.db

At least one of these is required:
   --cpan PATH_TO_CPAN_MIRROR
   --dir PATH_TO_SOURCE_DIR or PATH_TO_SOURCE_FILE
   --prefix USERNAME/Module-Name-1.00  (prefix is required if --dir is given)



Optional:
   --filter REGEX   only packages that match the regex will be indexed
   --pod            generate HTML pages from POD
   --syn            generate syntax highlighted source files

   --whois          update authors table of the database from the 00whois.xml file
   --collect        go over the CPAN mirror and add the name of each file to the 'distro' table

   --distro   A/AU/AUTHOR/Distro-Name-1.00.tar.gz    to process this distro
   --process  process all distros
   
   --all            do all the steps one by one in the processing

Examples:
$0 --cpan /var/www/cpan --output /var/www/digger --dbfile /var/www/digger/digger.db --collect --whois
$0 --cpan /var/www/cpan --output /var/www/digger --dbfile /var/www/digger/digger.db --distro S/SZ/SZABGAB/CPAN-Digger-0.01.tar.gz

END_USAGE
}

#   --authors        generate an html page for each author
