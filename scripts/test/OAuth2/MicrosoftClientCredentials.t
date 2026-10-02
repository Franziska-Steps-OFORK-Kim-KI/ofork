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

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $OAuth2Object = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftClientCredentials');

my $TenantID     = '11111111-2222-3333-4444-555555555555';
my $ClientID     = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
my $ClientSecret = 'Secret~Value.123';

my $ConfigSet = sub {
    my %Values = @_;
    for my $Key (qw(TenantID ClientID ClientSecret)) {
        $ConfigObject->Set(
            Key   => "OAuth2::Microsoft::$Key",
            Value => $Values{$Key},
        );
    }
};

# Replace the HTTP call; every test case defines the response and checks the request.
my @Requests;
my %NextResponse;
{
    no warnings 'redefine';    ## no critic
    *Kernel::System::OAuth2::MicrosoftClientCredentials::_TokenRequest = sub {
        my ( $Self, %Param ) = @_;
        push @Requests, \%Param;
        return %NextResponse;
    };
}

my $Reset = sub {
    @Requests = ();
    $OAuth2Object->AccessTokenDelete();
};

# XOAUTH2 string, example from the Microsoft documentation
$Self->Is(
    $OAuth2Object->XOAUTH2StringBuild(
        User        => 'test@contoso.onmicrosoft.com',
        AccessToken => 'EwBAAl3BAAUFFpUAo7J3Ve0bjLBWZWCclRC3EoAA',
    ),
    'dXNlcj10ZXN0QGNvbnRvc28ub25taWNyb3NvZnQuY29tAWF1dGg9QmVhcmVyIEV3QkFBbDNCQUFVRkZwVUFvN0ozVmUwYmpMQldaV0NjbFJDM0VvQUEBAQ==',
    'XOAUTH2StringBuild() matches the Microsoft documentation example',
);
$Self->Is(
    $OAuth2Object->XOAUTH2StringBuild( User => '', AccessToken => 'x' ),
    undef,
    'XOAUTH2StringBuild() without User returns undef',
);

