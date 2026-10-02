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

use Kernel::System::MailAccount::IMAPSOAuth2;
use Kernel::System::OAuth2::MicrosoftClientCredentials;    # load before mocking, the ObjectManager would otherwise overwrite the mocks
use MIME::Base64 qw(decode_base64);

# token module mock
my %TokenResult;
my $TokenDeleted;
{
    no warnings 'redefine';    ## no critic
    *Kernel::System::OAuth2::MicrosoftClientCredentials::AccessTokenGet    = sub { return %TokenResult };
    *Kernel::System::OAuth2::MicrosoftClientCredentials::AccessTokenDelete = sub { $TokenDeleted = 1; return 1 };
}

# Mail::IMAPClient mock
my ( %NewParams, @CallbackResults, $AuthResult, $LoggedOut, @DebugDuringAuth, $NewFails );
{
    no warnings 'redefine';    ## no critic
    *Mail::IMAPClient::new = sub {
        my ( $Class, %Param ) = @_;
        %NewParams = %Param;
        return if $NewFails;
        return bless { Debug => $Param{Debug} }, 'Test::IMAPSOAuth2::Client';
    };
}
{
    no strict 'refs';    ## no critic
    *{'Test::IMAPSOAuth2::Client::Debug'} = sub {
        my ( $Self, $Value ) = @_;
        $Self->{Debug} = $Value if defined $Value;
        return $Self->{Debug};
    };
    *{'Test::IMAPSOAuth2::Client::authenticate'} = sub {
        my ( $Self, $Scheme, $Callback ) = @_;
        push @DebugDuringAuth, $Self->{Debug};

        # Simulate a server that sends a second challenge after a failure.
        @CallbackResults = ( $Callback->( '', $Self ), $Callback->( 'eyJzdGF0dXMiOiI0MDAifQ==', $Self ) );
        return $AuthResult;
    };
    *{'Test::IMAPSOAuth2::Client::LastError'} = sub { return 'NO AUTHENTICATE failed.' };
    *{'Test::IMAPSOAuth2::Client::logout'}    = sub { $LoggedOut = 1; return 1 };
}

my $Backend = Kernel::System::MailAccount::IMAPSOAuth2->new();

my $Connect = sub {
    ( %NewParams, @CallbackResults, @DebugDuringAuth ) = ();
    ( $LoggedOut, $TokenDeleted ) = ( 0, 0 );
    return $Backend->Connect(
        Login    => 'support@example.com',
        Password => 'oauth2-not-used',
        Host     => 'outlook.office365.com',
        Timeout  => 60,
        Debug    => 1,
    );
};

%TokenResult = ( Success => 1, AccessToken => 'TOKEN-1' );

# success
$AuthResult = 1;
my %Result = $Connect->();
$Self->True( $Result{Successful}, 'Connect() succeeds' );
$Self->Is( $Result{Type}, 'IMAPSOAuth2', 'Connect() returns the type' );
$Self->Is( ref $Result{IMAPObject}, 'Test::IMAPSOAuth2::Client', 'Connect() returns the IMAP object' );
$Self->Is( $NewParams{Server}, 'outlook.office365.com', 'Server' );
$Self->Is( $NewParams{Port},   993,                     'Port 993' );
$Self->False( exists $NewParams{User},     'No User passed, so Mail::IMAPClient does not log in by itself' );
$Self->False( exists $NewParams{Password}, 'No Password passed' );
my %SSL = @{ $NewParams{Ssl} || [] };
$Self->Is( $SSL{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'Certificate is verified' );
$Self->Is( $SSL{SSL_verifycn_name}, 'outlook.office365.com', 'Certificate is checked against the host name' );
$Self->Is(
    decode_base64( $CallbackResults[0] ),
    "user=support\@example.com\x01auth=Bearer TOKEN-1\x01\x01",
    'First challenge is answered with the XOAUTH2 string',
);
$Self->Is( $CallbackResults[1], '', 'A further challenge is answered with an empty line, not the string again' );
$Self->IsDeeply( \@DebugDuringAuth, [0], 'Debug output is off while authenticating' );
$Self->Is( $Result{IMAPObject}->Debug(), 1, 'Debug setting is restored' );

# server rejects the login
$AuthResult = undef;
%Result     = $Connect->();
$Self->False( $Result{Successful}, 'Connect() fails if authentication fails' );
$Self->True( ( ( $Result{Message} // '' ) =~ m{support\@example\.com} ) ? 1 : 0, 'Message names the mailbox' );
$Self->True( ( ( $Result{Message} // '' ) =~ m{Add-MailboxPermission} ) ? 1 : 0, 'Message points to the mailbox permission' );
$Self->True( $LoggedOut,    'Connection is closed after failed authentication' );
$Self->True( $TokenDeleted, 'Token is deleted after failed authentication' );

# token request fails
%TokenResult = ( Success => 0, ErrorMessage => 'OAuth2: Token request to Microsoft Entra failed (HTTP 401): invalid_client: AADSTS7000222: expired' );
%Result      = $Connect->();
$Self->False( $Result{Successful}, 'Connect() fails without token' );
$Self->True( ( ( $Result{Message} // '' ) =~ m{AADSTS7000222} ) ? 1 : 0, 'Token error is passed on' );
$Self->False( %NewParams ? 1 : 0, 'No IMAP connection without token' );

# connection fails
%TokenResult = ( Success => 1, AccessToken => 'TOKEN-1' );
$NewFails    = 1;
%Result      = $Connect->();
$Self->False( $Result{Successful}, 'Connect() fails if the server is not reachable' );
$Self->True( ( ( $Result{Message} // '' ) =~ m{outlook\.office365\.com} ) ? 1 : 0, 'Message names the host' );
$NewFails = 0;

# missing parameters
%Result = $Backend->Connect( Host => 'outlook.office365.com', Timeout => 60, Debug => 0 );
$Self->False( $Result{Successful}, 'Connect() without Login fails' );

1;
