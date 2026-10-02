# --
# Copyright (C) 2010-2026 OFORK, https://o-fork.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use MIME::Base64 qw(encode_base64);
use Kernel::System::OAuth2::MicrosoftClientCredentials;    # load before mocking, the ObjectManager would otherwise overwrite the mocks
use Kernel::System::OAuth2::MicrosoftMailboxCheck;

# token with the given roles, only the payload matters
my $TokenWithRoles = sub {
    my @Roles   = @_;
    my $Payload = '{"aud":"https://outlook.office365.com","roles":[' . join( ',', map {"\"$_\""} @Roles ) . ']}';
    ( my $Encoded = encode_base64( $Payload, '' ) ) =~ tr{+/=}{-_}d;
    return "eyJ0eXAiOiJKV1QifQ.$Encoded.signature";
};

my %TokenResult;
my ( @MailboxLogins, %MailboxLoginResult, @SMTPChecks, %SMTPCheckResult );
{
    no warnings 'redefine';    ## no critic
    *Kernel::System::OAuth2::MicrosoftClientCredentials::AccessTokenGet = sub { return %TokenResult };
    *Kernel::System::OAuth2::MicrosoftMailboxCheck::_MailboxLogin = sub {
        my ( $Self, %Param ) = @_;
        push @MailboxLogins, "$Param{Protocol} $Param{Address}";
        return %MailboxLoginResult;
    };
    *Kernel::System::OAuth2::MicrosoftMailboxCheck::_SMTPAuthCheck = sub {
        my ( $Self, %Param ) = @_;
        push @SMTPChecks, $Param{Address};
        return %SMTPCheckResult;
    };
}

my $CheckObject = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftMailboxCheck');

