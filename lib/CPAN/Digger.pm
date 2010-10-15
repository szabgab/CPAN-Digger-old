package CPAN::Digger;
use 5.010;
use Moose;

our $VERSION = '0.01';

use autodie;
use Carp           ();
use Cwd            qw(cwd);
use Capture::Tiny  qw(capture);
use Data::Dumper   qw(Dumper);
use File::Basename qw(basename dirname);
use File::Copy     qw(copy move);
use File::Path     qw(mkpath);
use File::Spec;
use File::Temp     qw(tempdir);
use Parse::CPAN::Packages;
use Template;
use YAML::Any      ();

use CPAN::Digger::DB;

has 'root'   => (is => 'ro', isa => 'Str');
has 'cpan'   => (is => 'ro', isa => 'Str');
has 'output' => (is => 'ro', isa => 'Str');


my %db;
my %counter;

END {
	print Dumper \%counter;
}
sub run_index {
	my $self = shift;

	my $p = Parse::CPAN::Packages->new( File::Spec->catfile( $self->cpan, 'modules', '02packages.details.txt.gz' ));

	$ENV{PATH} = '/bin:/usr/bin';
	%db =  CPAN::Digger::DB->dbh;

	my $tt = $self->get_tt;

	my @distributions = $p->distributions;
	DISTRO:
	foreach my $d (@distributions) {
		$counter{distro}++;
#		last if  $counter{distro}++ > 5;
		if ($ENV{DIGGER_TEST}) {
			next if $d->dist !~ /Padre/;
		}

		LOG("Working on " . $d->prefix);
		my $path    = dirname $d->prefix;
		my $src     = File::Spec->catfile( $self->cpan, 'authors', 'id', $d->prefix );
		my $src_dir = File::Spec->catdir( $self->output, 'src' , lc $d->cpanid);
		my $dist_dir = File::Spec->catdir( $self->output, 'dist', $d->dist);

		# untaint
		foreach my $p ($src, $src_dir, $dist_dir) {
			$p = eval {_untaint_path($p)};
			if ($@) {
				chomp $@;
				WARN($@);
				next DISTRO;
			}
		}

		my %data = (
			name   => $d->dist,
			author => lc $d->cpanid,
		);

		mkpath $dist_dir;
		mkpath $src_dir;
		chdir $src_dir;
		if (not -e File::Spec->catdir($src_dir, $d->distvname)) {
			my $unzip = $self->unzip($d, $src);
			if (not $unzip) {
				$counter{unzip_failed}++;
				next;
			}
			if ($unzip == 2) {
				$counter{unzip_without_subdir}++;
				$data{unzip_without_subdir} = 1;
			}
		}
		if (not -e File::Spec->catdir($src_dir, $d->distvname)) {
			WARN("No directory for $src_dir " . $d->distvname);
			$counter{no_directory}++;
			next;
		}
		

		if (not $d->distvname) {
			WARN("distvname is empty, skipping database update");
			$counter{distvname_empty}++;
			next;
		}

		chdir $d->distvname;
		$data{has_meta} = -e 'META.yml';
		# TODO we need to make sure the data we read from META.yml is correct and
		# someone does not try to fill it with garbage or too much data.
		if ($data{has_meta}) {
			eval {
				my $meta = YAML::Any::LoadFile('META.yml');
				#print Dumper $meta;
				my @fields = qw(license abstract author name requires version);
				foreach my $field (@fields) {
					$data{meta}{$field} = $meta->{$field};
				}
			};
			if ($@) {
				WARN("Exception while reading YAML file: $@");
				$counter{exception_in_yaml}++;
				$data{exception_in_yaml} = $@;
			}
		}

		if (-d 'xt') {
			$data{xt} = 1;
		}
		if (-d 't') {
			$data{t} = 1;
		}
		if (-f 'test.pl') {
			$data{test_file} = 1;
		}
		my @example_dirs = qw(eg examples);
		foreach my $dir (@example_dirs) {
			if (-d $dir) {
				$data{examples} = $dir;
			}
		}
		my @changes_files = qw(Changes CHANGES ChangeLog);

		LOG("Update DB");
		eval {
			$db{distro}->update({ name => $d->dist }, \%data , { upsert => 1 });
		};
		if ($@) {
			WARN("Exception in MongoDB: $@");
		}

		my @readme_files = qw('README');
		# additional fields needed for the main page of the distribution
		my @special_files = grep { -e $_ } (qw(META.yml MANIFEST INSTALL Makefile.PL Build.PL), @changes_files, @readme_files);
		#opendir my($dh), '.';
		#my @content = eval { map { _untaint_path($_) } grep {$_ ne '.' and $_ ne '..'} readdir $dh };

		$data{special_files} = \@special_files;
		$data{distvname} = $d->distvname;
		my $outfile = File::Spec->catfile($dist_dir, 'index.html');
		$tt->process('dist.tt', \%data, $outfile) or die $tt->error;
	}

	#$self->generate_central_files;
	#$self->copy_static_files;

	return;
}

