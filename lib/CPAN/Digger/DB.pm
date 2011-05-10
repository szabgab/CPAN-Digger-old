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
#    die("Creating '$dbdir'");
    mkpath $dbdir if not -d $dbdir;
    system "sqlite3 $dbfile < schema/digger.sql" if not -e $dbfile;
    $self->dbh( DBI->connect("dbi:SQLite:dbname=$dbfile","","", {
        RaiseError       => 1,
        PrintError       => 0,
        AutoCommit       => 1,
        FetchHashKeyName => 'NAME_lc',
    }) );

    return;
}


sub insert_distro {
    my ($self, @args) = @_;

    my $count = $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro WHERE path = ?', {}, $args[3]);
    if (not $count) {
        eval {
            $self->dbh->do($sql_insert, {}, @args);
        };
        if ($@) {
            CPAN::Digger::Index::ERROR("Exception in insert_distro @args");
        }
    }
}

# search by the name of the distribution
sub get_distros_like {
    my ($self, $str) = @_;
    return $self->_get_distros($str, q{
       SELECT author, name, version
       FROM distro 
       WHERE name LIKE ? 
       ORDER BY name, version
       LIMIT 100});
}

# search by the name of the distribution - latest version for each distribution
sub get_distros_latest_version {
    my ($self, $str) = @_;

    return $self->_get_distros($str, q{
        SELECT author, version, A.name, A.id
        FROM distro A, (SELECT max(version) AS v, name
                        FROM distro where name like ?
                        GROUP BY name) AS B
        WHERE A.version=B.v and A.name=B.name ORDER BY A.name});
}

# list all the distributions (latest version only) of a specific author (pauseid)
# if the latest version was uploaded by someone else, don't list it
# returns and ARRAY ref of HASH-es
sub get_distros_of {
    my ($self, $pauseid) = @_;

    my $sth = $self->dbh->prepare(q{
        SELECT author, version, A.name, A.id, A.file_timestamp, A.path
        FROM distro A, (SELECT max(version) AS v, name
                        FROM distro GROUP BY name) AS B
        WHERE A.version=B.v and A.name=B.name AND A.author = ? ORDER BY A.name});
    $sth->execute($pauseid);
    my @results;
    while (my $hr = $sth->fetchrow_hashref) {
       push @results, $hr;
    }
    return \@results;
}

sub get_distro_latest {
    my ($self, $name) = @_;

    my $sth = $self->dbh->prepare(q{
        SELECT id, author, name, version, path, file_timestamp, added_timestamp 
        FROM distro 
        WHERE name = ? 
           ORDER BY file_timestamp DESC 
           LIMIT 1});
    $sth->execute($name);
    my $r = $sth->fetchrow_hashref;
    $sth->finish;

    return $r;
}

sub get_distro_by_path {
    my ($self, $path) = @_;

    my $sth = $self->dbh->prepare('SELECT * FROM distro WHERE path = ?');
    $sth->execute($path);
    my $r = $sth->fetchrow_hashref;
    $sth->finish;

    return $r;
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
# returns a HASH ref.
sub get_author {
    my ($self, $pauseid) = @_;

    my $sth = $self->dbh->prepare('SELECT * FROM author WHERE pauseid = ?');
    $sth->execute($pauseid);
    my $data = $sth->fetchrow_hashref;
    $sth->finish;

    return $data;
}

sub get_all_authors {
    my ($self) = @_;
    return $self->get_authors('');
    #return $self->_get_distros($str, q{SELECT * FROM author ORDER BY pauseid});
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

sub unzip_error {
    my ($self, $path, $error, $details) = @_;
    CPAN::Digger::Index::WARN("unzip_error $error - $details in $path");
    my $cnt = $self->dbh->do('UPDATE distro SET unzip_error=?, unzip_error_details=? WHERE path=?', {},
        $error, $details, $path);
    # TODO: report if cannot update?
}

sub update_distro_details {
    my ($self, $data, $id) = @_;

    my @all_fields = qw(has_meta_yml has_meta_json has_t meta_homepage meta_repository meta_abstract);
    my @fields = grep {defined $data->{$_}} @all_fields;
    my $fields = join ' ', map {", $_"} @fields;
    my @values = map { $data->{$_} } @fields;
    my $placeholders = join '', (', ?' x scalar @values);
    my $sql = "INSERT INTO distro_details (id $fields) VALUES(? $placeholders)";

    #CPAN::Digger::Index::LOG("SQL: $sql");
    #CPAN::Digger::Index::LOG("$id @values");
    $self->dbh->do('DELETE FROM distro_details WHERE id=?', {}, $id);
    $self->dbh->do($sql, {}, $id, @values);

    return;
}

sub get_distro_details {
    my ($self, $id) = @_;

    return $self->dbh->selectrow_hashref('SELECT * FROM distro_details WHERE id=?', {}, $id);
}

1;
