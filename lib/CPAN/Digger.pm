package CPAN::Digger;
use 5.010;
use Moose;

our $VERSION = '0.01';

use autodie;
use Carp                  ();
use Template              ();

use CPAN::Digger::DB;

has 'root'   => (is => 'ro', isa => 'Str');
has 'cpan'   => (is => 'ro', isa => 'Str');
has 'output' => (is => 'ro', isa => 'Str');
has 'filter' => (is => 'ro', isa => 'Str');
has 'pod'    => (is => 'ro', isa => 'Str');

has 'db'     => (is => 'rw', isa => 'MongoDB::Database');

has 'tt'     => (is => 'rw', isa => 'Template');

sub BUILD {
	my $self = shift;
	$self->db(CPAN::Digger::DB->db);
};


sub get_tt {
	my $self = shift;

	if (not $self->tt) {

		my $root = $self->root;
	
		my $config = {
			INCLUDE_PATH => "$root/views",
			INTERPOLATE  => 1,
			POST_CHOMP   => 1,
		#	PRE_PROCESS  => 'incl/header.tt',
		#	POST_PROCESS  => 'incl/footer.tt',
			EVAL_PERL    => 1,
		};
		$self->tt(Template->new($config));
	}

	return $self->tt;
}


1;

=head1 NAME

CPAN::Digger - To dig CPAN

=head1 AUTHOR

Gabor Szabo L<gabor@szabgab.com>

=head1 LICENSE

perl

=cut
