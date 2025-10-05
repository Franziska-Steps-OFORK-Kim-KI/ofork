# --
# Kernel/System/Console/Command/Maint/Database/PasswordCrypt.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: PasswordCrypt.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::Database::PasswordCrypt;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Make a database password unreadable for inclusion in Kernel/Config.pm.');
    $Self->AddArgument(
        Name        => 'password',
        Description => "The database password to be encrypted.",
        Required    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Password = $Self->GetArgument('password');
    chomp $Password;
    my $CryptedString = $Kernel::OM->Get('Kernel::System::DB')->_Encrypt($Password);

    $Self->Print(
        "<red>Please note that this just makes the password unreadable but is not a secure form of encryption.</red>\n"
    );
    $Self->Print("<green>Crypted password: </green>{$CryptedString}\n");

    return $Self->ExitCodeOk();
}

1;
