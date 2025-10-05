# --
# Kernel/System/Console/Command/Admin/Config/ListInvalid.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: ListInvalid.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Config::ListInvalid;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::SysConfig',
    'Kernel::System::YAML',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('List invalid system configuration.');
    $Self->AddOption(
        Name        => 'export-to-path',
        Description => "Export list to a YAML file instead.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my @InvalidSettings = $SysConfigObject->ConfigurationInvalidList(
        Undeployed => 1,
        NoCache    => 1,
    );

    if ( !scalar @InvalidSettings ) {
        $Self->Print("<green>All settings are valid.</green>\n");
        return $Self->ExitCodeOk();
    }

    my $ExportToPath = $Self->GetOption('export-to-path');

    if ($ExportToPath) {
        $Self->Print("<red>Settings with invalid values have been found.</red>\n");
    }
    else {
        $Self->Print("<red>The following settings have an invalid value:</red>\n");
    }

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my %EffectiveValues;
    SETTINGNAME:
    for my $SettingName (@InvalidSettings) {
        my %Setting = $SysConfigObject->SettingGet(
            Name => $SettingName,
        );

        if ($ExportToPath) {
            $EffectiveValues{$SettingName} = $Setting{EffectiveValue};
            next SETTINGNAME;
        }

        my $EffectiveValue = $MainObject->Dump(
            $Setting{EffectiveValue},
        );

        $EffectiveValue =~ s/\$VAR1 = //;

        $Self->Print("    $SettingName = $EffectiveValue");
    }

    if ($ExportToPath) {

        my $EffectiveValuesYAML = $Kernel::OM->Get('Kernel::System::YAML')->Dump(
            Data => \%EffectiveValues,
        );

        # Write settings to a file.
        my $FileLocation = $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
            Location => $ExportToPath,
            Content  => \$EffectiveValuesYAML,
            Mode     => 'utf8',
        );

        # Check if target file exists.
        if ( !$FileLocation ) {
            $Self->PrintError("Could not write file $ExportToPath!\nFail.\n");
            return $Self->ExitCodeError();
        }

        $Self->Print("<green>Done.</green>\n");
    }

    return $Self->ExitCodeError();
}

1;
