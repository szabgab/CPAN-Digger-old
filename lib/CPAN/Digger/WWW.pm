package CPAN::Digger::WWW;
use Dancer ':syntax';

our $VERSION = '0.1';

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

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die;
    local $/ = undef;
    <$fh>;
}

true;
