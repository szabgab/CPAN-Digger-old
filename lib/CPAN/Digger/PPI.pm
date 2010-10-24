package CPAN::Digger::PPI;
use 5.010;
use Moose;

use PPI::Document;
use PPI::Find;
use Data::Dumper qw(Dumper);

has 'infile' => (is => 'rw');

sub read_file {
	my $self = shift;
	
	my $file = $self->infile;
	my $text = do {
		open my $fh, '<', $file or die;
		local $/ = undef;
		<$fh>;
	};
	return $text;
}

sub process {
	my $self = shift;

	my $text = $self->read_file;

	my $ppi = PPI::Document->new( \$text );
	die if not defined $ppi;
	$ppi->index_locations;

	my @things = PPI::Find->new(
		sub {
			# This is a fairly ugly search
			return 1 if ref $_[0] eq 'PPI::Statement::Package';
			return 1 if ref $_[0] eq 'PPI::Statement::Include';
			return 1 if ref $_[0] eq 'PPI::Statement::Sub';
			return 1 if ref $_[0] eq 'PPI::Statement';
		}
	)->in($ppi);

	my %cur_pkg;

	foreach my $thing (@things) {
		if ( ref $thing eq 'PPI::Statement::Package' ) {
			print $thing->namespace, "\n";
		}
	}

	#print Dumper \@things;
	return;
}


1;
