package CPAN::Digger::DB;
use 5.008008;
use Moose;

has 'dbfile' => (is => 'ro', isa => 'Str');
has 'dbh'    => (is => 'rw');

use DBI;
use File::Basename qw(dirname);
use File::Path     qw(mkpath);

my $sql_insert = q{
    INSERT INTO distro (author, name, version, path, file_timestamp, added_timestamp) 
                VALUES (?, ?, ?, ?, ?, ?)
};
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
    return $self->_get_distros($str, q{
       SELECT author, name, version 
       FROM distro 
       WHERE name LIKE ? 
       ORDER BY name, version
       LIMIT 100});
}
sub get_distros_latest_version {
    my ($self, $str) = @_;
    return $self->_get_distros($str, q{
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

# get all the data from the 'author' table for a single pauseid
sub get_author {
    my ($self, $pauseid) = @_;
    my $sth = $self->dbh->prepare('SELECT * FROM author WHERE pauseid = ?');
    $sth->execute($pauseid);
    my $data = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish;

    return $data;
}

sub get_authors {
    my ($self, $str) = @_;
    return $self->_get_distros($str, q{SELECT * FROM author where pauseid LIKE ? ORDER BY pauseid});
}

sub add_author {
    my ($self, $data, $pauseid) = @_;
    
    Carp::croak('pauseid is required') if not $pauseid;
    my @fields = qw(name email asciiname homepage);
    my $fields = join ', ', grep { defined $data->{$_} } @fields;
    my @values = map { $data->{$_} } grep { defined $data->{$_} } @fields;
    my $placeholders = join ', ', ('?') x scalar @values;
    
    my $sql = "INSERT INTO author (pauseid, $fields) VALUES(?, $placeholders)";
    #print "$sql\n";
    $self->dbh->do($sql, {}, $pauseid, @values);

    return;
}
sub update_author {
    my ($self, $data, $pauseid) = @_;

    Carp::croak('pauseid is required') if not $pauseid;
    my @fields = qw(name email asciiname homepage);

    my $sql = "UPDATE author SET ";
    $sql .= join ', ', map {"$_ = ?"} @fields;
   
    $sql .= " WHERE pauseid = ?";
    #print "$sql\n";
    #$self->dbh->do($sql, {}, @$data->{@fields}, $pauseid);

    return;
}

1;
