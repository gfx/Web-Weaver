package Web::Weaver::LWP;
use strict;
use warnings;

use parent qw(Web::Weaver LWP::UserAgent);

sub new {
    my($self, %args) = @_;
    $args{agent} ||= $self->default_user_agent;
    return $self->SUPER::new(%args);
}

sub request {
    my($self, $env) = @_;

    my $uri = $self->build_uri($env);
    # convert PSGI request into HTTP::Request
    my $request = HTTP::Request->new(
        $env->{REQUEST_METHOD},
        $uri,
        # TODO: headers, content
    );

    my $response = $self->SUPER::request($request);

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
}

1;

