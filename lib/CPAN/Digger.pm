package CPAN::Digger;
use 5.008008;
use Moose;
use MooseX::StrictConstructor;

our $VERSION = '0.01';

use autodie;
use Carp                  ();
use Template              ();

#use CPAN::Digger::DB;

has 'root'    => (is => 'ro', isa => 'Str');
has 'dbfile'  => (is => 'ro', isa => 'Str');

#has 'db'     => (is => 'rw', isa => 'MongoDB::Database');

has 'tt'     => (is => 'rw', isa => 'Template');

sub BUILD {
	my $self = shift;
	#$self->db(CPAN::Digger::DB->db);
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

=head1 SYNOPSIS

This module is the the web application running at L<http://...>.
You can use the interface by browsing there.

For internal usage follow the SETUP section.

=head1 SETUP

Download the tar.gz file. Open it and install all its dependencies.

Running perl script\cpan_digger_index.pl will create a local database
using the module given in the directory given with the --dir option.

Running CPAN-Digger-WWW.pl will launch a stand-alone web server.

=head1 Indexing

=head2 Word indexing (planned)

For each distribution split up the name and each part of the name becomes a word

For each module name probably the parts of the name might be words though the last part should
be the most significants

META.yml might have some keywords stored

Names of the functions / methods

Gull text indexing of the POD for each module

Various sections might have different weight.

Later we will allow users of the site to add keywords to the modules/distributions

Store each keyword in lowercase only and map everything to lowercase
for each word include where it could be found

   word    type_of_source       the source
   cgi     distro               CGI-Simple
   cgi     distro               CGI-Application
   cgi     module               CGI::Simple
   cgi     module               CGI::Application

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT

Copyright 2010 Gabor Szabo L<gabor@szabgab.com>


=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# Copyright 2010 Gabor Szabo http://szabgab.com/
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
