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

use Kernel::System::MailAccount::POP3SOAuth2;
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

# Net::POP3 mock: responses are given as Net::Cmd classes (2 = +OK, 3 = "+" continuation, 5 = -ERR)
my ( %NewParams, @Commands, @Responses, @DebugDuringCommands, $Debug, $Quit, $NewFails, @PopStat );
{
    no warnings 'redefine';    ## no critic
    *Net::POP3::new = sub {
        my ( $Class, $Host, %Param ) = @_;
        %NewParams = ( Host => $Host, %Param );
        return if $NewFails;
        return bless {}, 'Test::POP3SOAuth2::Client';
    };
}
{
    no strict 'refs';    ## no critic
    *{'Test::POP3SOAuth2::Client::debug'} = sub {
        my ( $Self, $Value ) = @_;
        my $Old = $Debug;
        $Debug = $Value if defined $Value;
        return $Old;
    };
    *{'Test::POP3SOAuth2::Client::command'} = sub {
        my ( $Self, @Param ) = @_;
        push @Commands,            join ' ', @Param;
        push @DebugDuringCommands, $Debug;
        return $Self;
    };
    *{'Test::POP3SOAuth2::Client::response'} = sub { return shift @Responses };
    *{'Test::POP3SOAuth2::Client::message'}  = sub { return "Authentication failure: unknown user name or bad password.\n" };
    *{'Test::POP3SOAuth2::Client::popstat'}  = sub { return @PopStat };
    *{'Test::POP3SOAuth2::Client::quit'}     = sub { $Quit = 1; return 1 };
}

my $Backend = Kernel::System::MailAccount::POP3SOAuth2->new();

my $Connect = sub {
    my %Param = @_;
    ( %NewParams, @Commands, @DebugDuringCommands ) = ();
    ( $Quit, $TokenDeleted ) = ( 0, 0 );
    $Debug     = 1;
    @Responses = @{ $Param{Responses} || [] };
    @PopStat   = @{ $Param{PopStat} || [] };
    return $Backend->Connect(
        Login    => 'support@example.com',
        Password => 'oauth2-not-used',
        Host     => 'outlook.office365.com',
        Timeout  => 60,
        Debug    => 1,
    );
};

%TokenResult = ( Success => 1, AccessToken => 'TOKEN-1' );

# success with messages
my %Result = $Connect->( Responses => [ 3, 2 ], PopStat => [ 4, 12345 ] );
$Self->True( $Result{Successful}, 'Connect() succeeds after "+" and "+OK"' );
$Self->Is( $Result{Type}, 'POP3SOAuth2', 'Connect() returns the type' );
$Self->Is( ref $Result{PopObject}, 'Test::POP3SOAuth2::Client', 'Connect() returns the POP3 object' );
$Self->Is( $Result{NOM}, 4, 'Connect() returns the number of messages like login() does' );
$Self->Is( $NewParams{Host}, 'outlook.office365.com', 'Host' );
$Self->Is( $NewParams{Port}, 995,                     'Port 995' );
$Self->True( $NewParams{SSL}, 'SSL is used' );
$Self->Is( $NewParams{SSL_verify_mode}, IO::Socket::SSL::SSL_VERIFY_PEER(), 'Certificate is verified' );
$Self->Is( $NewParams{SSL_verifycn_name}, 'outlook.office365.com', 'Certificate is checked against the host name' );
$Self->Is( $Commands[0], 'AUTH XOAUTH2', 'First command is AUTH XOAUTH2' );
$Self->Is(
    decode_base64( $Commands[1] ),
    "user=support\@example.com\x01auth=Bearer TOKEN-1\x01\x01",
    'Second command is the XOAUTH2 string',
);
$Self->IsDeeply( \@DebugDuringCommands, [ 0, 0 ], 'Debug output is off while authenticating' );
$Self->Is( $Debug, 1, 'Debug setting is restored' );
$Self->False( $TokenDeleted, 'Token is kept after success' );
$Self->False( $Quit,         'Connection stays open after success' );

# success without messages
%Result = $Connect->( Responses => [ 3, 2 ], PopStat => [ 0, 0 ] );
$Self->True( $Result{Successful}, 'Connect() succeeds on an empty mailbox' );
$Self->Is( $Result{NOM}, '0E0', 'Empty mailbox returns "0E0" like login() does' );

# server rejects the XOAUTH2 string
%Result = $Connect->( Responses => [ 3, 5 ] );
$Self->False( $Result{Successful}, 'Connect() fails on -ERR' );
$Self->True( ( ( $Result{Message} // '' ) =~ m{support\@example\.com} ) ? 1 : 0, 'Message names the mailbox' );
$Self->True( ( ( $Result{Message} // '' ) =~ m{Add-MailboxPermission} ) ? 1 : 0, 'Message points to the mailbox permission' );
$Self->True( ( ( $Result{Message} // '' ) =~ m{POP\.AccessAsApp} ) ? 1 : 0, 'Message points to the POP permission' );
$Self->False( ( ( $Result{Message} // '' ) =~ m{TOKEN-1} ) ? 1 : 0, 'Message does not contain the token' );
$Self->True( $Quit,         'Connection is closed after failed authentication' );
$Self->True( $TokenDeleted, 'Token is deleted after failed authentication' );
$Self->Is( $Debug, 1, 'Debug setting is restored after failure' );

# server sends a further challenge instead of an error
%Result = $Connect->( Responses => [ 3, 3, 5 ] );
$Self->False( $Result{Successful}, 'Connect() fails if the server sends a further challenge' );
$Self->Is( scalar @Commands, 3, 'A further challenge is answered once' );
$Self->Is( $Commands[2], '', 'A further challenge is answered with an empty line, not the string again' );

# server does not offer XOAUTH2
%Result = $Connect->( Responses => [5] );
$Self->False( $Result{Successful}, 'Connect() fails if AUTH XOAUTH2 is rejected' );
$Self->Is( scalar @Commands, 1, 'XOAUTH2 string is not sent if AUTH XOAUTH2 is rejected' );

# STAT fails after login
%Result = $Connect->( Responses => [ 3, 2 ], PopStat => [] );
$Self->False( $Result{Successful}, 'Connect() fails if STAT fails' );
$Self->True( $Quit, 'Connection is closed if STAT fails' );

# token request fails
%TokenResult = ( Success => 0, ErrorMessage => 'OAuth2: Token request to Microsoft Entra failed (HTTP 401): invalid_client: AADSTS7000222: expired' );
%Result      = $Connect->();
$Self->False( $Result{Successful}, 'Connect() fails without token' );
$Self->True( ( ( $Result{Message} // '' ) =~ m{AADSTS7000222} ) ? 1 : 0, 'Token error is passed on' );
$Self->False( %NewParams ? 1 : 0, 'No POP3 connection without token' );

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
