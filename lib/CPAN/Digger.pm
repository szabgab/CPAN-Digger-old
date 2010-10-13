package CPAN::Digger;
use 5.010;
use Moose;

our $VERSION = '0.01';

use Data::Dumper   qw(Dumper);
use File::Basename qw(basename dirname);
use File::Copy     qw(copy);
use File::Path     qw(mkpath);
use File::Spec;
use Parse::CPAN::Packages;
use Template;
use YAML::Any      ();

use CPAN::Digger::DB;

has 'root'   => (is => 'ro', isa => 'Str');
has 'cpan'   => (is => 'ro', isa => 'Str');
has 'output' => (is => 'ro', isa => 'Str');


my %db;

sub run_index {
	my $self = shift;

	my $p = Parse::CPAN::Packages->new( File::Spec->catfile( $self->cpan, 'modules', '02packages.details.txt.gz' ));

	%db =  CPAN::Digger::DB->dbh;

	my $tt = $self->get_tt;

	my @distributions = $p->distributions;
	foreach my $d (@distributions) {
		LOG("Working on " . $d->prefix);
		my $path    = dirname $d->prefix;
		my $src     = File::Spec->catfile( $self->cpan, 'authors', 'id', $d->prefix );
		my $src_dir = File::Spec->catdir( $self->output, 'src' , lc $d->cpanid);
		my $dist_dir = File::Spec->catdir( $self->output, 'dist', $d->dist);

		mkpath $dist_dir;
		mkpath $src_dir;
		chdir $src_dir;
		if (not -e File::Spec->catdir($src_dir, $d->distvname)) {
			$self->unzip($d, $src);
		}
		if (not -e File::Spec->catdir($src_dir, $d->distvname)) {
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

		# additional fields needed for the main page of the distribution
		$data{distvname} = $d->distvname;
		my $outfile = File::Spec->catfile($dist_dir, 'index.html');
		$tt->process('dist.tt', \%data, $outfile) or die $tt->error;
		
last if $main::counter++ > 5;
	}

	my %map = (
		'index.tt' => 'index.html',
	);
	foreach my $infile (keys %map) {
		my $outfile = File::Spec->catfile($self->output, $map{$infile});
		my $data = {};
		$tt->process($infile, $data, $outfile) or die $tt->error;
	}

	foreach my $file (glob File::Spec->catdir($self->root, 'static', '*')) {
		my $output = File::Spec->catdir($self->output, basename($file));
		LOG("Copy $file to $output");
		copy $file, $output;
	}
}


sub run {
	my $self = shift;
	my %args = @_;

	require CGI;
	my $q = CGI->new;
	my $term = $q->param('q') // '';
	$term =~ s/[^\w]//g; # sanitize for now
	my %db =  CPAN::Digger::DB->dbh;
	my $result = $db{distro}->find({ name => qr/$term/ });

	my $tt = $self->get_tt;
	print $q->header;

	my @results;
	while (my $d = $result->next) {
		push @results, $d;
	}

	my %data = (
		results => \@results,
	);
	$tt->process('result.tt', \%data) or die $tt->error;
	return;
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

sub get_tt {
	my $self = shift;

	my $root = $self->root;

	my $config = {
		INCLUDE_PATH => "$root/tt",
		INTERPOLATE  => 1,
		POST_CHOMP   => 1,
	#	PRE_PROCESS  => 'incl/header.tt',
	#	POST_PROCESS  => 'incl/footer.tt',
		EVAL_PERL    => 1,
	};
	Template->new($config);
}

1;


