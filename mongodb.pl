use strict;
use warnings;
use MongoDB;

my $connection = MongoDB::Connection->new(host => 'localhost', port => 27017);
my $db         = $connection->test;
my $coll       = $db->test_collection;

$coll->insert({ 'name' => 'a', code => 1 });
$coll->insert({ 'name' => 'b', code => 1 });
$coll->insert({ 'name' => 'c', code => 2 });

my $r3 = $db->run_command([
    "distinct" => "test_collection",
    "key"      => "code",
    "query"    => {}
]);

print "R3: $r3\n";

for my $d ( @{ $r3->{values} } ) {
    print "D: $d\n";
}
