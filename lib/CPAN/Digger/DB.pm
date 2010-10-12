package CPAN::Digger::DB;
use 5.010;
use Moose;

use MongoDB;

sub db {
	my $connection = MongoDB::Connection->new(host => 'localhost', port => 27017);
	my $db         = $connection->cpan_digger;
	return $db;
}

sub dbh {
	my $class = shift;
	my $db = $class->db;
	
	my %db;
	$db{distro}    = $db->distro;
	$db{author}    = $db->author;

	return %db;
}

1;
