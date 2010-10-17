package CPAN::Digger::DB;
use 5.010;
use Moose;

use MongoDB;

sub db {
	my $connection = MongoDB::Connection->new(host => 'localhost', port => 27017);
	my $db         = $connection->cpan_digger;
	return $db;
}


1;
