package Plugins::QueueLimit::Plugin;

#
# LMS-QueueLimit
#
# Copyright (c) 2020 Craig Drummond <craig.p.drummond@gmail.com>
#
# MIT license.
#

use strict;

use base qw(Slim::Plugin::Base);

use Slim::Utils::Log;
use Slim::Utils::Misc;
use Slim::Utils::Prefs;
use Slim::Utils::Strings qw(string);

use Plugins::QueueLimit::PlayerSettings;

my $QUEUE_CHECK_SIZE = 60;
my $QUEUE_HISTORY_SIZE = 40;

my $log = Slim::Utils::Log->addLogCategory({
    'category' => 'plugin.queuelimit',
    'defaultLevel' => 'ERROR',
    'description' => 'PLUGIN_QUEUELIMIT'
});

my $prefs = preferences('plugin.queuelimit');
my $serverPrefs = preferences('server');

sub getDisplayName {
    return 'PLUGIN_QUEUELIMIT';
}

my @browseMenuChoices = (
    'PLUGIN_QUEUELIMIT_ENABLE',
);
my %menuSelection;

my %defaults = (
    'enabled' => 0,
);

sub initPlugin {
    my $class = shift;
    $class->SUPER::initPlugin(@_);
    Plugins::QueueLimit::PlayerSettings->new();
    Slim::Control::Request::subscribe(\&QueueLimit_newSongCallback, [['playlist'], ['newsong']]);
}

sub shutdownPlugin {
    Slim::Control::Request::unsubscribe(\&QueueLimit_newSongCallback);
}

sub QueueLimit_newSongCallback {
    my $request = shift;
    my $client = $request->client();
    return unless defined $client;

    my $cPrefs = $prefs->client($client);
    return unless ($cPrefs->get('enabled')) && !(Slim::Player::Sync::isSlave($client)) && $request->getRequest(0) eq 'playlist';

    my $index = Slim::Player::Source::playingSongIndex($client);
    if ($index>=$QUEUE_CHECK_SIZE) {
        Slim::Player::Playlist::removeTrack($client, 0, $index-$QUEUE_HISTORY_SIZE);
        Slim::Player::Playlist::refreshPlaylist($client);
    }
}

sub lines {
    my $client = shift;
    my ($line1, $line2, $overlay2);
    my $flag;

    $line1 = $client->string('PLUGIN_QUEUELIMIT') . " (" . ($menuSelection{$client}+1) . " " . $client->string('OF') . " " . ($#browseMenuChoices + 1) . ")";
    $line2 = $client->string($browseMenuChoices[$menuSelection{$client}]);

    # Add a checkbox
    if ($browseMenuChoices[$menuSelection{$client}] eq 'PLUGIN_QUEUELIMIT_ENABLE') {
        $flag  = $prefs->client($client)->get('enabled');
        $overlay2 = Slim::Buttons::Common::checkBoxOverlay($client, $flag);
    }

    return {
        'line'    => [ $line1, $line2],
        'overlay' => [undef, $overlay2],
    };
}

my %functions = (
    'up' => sub  {
        my $client = shift;
        my $newposition = Slim::Buttons::Common::scroll($client, -1, ($#browseMenuChoices + 1), $menuSelection{$client});
        $menuSelection{$client} =$newposition;
        $client->update();
    },
    'down' => sub  {
        my $client = shift;
        my $newposition = Slim::Buttons::Common::scroll($client, +1, ($#browseMenuChoices + 1), $menuSelection{$client});
        $menuSelection{$client} =$newposition;
        $client->update();
    },
    'right' => sub {
        my $client = shift;
        my $cPrefs = $prefs->client($client);
        my $selection = $menuSelection{$client};

        if ($browseMenuChoices[$selection] eq 'PLUGIN_QUEUELIMIT_ENABLE') {
            my $enabled = $cPrefs->get('enabled') || 0;
            $client->showBriefly({ 'line1' => string('PLUGIN_QUEUELIMIT'), 
                                   'line2' => string($enabled ? 'PLUGIN_QUEUELIMIT_DISABLING' : 'PLUGIN_QUEUELIMIT_ENABLING') });
            $cPrefs->set('enabled', ($enabled ? 0 : 1));
        }
    },
    'left' => sub {
        my $client = shift;
        Slim::Buttons::Common::popModeRight($client);
    },
);

sub setDefaults {
    my $client = shift;
    my $force = shift;
    my $clientPrefs = $prefs->client($client);
    $log->debug("[" . $client->id . "] Checking defaults for " . $client->name() . " Forcing: " . $force);
    foreach my $key (keys %defaults) {
        if (!defined($clientPrefs->get($key)) || $force) {
            $log->debug("Setting default value for $key: " . $defaults{$key});
            $clientPrefs->set($key, $defaults{$key});
        }
    }
}

sub getFunctions { return \%functions;}
 
1;

