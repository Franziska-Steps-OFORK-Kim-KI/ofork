# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/SessionConfigSettings.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: SessionConfigSettings.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::SessionConfigSettings;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub GetDisplayPath {
    return Translatable('OFORK') . '/' . Translatable('Session Config Settings');
}

sub Run {
    my $Self = shift;

    my @Settings = qw(
        SessionMaxTime
        SessionMaxIdleTime
        AgentSessionLimitPriorWarning
        AgentSessionLimit
        AgentSessionPerUserLimit
        CustomerSessionLimit
        CustomerSessionPerUserLimit
    );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    for my $Setting (@Settings) {

        my $ConfigValue = $ConfigObject->Get($Setting);

        my $Message;

        $Self->AddResultInformation(
            Identifier => $Setting,
            Label      => $Setting,
            Value      => $ConfigValue,
        );
    }

    return $Self->GetResults();
}

1;
