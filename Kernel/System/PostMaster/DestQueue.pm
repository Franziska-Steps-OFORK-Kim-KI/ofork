# --
# Kernel/System/PostMaster/DestQueue.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: DestQueue.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PostMaster::DestQueue;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Queue',
    'Kernel::System::SystemAddress',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get parser object
    $Self->{ParserObject} = $Param{ParserObject} || die "Got no ParserObject!";

    # Get communication log object.
    $Self->{CommunicationLogObject} = $Param{CommunicationLogObject} || die "Got no CommunicationLogObject!";

    return $Self;
}

sub GetQueueID {
    my ( $Self, %Param ) = @_;

    # get email headers
    my %GetParam = %{ $Param{Params} };

    # check possible to, cc and resent-to emailaddresses
    my $Recipient = '';
    RECIPIENT:
    for my $Key (qw(Resent-To Envelope-To To Cc Delivered-To X-Original-To)) {

        next RECIPIENT if !$GetParam{$Key};

        if ($Recipient) {
            $Recipient .= ', ';
        }

        $Recipient .= $GetParam{$Key};
    }

    # get system address object
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');

    # get addresses
    my @EmailAddresses = $Self->{ParserObject}->SplitAddressLine( Line => $Recipient );

    # check addresses
    EMAIL:
    for my $Email (@EmailAddresses) {

        next EMAIL if !$Email;

        my $Address = $Self->{ParserObject}->GetEmailAddress( Email => $Email );

        next EMAIL if !$Address;

        # lookup queue id if recipiend address
        my $QueueID = $SystemAddressObject->SystemAddressQueueID(
            Address => $Address,
        );

        if ($QueueID) {
            $Self->{CommunicationLogObject}->ObjectLog(
                ObjectLogType => 'Message',
                Priority      => 'Debug',
                Key           => ref($Self),
                Value         => "Match email: $Email to QueueID $QueueID (MessageID:$GetParam{'Message-ID'})!",
            );

            return $QueueID;
        }

        # Address/Email not matched with any that is configured in the system
        #   or any error occured while checking it.

        $Self->{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Debug',
            Key           => ref($Self),
            Value         => "No match for email: $Email (MessageID:$GetParam{'Message-ID'})!",
        );
    }

    # If we get here means that none of the addresses in the message is defined as a system address
    #   or an error occured while checking it.

    my $Queue   = $Kernel::OM->Get('Kernel::Config')->Get('PostmasterDefaultQueue');
    my $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup(
        Queue => $Queue,
    );

    if ($QueueID) {
        $Self->{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Debug',
            Key           => ref($Self),
            Value         => "MessageID:$GetParam{'Message-ID'} to 'PostmasterDefaultQueue' ( QueueID:${QueueID} ).",
        );

        return $QueueID;
    }

    $Self->{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Error',
        Key           => ref($Self),
        Value         => "Couldn't get QueueID for 'PostmasterDefaultQueue' (${Queue}) !",
    );

    $Self->{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Debug',
        Key           => ref($Self),
        Value         => "MessageID:$GetParam{'Message-ID'} to QueueID:1!",
    );

    return 1;
}

sub GetTrustedQueueID {
    my ( $Self, %Param ) = @_;

    # get email headers
    my %GetParam = %{ $Param{Params} };

    return if !$GetParam{'X-OFORK-Queue'};

    $Self->{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Debug',
        Key           => 'Kernel::System::PostMaster::DestQueue',
        Value         => "Existing X-OFORK-Queue header: $GetParam{'X-OFORK-Queue'} (MessageID:$GetParam{'Message-ID'})!",
    );

    # get dest queue
    return $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup(
        Queue => $GetParam{'X-OFORK-Queue'},
    );
}

1;
