package CPAN::Digger::DB;
use 5.008008;
use Moose;

has 'dbfile' => (is => 'ro', isa => 'Str');
has 'dbh'    => (is => 'rw');

use DBI;
use File::Basename qw(dirname);
use File::Path     qw(mkpath);

my $sql_insert = 'INSERT INTO distro (author, name, version, path, file_timestamp, added_timestamp) VALUES (?, ?, ?, ?, ?, ?)';
sub setup {
    my ($self) = @_;

    my $dbfile = $self->dbfile;
    my $dbdir = dirname $dbfile;
    mkpath $dbdir if not -d $dbdir;
    system "sqlite3 $dbfile < schema/digger.sql" if not -e $dbfile;
    $self->dbh( DBI->connect("dbi:SQLite:dbname=$dbfile","","", {RaiseError => 1, PrintError => 0, AutoCommit => 1}) );

    return;
}

sub insert_distro {
    my ($self, @args) = @_;

    $self->dbh->do($sql_insert, {}, @args);
}

1;
