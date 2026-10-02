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

use Kernel::System::Email::SMTPTLSOAuth2;
use MIME::Base64 qw(decode_base64);

my $OAuth2Object = $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftClientCredentials');

# token module mock
my %TokenResult;
my $TokenDeleted;
{
    no warnings 'redefine';    ## no critic
    *Kernel::System::OAuth2::MicrosoftClientCredentials::AccessTokenGet    = sub { return %TokenResult };
    *Kernel::System::OAuth2::MicrosoftClientCredentials::AccessTokenDelete = sub { $TokenDeleted = 1; return 1 };
}

# communication log mock
my @LogEntries;
my $CommunicationLogObject = bless {}, 'Test::SMTPTLSOAuth2::CommunicationLog';
{
    no strict 'refs';    ## no critic
    *{'Test::SMTPTLSOAuth2::CommunicationLog::ObjectLog'} = sub {
        my ( $Self, %Param ) = @_;
        push @LogEntries, "$Param{Priority}: $Param{Value}";
        return 1;
    };
}

# SMTP mock with the same calling convention as _GetSMTPSafeWrapper()
my ( @Calls, @Responses, $Debug, @DebugDuringCommands );
my $SMTP = sub {
    my ( $Operation, @Params ) = @_;
    push @Calls, [ $Operation, @Params ];
    if ( $Operation eq 'debug' ) {
        my $Old = $Debug;
        $Debug = $Params[0] if @Params;
        return $Old;
    }
    if ( $Operation eq 'command' ) {
        push @DebugDuringCommands, $Debug;
        return 1;
    }
    return shift @Responses if $Operation eq 'response';
    return '535' if $Operation eq 'code';
    return "5.7.3 Authentication unsuccessful\n" if $Operation eq 'message';
    return 1;
};

my $SendObject = Kernel::System::Email::SMTPTLSOAuth2->new();

my $Run = sub {
    my %Param = @_;
    ( @Calls, @LogEntries, @DebugDuringCommands ) = ();
    $TokenDeleted = 0;
    $Debug        = 1;
    @Responses    = @{ $Param{Responses} || [] };
    return $SendObject->_Authenticate(
        SMTP                   => $SMTP,
        CommunicationLogObject => $CommunicationLogObject,
        From                   => $Param{From},
    );
};

%TokenResult = ( Success => 1, AccessToken => 'TOKEN-1' );

# success, address in angle brackets and upper case letters
my %Result = $Run->( From => '<Support@Example.COM>', Responses => [ 3, 2 ] );
$Self->True( $Result{Success}, 'Authentication succeeds after 334 and 235' );
my @CommandCalls = grep { $_->[0] eq 'command' } @Calls;
$Self->Is( $CommandCalls[0]->[1], 'AUTH XOAUTH2', 'First command is AUTH XOAUTH2' );
$Self->Is(
    decode_base64( $CommandCalls[1]->[1] ),
    "user=support\@example.com\x01auth=Bearer TOKEN-1\x01\x01",
    'Second command is the XOAUTH2 string for the bare, lower case sender address',
);
$Self->IsDeeply( \@DebugDuringCommands, [ 0, 0 ], 'SMTP debug output is off while authenticating' );
$Self->Is( $Debug, 1, 'SMTP debug setting is restored' );
$Self->False( $TokenDeleted, 'Token is kept after success' );
$Self->False(
    ( ( join "\n", @LogEntries ) =~ m{TOKEN-1} ) ? 1 : 0,
    'Token does not appear in the communication log',
);

