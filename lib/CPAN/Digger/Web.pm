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


	my $m = $q->param('m') || '';
	$m =~ s/[^\w:.*+?-]//g; # sanitize for now

	my $license = $q->param('license') || '';
	$license =~ s/[^\w:.*+?-]//g; # sanitize for now
	
	my $start_time = time;

	my $result;
	if ($m) {
		$data{q} = $m;
		$result = $self->db->distro->find({ 'modules.name' => $m });
	} elsif ($term) {
		$data{q} = $term;
		$result = $self->db->distro->find({ 'name' => qr/$term/i });
	} elsif ($license) {
		$data{q} = $term;
		$result = $self->db->distro->find({ 'meta.license' => $license });
	} else {
		$data{not_term_found} = 1;
		$tt->process('result.tt', \%data) or die $tt->error;
		return;
	}


	my @results;
	my $count = 0;
	while (my $d = $result->next) {
		$count++;
		push @results, $d;
	}
	if (not $count) {
		$data{not_found} = 1;
	}

	my $end_time = time;
	$data{results} = \@results;
	$data{ellapsed_time} = $end_time - $start_time;
	$tt->process('result.tt', \%data) or die $tt->error;

	return;
}

1;
