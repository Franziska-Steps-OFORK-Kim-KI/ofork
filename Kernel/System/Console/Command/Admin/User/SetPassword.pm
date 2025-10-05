# --
# Kernel/System/Console/Command/Admin/User/SetPassword.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: SetPassword.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::User::SetPassword;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::User',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Update the password for an agent.');
    $Self->AddArgument(
        Name        => 'user',
        Description => "Specify the user login of the agent to be updated.",
        Required    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddArgument(
        Name        => 'password',
        Description => "Set a new password for the agent (a password will be generated otherwise).",
        Required    => 0,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Login = $Self->GetArgument('user');

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');
    my %UserList   = $UserObject->UserSearch(
        UserLogin => $Login,
    );

    if ( !scalar %UserList ) {
        $Self->PrintError("No user found with login '$Login'!\n");
        return $Self->ExitCodeError();
    }

    # if no password has been provided, generate one
    my $Password = $Self->GetArgument('password');
    if ( !$Password ) {
        $Password = $UserObject->GenerateRandomPassword( Size => 12 );
        $Self->Print("<yellow>Generated password '$Password'.</yellow>\n");
    }

    my $Result = $UserObject->SetPassword(
        UserLogin => $Login,
        PW        => $Password,
    );

    if ( !$Result ) {
        $Self->PrintError("Failed to set password!\n");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Successfully set password for user '$Login'.</green>\n");
    return $Self->ExitCodeOk();
}

1;
