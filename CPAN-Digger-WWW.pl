#!C:\strawberry\perl\bin\perl.exe
use Dancer;
use lib path(dirname(__FILE__), 'lib');
load_app 'CPAN::Digger::WWW';
dance;
