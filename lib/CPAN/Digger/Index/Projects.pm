package CPAN::Digger::Index::Projects;
use Moose;

extends 'CPAN::Digger::Index';

has 'projects'      => (is => 'ro', isa => 'Str');
has 'projects_data' => (is => 'rw', isa => 'ArrayRef');

use CPAN::Digger::Tools;
use CPAN::Digger::DB;

use Data::Dumper qw(Dumper);
use YAML         qw(LoadFile);

# stupid duplicate from Index.pm
my $dbx;
sub db {
	if (not $dbx) {
		$dbx = CPAN::Digger::DB->new;
		$dbx->setup;
	}
	return $dbx;
}

sub get_projects {
	my ($self) = @_;
	if (not $self->projects_data) {
		my $d = LoadFile $self->projects;
		$self->projects_data($d->{projects});
	}
	return $self->projects_data;
}

sub update_from_whois {
	my ($self) = @_;

	LOG('start adding authors');

	my $projects = $self->get_projects;
	#die Dumper $p;

	db->dbh->begin_work;
	foreach my $p (@$projects) {
		my $have = db->get_author($p->{author});
		if (not $have) {
			LOG("add_author $p->{author}");
			db->add_author({}, $p->{author});
		}
	}
	db->dbh->commit;

	LOG('adding authors finished');

	return;
}

sub collect_distributions {
	WARN('collect_distributions NOT yet implemented');
	return;
}

sub process_all_distros {
	WARN('process_all_distros NOT yet implemented');
	return;
}


#sub generate_central_files {
#	return;
#}

1;

