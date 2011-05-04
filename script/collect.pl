#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use File::Basename qw(dirname);
use File::Find::Rule;
use Getopt::Long qw(GetOptions);

my %opt;
GetOptions(\%opt,
   'cpan=s',
   'dbfile=s',
) or usage();
usage() if not $opt{cpan} or not -d $opt{cpan};
usage() if not $opt{dbfile};


my $dbfile = $opt{dbfile};
my $dbdir = dirname $dbfile;

mkdir $dbdir if not -d $dbdir;
system "sqlite3 $dbfile < schema/digger.sql" if not -e $dbfile;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","", {RaiseError => 1, PrintError => 0, AutoCommit => 1});
my $sql_insert = 'INSERT INTO distro (author, name, version, path, file_timestamp, added_timestamp) VALUES (?, ?, ?, ?, ?, ?)';

my @files = File::Find::Rule
   ->file()
   ->relative
   ->name( '*.tar.gz' )
   ->in($opt{cpan});

foreach my $file (@files) {
    # authors/id/F/FA/FAKE1/My-Package-1.02.tar.gz
    print "$file\n";
    if ($file =~ m{^authors/id/\w/\w\w/(\w+)/([\w-]*?)-([\d.]+)(\.tar\.gz)$} ) {
        print "$1  - $2 - $3\n";
        $dbh->do($sql_insert, {}, $1, $2, $3, $file, (stat "$opt{cpan}/$file")[9], time);
    } else {
        print "ERROR - could not parse path\n";
    }
}

sub usage {
    die "Usage --cpan path/to/cpan/mirror --dbfile path/to/database.db\n";
}

