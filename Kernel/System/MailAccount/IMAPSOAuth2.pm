# --
# Kernel/System/MailAccount/IMAPSOAuth2.pm
# Copyright (C) 2010-2026 OFORK, https://o-fork.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::MailAccount::IMAPSOAuth2;

use strict;
use warnings;

use IO::Socket::SSL;
use Mail::IMAPClient;

use parent qw(Kernel::System::MailAccount::IMAPTLS);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CommunicationLog',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::OAuth2::MicrosoftClientCredentials',
);

=head1 NAME

Kernel::System::MailAccount::IMAPSOAuth2 - fetch mails from Exchange Online with OAuth2

=head1 DESCRIPTION

IMAP over SSL (port 993) with SASL XOAUTH2. The login is the address of the
mailbox; the password of the mail account is not used. Fetching itself is
inherited from IMAPTLS.

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

    my $Type = 'IMAPSOAuth2';

    my $OAuth2Object = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftClientCredentials');

    my %Token = $OAuth2Object->AccessTokenGet();
    if ( !$Token{Success} ) {
        return (
            Successful => 0,
            Message    => "$Type: $Token{ErrorMessage}",
        );
    }

    # connect to host, Mail::IMAPClient does not log in without User and Password
    my $IMAPObject = Mail::IMAPClient->new(
        Server  => $Param{Host},
        Port    => 993,
        Ssl     => [
            SSL_verify_mode     => IO::Socket::SSL::SSL_VERIFY_PEER(),
            SSL_verifycn_scheme => 'imap',
            SSL_verifycn_name   => $Param{Host},
        ],
        Timeout => $Param{Timeout},
        Debug   => $Param{Debug},
        Uid     => 1,

        # see bug#8791: needed for some Microsoft Exchange backends
        Ignoresizeerrors => 1,
    );

    if ( !$IMAPObject ) {
        return (
            Successful => 0,
            Message    => "$Type: Can't connect to $Param{Host}: $@\n",
        );
    }

    my $XOAUTH2String = $OAuth2Object->XOAUTH2StringBuild(
        User        => $Param{Login},
        AccessToken => $Token{AccessToken},
    );

    # After a failed XOAUTH2 login the server may send another challenge;
    # an empty line ends the exchange instead of sending the string again.
    my $ChallengeCount = 0;
    my $Callback       = sub {
        return '' if $ChallengeCount++;
        return $XOAUTH2String;
    };

    # keep the token out of the Mail::IMAPClient debug output
    my $Debug = $IMAPObject->Debug();
    $IMAPObject->Debug(0);
    my $Auth = $IMAPObject->authenticate( 'XOAUTH2', $Callback );
    $IMAPObject->Debug($Debug);

    if ( !$Auth ) {
        my $Error = $IMAPObject->LastError() // '';
        $IMAPObject->logout();
        $OAuth2Object->AccessTokenDelete();

        return (
            Successful => 0,
            Message    => "$Type: XOAUTH2 authentication for mailbox '$Param{Login}' on $Param{Host} failed ($Error). "
                . 'Check that the mailbox has FullAccess for the Exchange service principal (Add-MailboxPermission) '
                . 'and that New-ServicePrincipal used the object ID from "Enterprise applications".',
        );
    }

    return (
        Successful => 1,
        IMAPObject => $IMAPObject,
        Type       => $Type,
    );
}

1;
