# --
# Kernel/System/Console/Command/Maint/GenericInterface/DebugLog/Cleanup.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Cleanup.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::GenericInterface::DebugLog::Cleanup;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::GenericInterface::DebugLog',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Delete Generic Interface debug log entries.');

    $Self->AddOption(
        Name        => 'created-before-days',
        Description => "Remove debug log entries created more than ... days ago.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    if ( $Self->GetOption('created-before-days') eq '0' ) {
        die "created-before-days must be greater than 0\n";
    }
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Deleting Generic Interface debug log entries...</yellow>\n");

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    my $Success = $DateTimeObject->Subtract(
        Days => $Self->GetOption('created-before-days'),
    );

    $Success = $Kernel::OM->Get('Kernel::System::GenericInterface::DebugLog')->LogCleanup(
        CreatedAtOrBefore => $DateTimeObject->ToString(),
    );

    if ( !$Success ) {
        $Self->Print("<green>Fail.</green>\n");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
