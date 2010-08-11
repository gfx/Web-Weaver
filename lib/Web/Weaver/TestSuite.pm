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
    test_psgi(
        # proxy server
        app => $module->to_psgi(sub {
            my($env) = @_;
            $env->{SERVER_PORT} = $port;
        }),

        # client 
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => "http://localhost/hello?xxx");
            my $res = $cb->($req);

            ok $res->is_success;
            is $res->content_type, 'application/x-perl';
            
            #note $res->content;
            my $env = eval 'no strict qw(vars refs); ' . $res->content;
            diag "Eval error: " . $@ if $@;
            is $env->{SERVER_PORT}, $port;
            is $env->{REQUEST_URI}, "/hello?xxx";
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
                ['Content-Type' => 'text/html'],
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
