#!/usr/bin/perl
use 5.008008;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper          qw(Dumper);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

use CPAN::Digger::Index;

run();
exit;


sub run {
	
	my $root = dirname dirname abs_path $0;

	my %opt;
	GetOptions(\%opt,
		'output=s',
		'dbfile=s',

		'cpan=s',
		'filter=s',

	# temporarily disabled
	#	'dir=s',
	#	'name=s',
	#	'author=s',
	#	'version=s',

		'whois',
		'collect',
		'process',


		'prepare',
		'pod',
		'syn',
		'outline',

		'full',
	) or usage();


	usage('--dbfile required') if not $opt{dbfile};
	usage('--cpan or --dir required') if not $opt{cpan} and not $opt{dir};
	usage("Directory '$opt{cpan}' not found") if $opt{cpan} and not -d $opt{cpan};
	usage('if --dir is given then --name also need to be supplied')
		if $opt{dir} and not $opt{name};
	usage('--output required') if not $opt{output};
	usage('--output must be given an existing directory') if not -d $opt{output};

	usage('On or more of --collect, --whois  or --process is needed')
		if  not $opt{collect}
		and not $opt{whois}
		and not $opt{process};

	if ($opt{process}) {
		usage('On or more of --syn, --pod, --prepare, --outline or --full is needed')
			if  not $opt{full}
			and not $opt{syn}
			and not $opt{pod}
			and not $opt{prepare}
			and not $opt{outline};
	}

	$opt{root} = $root;

	if (delete $opt{full}) {
		$opt{$_} = 1 for qw(prepare syn pod outline);
	}

	my %run;
	$run{$_} = delete $opt{$_} for qw(collect whois process);

	$ENV{CPAN_DIGGER_DBFILE} = $opt{dbfile};

	my $cpan = CPAN::Digger::Index->new(%opt);
	if ($run{whois}) {
		$cpan->update_from_whois;
	}

	if ($run{collect}) {
		$cpan->collect_distributions;
	}

	if ($run{process}) {
		$cpan->process_all_distros();
	}
}
# $cpan->generate_central_files;


sub usage {
	my $msg = shift;
	if ($msg) {
		print "\n*** $msg\n\n";
	}
	die <<"END_USAGE";
Usage: perl $0
Required:
   --output PATH_TO_OUTPUT_DIRECTORY
   --dbfile path/to/database.db

One of these is required:
   --cpan PATH_TO_CPAN_MIRROR
   --dir PATH_TO_SOURCE_DIR or PATH_TO_SOURCE_FILE

   --name NAME_OF_PROJECT  (name is required if --dir is given)


Optional:
   --filter REGEX   only packages that match the regex will be indexed

One of these is required:
   --whois          update authors table of the database from the 00whois.xml file
   --collect        go over the CPAN mirror and add the name of each file to the 'distro' table

   --distro   A/AU/AUTHOR/Distro-Name-1.00.tar.gz    to process this distro
   --process  process all distros

If --process is give then one or more of the steps:
   --prepare        
   --pod            generate HTML pages from POD
   --syn            generate syntax highlighted source files
   --outline
   --full           do all the steps one by one in the process

Examples:
$0 --cpan /var/www/cpan --output /var/www/digger --dbfile /var/www/digger/digger.db --collect --whois
$0 --cpan /var/www/cpan --output /var/www/digger --dbfile /var/www/digger/digger.db --filter '^CPAN-Digger$'

END_USAGE
}
