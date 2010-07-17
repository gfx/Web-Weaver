package Web::Weaver;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.0001';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use LWP::UserAgent;
use Data::Dump qw(dump);

my $agent = sprintf '%s/%s', __PACKAGE__, $VERSION;

sub to_psgi {
    my($self, $request_rewriter) = @_;

    my $ua = LWP::UserAgent->new(agent => $agent);

    return sub {
        my($env) = @_;

        $request_rewriter->($env);

        # re-construct the request URI
        my $uri = sprintf '%s://%s:%s%s',
            $env->{'psgi.url_scheme'},
            $env->{REMOTE_ADDR},
            $env->{SERVER_PORT},
            $env->{REQUEST_URI},
        ;
        # convert PSGI request into HTTP::Request
        my $request = HTTP::Request->new(
            $env->{REQUEST_METHOD},
            $uri,
            # TODO: headers, content
        );

        my $response = $ua->request($request);

        # convert HTTP::Response into PSGI response
        my @headers;
        $response->headers->scan(sub {
            my($key, $val) = @_;
            push @headers, $key => $val;
        });
        return [
            $response->code,
            \@headers,
            [ $response->content ],
        ];
    };
}

1;
__END__

=head1 NAME

Web::Weaver - PSGI proxy server

=head1 VERSION

This document describes Web::Weaver version 0.0001.

=head1 SYNOPSIS

    #!psgi
    use Web::Weaver;

    my $app = Web::Weaver->to_psgi(sub {
        my($env) = @_;
        # rewrite $env
        $env->{REMOTE_ADDR} = MY_APP_REMOTE_ADDR();
        $env->{SERVER_PORT} = MY_APP_SERVER_PORT();
        retur $env;
    });

    return $app; # as a PSGI application

=head1 DESCRIPTION

Web::Weaver is a PSGI application that behaves as a proxy server.

=head1 INTERFACE

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<PSGI>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
