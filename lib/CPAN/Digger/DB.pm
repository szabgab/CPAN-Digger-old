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

    my $count = $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro WHERE path = ?', {}, $args[3]);
    if (not $count) {
        $self->dbh->do($sql_insert, {}, @args);
    }
}

sub get_distros {
    my ($self, $str) = @_;
    return $self->_get_distros($str, qq{
       SELECT author, name, version 
       FROM distro 
       WHERE name LIKE ? 
       ORDER BY name
       LIMIT 100});
}
sub get_distros_latest_version {
    my ($self, $str) = @_;
    return $self->_get_distros($str, qq{
        SELECT author, version, A.name, A.id
        FROM distro A, (SELECT max(version) AS v, name
                        FROM distro where name like ?
                        GROUP BY name) AS B
        WHERE A.version=B.v and A.name=B.name ORDER BY A.name});
}

sub _get_distros {
    my ($self, $str, $sql) = @_;
    $str = '%' . $str . '%';
    my $sth = $self->dbh->prepare($sql);
    $sth->execute($str);
    my @results;
    while (my $hr = $sth->fetchrow_hashref) {
       push @results, $hr;
    }
    return \@results;
}


1;
