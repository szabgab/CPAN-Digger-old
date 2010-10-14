use strict;
use warnings;

use Test::More;

plan tests => 1;

use CPAN::Digger;

my $d = CPAN::Digger->new;
isa_ok($d, 'CPAN::Digger');


# Test cases for unzip and process files:

# fail in the unzip

# open in the current directory and not in a subdirectory (e.g.
#         cpan/authors/id/J/JW/JWIEGLEY/Pilot-0.4.tar.gz )

# could not sanitize file name:
# Easy WML 0.1
# from cpan/authors/id/C/CA/CARTER/Easy-WML-0.1.tar.gz
