#!/usr/bin/perl
use 5.010;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $root;
BEGIN {
	$root = dirname dirname abs_path $0;
}
use lib File::Spec->catdir($root, 'lib');
use CPAN::Digger;

my $cpan = CPAN::Digger->new(root => $root);
$cpan->run;

