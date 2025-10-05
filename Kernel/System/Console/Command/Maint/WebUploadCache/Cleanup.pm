# --
# Kernel/System/Console/Command/Maint/WebUploadCache/Cleanup.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Cleanup.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::WebUploadCache::Cleanup;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Web::UploadCache',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Cleanup the upload cache.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Cleaning up the upload cache files...</yellow>\n");

    my @DeletedFiles = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCleanUp();
    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
