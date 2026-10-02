# --
# Kernel/System/MailAccount/POP3SOAuth2.pm
# Copyright (C) 2010-2026 OFORK, https://o-fork.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::MailAccount::POP3SOAuth2;

use strict;
use warnings;

use IO::Socket::SSL;
use Net::POP3;

use parent qw(Kernel::System::MailAccount::POP3);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CommunicationLog',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::OAuth2::MicrosoftClientCredentials',
);

# Use Net::SSLGlue::POP3 on systems with older Net::POP3 modules that cannot handle POP3S.
BEGIN {
    if ( !defined &Net::POP3::starttls ) {
        require Net::SSLGlue::POP3;
    }
}

=head1 NAME

Kernel::System::MailAccount::POP3SOAuth2 - fetch mails from Exchange Online with OAuth2 over POP3

=head1 DESCRIPTION

POP3 over SSL (port 995) with SASL XOAUTH2. The login is the address of the
mailbox; the password of the mail account is not used. The Entra app needs the
application permission POP.AccessAsApp. Fetching itself is inherited from POP3.

Tenant, client ID and client secret are set in the system configuration
(group Core::Email::OAuth2, settings OAuth2::Microsoft::*).

=cut

sub Connect {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Login Host Timeout Debug)) {
        if ( !defined $Param{$_} ) {
            return (
                Successful => 0,
                Message    => "Need $_!",
            );
        }
    }

    my $Type = 'POP3SOAuth2';

    my $OAuth2Object = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftClientCredentials');

    my %Token = $OAuth2Object->AccessTokenGet();
    if ( !$Token{Success} ) {
        return (
            Successful => 0,
            Message    => "$Type: $Token{ErrorMessage}",
        );
    }

    # connect to host, unlike POP3S the server certificate is verified
    my $PopObject = Net::POP3->new(
        $Param{Host},
        Port                => 995,
        Timeout             => $Param{Timeout},
        Debug               => $Param{Debug},
        SSL                 => 1,
        SSL_verify_mode     => IO::Socket::SSL::SSL_VERIFY_PEER(),
        SSL_verifycn_scheme => 'pop3',
        SSL_verifycn_name   => $Param{Host},
    );

    if ( !$PopObject ) {
        return (
            Successful => 0,
            Message    => "$Type: Can't connect to $Param{Host}",
        );
    }

    my $XOAUTH2String = $OAuth2Object->XOAUTH2StringBuild(
        User        => $Param{Login},
        AccessToken => $Token{AccessToken},
    );

    # keep the token out of the Net::POP3 debug output
    my $Debug = $PopObject->debug(0);

    # two steps as in the Microsoft example: AUTH XOAUTH2, "+", string, "+OK"
    my $Success = 0;
    $PopObject->command( 'AUTH', 'XOAUTH2' );
    if ( ( $PopObject->response() // 0 ) == 3 ) {
        $PopObject->command($XOAUTH2String);
        my $Response = $PopObject->response() // 0;

        # a further challenge after a failed login is answered with an empty line
        if ( $Response == 3 ) {
            $PopObject->command('');
            $Response = $PopObject->response() // 0;
        }
        $Success = ( $Response == 2 );
    }

    $PopObject->debug( $Debug // 0 );

    if ( !$Success ) {
        my $Error = $PopObject->message() // '';
        $Error =~ s{ \s+ \z }{}xms;

        $PopObject->quit();
        $OAuth2Object->AccessTokenDelete();

        return (
            Successful => 0,
            Message    => "$Type: XOAUTH2 authentication for mailbox '$Param{Login}' on $Param{Host} failed ($Error). "
                . 'Check that the Entra app has the permission POP.AccessAsApp, that the mailbox has FullAccess '
                . 'for the Exchange service principal (Add-MailboxPermission) and that New-ServicePrincipal used '
                . 'the object ID from "Enterprise applications".',
        );
    }

    # login() returns the number of messages, XOAUTH2 does not
    my ($MessageCount) = $PopObject->popstat();
    if ( !defined $MessageCount ) {
        $PopObject->quit();

        return (
            Successful => 0,
            Message    => "$Type: Can't read the number of messages of mailbox '$Param{Login}' on $Param{Host}.",
        );
    }

    return (
        Successful => 1,
        PopObject  => $PopObject,
        NOM        => $MessageCount || '0E0',
        Type       => $Type,
    );
}

1;
