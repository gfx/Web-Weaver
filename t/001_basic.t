#!perl -w

use strict;
use Test::More;

use Web::Weaver;
use HTTP::Server::PSGI;
use Plack::Test;
use Test::TCP;
use Data::Dumper;

test_tcp
client => sub {
    my($port) = @_;
    test_psgi

    # proxy server
    app => Web::Weaver->to_psgi(sub {
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

        my $env = eval 'no strict qw(vars refs); ' . $res->content;
        diag $@ if $@;
        is $env->{SERVER_PORT}, $port;
        is $env->{REQUEST_URI}, "/hello?xxx";
    },
    ;
},

# target server, which simply returns the request env
server => sub {
    my($port) = @_;

    my $server = HTTP::Server::PSGI->new(
        host => '127.0.0.1',
        port => $port,
    );

    $server->run(sub {
        my($env) = @_;
        return [
            200,
            [ 'Content-Type' => 'application/x-perl' ],
            [ Dumper($env) ], # return the request as is
        ];
    });
};


done_testing;
