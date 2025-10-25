# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/UI/AgentSkinUsage.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: AgentSkinUsage.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::UI::AgentSkinUsage;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::User',
);

sub GetDisplayPath {
    return Translatable('OFORK') . '/' . Translatable('UI - Agent Skin Usage');
}

sub Run {
    my $Self = shift;

    # First get count of all agents. We avoid checking for Valid for performance reasons, as this
    #   would require fetching of all agent data to check for the preferences.
    my $DBObject              = $Kernel::OM->Get('Kernel::System::DB');
    my $AgentsWithDefaultSkin = 1;
    $DBObject->Prepare( SQL => 'SELECT count(*) FROM users' );
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $AgentsWithDefaultSkin = $Row[0];
    }

    my $DefaultSkin = $Kernel::OM->Get('Kernel::Config')->Get('Loader::Agent::DefaultSelectedSkin');

    my %SkinPreferences = $Kernel::OM->Get('Kernel::System::User')->SearchPreferences(
        Key => 'UserSkin',
    );

    my %SkinUsage;

    # Check how many agents have a skin preference configured, assume default skin for the rest.
    for my $UserID ( sort keys %SkinPreferences ) {
        $SkinUsage{ $SkinPreferences{$UserID} }++;
        $AgentsWithDefaultSkin--;
    }
    $SkinUsage{$DefaultSkin} += $AgentsWithDefaultSkin;

    for my $Skin ( sort keys %SkinUsage ) {

        $Self->AddResultInformation(
            Identifier => $Skin,
            Label      => $Skin,
            Value      => $SkinUsage{$Skin},
        );
    }

    return $Self->GetResults();
}

1;
