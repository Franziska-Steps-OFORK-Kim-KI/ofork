# --
# Kernel/System/Console/Command/Maint/SupportData/CollectAsynchronous.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: CollectAsynchronous.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::SupportData::CollectAsynchronous;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::SupportDataCollector',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Collect certain support data asynchronously.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Collecting asynchronous support data...</yellow>\n");

    my %Result = $Kernel::OM->Get('Kernel::System::SupportDataCollector')->CollectAsynchronous();

    if ( !$Result{Success} ) {
        $Self->PrintError("Asynchronous data collection was not successful.");
        $Self->PrintError("$Result{ErrorMessage}");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
