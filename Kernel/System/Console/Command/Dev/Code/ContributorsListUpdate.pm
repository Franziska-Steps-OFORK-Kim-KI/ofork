# --
# Kernel/System/Console/Command/Dev/Code/ContributorsListUpdate.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: ContributorsListUpdate.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Dev::Code::ContributorsListUpdate;

use strict;
use warnings;

use IO::File;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Update the list of contributors based on git commit information.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    chdir $Kernel::OM->Get('Kernel::Config')->Get('Home');

    my @Lines = qx{git log --format="%aN <%aE>"};
    my %Seen;
    map { $Seen{$_}++ } @Lines;

    my $FileHandle = IO::File->new( 'AUTHORS.md', 'w' );
    $FileHandle->print("The following persons contributed to OFORK:\n\n");

    AUTHOR:
    for my $Author ( sort keys %Seen ) {
        chomp $Author;
        if ( $Author =~ m/^[^<>]+ \s <>\s?$/smx ) {
            $Self->Print("<yellow>Could not find Author $Author, skipping.</yellow>\n");
            next AUTHOR;
        }
        $FileHandle->print("* $Author\n");
    }

    $FileHandle->close();

    return $Self->ExitCodeOk();
}

1;
