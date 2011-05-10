package CPAN::Digger::WWW;
use Dancer ':syntax';

our $VERSION = '0.1';

use CPAN::Digger::DB;

use Data::Dumper  qw(Dumper);
use Encode        qw(decode);
use File::Basename qw(basename);
use List::Util    qw(max);
use POSIX         ();
use Time::HiRes   qw(time);

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

# search.cpan.org keeps the users in ~pauseid 
# This is a UNIXism so we have them under /id/pauseid
# but we want to make it comfortable to those who used to the way
# search.cpan.org does this
get '/~*' => sub {
    my ($path) = splat;
    redirect '/id/' . $path;
};

get '/id/:pauseid/' => sub {
    redirect '/id/' . params->{pauseid};
};

get '/id/:pauseid' => sub {
    my $pauseid = lc(params->{pauseid} || '');
    my $t0 = time;
    
    # TODO show error if no pauseid received
    $pauseid =~ s/\W//g; # sanitise

    debug($pauseid);
    
    my $dbfile = $ENV{CPAN_DIGGER_DBFILE};
    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;

    my $author = $db->get_author(uc $pauseid);
    debug(Dumper $author);
    my $distributions = $db->get_distros_of(uc $pauseid);
    my $last_upload = max(map {$_->{file_timestamp}} @$distributions);

    foreach my $d (@$distributions) {
        $d->{release} = _date(delete $d->{file_timestamp});
        $d->{distrover} = "$d->{name}-$d->{version}";
        $d->{filename}  = basename($d->{path});
    }
    my %data = (
        name        => decode('utf8', $author->{name} || $author->{asciiname} || ''),
        last_upload => _date($last_upload),
	pauseid     => uc($pauseid),
	lcpauseid   => lc($pauseid),
	email       => $author->{email},
	homepage    => $author->{homepage},
	backpan     => uc(join("/", substr($pauseid, 0, 1), substr($pauseid, 0, 2), $pauseid)),
	distributions => $distributions,
        ellapsed_time => time - $t0,
    );
    return template 'author.tt', \%data;
};

get '/dist/:name/' => sub {
    redirect '/dist/' . params->{name};
};

get '/dist/:name' => sub {
    my $name = params->{name} || '';
    my $t0 = time;
    
    # TODO show error if no name received
    $name =~ s/[^\w-]//g; # sanitise

    debug($name);
    my $dbfile = $ENV{CPAN_DIGGER_DBFILE};
    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;

    my $d = $db->get_distro_latest($name);
    my $details = $db->get_distro_details_by_id($d->{id});
    #debug(Dumper $d);
    #debug(Dumper $details);

    my $author = $db->get_author(uc $d->{author});

#debug($d->{file_timestamp});
#debug(_date($d->{file_timestamp}));

    my %data = (
        name      => $name,
        pauseid   => $d->{author},
        released  => _date($d->{file_timestamp}),
        distvname => "$name-$d->{version}",
        author    => {
            name => decode('utf8', $author->{name}),
        },
        meta_data => {
            abstract => '',
        },
        ellapsed_time => time-$t0,
    );
    $data{$_} = $d->{$_} for qw(version path);
    $data{$_} = $details->{$_} for qw(has_t has_meta_yml has_meta_json); # test_file
    #debug(Dumper \%data);
    return template 'dist.tt', \%data;
};

foreach my $page (qw(news faq)) {
    get "/$page" => sub {
        template $page;
    };
    get "/$page/" => sub {
        redirect "/$page";
    };
};

# get '/licenses' => sub {
    # my $data_file = path config->{public}, 'data', 'licenses.json';
    # my $json = eval {from_json slurp($data_file)};
    # template 'licenses', {
        # licenses => $json,
    # };
# };


# get '/license/:query' => sub {
    # my $license = params->{query}|| '';
    # $license =~ s/[^\w:.*+?-]//g; # sanitize for now
    # return _data({ 'meta.license' => $license });
# };

