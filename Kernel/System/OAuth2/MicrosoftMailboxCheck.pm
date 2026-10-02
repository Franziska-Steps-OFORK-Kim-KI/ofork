# --
# Kernel/System/OAuth2/MicrosoftMailboxCheck.pm
# Copyright (C) 2010-2026 OFORK, https://o-fork.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::OAuth2::MicrosoftMailboxCheck;

use strict;
use warnings;

use MIME::Base64 qw(decode_base64);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::OAuth2::MicrosoftClientCredentials',
);

=head1 NAME

Kernel::System::OAuth2::MicrosoftMailboxCheck - check whether the Entra app may use an Exchange Online mailbox

=head1 DESCRIPTION

Checks for one address what OFORK needs to fetch from and send as this mailbox
with OAuth2:

=over 4

=item Token: the Entra app gets a token, and which application permissions it contains.

=item MailboxAccess: an XOAUTH2 login via IMAP (or POP3, if the app only has
POP.AccessAsApp) succeeds. Exchange only allows it with FullAccess for the
service principal, so this proves the mailbox is released for the app.

=item SMTPAuth: an XOAUTH2 login via SMTP succeeds. Exchange accepts it even
without FullAccess, so this only proves that SMTP AUTH is enabled.

=back

Nothing is sent and nothing is changed in the mailbox.

Messages are English format strings with placeholders in C<MessageData>, ready for
C<< $LanguageObject->Translate( $Message, @{$MessageData} ) >>.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CheckObject = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftMailboxCheck');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Host} = 'outlook.office365.com';

    return $Self;
}

=head2 MailboxCheck()

    my %Result = $CheckObject->MailboxCheck(
        Address => 'support@example.com',
    );

returns

    %Result = (
        Successful => 1,    # all checks successful
        Checks     => [
            {
                Name        => 'Token',            # Token, MailboxAccess, SMTPAuth
                Successful  => 1,
                Message     => 'Token received, application permissions: %s.',
                MessageData => [ 'IMAP.AccessAsApp, SMTP.SendAsApp' ],
            },
            ...
        ],
    );

=cut

sub MailboxCheck {
    my ( $Self, %Param ) = @_;

    my $Address = $Param{Address} // '';
    $Address =~ s{ \A \s+ | \s+ \z }{}xmsg;

    if ( $Address !~ m{ \A [^\s@]+ @ [^\s@]+ \z }xms ) {
        return (
            Successful => 0,
            Checks     => [
                {
                    Name        => 'Address',
                    Successful  => 0,
                    Message     => Translatable('"%s" is not a valid email address.'),
                    MessageData => [$Address],
                },
            ],
        );
    }

    my @Checks;

    my %Token = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftClientCredentials')->AccessTokenGet();
    if ( !$Token{Success} ) {
        return (
            Successful => 0,
            Checks     => [
                {
                    Name        => 'Token',
                    Successful  => 0,
                    Message     => '%s',
                    MessageData => [ $Token{ErrorMessage} ],
                },
            ],
        );
    }

    my %Roles = map { $_ => 1 } $Self->_TokenRoles( AccessToken => $Token{AccessToken} );
    push @Checks, {
        Name        => 'Token',
        Successful  => 1,
        Message     => Translatable('Token received, application permissions: %s.'),
        MessageData => [ join( ', ', sort keys %Roles ) || '-' ],
    };

    # mailbox access proves FullAccess for the service principal
    my $Protocol = $Roles{'IMAP.AccessAsApp'} ? 'IMAP' : $Roles{'POP.AccessAsApp'} ? 'POP3' : '';
    if ( !$Protocol ) {
        push @Checks, {
            Name        => 'MailboxAccess',
            Successful  => 0,
            Message     => Translatable('The Entra app has neither IMAP.AccessAsApp nor POP.AccessAsApp, so the mailbox access can\'t be checked.'),
            MessageData => [],
        };
    }
    else {
        my %Login = $Self->_MailboxLogin(
            Protocol => $Protocol,
            Address  => $Address,
        );
        push @Checks, $Login{Successful}
            ? {
            Name        => 'MailboxAccess',
            Successful  => 1,
            Message     => Translatable('Mailbox is released for the Entra app (login via %s successful).'),
            MessageData => [$Protocol],
            }
            : {
            Name    => 'MailboxAccess',
            Successful => 0,
            Message => Translatable(
                'Mailbox is not released for the Entra app (login via %s failed: %s). Grant FullAccess with Add-MailboxPermission; right after a change, Exchange may need some time.'
            ),
            MessageData => [ $Protocol, $Self->_ShortMessage( Message => $Login{Message} ) ],
            };
    }

    # SMTP AUTH; Exchange accepts the login even without FullAccess
    if ( !$Roles{'SMTP.SendAsApp'} ) {
        push @Checks, {
            Name        => 'SMTPAuth',
            Successful  => 0,
            Message     => Translatable('The Entra app has no SMTP.SendAsApp, so OFORK can\'t send as this address.'),
            MessageData => [],
        };
    }
    else {
        my %SMTP = $Self->_SMTPAuthCheck( Address => $Address );
        push @Checks, $SMTP{Successful}
            ? {
            Name        => 'SMTPAuth',
            Successful  => 1,
            Message     => Translatable('SMTP AUTH login successful.'),
            MessageData => [],
            }
            : {
            Name        => 'SMTPAuth',
            Successful  => 0,
            Message     => Translatable('SMTP AUTH login failed: %s. Enable it with Set-CASMailbox -SmtpClientAuthenticationDisabled $false.'),
            MessageData => [ $Self->_ShortMessage( Message => $SMTP{Message} ) ],
            };
    }

    return (
        Successful => ( grep { !$_->{Successful} } @Checks ) ? 0 : 1,
        Checks     => \@Checks,
    );
}

