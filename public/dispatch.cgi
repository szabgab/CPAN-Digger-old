#!C:\strawberry\perl\bin\perl.exe
use Plack::Runner;
use Dancer ':syntax';
my $psgi = path(dirname(__FILE__), '..', 'CPAN-Digger-WWW.pl');
Plack::Runner->run($psgi);
