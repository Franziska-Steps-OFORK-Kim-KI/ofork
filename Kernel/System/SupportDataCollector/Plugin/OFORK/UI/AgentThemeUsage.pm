# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/UI/AgentThemeUsage.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: AgentThemeUsage.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::UI::AgentThemeUsage;

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
    return Translatable('OFORK') . '/' . Translatable('UI - Agent Theme Usage');
}

sub Run {
    my $Self = shift;

    # First get count of all agents. We avoid checking for Valid for performance reasons, as this
    #   would require fetching of all agent data to check for the preferences.
    my $DBObject               = $Kernel::OM->Get('Kernel::System::DB');
    my $AgentsWithDefaultTheme = 1;
    $DBObject->Prepare( SQL => 'SELECT count(*) FROM users' );
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $AgentsWithDefaultTheme = $Row[0];
    }

    my $DefaultThem = $Kernel::OM->Get('Kernel::Config')->Get('DefaultTheme');

    my %ThemePreferences = $Kernel::OM->Get('Kernel::System::User')->SearchPreferences(
        Key => 'UserTheme',
    );

    my %ThemeUsage;

    # Check how many agents have a theme preference configured, assume default theme for the rest.
    for my $UserID ( sort keys %ThemePreferences ) {
        $ThemeUsage{ $ThemePreferences{$UserID} }++;
        $AgentsWithDefaultTheme--;
    }
    $ThemeUsage{$DefaultThem} += $AgentsWithDefaultTheme;

    for my $Theme ( sort keys %ThemeUsage ) {

        $Self->AddResultInformation(
            Identifier => $Theme,
            Label      => $Theme,
            Value      => $ThemeUsage{$Theme},
        );
    }

    return $Self->GetResults();
}

1;
