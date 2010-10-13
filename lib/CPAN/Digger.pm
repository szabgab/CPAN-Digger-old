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
use YAML::Any      ();

use CPAN::Digger::DB;

has 'tt'     => (is => 'ro', isa => 'Str');
has 'cpan'   => (is => 'ro', isa => 'Str');
has 'output' => (is => 'ro', isa => 'Str');

my %db;

sub run_index {
	my $self = shift;

	my $p = Parse::CPAN::Packages->new( File::Spec->catfile( $self->cpan, 'modules', '02packages.details.txt.gz' ));

	%db =  CPAN::Digger::DB->dbh;

	my @distributions = $p->distributions;
	foreach my $d (@distributions) {
		LOG("Working on " . $d->prefix);
		my $path = dirname $d->prefix;
		my $src  = File::Spec->catfile( $self->cpan, 'authors', 'id', $d->prefix );
		my $dir  = File::Spec->catdir( $self->output, 'id' , lc $d->cpanid);

		mkpath $dir;
		chdir $dir;
		if (not -e File::Spec->catdir($dir, $d->distvname)) {
			$self->unzip($d, $src);
		}
		if (not -e File::Spec->catdir($dir, $d->distvname)) {
			WARN("No directory for $src");
			next;
			
		}
		
		chdir $d->distvname;
		my %data = (
			name   => $d->dist,
			author => lc $d->cpanid,
		);

		$data{has_meta} = -e 'META.yml';
		# TODO we need to make sure the data we read from META.yml is correct and
		# someone does not try to fill it with garbage or too much data.
		if ($data{has_meta}) {
			my $meta = YAML::Any::LoadFile('META.yml');
			#print Dumper $meta;
			$data{meta}{license} = $meta->{license};
		}

		LOG("Update DB");
		$db{distro}->update({ name => $d->dist }, \%data , { upsert => 1 });
		
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

sub WARN {
	LOG("WARN: $_[0]");
}
sub LOG {
	my $msg = shift;
	print "$msg\n";
}

sub unzip {
	my ($self, $d, $src) = @_;
	if (substr($d->prefix, -7) eq '.tar.gz') {
		my $cmd = "tar xzf $src";
		LOG($cmd);
		my $out = qx{$cmd};
		#say '----';
		#say $out;
	} else {
		WARN("Does not know how unzip $src");
	}
}

1;


