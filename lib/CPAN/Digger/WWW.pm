package CPAN::Digger::WWW;

our $VERSION = '0.01';

use Dancer ':syntax';

use CPAN::Digger::DB;

use Data::Dumper  qw(Dumper);
use Encode        qw(decode);
use File::Basename qw(basename);
use List::Util    qw(max);
use POSIX         ();
use Time::HiRes   qw(time);
#use JSON;

# for development:
# on the real server the index file will be static
# if ($^O =~ m/win32/i) {
    # get '/' => sub {
        # #send_file(path config->{public}, 'index.html');
        # send_file 'index.html';
        # #template 'index';
    # };
# }

#before sub {
    #return { error => 'no db configuration' } if not $dbfile;
#};

#set serializer => 'Mutable';

my $dbx;
sub db {
    if (not $dbx) {
        $dbx = CPAN::Digger::DB->new;
        $dbx->setup;
    }
    return $dbx;

}


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
    

    my $author = db->get_author(uc $pauseid);
    debug(Dumper $author);
    my $distributions = db->get_distros_of(uc $pauseid);
    my $last_upload = max(map {$_->{file_timestamp}} @$distributions);

    foreach my $d (@$distributions) {
        $d->{release} = _date(delete $d->{file_timestamp});
        $d->{distrover} = "$d->{name}-$d->{version}";
        $d->{filename}  = basename($d->{path});
    }
    my %data = (
        name        => decode('utf8', $author->{name} || $author->{asciiname} || ''),
        last_upload => ($last_upload ? _date($last_upload) : 'NA'),
	pauseid     => uc($pauseid),
	lcpauseid   => lc($pauseid),
	email       => $author->{email},
        link_email  => ($author->{email} and $author->{email} ne 'CENSORED' ? 1 : 0),
	homepage    => $author->{homepage},
	homedir     => $author->{homedir},
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

    my $d = db->get_distro_latest($name);
    my $details = db->get_distro_details_by_id($d->{id});
    #debug(Dumper $d);
    #debug(Dumper $details);

    my $author = db->get_author(uc $d->{author});

#debug($d->{file_timestamp});
#debug(_date($d->{file_timestamp}));

    my %meta_data;
    $meta_data{$_} = $details->{"meta_$_"} for qw(abstract version license);

    my %data = (
        name      => $name,
        pauseid   => $d->{author},
        released  => _date($d->{file_timestamp}),
        distvname => "$name-$d->{version}",
        author    => {
            name => decode('utf8', $author->{name}),
        },
        meta_data => \%meta_data,
        ellapsed_time => time-$t0,
    );
    $data{$_} = $d->{$_} for qw(version path);
    $data{$_} = $details->{$_} for qw(has_t test_file has_meta_yml has_meta_json examples min_perl);
    if ($details->{special_files}) {
        $data{special_files}  = [split /,/, $details->{special_files}];
    }
    if ($details->{pods}) {
        $data{modules} = from_json($details->{pods});
    }

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

get '/stats' => sub {

    my %data = (
        unzip_errors => db->count_unzip_errors,
	total_number_of_distributions => db->count_distros,
	distinct_distributions => db->count_distinct_distros,
	has_meta_json => db->count_meta_json,
	has_meta_yaml => db->count_meta_yaml,
	has_no_meta   => db->count_no_meta,
	has_test_file => db->count_test_file,
	has_t_dir     => db->count_t_dir,
	has_xt_dir    => db->count_xt_dir,
	has_no_tests  => db->count_no_tests,
	
	number_of_authors => db->count_authors,

	number_of_modules => db->count_modules,

    );
    template 'stats.tt', \%data;
};

# get '/licenses' => sub {
    # my $data_file = path config->{public}, 'data', 'licenses.json';
    # my $json = eval {from_json slurp($data_file)};
    # template 'licenses', {
        # licenses => $json,
    # };
# };

get '/query' => sub {
    return query();
};

sub query {
    my $data = run_query();
 
    return render_response('query.tt', $data);
}

sub render_response {
    my ($template, $data) = @_;

    my $content_type = request->content_type || params->{content_type} || '';
    if ($content_type =~ /json/) {
       content_type 'text/plain';
       return to_json $data, {utf8 => 0};
    } else {
      return template $template, $data;
    }
}

sub run_query {
    my $term = params->{query} || '';
    my $what = params->{what} || '';
    my $t0 = time;

    if ($what !~ /^(distribution|author)$/) {
        return { error => "Invalid search type: '$what'" };
    }

    $term =~ s/[^\w:.*+?-]//g; # sanitize for now
    #my $data = { 'abc' => $term };


    my $data;
    if ($what eq 'distribution') {
        $data = db->get_distros_latest_version($term);
        $_->{distribution} = 1 for @$data;
    }
    if ($what eq 'author') {
        $data = db->get_authors($term);
        $_->{author} = 1 for @$data;
        foreach my $d (@$data) {
            $d->{name} = decode('utf8', $d->{name});
        }
    }
    return {data => $data, ellapsed_time => time-$t0};
}

get '/m/:module' => sub {
    my $name = params->{module} || '';
    $name =~ s/[^\w:.*+?-]//g; # sanitize for now
    
    my $module = db->get_module_by_name($name);
    if (not $module ){
        return template 'error', {
            no_such_module => 1, 
            module => $name,
        };
    }

    my $distro = db->get_distro_by_id($module->{distro});
    return "Wow, could not find corresponding distribution" if not $distro;

    $name =~ s{::}{/}g;
    foreach my $ext (qw(pm pod)) {
        my $path = "/dist/$distro->{name}/lib/$name.$ext";
        my $full_path = path config->{appdir}, '..', 'digger', $path;
        return redirect $path if -e $full_path;
    }

    return template 'error', {
         no_pod_found => 1, 
         module => $name,
    };
    
    
    #my $distro_details = db->get_distro_details_by_id($distro->{id});
    #return to_json {module => $module, distro => $distro, details => $distro_details};
    #return $distro_details->{pods};
    
    # # TODO: maybe in case of no hit, run the query with regex and find
    # # all the modules (or packages?) that have this string in their name
    
    # TODO what if we received several results? 
    # Should we show a list of links?
};


# this part is only needed in the stand alone environment
# if used under Apache, then Apache should be configured
# to handle these static files
get qr{/(syn|src|dist)(/.*)?} => sub {
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
    if (not defined $full_path) {
        return template 'error', {
            cannot_handle => 1, 
        };
    }


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
                return slurp($full_path);
            } else {
                # get the name of the distro
                # using that get the author, the latest version
                my %data = (
                    html => scalar slurp($full_path),
                );

                my $dist_name;
                my $sub_path;
                if ($path =~ m{^/dist/([^/]+)/(.*)}) {
                    $dist_name = $1;
                    $sub_path  = $2;
                    ($data{syn} = $path) =~ s{^/dist}{/syn};
                }
                if ($path =~ m{^/syn/([^/]+)/(.*)}) {
                    $dist_name = $1;
                    $sub_path  = $2;
                    ($data{pod} = $path) =~ s{^/syn}{/dist};
                }
                #if ($path =~ m{^/src
                if ($dist_name) {
                    my $d = db->get_distro_latest($dist_name);
                    #my $details = db->get_distro_details_by_id($d->{id});
                    $data{src} = "/src/$d->{author}/$dist_name-$d->{version}/$sub_path";
                    $data{dist} = $dist_name;
                    $data{title} = $dist_name;
                }

                return template 'file', \%data;
            }
            
        } else {
            return "This file was empty";
        }
    }

    return template 'error', {
         cannot_handle => 1, 
    };
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