sub generate_central_files {
	my $self = shift;

	my $tt = $self->get_tt;
	my %map = (
		'index.tt' => 'index.html',
		'news.tt'  => 'news.html',
	);
	foreach my $infile (keys %map) {
		my $outfile = _untaint_path(File::Spec->catfile($self->output, $map{$infile}));
		my $data = {};
		$tt->process($infile, $data, $outfile) or die $tt->error;
	}
	return;
}

sub copy_static_files {
	my $self = shift;
	foreach my $file (glob File::Spec->catdir($self->root, 'static', '*')) {
		$file = _untaint_path($file);
		my $output = _untaint_path(File::Spec->catdir($self->output, basename($file)));
		LOG("Copy $file to $output");
		copy $file, $output;
	}
	return;
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

	my @cmd;
	given ($d->prefix) {
		when (qr/\.(tar\.gz|tgz)$/) {
			@cmd = ('tar', 'xzf', "'$src'");
		}
		when (qr/\.tar\.bz2$/) {
			@cmd = ('tar', 'xjf', "'$src'");
		}
		when (qr/\.zip$/) {
			@cmd = ('unzip', "'$src'");
		}
		default{
		}
	}
	if (@cmd) {
		my $cmd = join " ", @cmd;
		#LOG(join " ", @cmd);
		LOG($cmd);

		my $cwd = eval { _untaint_path(cwd()) };
		if ($@) {
			WARN("Could not untaint cwd: '" . cwd() . "'  $@");
			return;
		}
		my $temp = tempdir( CLEANUP => 1 );
		chdir $temp;
		my ($out, $err) = eval { capture { system($cmd) } };
		if ($@) {
			die "$cmd $@";
		}
		if ($err) {
			WARN("Command ($cmd) failed: $err");
			chdir $cwd;
			return;
		}

		# TODO check if this was really successful?
		# TODO check what were the permission bits
		_chmod($temp);

		opendir my($dh), '.';
		my @content = eval { map { _untaint_path($_) } grep {$_ ne '.' and $_ ne '..'} readdir $dh };
		if ($@) {
			WARN("Could not untaint content of directory: $@");
			chdir $cwd;
			return;
		}
		
		#print "CON: @content\n";
		if (@content == 1 and $content[0] eq $d->distvname) {
			# using external mv as File::Copy::move cannot move directory...
			my $cmd_move = "mv " . $d->distvname . " $cwd";
			#LOG("Moving " . $d->distvname . " to $cwd");
			LOG($cmd_move);
			#move $d->distvname, File::Spec->catdir( $cwd, $d->distvname );
			system($cmd_move);
			# TODO: some files open with only read permissions on the main directory.
			# this needs to be reported and I need to correct it on the local unzip setting
			# xw on the directories and w on the files
			chdir $cwd;
			return 1;
		} else {
			my $target_dir = eval { _untaint_path(File::Spec->catdir( $cwd, $d->distvname )) };
			if ($@) {
				WARN("Could not untaint target_directory: $@");
				chdir $cwd;
				return;
			}
			LOG("Need to create $target_dir");
			mkdir $target_dir;
			foreach my $thing (@content) {
				system "mv $thing $target_dir";
			}
			chdir $cwd;
			return 2;
		}
	} else {
		WARN("Does not know how to unzip $src");
	}
	return 0;
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

sub _untaint_path {
	my $p = shift;
	if ($p =~ m{^([\w/.-]+)$}x) {
		$p = $1;
	} else {
		Carp::confess("Untaint failed for '$p'\n");
	}
	if (index($p, '..') > -1) {
		Carp::confess("Found .. in '$p'\n");
	}
	return $p;
}

sub _chmod {
	my $dir = shift;
	opendir my ($dh), $dir;
	my @content = eval { map { _untaint_path($_) } grep {$_ ne '.' and $_ ne '..'} readdir $dh };
	if ($@) {
		WARN("Could not untaint: $@");
	}
	foreach my $thing (@content) {
		my $path = File::Spec->catfile($dir, $thing);
		given ($path) {
			when (-l $_) {
				WARN("Symlink found '$path'");
				unlink $path;
			}
			when (-d $_) {
				chmod 0755, $path;
				_chmod($path);
			}
			when (-f $_) {
				chmod 0644, $path;
			}
			default {
				WARN("Unknown thing '$path'");
			}
		}
	}
	return;
}

1;


