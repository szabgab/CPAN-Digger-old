#!/usr/bin/env perl

BEGIN {
$ENV{CPAN_DIGGER_DBFILE} = '/home/gabor/work/digger/digger.db';
#warn "P: $ENV{PERL5LIB}";
    use lib '/home/gabor/perl5/local/lib/perl5';
    use lib '/home/gabor/perl5/local/lib/perl5/x86_64-linux-gnu-thread-multi';
}

use Dancer ':syntax';
use FindBin '$RealBin';
use Plack::Handler::FCGI;

# For some reason Apache SetEnv directives dont propagate
# correctly to the dispatchers, so forcing PSGI and env here 
# is safer.
set apphandler => 'PSGI';
#set environment => 'production';
set environment => 'test';

my $psgi = path($RealBin, '..', 'bin', 'app.pl');
my $app = do($psgi);
my $server = Plack::Handler::FCGI->new(nproc => 5, detach => 1);

$server->run($app);
