package Web::Weaver::Curl;
use strict;
use warnings;

use parent qw(Web::Weaver);

use Carp ();
use WWW::Curl::Easy;
use HTTP::Response::Parser qw(parse_http_response);

use Data::Dump qw(dump);

sub new {
    my($class, %args) = @_;
    
    my $agent   = delete $args{agent};
    my $timeout = delete $args{timeout};
    if(%args) {
        Carp::croak("Unknown options: " . join ", ", sort keys %args);
    }

    my $curl = WWW::Curl::Easy->new();
    $curl->setopt(CURLOPT_HEADER, 0);

    $curl->setopt(CURLOPT_USERAGENT,
        $agent || $class->default_user_agent);

    $curl->setopt(CURLOPT_TIMEOUT,   $timeout) if defined $timeout;

    return bless { curl => $curl }, $class;
}

sub request {
    my($self, $env) = @_;

    my $curl = $self->{curl};

    my $uri = $self->build_uri($env);

    $curl->setopt(CURLOPT_URL, $uri);

    my $header = '';
    open my $header_fh, '>', \$header;
    $curl->setopt(CURLOPT_WRITEHEADER, \$header_fh);

    my $body = '';
    open my $body_fh, '>', \$body;
    $curl->setopt(CURLOPT_WRITEDATA, \$body_fh);

    my $ret = $curl->perform();

    my %res;
    parse_http_response($header, \%res);
    return [$res{_rc}, [%{$res{_headers}}], [$body]];
}

1;