get '/q/:query/:what' => sub {
    my $term = params->{query} || '';
    my $what = params->{what} || '';
    my $t0 = time;
    if ($what !~ /^(distribution|author)$/) {
        return to_json { error => 'Invalid search type' };
    }

    $term =~ s/[^\w:.*+?-]//g; # sanitize for now
    content_type 'text/plain';
    #my $data = { 'abc' => $term };

    my $dbfile = $ENV{CPAN_DIGGER_DBFILE};
    return to_json { error => 'no db configuration' } if not $dbfile;

    my $db = CPAN::Digger::DB->new(dbfile => $dbfile);
    $db->setup;

    my $data;
    if ($what eq 'distribution') {
        $data = $db->get_distros_latest_version($term);
        $_->{type} = 'd' for @$data;
    }
    if ($what eq 'author') {
        $data = $db->get_authors($term);
        $_->{type} = 'a' for @$data;
        foreach my $d (@$data) {
            $d->{name} = decode('utf8', $d->{name});
        }
    }
    return to_json({data => $data, ellapsed_time => time-$t0}, {utf8 => 0});
};


# get '/module/:query' => sub {
    # my $module = params->{query} || '';
    # $module =~ s/[^\w:.*+?-]//g; # sanitize for now
    # return _data({ 'modules.name' => $module });
# };

# get '/m/:query' => sub {
    # my $module = params->{query} || '';
    # $module =~ s/[^\w:.*+?-]//g; # sanitize for now
    # my $results = _fetch_from_db({ 'modules.name' => $module });
# 
    # # TODO: maybe in case of no hit, run the query with regex and find
    # # all the modules (or packages?) that have this string in their name
    # if (not @$results) {
        # template 'error', {
            # no_such_module => 1, 
            # module => $module,
        # };
    # } elsif (@$results == 1) {
        # $module =~ s{::}{/}g;
        # return redirect "/dist/$results->[0]{name}/lib/$module.pm";
    # } else {
        # my $path = $module;
        # $path =~ s{::}{/}g;
        # my @links;
        # foreach my $r (@$results) {
            # push @links, {
                # distro => $r->{name},
                # module => $module,
                # path   => $path,
            # };
        # }
        # template => 'modules', {
            # module => $module,
            # links  => \@links,
        # }
    # }
# 
# 
    # # TODO what if we received several results? 
    # # Should we show a list of links?
# };


# sub _data {
    # my ($params) = @_;
# 
    # my $start_time = time;
# 
    # my $results = _fetch_from_db($params);
# 
    # my $end_time = time;
# 
    # content_type 'text/plain';
# 
    # return to_json({
        # results => $results,
        # ellapsed_time => $end_time - $start_time,
        # }, utf8 => 1, convert_blessed => 1);
# }
# 
# sub _fetch_from_db {
    # my ($params) = @_;
# }
# 

# this part is only needed in the stand alone environment
# if used under Apache, then Apache should be configured
# to handle these static files
get qr{/(syn|src|data)(/.*)?} => sub {
    # TODO this gives a warning in Dancer::Router if we ask for dist only as the
    # capture in the () is an undef
    #my ($path) = splat; 
    #$path ||= '/';
    #$path = "/dist$path";

    my $path = request->path;
    # TODO: how can I add a configuration option to config.yml 
    # to point to a directory relative to the appdir ?
    #return config->{appdir};
    my $full_path = path config->{appdir}, '..', 'digger', $path;
    return "Cannot handle $path as full_path is undef" if not defined $full_path;
    if (-d $full_path) {
        if ($path !~ m{/$}) {
            return redirect request->path . '/';
        }
        if (-e path($full_path, 'index.html')) {
            $full_path = path($full_path, 'index.html');
        } else {
            if (opendir my $dh, $full_path) {
                my (@dirs, @files);
                while (my $thing = readdir $dh) {
                    next if $thing eq '.' or $thing eq '..';
                    if (-d path $full_path, $thing) {
                        push @dirs, $thing;
                    } else {
                        push @files, $thing;
                    }
                }
                return template 'directory', {
                    dirs  => \@dirs,
                    files => \@files,
                };
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

sub _date {
    return POSIX::strftime("%Y %b %d", gmtime shift);
}

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

