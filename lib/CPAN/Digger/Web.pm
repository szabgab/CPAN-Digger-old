package CPAN::Digger::Web;
use 5.010;
use Moose;

our $VERSION = '0.01';

extends 'CPAN::Digger';

use autodie;
use Time::HiRes           qw(time);

sub run {
	my $self = shift;
	my %args = @_;

	require CGI;
	my $q = CGI->new;

	my $tt = $self->get_tt;
	print $q->header;

	my $term = $q->param('q') || '';
	$term =~ s/[^\w:.*+?-]//g; # sanitize for now

	my %data;
	$data{q} = $term;

	if (not $term) {
		$data{not_found} = 1;
		$tt->process('result.tt', \%data) or die $tt->error;
		return;
	}

	
	my $start_time = time;
	my $result = $self->db->distro->find({ name => qr/$term/i });


	my @results;
	while (my $d = $result->next) {
		push @results, $d;
	}

	my $end_time = time;
	$data{results} = \@results;
	$data{ellapsed_time} = $end_time - $start_time;
	$tt->process('result.tt', \%data) or die $tt->error;

	return;
}

1;
