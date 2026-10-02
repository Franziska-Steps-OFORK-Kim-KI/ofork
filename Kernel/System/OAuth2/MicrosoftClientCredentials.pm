# --
# Kernel/System/OAuth2/MicrosoftClientCredentials.pm
# Copyright (C) 2010-2026 OFORK, https://o-fork.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::OAuth2::MicrosoftClientCredentials;

use strict;
use warnings;

use LWP::UserAgent;
use MIME::Base64 qw(encode_base64);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::JSON',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::OAuth2::MicrosoftClientCredentials - app-only OAuth2 tokens for Exchange Online

=head1 DESCRIPTION

Requests access tokens from Microsoft Entra with the client credentials grant
and builds the SASL XOAUTH2 string for IMAP and SMTP, see
https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $OAuth2Object = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftClientCredentials');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'OAuth2MicrosoftToken';

    # a cached token must stay valid for at least this many seconds
    $Self->{ExpiryMargin} = 300;

    # fixed by Microsoft for Exchange Online IMAP, POP and SMTP with the client credentials grant,
    # which always needs the tenant-specific token endpoint
    $Self->{Scope}    = 'https://outlook.office365.com/.default';
    $Self->{TokenURL} = 'https://login.microsoftonline.com/<TenantID>/oauth2/v2.0/token';

    return $Self;
}

=head2 AccessTokenGet()

returns a valid access token, from the cache or from Microsoft Entra

    my %Result = $OAuth2Object->AccessTokenGet();

returns

    %Result = (
        Success     => 1,
        AccessToken => 'eyJ0eXAiOi...',
    );

or

    %Result = (
        Success      => 0,
        ErrorMessage => 'OAuth2: Token request to Microsoft Entra failed (HTTP 401): invalid_client: AADSTS7000222: ...',
    );

=cut

sub AccessTokenGet {
    my ( $Self, %Param ) = @_;

    my %Config = $Self->_ConfigGet();
    if ( $Config{ErrorMessage} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Config{ErrorMessage},
        );
        return (
            Success      => 0,
            ErrorMessage => $Config{ErrorMessage},
        );
    }

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $CacheKey    = "$Config{TenantID}-$Config{ClientID}";

    my $CachedToken = $CacheObject->Get(
        Type          => $Self->{CacheType},
        Key           => $CacheKey,
        CacheInMemory => 0,
    );
    if ($CachedToken) {
        return (
            Success     => 1,
            AccessToken => $CachedToken,
        );
    }

    my %Response = $Self->_TokenRequest(
        URL  => $Config{TokenURL},
        Data => {
            client_id     => $Config{ClientID},
            client_secret => $Config{ClientSecret},
            scope         => $Self->{Scope},
            grant_type    => 'client_credentials',
        },
    );

    my $Content = $Response{Content} // '';
    my $Data;
    if ( $Content =~ m{ \A \s* \{ }xms ) {
        $Data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Content,
        );
    }
    if ( ref $Data ne 'HASH' ) {
        $Data = {};
    }

    if ( !$Response{StatusCode} || $Response{StatusCode} != 200 || !$Data->{access_token} ) {

        my $ErrorMessage = $Self->_ErrorMessageBuild(
            Response     => \%Response,
            Data         => $Data,
            ClientSecret => $Config{ClientSecret},
        );

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $ErrorMessage,
        );

        return (
            Success      => 0,
            ErrorMessage => $ErrorMessage,
        );
    }

    my $TTL = $Self->_CacheTTL(
        ExpiresIn => $Data->{expires_in},
    );
    if ($TTL) {
        $CacheObject->Set(
            Type          => $Self->{CacheType},
            Key           => $CacheKey,
            CacheInMemory => 0,
            Value         => $Data->{access_token},
            TTL           => $TTL,
        );
    }

    return (
        Success     => 1,
        AccessToken => $Data->{access_token},
    );
}

=head2 AccessTokenDelete()

removes cached access tokens, e. g. after a failed login

    $OAuth2Object->AccessTokenDelete();

=cut

sub AccessTokenDelete {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1;
}

=head2 XOAUTH2StringBuild()

