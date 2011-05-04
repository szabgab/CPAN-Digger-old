use strict;
use warnings;

use autodie;
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Temp qw(tempdir);
use Storable qw(dclone);

use Test::More;
use Test::Deep;

plan tests => 6;

my $cleanup = !$ENV{KEEP};

my $cpan = tempdir( CLEANUP => $cleanup );
my $dbdir = tempdir( CLEANUP => $cleanup );
diag "cpan: $cpan";
diag "dbdir: $dbdir";

my $dbfile = "$dbdir/a.db";

use CPAN::Digger::DB;
use DBI;

### setup cpan
create_file( "$cpan/authors/id/F/FA/FAKE1/Package-Name-0.02.meta" );
create_file( "$cpan/authors/id/F/FA/FAKE1/Package-Name-0.02.tar.gz" );

copy 't/files/My-Package-1.02.tar.gz', "$cpan/authors/id/F/FA/FAKE1/";

### run collect
system("$^X script/collect.pl --cpan $cpan --dbfile $dbfile");

### check database
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
   [1, 'FAKE1', 'My-Package', '1.02', 'F/FA/FAKE1/My-Package-1.02.tar.gz', $TS, $TS],
   [2, 'FAKE1', 'Package-Name', '0.02', 'F/FA/FAKE1/Package-Name-0.02.tar.gz', $TS, $TS],
], 'data is ok');

my $expected_data = 
         [
            { 
              author => 'FAKE1',
              name => 'My-Package',
              version => '1.02'
            },
            {
              author => 'FAKE1',
              name => 'Package-Name',
              version => '0.02'
            },
          ];
my $expected_data2 = dclone($expected_data);
$expected_data2->[0]{id} = 1;
$expected_data2->[1]{id} = 2;

{
    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;
    my $data = $db->get_distros('Pack');
    cmp_deeply($data, $expected_data, 'get_distros');
}
#diag explain $data;


# run collect again without any update to CPAN
system("$^X script/collect.pl --cpan $cpan --dbfile $dbfile");
{
    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;
    my $data = $db->get_distros('Pack');
    my $data2 = $db->get_distros_latest_version('Pack');
    cmp_deeply($data, $expected_data, 'get_distros');
    cmp_deeply($data2, $expected_data2, 'get_distros_latest_version');
}


### change cpan
mkpath  "$cpan/authors/id/F/FA/FAKE2/";
copy 't/files/Some-Package-2.00.tar.gz', "$cpan/authors/id/F/FA/FAKE2/";
copy 't/files/Some-Package-2.01.tar.gz', "$cpan/authors/id/F/FA/FAKE2/";

### run collect
system("$^X script/collect.pl --cpan $cpan --dbfile $dbfile");

### check database
my $exp_data =  
         [
            { 
              author => 'FAKE1',
              name => 'My-Package',
              version => '1.02'
            },
            {
              author => 'FAKE1',
              name => 'Package-Name',
              version => '0.02'
            },
            {
              author => 'FAKE2',
              name => 'Some-Package',
              version => '2.00'
            },
            {
              author => 'FAKE2',
              name => 'Some-Package',
              version => '2.01'
            },
            ];
my $exp_data2 = dclone $exp_data;
splice(@$exp_data2, 2,1);
$exp_data2->[0]{id} = 1;
$exp_data2->[1]{id} = 2;
$exp_data2->[2]{id} = 4;

{
    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;
    my $data = $db->get_distros('Pack');
    cmp_deeply($data, $exp_data, 'get_distros');

    my $data2 = $db->get_distros_latest_version('Pack');
    cmp_deeply($data2, $exp_data2, 'get_distros_latest_version');
}


sub create_file {
    my $file = shift;
    mkpath dirname $file;
    open my $fh, '>', $file;
    print $fh "some text";
    close $fh;
}
