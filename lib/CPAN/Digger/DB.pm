package CPAN::Digger::DB;
use 5.010;
use Moose;

use MongoDB;

sub db {
	my $connection = MongoDB::Connection->new(host => '127.0.0.1', port => 27016);
	my $db         = $connection->cpan_digger;
	return $db;
}


1;
