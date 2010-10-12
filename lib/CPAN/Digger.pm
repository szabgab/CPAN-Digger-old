package CPAN::Digger;
use 5.010;
use Moose;

our $VERSION = '0.01';

#use File::Find::Rule;
use File::Basename qw(dirname);
use Parse::CPAN::Packages;

has 'cpan'   => (is => 'ro', isa => 'Str');
has 'output' => (is => 'ro', isa => 'Str');

sub run_index {
	my $self = shift;

	my $p = Parse::CPAN::Packages->new( File::Spec->catfile( $self->cpan, 'modules', '02packages.details.txt.gz' ));

	my @distributions = $p->distributions;
	foreach my $d (@distributions) {
		say $d->prefix;
		my $path = dirname $d->prefix;
		if $d->pre
exit;
	}
	#$d->cpanid;
	#$d->dist;
	#$d->version;
	
	#my $iterator = File::Find::Rule->file->name("*.tar.gz")->start( File::Spec->catfile($self->cpan, 'authors', 'id' ) );
	#while ( my $thing = $iterator->match ) {
	#	die $thing;
	#}
}

1;


