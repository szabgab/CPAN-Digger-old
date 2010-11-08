package CPAN::Digger::WWW;
use Dancer ':syntax';

our $VERSION = '0.1';

use CPAN::Digger::DB;
use Time::HiRes           qw(time);

# for development:
# on the real server the index file will be static
# if ($^O =~ m/win32/i) {
    # get '/' => sub {
        # #send_file(path config->{public}, 'index.html');
        # send_file 'index.html';
        # #template 'index';
    # };
# }

get '/' => sub {
    template 'index', {
        keywords => 'x,y',
    };
};
foreach my $page (qw(news faq)) {
    get "/$page" => sub {
        template $page;
    }
};


get '/licenses' => sub {
    my $data_file = path config->{public}, 'data', 'licenses.json';
    my $json = eval {from_json slurp($data_file)};
    template 'licenses', {
        licenses => $json,
    };
};


get '/dancer' => sub {
    content_type 'text/plain';
    to_dumper config;
};


get '/license/:query' => sub {
    my $license = params->{query}|| '';
    $license =~ s/[^\w:.*+?-]//g; # sanitize for now
    return _data({ 'meta.license' => $license });
};

get '/q/:query' => sub {
    my $term = params->{query} || '';
    $term =~ s/[^\w:.*+?-]//g; # sanitize for now
    return _data({ 'name' => qr/$term/i });
};

get '/module/:query' => sub {
    my $module = params->{query} || '';
    $module =~ s/[^\w:.*+?-]//g; # sanitize for now
    return _data({ 'modules.name' => $module });
};

get '/m/:query' => sub {
    my $module = params->{query} || '';
    $module =~ s/[^\w:.*+?-]//g; # sanitize for now
    my $results = _fetch_from_db({ 'modules.name' => $module });

    if (not @$results) {
        template 'error', {
            no_such_module => 1, 
            module => $module,
        };
    } elsif (@$results == 1) {
        $module =~ s{::}{/}g;
        return redirect "/dist/$results->[0]{name}/lib/$module.pm";
    } else {
        my $path = $module;
        $path =~ s{::}{/}g;
        my @links;
        foreach my $r (@$results) {
            push @links, {
                distro => $r->{name},
                module => $module,
                path   => $path,
            };
        }
        template => 'modules', {
            module => $module,
            links  => \@links,
        }
    }


    # TODO what if we received several results? 
    # Should we show a list of links?
};


sub _data {
    my ($params) = @_;

    my $start_time = time;

    my $results = _fetch_from_db($params);

    my $end_time = time;

    content_type 'text/plain';

    return to_json({
        results => $results,
        ellapsed_time => $end_time - $start_time,
        }, utf8 => 1, convert_blessed => 1);
}

sub _fetch_from_db {
    my ($params) = @_;

    my $result = CPAN::Digger::DB->db->distro->find($params);
    my @results;
    my $count = 0;
    while (my $d = $result->next) {
        $count++;
        #delete $d->{_id};
        my %data = (
            name => $d->{name},
            author => $d->{author},
        );
        push @results, \%data;
    }
    return \@results;
}


# this part is only needed in the stand alone environment
# if used under Apache, then Apache should be configured
# to handle these static files
get qr{/(src|dist|data)(/.*)?} => sub {
    # TODO this gives a warning in Dancer::Router if we ask for dist only as the
    # capture in the () is an undef
    #my ($path) = splat; 
    #$path ||= '/';
    #$path = "/dist$path";

    my $path = request->path;
    # TODO: how can I add a configuration option to config.yml 
    # to point to a directory relative to the appdir ?
    my $full_path = path config->{appdir}, '..', 'digger', $path;
    if (-d $full_path) {
        if (-e path($full_path, 'index.html')) {
            $full_path = path($full_path, 'index.html');
        } else {
            if (opendir my $dh, $full_path) {
                my @dir = grep {$_ ne '.' and $_ ne '..'} readdir $dh;
                my $html = "<ul>\n";
                $html .= join "\n", map { qq(<li><a href="$_">$_</a></li>) } sort @dir;
                $html .= "\n</ul>\n";
                return $html;
            } else {
                return "Cannot provide directory listing";
            }
            #return "directory listing $full_path";
        }
    }
    if (-f $full_path) {
#        print STDERR "Serving '$full_path'\n";
        if (-s $full_path) {
            if ($path =~ m{/src}) { # TODO stop hard coding here!
                content_type 'text/plain';
            }
            return slurp($full_path);
        } else {
            return "This file was empty";
        }
    }
    return "Cannot handle $path  $full_path";
};

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die;
    local $/ = undef;
    <$fh>;
}

true;

=head1 NAME

CPAN::Digger::WWW - Dancer based web interface to L<CPAN::Digger>

=head1 COPYRIGHT

Copyright 2010 Gabor Szabo L<gabor@szabgab.com>


=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2010 Gabor Szabo http://szabgab.com/
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