# Missing configuration
$Reset->();
$ConfigSet->( ClientID => $ClientID, ClientSecret => $ClientSecret );
my %Result = $OAuth2Object->AccessTokenGet();
$Self->False( $Result{Success}, 'AccessTokenGet() without TenantID fails' );
$Self->True(
    ( ( $Result{ErrorMessage} // '' ) =~ m{OAuth2::Microsoft::TenantID} ) ? 1 : 0,
    'Error message names the missing setting',
);
$Self->Is( scalar @Requests, 0, 'No HTTP request without complete configuration' );

# Invalid tenant ID
$Reset->();
$ConfigSet->( TenantID => 'contoso/../evil', ClientID => $ClientID, ClientSecret => $ClientSecret );
%Result = $OAuth2Object->AccessTokenGet();
$Self->False( $Result{Success}, 'AccessTokenGet() with invalid TenantID fails' );
$Self->Is( scalar @Requests, 0, 'No HTTP request with invalid TenantID' );

# Successful request, whitespace from copy and paste is trimmed
$Reset->();
$ConfigSet->( TenantID => " $TenantID ", ClientID => "$ClientID\n", ClientSecret => $ClientSecret );
%NextResponse = (
    StatusCode => 200,
    StatusLine => '200 OK',
    Content    => '{"token_type":"Bearer","expires_in":3599,"ext_expires_in":3599,"access_token":"TOKEN-1"}',
);
%Result = $OAuth2Object->AccessTokenGet();
$Self->True( $Result{Success}, 'AccessTokenGet() succeeds' );
$Self->Is( $Result{AccessToken}, 'TOKEN-1', 'AccessTokenGet() returns the token' );
$Self->Is( scalar @Requests, 1, 'One HTTP request' );
$Self->Is(
    $Requests[0]->{URL},
    "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token",
    'Default token URL with tenant ID',
);
$Self->IsDeeply(
    $Requests[0]->{Data},
    {
        client_id     => $ClientID,
        client_secret => $ClientSecret,
        scope         => 'https://outlook.office365.com/.default',
        grant_type    => 'client_credentials',
    },
    'Token request form data',
);

# Cached token
%NextResponse = ( StatusCode => 500, StatusLine => '500 must not be called', Content => '' );
%Result = $OAuth2Object->AccessTokenGet();
$Self->Is( $Result{AccessToken}, 'TOKEN-1', 'Second call returns the cached token' );
$Self->Is( scalar @Requests, 1, 'Second call does not request a new token' );

# Deleted token
$OAuth2Object->AccessTokenDelete();
%NextResponse = ( StatusCode => 200, StatusLine => '200 OK', Content => '{"expires_in":3599,"access_token":"TOKEN-2"}' );
%Result = $OAuth2Object->AccessTokenGet();
$Self->Is( $Result{AccessToken}, 'TOKEN-2', 'After AccessTokenDelete() a new token is requested' );
$Self->Is( scalar @Requests, 2, 'Second HTTP request after AccessTokenDelete()' );

# Short-lived token is used but not cached
$Reset->();
%NextResponse = ( StatusCode => 200, StatusLine => '200 OK', Content => '{"expires_in":300,"access_token":"TOKEN-SHORT"}' );
%Result = $OAuth2Object->AccessTokenGet();
$Self->Is( $Result{AccessToken}, 'TOKEN-SHORT', 'Short-lived token is returned' );
$OAuth2Object->AccessTokenGet();
$Self->Is( scalar @Requests, 2, 'Short-lived token is not cached' );

# Cache TTL
$Self->Is( $OAuth2Object->_CacheTTL( ExpiresIn => 3599 ), 3299, '_CacheTTL() subtracts 300 seconds' );
$Self->Is( $OAuth2Object->_CacheTTL( ExpiresIn => 300 ),  0,    '_CacheTTL() is 0 at 300 seconds' );
$Self->Is( $OAuth2Object->_CacheTTL( ExpiresIn => 'x' ),  0,    '_CacheTTL() is 0 for invalid values' );
$Self->Is( $OAuth2Object->_CacheTTL(),                    0,    '_CacheTTL() is 0 without value' );

# Entra error response
$Reset->();
%NextResponse = (
    StatusCode => 401,
    StatusLine => '401 Unauthorized',
    Content    => '{"error":"invalid_client","error_description":"AADSTS7000222: The provided client secret keys for app are expired.\r\nTrace ID: abc\r\nCorrelation ID: def"}',
);
%Result = $OAuth2Object->AccessTokenGet();
$Self->False( $Result{Success}, 'AccessTokenGet() fails on Entra error' );
$Self->True(
    ( ( $Result{ErrorMessage} // '' ) =~ m{HTTP\s401.*invalid_client.*AADSTS7000222}xms ) ? 1 : 0,
    'Error message contains HTTP status, error and AADSTS code',
);
$Self->False(
    ( ( $Result{ErrorMessage} // '' ) =~ m{Trace ID} ) ? 1 : 0,
    'Error message only contains the first line of error_description',
);

# Entra error response on a single line, as returned by the real endpoint
$Reset->();
%NextResponse = (
    StatusCode => 400,
    StatusLine => '400 Bad Request',
    Content    => '{"error":"invalid_request","error_description":"AADSTS90002: Tenant \'x\' not found. Check to make sure you have the correct tenant ID. Trace ID: abc Correlation ID: def Timestamp: 2026-10-02 21:14:02Z"}',
);
%Result = $OAuth2Object->AccessTokenGet();
$Self->True(
    ( ( $Result{ErrorMessage} // '' ) =~ m{AADSTS90002.*correct\stenant\sID\.\z}xms ) ? 1 : 0,
    'Single-line error_description keeps the text up to the trace ID',
);
$Self->False(
    ( ( $Result{ErrorMessage} // '' ) =~ m{Trace ID|Correlation ID} ) ? 1 : 0,
    'Single-line error_description drops trace and correlation IDs',
);

# Non-JSON error response, e.g. proxy or network error from LWP
$Reset->();
%NextResponse = ( StatusCode => 500, StatusLine => "500 Can't connect to login.microsoftonline.com:443", Content => 'Bad gateway' );
%Result = $OAuth2Object->AccessTokenGet();
$Self->False( $Result{Success}, 'AccessTokenGet() fails on non-JSON error' );
$Self->True(
    ( ( $Result{ErrorMessage} // '' ) =~ m{Can't connect} ) ? 1 : 0,
    'Error message contains the HTTP status line',
);

# The secret never appears in error messages, even if the server echoes it
$Reset->();
%NextResponse = (
    StatusCode => 400,
    StatusLine => '400 Bad Request',
    Content    => qq|{"error":"invalid_request","error_description":"Bad value $ClientSecret"}|,
);
%Result = $OAuth2Object->AccessTokenGet();
$Self->False(
    ( ( $Result{ErrorMessage} // '' ) =~ m{\Q$ClientSecret\E} ) ? 1 : 0,
    'Client secret is removed from the error message',
);

# Tenant domain instead of the tenant ID
$Reset->();
$ConfigSet->( TenantID => 'contoso.onmicrosoft.com', ClientID => $ClientID, ClientSecret => $ClientSecret );
%NextResponse = ( StatusCode => 200, StatusLine => '200 OK', Content => '{"expires_in":3599,"access_token":"TOKEN-3"}' );
$OAuth2Object->AccessTokenGet();
$Self->Is(
    $Requests[0]->{URL},
    'https://login.microsoftonline.com/contoso.onmicrosoft.com/oauth2/v2.0/token',
    'Token URL is built from the tenant domain',
);

# Cached token is not shared between different apps
$ConfigSet->( TenantID => 'contoso.onmicrosoft.com', ClientID => 'ffffffff-bbbb-cccc-dddd-eeeeeeeeeeee', ClientSecret => $ClientSecret );
%NextResponse = ( StatusCode => 200, StatusLine => '200 OK', Content => '{"expires_in":3599,"access_token":"TOKEN-4"}' );
%Result = $OAuth2Object->AccessTokenGet();
$Self->Is( $Result{AccessToken}, 'TOKEN-4', 'A token cached for another client ID is not reused' );

$Reset->();

1;
