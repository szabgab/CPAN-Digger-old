package CPAN::Digger::DB;
use 5.008008;
use Moose;

use MongoDB;

#has 'mydb'     => (is => 'rw', isa => 'MongoDB::Database');
my $db;

sub db {
	#my $db = self->mydb;
	return $db if $db;

	my $connection = MongoDB::Connection->new(host => '127.0.0.1', port => 27016);
	$db         = $connection->cpan_digger;
	#self->mydb($db);
	return $db;
}



1;
