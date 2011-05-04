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
    # Sample files:
    # F/FA/FAKE1/My-Package-1.02.tar.gz
    # Z/ZI/ZIGOROU/Module-Install-TestVars-0.01_02.tar.gz
    # G/GR/GREENBEAN/Asterisk-AMI-v0.2.0.tar.gz
    # Z/ZA/ZAG/Objects-Collection-029targz/Objects-Collection-0.29.tar.gz
    my $PREFIX     = qr{\w/\w\w/(\w+)/};
    my $SUBDIRS    = qr{(?:[\w/-]+/)};
    my $PACKAGE    = qr{([\w-]*?)};
    my $VERSION_NO = qr{[\d._]+};
    my $CRAZY_VERSION_NO = qr {[\w.]+};
    my $EXTENSION  = qr{(?:\.tar\.gz)};
    if ($file =~ m{^$PREFIX           # P/PA/PAUSEID
                   $SUBDIRS?          # optional garbage
                   $PACKAGE
                   -v?($VERSION_NO)      # version
                   $EXTENSION
                   $}x ) {
        #print "$1  - $2 - $3\n";
        $db->insert_distro($1, $2, $3, $file, (stat "$opt{cpan}/authors/id/$file")[9], time);

    # K/KR/KRAKEN/Net-Telnet-Cisco-IOS-0.4beta.tar.gz
    } elsif ($file =~ m{^$PREFIX           # P/PA/PAUSEID
                   $SUBDIRS?          # optional garbage
                   $PACKAGE
                   -v?($CRAZY_VERSION_NO)      # version
                   $EXTENSION
                   $}x ) {
        $db->insert_distro($1, $2, $3, $file, (stat "$opt{cpan}/authors/id/$file")[9], time);
     } else {
        warn "ERROR - could not parse filename $file\n";
    }
}

sub usage {
    die "Usage --cpan path/to/cpan/mirror --dbfile path/to/database.db\n";
}