returns the base64 encoded SASL XOAUTH2 string

    my $XOAUTH2String = $OAuth2Object->XOAUTH2StringBuild(
        User        => 'support@example.com',    # mailbox to log in to
        AccessToken => 'eyJ0eXAiOi...',
    );

=cut

sub XOAUTH2StringBuild {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(User AccessToken)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return undef;
        }
    }

    return encode_base64( "user=$Param{User}\x01auth=Bearer $Param{AccessToken}\x01\x01", '' );
}

sub _ConfigGet {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %Config;
    for my $Key (qw(TenantID ClientID ClientSecret)) {
        my $Value = $ConfigObject->Get("OAuth2::Microsoft::$Key") // '';

        # IDs are usually copied from the Entra admin center
        $Value =~ s{ \A \s+ | \s+ \z }{}xmsg;
        $Config{$Key} = $Value;
    }

    for my $Key (qw(TenantID ClientID ClientSecret)) {
        if ( !$Config{$Key} ) {
            return (
                ErrorMessage => "OAuth2: SysConfig setting 'OAuth2::Microsoft::$Key' is not configured.",
            );
        }
    }

    # tenant ID (GUID) or tenant domain, it becomes part of the token URL
    if ( $Config{TenantID} !~ m{ \A [A-Za-z0-9.-]+ \z }xms ) {
        return (
            ErrorMessage => "OAuth2: SysConfig setting 'OAuth2::Microsoft::TenantID' contains invalid characters.",
        );
    }

    ( $Config{TokenURL} = $Self->{TokenURL} ) =~ s{<TenantID>}{$Config{TenantID}}xmsg;

    return %Config;
}

sub _CacheTTL {
    my ( $Self, %Param ) = @_;

    return 0 if !defined $Param{ExpiresIn};
    return 0 if $Param{ExpiresIn} !~ m{ \A \d+ \z }xms;

    my $TTL = $Param{ExpiresIn} - $Self->{ExpiryMargin};

    return $TTL > 0 ? $TTL : 0;
}

sub _ErrorMessageBuild {
    my ( $Self, %Param ) = @_;

    my %Response = %{ $Param{Response} };
    my $Data     = $Param{Data};

    my $ErrorMessage;
    if ( $Data->{error} ) {

        # error_description continues with trace and correlation IDs, on further lines or on the same line
        my ($Description) = split m{\r?\n}xms, ( $Data->{error_description} // '' );
        $Description //= '';
        $Description =~ s{ \s* Trace \s ID: .* \z }{}xms;

        $ErrorMessage = sprintf(
            'OAuth2: Token request to Microsoft Entra failed (HTTP %s): %s: %s',
            $Response{StatusCode} // '-',
            $Data->{error},
            $Description // '',
        );
    }
    else {
        $ErrorMessage = sprintf(
            'OAuth2: Token request to Microsoft Entra failed (HTTP %s).',
            $Response{StatusLine} // $Response{StatusCode} // '-',
        );
    }

    if ( $Param{ClientSecret} ) {
        $ErrorMessage =~ s{\Q$Param{ClientSecret}\E}{[hidden]}xmsg;
    }

    return $ErrorMessage;
}

sub _TokenRequest {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Kernel::System::WebUserAgent drops the response body on errors,
    # but it contains the AADSTS error code we want to report.
    my $UserAgent = LWP::UserAgent->new(
        timeout  => $ConfigObject->Get('WebUserAgent::Timeout') || 15,
        agent    => ( $ConfigObject->Get('Product') // 'OFORK' ) . ' ' . ( $ConfigObject->Get('Version') // '' ),
        ssl_opts => { verify_hostname => 1 },
    );

    my $Proxy = $ConfigObject->Get('WebUserAgent::Proxy');
    if ($Proxy) {
        $UserAgent->proxy( [ 'http', 'https' ], $Proxy );
    }

    my $Response = $UserAgent->post( $Param{URL}, $Param{Data} );

    return (
        StatusCode => $Response->code(),
        StatusLine => $Response->status_line(),
        Content    => $Response->decoded_content() // '',
    );
}

1;
