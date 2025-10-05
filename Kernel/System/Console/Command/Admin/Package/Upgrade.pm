# --
# Kernel/System/Console/Command/Admin/Package/Upgrade.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Upgrade.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Package::Upgrade;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand Kernel::System::Console::Command::Admin::Package::List);

our @ObjectDependencies = (
    'Kernel::System::Package',
    'Kernel::Config',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Upgrade an OFORK package.');
    $Self->AddOption(
        Name        => 'force',
        Description => 'Force package upgrade even if validation fails.',
        Required    => 0,
        HasValue    => 0,
    );
    $Self->AddArgument(
        Name => 'location',
        Description =>
            "Specify a file path, a remote repository (https://ftp.o-fork.de/AddOns/:Package-1.0.0.opm) or just any online repository (online:Package).",
        Required   => 1,
        ValueRegex => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Upgrading package...</yellow>\n");

    my $FileString = $Self->_PackageContentGet( Location => $Self->GetArgument('location') );
    return $Self->ExitCodeError() if !$FileString;

    # parse package
    my %Structure = $Kernel::OM->Get('Kernel::System::Package')->PackageParse(
        String => $FileString,
    );

    # intro screen
    if ( $Structure{IntroUpgrade} ) {
        my %Data = $Self->_PackageMetadataGet(
            Tag                  => $Structure{IntroUpgrade},
            AttributeFilterKey   => 'Type',
            AttributeFilterValue => 'pre',
        );
        if ( $Data{Description} ) {
            print "+----------------------------------------------------------------------------+\n";
            print "| $Structure{Name}->{Content}-$Structure{Version}->{Content}\n";
            print "$Data{Title}";
            print "$Data{Description}";
            print "+----------------------------------------------------------------------------+\n";
        }
    }

    # upgrade
    my $Success = $Kernel::OM->Get('Kernel::System::Package')->PackageUpgrade(
        String => $FileString,
        Force  => $Self->GetOption('force'),
    );

    if ( !$Success ) {
        $Self->PrintError("Package upgrade failed.");
        return $Self->ExitCodeError();
    }

    # intro screen
    if ( $Structure{IntroUpgrade} ) {
        my %Data = $Self->_PackageMetadataGet(
            Tag                  => $Structure{IntroUpgrade},
            AttributeFilterKey   => 'Type',
            AttributeFilterValue => 'post',
        );
        if ( $Data{Description} ) {
            print "+----------------------------------------------------------------------------+\n";
            print "| $Structure{Name}->{Content}-$Structure{Version}->{Content}\n";
            print "$Data{Title}";
            print "$Data{Description}";
            print "+----------------------------------------------------------------------------+\n";
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
