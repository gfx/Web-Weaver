package Web::Weaver::TestSuite;

use strict;
use warnings;

use parent qw(Test::Builder::Module);
our @EXPORT = qw(test_suite);

use Test::More;

use HTTP::Server::PSGI;
use Plack::Test;
use Plack::Request;

use Test::TCP;
use Data::Dumper;

sub test_suite {
    my($module) = @_;

    test_tcp(
        client => sub {
            my($port) = @_;
            test_web_weaver($port, $module);
        },
        server => \&_psgi_echo_server,
    );
}

sub test_web_weaver {
    my($port, $module) = @_;

    my $app = $module->new(timeout => 1)->to_app();

    test_psgi(
        # proxy server
        app => sub {
            my($env) = @_;
            $env->{SERVER_PORT} = $port;
            return $app->($env);
        },

        # client 
        client => sub {
            my $cb = shift;

            note 'normal request';
            my $req = HTTP::Request->new(GET => "http://localhost/hello?xxx");
            my $res = $cb->($req);

            ok $res;
            ok $res->is_success, '... is success';
            is $res->code, 200, 'status: 200';
            is $res->content_type, 'application/x-perl',
                '... with correct content_type';
            
            #note $res->content;
            my $env = eval 'no strict qw(vars refs); ' . $res->content;
            diag "Eval error: " . $@ if $@;
            is $env->{SERVER_PORT}, $port, ' ... correct port';
            is $env->{REQUEST_URI}, "/hello?xxx", '... correct uri';
            like $env->{HTTP_USER_AGENT}, qr/Web::Weaver/, '... correct user ageent';

            note 'request not found';
            $req = HTTP::Request->new(GET => "http://localhost/hello?not_found=1");
            $res = $cb->($req);

            ok !$res->is_success, 'not found';
            is $res->code, 404, 'status: 404';
            is $res->content_type, 'text/plain';
            is $res->content, 'not_found';

            note 'request timeout';
            my $t0 = time();
            $req = HTTP::Request->new(GET => "http://localhost/hello?sleep=10");
            $res = $cb->($req);
            my $t1 = time();

            ok !$res->is_success, 'timeout';
            is $res->code, 500, 'status: 500';
            cmp_ok $t1 - $t0, '<', 2;
        },
    );
}

# target server, which simply returns the request env

sub _psgi_echo_server {
    my($port) = @_;

    my $server = HTTP::Server::PSGI->new(
        host => '127.0.0.1',
        port => $port,
    );

    $server->run(sub {
        my($env) = @_;
        my $req = Plack::Request->new($env);
        if($req->param('not_found')) {
            return [
                404,
                ['Content-Type' => 'text/plain'],
                ['not_found'],
            ];
        }
        elsif(my $t = $req->param('sleep')) {
            sleep $t;
        }
        
        return [
            200,
            [ 'Content-Type' => 'application/x-perl' ],
            [ Dumper($env) ], # return the request as is
        ];
    });
};

1;
