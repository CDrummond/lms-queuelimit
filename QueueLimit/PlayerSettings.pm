package Plugins::QueueLimit::PlayerSettings;

#
# LMS-QueueLimit
#
# Copyright (c) 2020-2021 Craig Drummond <craig.p.drummond@gmail.com>
#
# MIT license.
#

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Strings qw (string);
use Slim::Display::NoDisplay;
use Slim::Display::Display;


my $prefs = preferences('plugin.queuelimit');
my $log   = logger('plugin.queuelimit');

sub name {
    return Slim::Web::HTTP::CSRF->protectName('PLUGIN_QUEUELIMIT');
}

sub needsClient {
    return 1;
}

sub validFor {
    return 1;
}

sub page {
    return Slim::Web::HTTP::CSRF->protectURI('plugins/QueueLimit/settings/player.html');
}

sub prefs {
    my $class = shift;
    my $client = shift;
    return ($prefs->client($client), qw(enabled));
}

sub handler {
    my ($class, $client, $params) = @_;
    $log->debug("QueueLimit->handler() called. " . $client->name());
    if ($params->{'saveSettings'}) {
        $params->{'pref_enabled'} = 0 unless defined $params->{'pref_enabled'};
    }

    return $class->SUPER::handler( $client, $params );
}

1;
