#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use ok "Catalyst::Plugin::Session::DynamicExpiry";

{
    package MockApp::Session;

    sub calculate_extended_session_expires {
        42
    }

    sub _session { $_[0]{_session} ||= {} }
    sub session { $_[0]->_session }

    package MockApp;

    sub new { bless {}, shift }

    use base qw/
        Catalyst::Plugin::Session::DynamicExpiry
        MockApp::Session
    /;

    sub debug { 0 }
}

my $c = MockApp->new;

can_ok( $c, "calculate_extended_session_expires" );

is( $c->calculate_extended_session_expires, 42, "expiry time not overridden" );

$c->session_time_to_live( 100 );

cmp_ok( abs( $c->calculate_extended_session_expires - ( time + 100 ) ), "<=", 1, "expiry time overridden if ttl was set by accessor" );

$c->_save_session;

is( $c->session->{__time_to_live}, 100, "ttl stored in session" );

$c->session_time_to_live( undef );

is( $c->session->{__time_to_live}, undef, "ttl cleared from the session when the accessor was used" );

$c->session->{__time_to_live} = 10;

cmp_ok( abs( $c->calculate_extended_session_expires - ( time + 10 ) ), "<=", 1, "expiry time overridden if special key exists, and to the right value" );

