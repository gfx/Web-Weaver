package Web::Weaver;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.0001';

#use XSLoader;
#XSLoader::load(__PACKAGE__, $VERSION);

sub default_user_agent {
    return sprintf '%s/%s', __PACKAGE__, $VERSION;
}

sub to_app{
    my($class, $request_rewriter) = @_;

    my $self = ref($class) ? $class : $class->new();

    return sub {
        my($env) = @_;
        $request_rewriter->($env);
        return $self->request($env);
   };
}

sub build_uri {
    my($self, $env) = @_;
    return sprintf '%s://%s:%s%s',
        $env->{'psgi.url_scheme'},
        $env->{REMOTE_ADDR},
        $env->{SERVER_PORT},
        $env->{REQUEST_URI},
    ;
}

1;
__END__

=head1 NAME

Web::Weaver - PSGI proxy server

=head1 VERSION

This document describes Web::Weaver version 0.0001.

=head1 SYNOPSIS

    #!psgi
    use Web::Weaver::Curl; # or ::LWP

    my $app = Web::Weaver::Curl->to_app(sub {
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
