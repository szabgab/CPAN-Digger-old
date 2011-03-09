package CPAN::Digger::PPI;
use 5.008008;
use Moose;

use PPI::Document;
use PPI::Find;

has 'infile' => (is => 'rw', isa => 'Str');
has 'ppi'    => (is => 'rw', isa => 'PPI::Document');

sub read_file {
	my ($self) = @_;
	
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

sub get_outline {
	my ($self) = @_;

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

sub get_syntax {
	my ($self) = @_;

	my $ppi = $self->get_ppi;
	my $html = <<"END_HTML";
<html><head>
  <link rel="stylesheet" type="text/css" href="/css/style.css" /> 

  <script type="text/javascript" src="/js/jquery-1.4.2.min.js"></script>
  <script type="text/javascript" src="/js/jquery-ui-1.8.5.custom.min.js"></script>
  <script type="text/javascript" src="/js/digger.js"></script>
</head><body>
<div id="code">
END_HTML

	my @tokens = $ppi->tokens;
	my $current_row;
	foreach my $t (@tokens) {

		my ( $row, $rowchar, $col ) = @{ $t->location };

		my $css = $self->_css_class($t);
		my $content = $t->content;
		chomp $content;

		# TODO set the width of the rownumber constant
		# TODO allow the user to turn on/off row numbers
		#      (this should be some javascript setting hide/show)
		if (not defined $current_row or $current_row < $row) {
                        if (defined $current_row) {
				$html .= "</div>\n"; #close the row;
                        }
			$current_row = $row;
			$html .= qq(<div class="row">$current_row );
		}


		# TODO: how handle tabs and indentation in general??
		if ($t->isa('PPI::Token::Whitespace') and (length $content > 1)) {
			$content = qq(<pre class="ws">$content</pre>);
		}
		$html .= qq(<div class="$css">$content</div>);

		#		if ($row > $first and $row < $first + 5) {
		#			print "$row, $rowchar, ", $t->length, "  ", $t->class, "  ", $css, "  ", $t->content, "\n";
		#		}
		#		last if $row > 10;
		#my $color = $colors{$css};
		#if ( not defined $color ) {
		#	TRACE("Missing definition for '$css'\n") if DEBUG;
		#	next;
		#}
		#next if not $color;

		#my $start = 0; #$editor->PositionFromLine( $row - 1 ) + $rowchar - 1;
		#my $len   = $t->length;

		#$editor->StartStyling( $start, $color );
		#$editor->SetStyling( $len, $color );
	}
	$html .= "</div>\n"; #close the last row;
	$html .= "</div></body></html>\n";

	return $html;
}

sub _css_class {
	my $self  = shift;
	my $Token = shift;

	if ( $Token->isa('PPI::Token::Word') ) {

		# There are some words we can be very confident are
		# being used as keywords
		unless ( $Token->snext_sibling and $Token->snext_sibling->content eq '=>' ) {
			if ( $Token->content =~ /^(?:sub|return)$/ ) {
				return 'keyword';
			} elsif ( $Token->content =~ /^(?:undef|shift|defined|bless)$/ ) {
				return 'core';
			}
		}
		if ( $Token->previous_sibling and $Token->previous_sibling->content eq '->' ) {
			if ( $Token->content =~ /^(?:new)$/ ) {
				return 'core';
			}
		}
		if ( $Token->parent->isa('PPI::Statement::Include') ) {
			if ( $Token->content =~ /^(?:use|no)$/ ) {
				return 'keyword';
			}
			if ( $Token->content eq $Token->parent->pragma ) {
				return 'pragma';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Variable') ) {
			if ( $Token->content =~ /^(?:my|local|our)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Compound') ) {
			if ( $Token->content =~ /^(?:if|else|elsif|unless|for|foreach|while|my)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Package') ) {
			if ( $Token->content eq 'package' ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Scheduled') ) {
			return 'keyword';
		}
	}

	# Normal coloring
	my $css = ref $Token;
	$css =~ s/^.+:://;
	$css;
}

1;
