# --
# Kernel/System/Console/Command/Admin/Group/Add.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Add.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Group::Add;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Group'
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Create a new group.');
    $Self->AddOption(
        Name        => 'name',
        Description => "Name of the new group.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'comment',
        Description => "Comment for the new group.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Creating a new group...</yellow>\n");

    my $Success = $Kernel::OM->Get('Kernel::System::Group')->GroupAdd(
        UserID  => 1,
        ValidID => 1,
        Comment => $Self->GetOption('comment'),
        Name    => $Self->GetOption('name'),
    );

    # error handling
    if ( !$Success ) {
        $Self->PrintError("Can't create group.\n");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
