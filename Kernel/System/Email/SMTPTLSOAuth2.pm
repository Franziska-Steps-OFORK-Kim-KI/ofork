# --
# Kernel/System/Email/SMTPTLSOAuth2.pm
# Copyright (C) 2010-2026 OFORK, https://o-fork.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::SMTPTLSOAuth2;

use strict;
use warnings;

use IO::Socket::SSL;
use Mail::Address;
use Net::SMTP;

use parent qw(Kernel::System::Email::SMTPTLS);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CommunicationLog',
    'Kernel::System::Log',
    'Kernel::System::OAuth2::MicrosoftClientCredentials',
);

=head1 NAME

Kernel::System::Email::SMTPTLSOAuth2 - send mails through Exchange Online with OAuth2

=head1 DESCRIPTION

Uses STARTTLS (port 587 by default) and authenticates every mail with SASL XOAUTH2
as the envelope sender. The sender address must be a mailbox the Exchange service
principal of the Entra app has FullAccess to. "SendmailModule::AuthUser" and
"SendmailModule::AuthPassword" are not used.

=cut

sub _Connect {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(MailHost FQDN)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # Remove a possible port from the FQDN value
    my $FQDN = $Param{FQDN};
    $FQDN =~ s{:\d+}{}smx;

    # set up connection connection
    my $SMTP = Net::SMTP->new(
        $Param{MailHost},
        Hello   => $FQDN,
        Port    => $Param{SMTPPort} || 587,
        Timeout => 30,
        Debug   => $Param{SMTPDebug},
    );

    return if !$SMTP;

    # unlike SMTPTLS, the server certificate is verified
    if (
        !$SMTP->starttls(
            SSL_verify_mode     => IO::Socket::SSL::SSL_VERIFY_PEER(),
            SSL_verifycn_scheme => 'smtp',
            SSL_verifycn_name   => $Param{MailHost},
        )
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "SMTPTLSOAuth2: STARTTLS with '$Param{MailHost}' failed: "
                . ( IO::Socket::SSL::errstr() || 'unknown error' ),
        );
        return;
    }

    return $SMTP;
}

=head2 Send()

Sends a mail. If the envelope sender is empty (Loop mails such as auto responses and
notifications use "SendmailNotificationEnvelopeFrom", which is empty by default), the
address of the "From:" header of the mail is used for the XOAUTH2 login and as MAIL FROM.

=cut

sub Send {
    my ( $Self, %Param ) = @_;

    if ( !( $Param{From} // '' ) && $Param{Header} ) {
        my $HeaderFrom = $Self->_HeaderFromAddress( Header => $Param{Header} );
        $Param{From} = $HeaderFrom if $HeaderFrom;
    }

    return $Self->SUPER::Send(%Param);
}

# returns the bare address of the "From:" header line (not Reply-To or Resent-From)
sub _HeaderFromAddress {
    my ( $Self, %Param ) = @_;

    my $Header = ref $Param{Header} ? ${ $Param{Header} } : $Param{Header};
    return '' if !defined $Header;

    # only the header block, with folded lines unfolded
    $Header =~ s{ \r?\n \r?\n .* \z }{}xms;
    $Header =~ s{ \r?\n [ \t]+ }{ }xmsg;

    return '' if $Header !~ m{ (?: \A | \n ) From: [ \t]* ( [^\r\n]* ) }xmsi;
    my $Value = $1;

    my ($Address) = Mail::Address->parse($Value);
    return '' if !$Address;

    return $Address->address() // '';
}

=head2 _Authenticate()

authenticates with SASL XOAUTH2 as the envelope sender

Without "From" (connection check) only the token request is tested.
With "RequireFrom" (set by Send()) a missing sender is an error.

=cut

sub _Authenticate {
    my ( $Self, %Param ) = @_;

    my $SMTP                   = $Param{SMTP};
    my $CommunicationLogObject = $Param{CommunicationLogObject};

    my $OAuth2Object = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftClientCredentials');

    my $From = $Param{From} // '';
    if ( $From =~ m{ < ( [^<>]+ ) > }xms ) {
        $From = $1;
    }
    $From =~ s{ \A \s+ | \s+ \z }{}xmsg;
    $From = lc $From;

    if ( !$From && $Param{RequireFrom} ) {

        my $ErrorMessage = 'SMTPTLSOAuth2: Mail has no envelope sender; '
            . 'OAuth2 needs the sender address to select the mailbox.';

        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => 'Kernel::System::Email::SMTPTLSOAuth2',
            Value         => $ErrorMessage,
        );

        return (
            Success      => 0,
            ErrorMessage => $ErrorMessage,
        );
    }

    my %Token = $OAuth2Object->AccessTokenGet();
    if ( !$Token{Success} ) {

        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => 'Kernel::System::Email::SMTPTLSOAuth2',
            Value         => $Token{ErrorMessage},
        );

        return (
            Success      => 0,
            ErrorMessage => $Token{ErrorMessage},
        );
    }

    if ( !$From ) {

        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => 'Kernel::System::Email::SMTPTLSOAuth2',
            Value         => 'No sender given, OAuth2 token request succeeded, SMTP authentication skipped.',
        );

        return ( Success => 1 );
    }

    $CommunicationLogObject->ObjectLog(
        ObjectLogType => 'Connection',
        Priority      => 'Debug',
        Key           => 'Kernel::System::Email::SMTPTLSOAuth2',
        Value         => "Using SMTP XOAUTH2 authentication for mailbox '$From'.",
    );

    my $XOAUTH2String = $OAuth2Object->XOAUTH2StringBuild(
        User        => $From,
        AccessToken => $Token{AccessToken},
    );

    # keep the token out of the Net::SMTP debug output
    my $Debug = $SMTP->( 'debug', 0 );

    # two steps as in the Microsoft example: AUTH XOAUTH2, 334, string, 235
    my $Success = 0;
    $SMTP->( 'command', 'AUTH XOAUTH2' );
    if ( ( $SMTP->( 'response', ) // 0 ) == 3 ) {
        $SMTP->( 'command', $XOAUTH2String );
        $Success = ( ( $SMTP->( 'response', ) // 0 ) == 2 );
    }

    $SMTP->( 'debug', $Debug // 0 );

    return ( Success => 1 ) if $Success;

    my $Code    = $SMTP->( 'code', ) // '';
    my $Message = $SMTP->( 'message', ) // '';
    $Message =~ s{ \s+ \z }{}xms;

    $OAuth2Object->AccessTokenDelete();

    my $ErrorMessage = "SMTP XOAUTH2 authentication for sender '$From' failed (SMTP code: $Code, $Message). "
        . 'Check that the mailbox has FullAccess for the Exchange service principal (Add-MailboxPermission) '
        . 'and that SMTP AUTH is enabled for it (Set-CASMailbox -SmtpClientAuthenticationDisabled $false).';

    $CommunicationLogObject->ObjectLog(
        ObjectLogType => 'Connection',
        Priority      => 'Error',
        Key           => 'Kernel::System::Email::SMTPTLSOAuth2',
        Value         => $ErrorMessage,
    );

    return (
        Success      => 0,
        ErrorMessage => $ErrorMessage,
        Code         => $Code,
    );
}

1;
