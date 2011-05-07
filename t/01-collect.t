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

plan tests => 12;

my $cleanup = !$ENV{KEEP};

my $cpan = tempdir( CLEANUP => $cleanup );
my $dbdir = tempdir( CLEANUP => $cleanup );
my $outdir = tempdir( CLEANUP => $cleanup );
diag "cpan: $cpan";
diag "dbdir: $dbdir";

my $dbfile = "$dbdir/a.db";

use CPAN::Digger::DB;
use DBI;

my $TS = re('\d+'); # don't care about exact timestamps
my $ID = re('\d+'); # don't care about IDs as they are just helpers and they get allocated based on file-order


############################ setup cpan
create_file( "$cpan/authors/id/F/FA/FAKE1/Package-Name-0.02.meta" );
create_file( "$cpan/authors/id/F/FA/FAKE1/Package-Name-0.02.tar.gz" );

copy 't/files/My-Package-1.02.tar.gz', "$cpan/authors/id/F/FA/FAKE1/"  or die $!;
copy 't/files/02whois.xml', "$cpan/authors/00whois.xml" or die $!;
collect();

### check database
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
my $sth = $dbh->prepare('SELECT * FROM distro ORDER BY name');

my %expected_authors = (
  'AFOXSON' => {
   pauseid   => 'AFOXSON',
   name      => '',
   asciiname => undef,
   email     => undef,
   homepage  => undef
 },
 'KORSHAK' => {
   pauseid   => 'KORSHAK',
   name      => 'Ярослав Коршак',
   email     => 'CENSORED',
   asciiname => undef,
   homepage  => undef
 },
 'SPECTRUM' => {
   pauseid   => 'SPECTRUM',
   name      => 'Черненко Эдуард Павлович',
   email     => 'edwardspec@gmail.com',
   asciiname => 'Edward Chernenko',
   homepage  => 'http://absurdopedia.net/wiki/User:Edward_Chernenko'
 },
 'SZABGAB' => {
   pauseid   => 'SZABGAB',
   name      => 'גאבור סבו - Gábor Szabó',
   email     => 'gabor@pti.co.il',
   asciiname => 'Gabor Szabo',
   homepage  => 'http://szabgab.com/'
 },
 'YKO' => {
   pauseid   => 'YKO',
   name      => 'Ярослав Коршак',
   email     => 'ykorshak@gmail.com',
   asciiname => 'Yaroslav Korshak',
   homepage  => 'http://korshak.name/'
 },
 'NUFFIN' => {
   pauseid   => 'NUFFIN',
   name      => 'יובל קוג\'מן (Yuval Kogman)',
   email     => 'nothingmuch@woobling.org',
   asciiname => 'Yuval Kogman',
   homepage  => 'http://nothingmuch.woobling.org/'
  },
);


{
  $sth->execute;
  my @data;
  while (my @row = $sth->fetchrow_array) {
  #    diag "@row";
      push @data, \@row;
  }
  #diag explain @data;

  cmp_deeply(\@data, [
    [$ID, 'FAKE1', 'My-Package', '1.02', 'F/FA/FAKE1/My-Package-1.02.tar.gz', $TS, $TS],
    [$ID, 'FAKE1', 'Package-Name', '0.02', 'F/FA/FAKE1/Package-Name-0.02.tar.gz', $TS, $TS],
  ], 'data is ok') or diag explain \@data;

  my $authors = $dbh->selectall_hashref('SELECT * FROM author ORDER BY pauseid', 'pauseid');
  #diag explain $authors;
  cmp_deeply $authors, {
    map {$_ => $expected_authors{$_}} qw(AFOXSON KORSHAK SPECTRUM SZABGAB YKO)
    } , 'authors';
}

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
$expected_data2->[0]{id} = $ID;
$expected_data2->[1]{id} = $ID;

{
    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;
    my $data = $db->get_distros('Pack');
    my $data2 = $db->get_distros_latest_version('Pack');
    cmp_deeply($data, $expected_data, 'get_distros');
    cmp_deeply($data2, $expected_data2, 'get_distros_latest_version');

    cmp_deeply $db->get_authors('K'), [ map {$expected_authors{$_}} qw(KORSHAK YKO) ], 'authors with K';
    cmp_deeply $db->get_authors('N'), [ map {$expected_authors{$_}} qw(AFOXSON) ], 'authors with N';
}
#diag explain $data;


############################# run collect again without any update to CPAN
collect();
{
    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;
    my $data = $db->get_distros('Pack');
    my $data2 = $db->get_distros_latest_version('Pack');
    cmp_deeply($data, $expected_data, 'get_distros');
    cmp_deeply($data2, $expected_data2, 'get_distros_latest_version');
}


##################################### change cpan
mkpath  "$cpan/authors/id/F/FA/FAKE2/";
copy 't/files/Some-Package-2.00.tar.gz', "$cpan/authors/id/F/FA/FAKE2/";
copy 't/files/Some-Package-2.01.tar.gz', "$cpan/authors/id/F/FA/FAKE2/";
copy 't/files/03whois.xml', "$cpan/authors/00whois.xml" or die $!;

collect();

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
$exp_data2->[0]{id} = $ID;
$exp_data2->[1]{id} = $ID;
$exp_data2->[2]{id} = $ID;

my %expected_authors2 = (
  'NUFFIN' => $expected_authors{'NUFFIN'},
);

{
    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;
    my $data = $db->get_distros('Pack');
    cmp_deeply($data, $exp_data, 'get_distros');

    my $data2 = $db->get_distros_latest_version('Pack');
    cmp_deeply($data2, $exp_data2, 'get_distros_latest_version');


    my $authors = $dbh->selectall_hashref('SELECT * FROM author ORDER BY pauseid', 'pauseid');
    #diag explain $authors;
    cmp_deeply $authors, \%expected_authors, 'authors';

    cmp_deeply $db->get_authors('N'), [ map {$expected_authors{$_}} qw(AFOXSON NUFFIN) ], 'authors with N';
}


#################################################### end

sub create_file {
    my $file = shift;
    mkpath dirname $file;
    open my $fh, '>', $file;
    print $fh "some text";
    close $fh;
}

sub collect {
   system("$^X -Ilib script/cpan_digger_index.pl --cpan $cpan --dbfile $dbfile --output $outdir --collect --whois");
}