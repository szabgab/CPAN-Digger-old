use strict;
use warnings;

use Test::More;

plan tests => 1;

use CPAN::Digger;

my $d = CPAN::Digger->new;
isa_ok($d, 'CPAN::Digger');
