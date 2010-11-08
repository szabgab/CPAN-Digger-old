package CPAN::Digger::Pod;
use 5.010;
use Moose;

our $VERSION = '0.01';

#extends 'CPAN::Digger';
extends 'Pod::Simple::HTML';
#has 'podfile' => (is => 'rw', isa => 'Str');

use CPAN::Digger::Index;

use autodie;

sub process {
	my ($self, $infile, $outfile) = @_;

	$infile  = CPAN::Digger::Index::_untaint_path($infile);
	$outfile = CPAN::Digger::Index::_untaint_path($outfile);
	my $html;
	$self->html_css(
		qq(<link rel="stylesheet" type="text/css" title="pod_stylesheet" href="/style.css">\n),
	);
	$self->output_string( \$html );
	$self->parse_file( $infile );
	return if not $html;

	open my $out, '>', $outfile;
	print $out $html;
	return 1;
}




1;
