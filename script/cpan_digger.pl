#!/usr/bin/perl -T
use 5.010;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $root;
BEGIN {
	$root = dirname dirname abs_path $0;

	# sanitize variables to make Taint mode happy
	($root) = $root =~ m{   ([\w/-]+)  }x;
	my ($path) = $ENV{PERL5LIB} =~ m{   ([\w/:-]+)  }x;
	unshift @INC, split /:/, $path;
}
use lib File::Spec->catdir($root, 'lib');
use CPAN::Digger;

my $cpan = CPAN::Digger->new(root => $root);
$cpan->run;

