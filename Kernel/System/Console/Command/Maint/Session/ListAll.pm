# --
# Kernel/System/Console/Command/Maint/Session/ListAll.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: ListAll.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::Session::ListAll;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::AuthSession',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('List all sessions.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Listing all sessions...</yellow>\n");

    for my $SessionID ( $Kernel::OM->Get('Kernel::System::AuthSession')->GetAllSessionIDs() ) {
        $Self->Print("  $SessionID\n");
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
