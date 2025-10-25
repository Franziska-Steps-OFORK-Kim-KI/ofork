# --
# Kernel/System/PostMaster/Filter/DetectBounceEmail.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: DetectBounceEmail.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PostMaster::Filter::DetectBounceEmail;

use strict;
use warnings;

use Sisimai::Data;
use Sisimai::Message;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{ParserObject} = $Param{ParserObject} || die "Got no ParserObject";

    # Get communication log object.
    $Self->{CommunicationLogObject} = $Param{CommunicationLogObject} || die "Got no CommunicationLogObject!";

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # Ensure that the flag X-OFORK-Bounce doesn't exist if we didn't analysed it yet.
    delete $Param{GetParam}->{'X-OFORK-Bounce'};

    $Self->{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Debug',
        Key           => ref($Self),
        Value         => 'Checking if is a Bounce e-mail.',
    );

    my $BounceMessage = Sisimai::Message->new( data => $Self->{ParserObject}->GetPlainEmail() );

    return 1 if !$BounceMessage;

    my $BounceData = Sisimai::Data->make( data => $BounceMessage );

    return 1 if !$BounceData || !@{$BounceData};

    my $MessageID = $BounceData->[0]->messageid();

    return 1 if !$MessageID;

    $MessageID = sprintf '<%s>', $MessageID;

    $Param{GetParam}->{'X-OFORK-Bounce'}                   = 1;
    $Param{GetParam}->{'X-OFORK-Bounce-OriginalMessageID'} = $MessageID;
    $Param{GetParam}->{'X-OFORK-Bounce-ErrorMessage'}      = $Param{GetParam}->{Body};
    $Param{GetParam}->{'X-OFORK-Loop'}                     = 1;

    $Self->{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Debug',
        Key           => ref($Self),
        Value         => sprintf(
            'Detected Bounce for e-mail "%s"',
            $MessageID,
        ),
    );

    return 1;
}

1;
