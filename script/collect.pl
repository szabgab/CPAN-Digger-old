#!/usr/bin/perl
use strict;
use warnings;

use File::Find::Rule;
use Getopt::Long qw(GetOptions);

use lib 'lib';
use CPAN::Digger::DB;


my %opt;
GetOptions(\%opt,
   'cpan=s',
   'dbfile=s',
) or usage();
usage() if not $opt{cpan} or not -d $opt{cpan};
usage() if not $opt{dbfile};


# $ENV{CPAN_DIGGER_DBFILE} = 

my $db = CPAN::Digger::DB->new(dbfile => $opt{dbfile});
$db->setup;

my $files = File::Find::Rule
   ->file()
   ->relative
   ->name( '*.tar.gz' )
   ->start( "$opt{cpan}/authors/id" );

while (my $file = $files->match) {
    # F/FA/FAKE1/My-Package-1.02.tar.gz
    #print "$file\n";

    if ($file =~ m{^\w/\w\w/(\w+)/([\w-]*?)-([\d.]+)(\.tar\.gz)$} ) {
        #print "$1  - $2 - $3\n";
        $db->insert_distro($1, $2, $3, $file, (stat "$opt{cpan}/authors/id/$file")[9], time);
    } else {
        warn "ERROR - could not parse filename $file\n";
    }
}

sub usage {
    die "Usage --cpan path/to/cpan/mirror --dbfile path/to/database.db\n";
}

