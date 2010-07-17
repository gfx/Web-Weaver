#!perl -w
use strict;
use Test::More;
use Test::TCP;
use IO::Socket::INET;

use HTTP::Server::PSGI;

test_tcp
    client => sub {
        my($port) = @_;

        my $sock = IO::Socket::INET->new(
            PeerPort => $port,
            PeerAddr => '127.0.0.1',
            #Proto    => 'tcp'
        ) or die "Cannot open client socket: $!";

        print $sock "GET / HTTP/1.0\n\n";

        diag <$sock>;
    },
    server => sub {
        my($port) = @_;

        my $server = HTTP::Server::PSGI->new( port => $port );

        $server->run(sub {
            return [ 200, ['Content-Type' => 'text/plain'], ['Hello, world!']];
        });
    },
;

pass;

done_testing;