# server rejects the credentials
%Result = $Run->( From => 'support@example.com', Responses => [ 3, 5 ] );
$Self->False( $Result{Success}, 'Authentication fails on 535' );
$Self->Is( $Result{Code}, '535', 'SMTP code is returned' );
$Self->True( ( ( $Result{ErrorMessage} // '' ) =~ m{support\@example\.com} ) ? 1 : 0, 'Error message names the sender' );
$Self->True( ( ( $Result{ErrorMessage} // '' ) =~ m{Add-MailboxPermission} ) ? 1 : 0, 'Error message points to the mailbox permission' );
$Self->True( $TokenDeleted, 'Token is deleted after failed authentication' );
$Self->Is( $Debug, 1, 'SMTP debug setting is restored after failure' );

# server does not offer XOAUTH2
%Result = $Run->( From => 'support@example.com', Responses => [5] );
$Self->False( $Result{Success}, 'Authentication fails if AUTH XOAUTH2 is rejected' );
@CommandCalls = grep { $_->[0] eq 'command' } @Calls;
$Self->Is( scalar @CommandCalls, 1, 'XOAUTH2 string is not sent if AUTH XOAUTH2 is rejected' );

# token request fails
%TokenResult = ( Success => 0, ErrorMessage => 'OAuth2: SysConfig setting \'OAuth2::Microsoft::TenantID\' is not configured.' );
%Result = $Run->( From => 'support@example.com' );
$Self->False( $Result{Success}, 'Authentication fails without token' );
$Self->True( ( ( $Result{ErrorMessage} // '' ) =~ m{TenantID} ) ? 1 : 0, 'Token error is passed on' );
$Self->Is( scalar( grep { $_->[0] eq 'command' } @Calls ), 0, 'No SMTP command without token' );

# connection check without sender: token is requested, no SMTP authentication
%TokenResult = ( Success => 1, AccessToken => 'TOKEN-1' );
%Result = $Run->( From => '' );
$Self->True( $Result{Success}, 'Check without sender succeeds when the token can be requested' );
$Self->Is( scalar( grep { $_->[0] eq 'command' } @Calls ), 0, 'No SMTP command without sender' );

# sending (RequireFrom is set by Send()) without sender
%Result = $SendObject->_Authenticate(
    SMTP                   => $SMTP,
    CommunicationLogObject => $CommunicationLogObject,
    From                   => '',
    RequireFrom            => 1,
);
$Self->False( $Result{Success}, 'Sending without sender fails' );
$Self->True( ( ( $Result{ErrorMessage} // '' ) =~ m{sender}i ) ? 1 : 0, 'Error message mentions the missing sender' );

# Send(): empty envelope sender (Loop mails) falls back to the From: header
{
    no warnings 'redefine';    ## no critic
    local *Kernel::System::Email::SMTPTLSOAuth2::Check = sub {
        my ( $Class, %Param ) = @_;
        my %Auth = $Class->_Authenticate( %Param, SMTP => $SMTP, CommunicationLogObject => $CommunicationLogObject );
        return ( %Auth, SMTP => $SMTP );
    };

    my $Send = sub {
        my %Param = @_;
        ( @Calls, @LogEntries, @DebugDuringCommands ) = ();
        $Debug     = 1;
        @Responses = ( 3, 2 );
        my $Header = $Param{Header};
        my $Body   = "Body\n";
        return $SendObject->Send(
            From                   => $Param{From},
            ToArray                => ['customer@example.org'],
            Header                 => ref $Header ? $Header : \$Header,
            Body                   => \$Body,
            CommunicationLogObject => $CommunicationLogObject,
        );
    };

    my $Header = "Subject: Test\nFrom: \"Support\" <Support\@Example.com>\nReply-To: other\@example.com\nTo: customer\@example.org\n";
    my $Sent   = $Send->( From => '', Header => $Header );
    @CommandCalls = grep { $_->[0] eq 'command' } @Calls;
    $Self->True( $Sent->{Success} ? 1 : 0, 'Send with empty envelope and From header succeeds' );
    $Self->Is(
        decode_base64( $CommandCalls[1]->[1] // '' ),
        "user=support\@example.com\x01auth=Bearer TOKEN-1\x01\x01",
        'Empty envelope sender: XOAUTH2 user is the address of the From header',
    );
    my ($MailFrom) = grep { $_->[0] eq 'mail' } @Calls;
    $Self->Is( $MailFrom->[1], 'Support@Example.com', 'Empty envelope sender: MAIL FROM is the address of the From header' );

    # folded header, lower case field name, Resent-From and Reply-To must not match
    $Header = "Resent-From: wrong\@example.com\nreply-to: wrong2\@example.com\nfrom:\n Support Team\n <folded\@example.com>\nSubject: X\n";
    $Sent   = $Send->( From => '', Header => $Header );
    ($MailFrom) = grep { $_->[0] eq 'mail' } @Calls;
    $Self->Is( $MailFrom->[1], 'folded@example.com', 'Folded, lower case From header is parsed' );

    # envelope sender wins over the header
    $Header = "From: header\@example.com\nSubject: X\n";
    $Sent   = $Send->( From => 'envelope@example.com', Header => $Header );
    ($MailFrom) = grep { $_->[0] eq 'mail' } @Calls;
    $Self->Is( $MailFrom->[1], 'envelope@example.com', 'A given envelope sender is not replaced by the header' );

    # neither envelope sender nor From header
    $Header = "Reply-To: wrong\@example.com\nSubject: X\n";
    $Sent   = $Send->( From => '', Header => $Header );
    $Self->False( $Sent->{Success} ? 1 : 0, 'Send without envelope sender and From header fails' );
    $Self->True( ( ( $Sent->{ErrorMessage} // '' ) =~ m{no envelope sender}i ) ? 1 : 0, 'Error mentions the missing envelope sender' );
    $Self->Is( scalar( grep { $_->[0] eq 'command' } @Calls ), 0, 'No SMTP command without any sender' );
}

# _GetSMTPSafeWrapper must not log parameters of auth/command calls
{
    my $FakeSMTP = bless {}, 'Test::SMTPTLSOAuth2::FakeSMTP';
    {
        no strict 'refs';    ## no critic
        *{'Test::SMTPTLSOAuth2::FakeSMTP::command'} = sub { die "boom\n" };
        *{'Test::SMTPTLSOAuth2::FakeSMTP::auth'}    = sub { die "boom\n" };
        *{'Test::SMTPTLSOAuth2::FakeSMTP::to'}      = sub { die "boom\n" };
    }

    my @SystemLog;
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    {
        no warnings 'redefine';    ## no critic
        no strict 'refs';    ## no critic
        local *{ ref($LogObject) . '::Log' } = sub {
            my ( $Class, %Param ) = @_;
            push @SystemLog, $Param{Message};
            return 1;
        };

        my $Wrapper = $SendObject->_GetSMTPSafeWrapper( SMTP => $FakeSMTP );
        $Wrapper->( 'command', 'SECRET-XOAUTH2-STRING' );
        $Wrapper->( 'auth',    'user', 'SECRET-PASSWORD' );
        $Wrapper->( 'to',      'rcpt@example.org' );
    }

    $Self->Is( scalar @SystemLog, 3, 'Each failed SMTP call is logged' );
    $Self->False(
        ( ( join "\n", @SystemLog ) =~ m{SECRET} ) ? 1 : 0,
        'Parameters of command and auth calls are not logged',
    );
    $Self->True( ( ( $SystemLog[0] // '' ) =~ m{SMTP->command\(\[hidden\]\)} ) ? 1 : 0, 'Hidden marker is logged instead' );
    $Self->True( ( ( $SystemLog[2] // '' ) =~ m{rcpt\@example\.org} ) ? 1 : 0, 'Parameters of other calls are still logged' );
}

1;
