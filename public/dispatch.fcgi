#!/usr/bin/env perl

BEGIN {
$ENV{CPAN_DIGGER_DBFILE} = '/home/gabor/work/digger/digger.db';
# in the production environment
    use lib '/home/gabor/perl5/local/lib/perl5';
    use lib '/home/gabor/perl5/local/lib/perl5/x86_64-linux-gnu-thread-multi';

# in the development environment
    use lib '/home/gabor/perl5/lib/perl5';
    use lib '/home/gabor/perl5/lib/perl5/x86_64-linux-gnu-thread-multi';
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
my $app = Plack::Util::load_psgi($psgi);
#my $app = do($psgi);
die $! if not defined $app;
my $server = Plack::Handler::FCGI->new(nproc => 5, detach => 1);

$server->run($app);
