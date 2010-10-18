use strict;
use warnings;
use MongoDB;

my $connection = MongoDB::Connection->new(host => 'localhost', port => 27017);
my $db         = $connection->test;
$db->insert({ 'name' => 'a', code => 1 });
$db->insert({ 'name' => 'b', code => 1 });
$db->insert({ 'name' => 'c', code => 2 });

my $distinct = $db->distinct('code');
print "$distinct\n";   #  MongoDB::Collection=HASH(0x14f4798)
my $r1 = $distinct->find();
print "$r1\n";          # MongoDB::Cursor=HASH(0x853260)
while (my $d = $r1->next) {
	print "$d\n";
}


my $r2 = $distinct->find('code');

print "R2: $r2\n";          # MongoDB::Cursor=HASH(0x853260)
while (my $d = $r2->next) {
	print "D: $d\n";
}
# throws an exception:
# not a reference at /home/gabor/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/MongoDB/Cursor.pm line 231.



print "done\n";