# message with its placeholders filled in, as the frontend shows it
my $Text = sub {
    my $Check = shift // {};
    my @Data  = @{ $Check->{MessageData} || [] };
    ( my $Message = $Check->{Message} // '' ) =~ s{%s}{shift(@Data) // ''}xmsge;
    return $Message;
};

my $Run = sub {
    ( @MailboxLogins, @SMTPChecks ) = ();
    my %Result = $CheckObject->MailboxCheck( Address => 'support@example.com' );
    my %Checks = map { $_->{Name} => $_ } @{ $Result{Checks} || [] };
    return ( \%Result, \%Checks );
};

# everything fine, IMAP preferred
%TokenResult        = ( Success => 1, AccessToken => $TokenWithRoles->(qw(IMAP.AccessAsApp POP.AccessAsApp SMTP.SendAsApp)) );
%MailboxLoginResult = ( Successful => 1 );
%SMTPCheckResult    = ( Successful => 1 );
my ( $Result, $Checks ) = $Run->();
$Self->True( $Result->{Successful}, 'MailboxCheck() succeeds' );
$Self->IsDeeply( [ map { $_->{Name} } @{ $Result->{Checks} } ], [qw(Token MailboxAccess SMTPAuth)], 'Checks in order' );
$Self->IsDeeply( \@MailboxLogins, ['IMAP support@example.com'], 'Mailbox access is checked via IMAP if the app has IMAP.AccessAsApp' );
$Self->IsDeeply( \@SMTPChecks,    ['support@example.com'],      'SMTP AUTH is checked for the address' );
$Self->True( ( ( $Text->( $Checks->{Token} ) ) =~ m{SMTP\.SendAsApp} ) ? 1 : 0, 'Token check lists the roles' );

# only POP permission
%TokenResult = ( Success => 1, AccessToken => $TokenWithRoles->(qw(POP.AccessAsApp SMTP.SendAsApp)) );
( $Result, $Checks ) = $Run->();
$Self->IsDeeply( \@MailboxLogins, ['POP3 support@example.com'], 'Mailbox access is checked via POP3 if the app only has POP.AccessAsApp' );

# neither IMAP nor POP permission: access can't be checked
%TokenResult = ( Success => 1, AccessToken => $TokenWithRoles->(qw(SMTP.SendAsApp)) );
( $Result, $Checks ) = $Run->();
$Self->False( $Result->{Successful}, 'MailboxCheck() fails without IMAP and POP permission' );
$Self->False( $Checks->{MailboxAccess}->{Successful}, 'Mailbox access check fails' );
$Self->True(
    ( ( $Text->( $Checks->{MailboxAccess} ) ) =~ m{IMAP\.AccessAsApp.*POP\.AccessAsApp}xms ) ? 1 : 0,
    'Message names the missing permissions',
);
$Self->Is( scalar @MailboxLogins, 0, 'No mailbox login without IMAP or POP permission' );
$Self->IsDeeply( \@SMTPChecks, ['support@example.com'], 'SMTP AUTH is still checked' );

# no SMTP permission
%TokenResult = ( Success => 1, AccessToken => $TokenWithRoles->(qw(IMAP.AccessAsApp)) );
( $Result, $Checks ) = $Run->();
$Self->False( $Checks->{SMTPAuth}->{Successful}, 'SMTP check fails without SMTP.SendAsApp' );
$Self->True( ( ( $Text->( $Checks->{SMTPAuth} ) ) =~ m{SMTP\.SendAsApp} ) ? 1 : 0, 'Message names SMTP.SendAsApp' );
$Self->Is( scalar @SMTPChecks, 0, 'No SMTP connection without SMTP.SendAsApp' );

# mailbox not released
%TokenResult        = ( Success => 1, AccessToken => $TokenWithRoles->(qw(IMAP.AccessAsApp SMTP.SendAsApp)) );
%MailboxLoginResult = ( Successful => 0, Message => 'IMAPSOAuth2: XOAUTH2 authentication failed (1 NO User is authenticated but not connected.)' );
( $Result, $Checks ) = $Run->();
$Self->False( $Result->{Successful}, 'MailboxCheck() fails if the mailbox is not released' );
$Self->True(
    ( ( $Text->( $Checks->{MailboxAccess} ) ) =~ m{not\sconnected}xms ) ? 1 : 0,
    'Message contains the answer of Exchange',
);
$Self->True( ( ( $Text->( $Checks->{MailboxAccess} ) ) =~ m{Add-MailboxPermission} ) ? 1 : 0, 'Message points to Add-MailboxPermission' );

# SMTP AUTH disabled
%MailboxLoginResult = ( Successful => 1 );
%SMTPCheckResult    = ( Successful => 0, Message => 'SMTP code: 535, 5.7.139 Authentication unsuccessful, SmtpClientAuthentication is disabled for the Mailbox.' );
( $Result, $Checks ) = $Run->();
$Self->False( $Result->{Successful}, 'MailboxCheck() fails if SMTP AUTH is disabled' );
$Self->True( ( ( $Text->( $Checks->{SMTPAuth} ) ) =~ m{SmtpClientAuthentication} ) ? 1 : 0, 'Message contains the SMTP answer' );

# token request fails: nothing else is checked
%TokenResult = ( Success => 0, ErrorMessage => 'OAuth2: SysConfig setting \'OAuth2::Microsoft::TenantID\' is not configured.' );
( $Result, $Checks ) = $Run->();
$Self->False( $Result->{Successful}, 'MailboxCheck() fails without token' );
$Self->IsDeeply( [ map { $_->{Name} } @{ $Result->{Checks} } ], ['Token'], 'Only the token check is reported' );
$Self->True( ( ( $Text->( $Checks->{Token} ) ) =~ m{TenantID} ) ? 1 : 0, 'Token error is passed on' );
$Self->Is( scalar(@MailboxLogins) + scalar(@SMTPChecks), 0, 'No connection without token' );

# token is never part of a message
%TokenResult        = ( Success => 1, AccessToken => $TokenWithRoles->(qw(IMAP.AccessAsApp SMTP.SendAsApp)) );
%MailboxLoginResult = ( Successful => 1 );
%SMTPCheckResult    = ( Successful => 1 );
( $Result, $Checks ) = $Run->();
my $AllMessages = join "\n", map { $Text->($_) } @{ $Result->{Checks} };
$Self->False( ( index( $AllMessages, $TokenResult{AccessToken} ) >= 0 ) ? 1 : 0, 'Token does not appear in the messages' );

# invalid address
my %Invalid = $CheckObject->MailboxCheck( Address => 'not an address' );
$Self->False( $Invalid{Successful}, 'MailboxCheck() fails for an invalid address' );

# roles from a token that is not a JWT
$Self->IsDeeply( [ $CheckObject->_TokenRoles( AccessToken => 'opaque' ) ], [], '_TokenRoles() returns nothing for an opaque token' );

1;
