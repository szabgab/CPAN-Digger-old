package CPAN::Digger::PPI;
use 5.008008;
use Moose;

use PPI::Document;
use PPI::Find;

has 'infile' => (is => 'rw', isa => 'Str');
has 'ppi'    => (is => 'rw', isa => 'PPI::Document');

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

sub get_ppi {
	my ($self) = @_;

	if (not $self->ppi) {
		my $text = $self->read_file;
		my $ppi = PPI::Document->new( \$text );
		die if not defined $ppi;
		$ppi->index_locations;
		$self->ppi($ppi);
	}
	return $self->ppi;
}

sub process {
	my $self = shift;

	my $ppi = $self->get_ppi;

	my @things = PPI::Find->new(
		sub {
			# This is a fairly ugly search
			return 1 if ref $_[0] eq 'PPI::Statement::Package';
			return 1 if ref $_[0] eq 'PPI::Statement::Include';
			return 1 if ref $_[0] eq 'PPI::Statement::Sub';
			return 1 if ref $_[0] eq 'PPI::Statement';
		}
	)->in($ppi);

	my $check_alternate_sub_decls = 0;

	# Build the outline structure from the search results
	my @outline       = ();
	my $cur_pkg       = {};
	my $not_first_one = 0;
	foreach my $thing (@things) {
		if ( ref $thing eq 'PPI::Statement::Package' ) {
			if ($not_first_one) {
				if ( not $cur_pkg->{name} ) {
					$cur_pkg->{name} = 'main';
				}
				push @outline, $cur_pkg;
				$cur_pkg = {};
			}
			$not_first_one   = 1;
			$cur_pkg->{name} = $thing->namespace;
			$cur_pkg->{line} = $thing->location->[0];
		} elsif ( ref $thing eq 'PPI::Statement::Include' ) {
			next if $thing->type eq 'no';
			if ( $thing->pragma ) {
				push @{ $cur_pkg->{pragmata} }, { name => $thing->pragma, line => $thing->location->[0] };
			} elsif ( $thing->module ) {
				push @{ $cur_pkg->{modules} }, { name => $thing->module, line => $thing->location->[0] };
				unless ($check_alternate_sub_decls) {
					$check_alternate_sub_decls = 1
						if grep { $thing->module eq $_ } (
						'Method::Signatures',
						'MooseX::Declare',
						'MooseX::Method::Signatures'
						);
				}
			}
		} elsif ( ref $thing eq 'PPI::Statement::Sub' ) {
			push @{ $cur_pkg->{methods} }, { name => $thing->name, line => $thing->location->[0] };
		} elsif ( ref $thing eq 'PPI::Statement' ) {

			# last resort, let's analyse further down...
			my $node1 = $thing->first_element;
			my $node2 = $thing->child(2);
			next unless defined $node2;

			# Moose attribute declaration
			if ( $node1->isa('PPI::Token::Word') && $node1->content eq 'has' ) {
				push @{ $cur_pkg->{attributes} }, { name => $node2->content, line => $thing->location->[0] };
				next;
			}

			# MooseX::POE event declaration
			if ( $node1->isa('PPI::Token::Word') && $node1->content eq 'event' ) {
				push @{ $cur_pkg->{events} }, { name => $node2->content, line => $thing->location->[0] };
				next;
			}
		}
	}

	if ($check_alternate_sub_decls) {
		$ppi->find(
			sub {
				$_[1]->isa('PPI::Token::Word') or return 0;
				$_[1]->content =~ /^(?:func|method)\z/ or return 0;
				$_[1]->next_sibling->isa('PPI::Token::Whitespace') or return 0;
				my $sib_content = $_[1]->next_sibling->next_sibling->content or return 0;

				$sib_content =~ m/^\b(\w+)\b/;
				return 0 unless defined $1;

				push @{ $cur_pkg->{methods} }, { name => $1, line => $_[1]->line_number };

				return 1;
			}
		);
	}

	if ( not $cur_pkg->{name} ) {
		$cur_pkg->{name} = 'main';
	}

	push @outline, $cur_pkg;

	return \@outline;
}


1;