sub _TokenRoles {
    my ( $Self, %Param ) = @_;

    # only informative, the token is not verified here
    my ( undef, $Payload ) = split m{\.}xms, ( $Param{AccessToken} // '' );
    return if !$Payload;

    $Payload =~ tr{-_}{+/};
    $Payload .= '=' x ( ( 4 - length($Payload) % 4 ) % 4 );

    my $Data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => decode_base64($Payload),
    );
    return if ref $Data ne 'HASH' || ref $Data->{roles} ne 'ARRAY';

    return @{ $Data->{roles} };
}

sub _ShortMessage {
    my ( $Self, %Param ) = @_;

    my $Message = $Param{Message} // '';

    # keep the answer of the server, drop the hints that MailboxCheck() gives itself
    if ( $Message =~ m{ failed \s \( (.+?) \) \. }xms ) {
        $Message = $1;
    }
    # the message templates add their own full stop
    $Message =~ s{ [\s.]+ \z }{}xms;

    return $Message;
}

sub _MailboxLogin {
    my ( $Self, %Param ) = @_;

    my $Backend = $Param{Protocol} eq 'IMAP'
        ? 'Kernel::System::MailAccount::IMAPSOAuth2'
        : 'Kernel::System::MailAccount::POP3SOAuth2';

    if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($Backend) ) {
        return (
            Successful => 0,
            Message    => "Can't load $Backend.",
        );
    }

    my %Connect = $Backend->new()->Connect(
        Login    => $Param{Address},
        Password => '',
        Host     => $Self->{Host},
        Timeout  => 30,
        Debug    => 0,
    );

    if ( $Connect{IMAPObject} ) {
        $Connect{IMAPObject}->logout();
    }
    if ( $Connect{PopObject} ) {
        $Connect{PopObject}->quit();
    }

    return (
        Successful => $Connect{Successful} ? 1 : 0,
        Message    => $Connect{Message},
    );
}

sub _SMTPAuthCheck {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Backend = 'Kernel::System::Email::SMTPTLSOAuth2';
    if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($Backend) ) {
        return (
            Successful => 0,
            Message    => "Can't load $Backend.",
        );
    }

    my $SendObject = $Backend->new();
    my $MailHost   = $ConfigObject->Get('SendmailModule::Host') || 'smtp.office365.com';

    # Exchange Online hosts only, a different SMTP host would test something else
    $MailHost = 'smtp.office365.com' if $MailHost !~ m{ office365\.com \z | outlook\.com \z }xmsi;

    my $SMTP = $SendObject->_Connect(
        MailHost => $MailHost,
        FQDN     => $ConfigObject->Get('FQDN') || 'localhost',
        SMTPPort => $ConfigObject->Get('SendmailModule::Port') || 587,
    );
    if ( !$SMTP ) {
        return (
            Successful => 0,
            Message    => "Can't connect to $MailHost.",
        );
    }

    $SMTP = $SendObject->_GetSMTPSafeWrapper( SMTP => $SMTP );

    my %Result = $SendObject->_Authenticate(
        SMTP                   => $SMTP,
        CommunicationLogObject => bless( {}, 'Kernel::System::OAuth2::MicrosoftMailboxCheck::NullLog' ),
        From                   => $Param{Address},
        RequireFrom            => 1,
    );

    $SMTP->( 'quit', );

    return (
        Successful => $Result{Success} ? 1 : 0,
        Message    => $Result{ErrorMessage},
    );
}

# _Authenticate() logs into a communication log; the check reports the result itself
package Kernel::System::OAuth2::MicrosoftMailboxCheck::NullLog;    ## no critic

sub ObjectLog { return 1 }

1;
