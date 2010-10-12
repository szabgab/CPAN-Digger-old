package CPAN::Digger;
use 5.010;
use Moose;

our $VERSION = '0.01';

#use File::Find::Rule;

use File::Basename qw(dirname);
use File::Copy     qw(copy);
use File::Path     qw(mkpath);
use File::Spec;
use Parse::CPAN::Packages;

has 'tt'     => (is => 'ro', isa => 'Str');
has 'cpan'   => (is => 'ro', isa => 'Str');
has 'output' => (is => 'ro', isa => 'Str');

sub run_index {
	my $self = shift;

	my $p = Parse::CPAN::Packages->new( File::Spec->catfile( $self->cpan, 'modules', '02packages.details.txt.gz' ));

	my @distributions = $p->distributions;
	foreach my $d (@distributions) {
		say $d->prefix;
		my $path = dirname $d->prefix;
		my $src  = File::Spec->catfile( $self->cpan, 'authors', 'id', $d->prefix );
		my $dir = File::Spec->catdir( $self->output, 'id' , lc $d->cpanid);
		mkpath $dir;
		chdir $dir;
		if (substr($d->prefix, -7) eq '.tar.gz') {
			my $cmd = "tar xzf $src";
			#say $cmd;
			my $out = qx{$cmd};
			say '----';
			say $out;
		} else {
			warn "Skipping $src\n";
		}
last;
	}
	
	copy(File::Spec->catfile( $self->tt, 'index.tt' ), File::Spec->catfile( $self->output, 'index.html' ));

	#;
	#$d->dist;
	#$d->version;
	
	#my $iterator = File::Find::Rule->file->name("*.tar.gz")->start( File::Spec->catfile($self->cpan, 'authors', 'id' ) );
	#while ( my $thing = $iterator->match ) {
	#	die $thing;
	#}
}

1;


