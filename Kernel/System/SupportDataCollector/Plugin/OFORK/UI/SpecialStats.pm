# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/UI/SpecialStats.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: SpecialStats.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::UI::SpecialStats;

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
    return Translatable('OFORK') . '/' . Translatable('UI - Special Statistics');
}

sub Run {
    my $Self = shift;

    my %PreferenceMap = (
        UserNavBarItemsOrder         => Translatable('Agents using custom main menu ordering'),
        AdminNavigationBarFavourites => Translatable('Agents using favourites for the admin overview'),
    );

    for my $Preference ( sort keys %PreferenceMap ) {

        my %FoundPreferences = $Kernel::OM->Get('Kernel::System::User')->SearchPreferences(
            Key => $Preference,
        );

        $Self->AddResultInformation(
            Identifier => $Preference,
            Label      => $PreferenceMap{$Preference},
            Value      => scalar keys %FoundPreferences,
        );
    }

    return $Self->GetResults();
}

1;
