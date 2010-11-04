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
foreach my $page (qw(news faq licenses)) {
    get "/$page" => sub {
        template $page;
    }
};


get '/dancer' => sub {
    content_type 'text/plain';
    to_dumper config;
};

true;
