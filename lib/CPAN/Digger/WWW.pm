package CPAN::Digger::WWW;
use Dancer ':syntax';

our $VERSION = '0.1';

use CPAN::Digger::DB;
#use autodie;
#use Time::HiRes           qw(time);

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
    my $result = CPAN::Digger::DB->db->distro->find({ 'meta.license' => $license });
    return _data($result);
};

get '/q/:query' => sub {
    my $term = params->{query} || '';
    $term =~ s/[^\w:.*+?-]//g; # sanitize for now
    my $result = CPAN::Digger::DB->db->distro->find({ 'name' => qr/$term/i });
    return _data($result);
};

get '/m/:query' => sub {
    my $m = params->{query} || '';
    $m =~ s/[^\w:.*+?-]//g; # sanitize for now
    my $result = CPAN::Digger::DB->db->distro->find({ 'modules.name' => $m });
    return _data($result);
};

# my $start_time = time;
# 
# } else {
        # $data{not_term_found} = 1;
        # $tt->process('result.tt', \%data) or die $tt->error;
        # return;
# }
# 
#
sub _data {
    my ($result) = @_;

    my @results;
    my $count = 0;
    while (my $d = $result->next) {
        $count++;
        delete $d->{_id};
        push @results, $d;
    }
    content_type 'text/plain';

    return to_json({results => \@results}, utf8 => 1, convert_blessed => 1);
#    return to_dumper {results => \@results};
}

# if (not $count) {
        # $data{not_found} = 1;
# }
# 
# my $end_time = time;
# $data{ellapsed_time} = $end_time - $start_time;


sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die;
    local $/ = undef;
    <$fh>;
}

true;
