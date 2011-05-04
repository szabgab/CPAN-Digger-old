use strict;
use warnings;

use autodie;
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Temp qw(tempdir);

use Test::More;
use Test::Deep;

plan tests => 1;

my $cpan = tempdir( CLEANUP => 1 );
my $dbdir = tempdir( CLEANUP => 1 );
my $dbfile = "$dbdir/a.db";


### setup cpan
mkpath "$cpan/authors/id/F/FA/FAKE1";
{
    open my $fh, '>', "$cpan/authors/id/F/FA/FAKE1/Package-Name-0.02.meta";
    print $fh "some text";
    close $fh;
}
{
    open my $fh, '>', "$cpan/authors/id/F/FA/FAKE1/Package-Name-0.02.tar.gz";
    print $fh "some text";
    close $fh;
}
copy 't/files/My-Package-1.02.tar.gz', "$cpan/authors/id/F/FA/FAKE1/";

### run collect
system("$^X script/collect.pl --cpan $cpan --dbfile $dbfile");

### check database
use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
my $sth = $dbh->prepare('SELECT * FROM distro ORDER BY id ASC');
$sth->execute;
my @data;
while (my @row = $sth->fetchrow_array) {
#    diag "@row";
    push @data, \@row;
}
#diag explain @data;

my $TS = re('\d+');
cmp_deeply(\@data, [
   [1, 'FAKE1', 'My-Package', '1.02', 'authors/id/F/FA/FAKE1/My-Package-1.02.tar.gz', $TS, $TS],
   [2, 'FAKE1', 'Package-Name', '0.02', 'authors/id/F/FA/FAKE1/Package-Name-0.02.tar.gz', $TS, $TS],
], 'data is ok');


#
# change cpan
# run collect
# check database
