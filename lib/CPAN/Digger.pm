package CPAN::Digger;
use 5.010;
use Moose;

our $VERSION = '0.01';

use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);
use File::Copy     qw(copy);
use File::Path     qw(mkpath);
use File::Spec;
use Parse::CPAN::Packages;

use CPAN::Digger::DB;

has 'tt'     => (is => 'ro', isa => 'Str');
has 'cpan'   => (is => 'ro', isa => 'Str');
has 'output' => (is => 'ro', isa => 'Str');

sub run_index {
	my $self = shift;

	my $p = Parse::CPAN::Packages->new( File::Spec->catfile( $self->cpan, 'modules', '02packages.details.txt.gz' ));

	my %db =  CPAN::Digger::DB->dbh;

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
			$db{distro}->update({ name => $d->dist }, { name => $d->dist, author => lc $d->cpanid } , { upsert => 1 })
		} else {
			warn "Skipping $src\n";
		}
last if $main::counter++ > 5;
	}

	copy(File::Spec->catfile( $self->tt, 'index.tt' ), File::Spec->catfile( $self->output, 'index.html' ));

	#;
	#$d->dist;
	#$d->version;

}

sub run {
	my $self = shift;
	require CGI;
	my $q = CGI->new;
	my $term = $q->param('q');
	$term =~ s/[^\w]//g; # sanitize for now
	my %db =  CPAN::Digger::DB->dbh;
	my $result = $db{distro}->find({ name => qr/$term/ });

	print $q->header;
	print "<pre>\n";
	while (my $doc = $result->next) {
		say $doc->{name};
	}
#	print Dumper $result;
	print "\n</pre>\n";
}


1;


