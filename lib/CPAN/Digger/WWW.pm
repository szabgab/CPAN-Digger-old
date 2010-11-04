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

get '/m/:query' => sub {
    my $module = params->{query} || '';
    $module =~ s/[^\w:.*+?-]//g; # sanitize for now
    return _data({ 'modules.name' => $module });
};

sub _data {
    my ($params) = @_;

    my $start_time = time;

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

    my $end_time = time;

    content_type 'text/plain';

    return to_json({
        results => \@results,
        ellapsed_time => $end_time - $start_time,
        }, utf8 => 1, convert_blessed => 1);
}


sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die;
    local $/ = undef;
    <$fh>;
}

true;
