# --
# Kernel/System/Calendar/Event/Transport/NotificationView.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: NotificationView.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Calendar::Event::Transport::NotificationView;

use strict;
use warnings;

use parent qw(Kernel::System::Calendar::Event::Transport::Base);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::NotificationView',
    'Kernel::System::Calendar',
    'Kernel::System::Calendar::Appointment',
);

=head1 NAME

Kernel::System::Calendar::Event::Transport::NotificationView - notification view transport layer for appointment notifications

=head1 DESCRIPTION

Notification event transport layer.

=head1 PUBLIC INTERFACE


=head2 new()

create a notification transport object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new('');
    my $TransportObject = $Kernel::OM->Get('Kernel::System::Calendar::Event::Transport::NotificationView');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub SendNotification {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(UserID Notification Recipient)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Need $Needed!',
            );
            return;
        }
    }

    # Cleanup event data.
    $Self->{EventData} = undef;

    # Check to see if we received appointment or calendar ID.
    my $ObjectID;
    my $ObjectType;
    if ( $Param{AppointmentID} ) {
        $ObjectID   = $Param{AppointmentID};
        $ObjectType = 'Appointment';
    }
    elsif ( $Param{CalendarID} ) {
        $ObjectID   = $Param{CalendarID};
        $ObjectType = 'Calendar';
    }
    return if !$ObjectID;

    # Get recipient data.
    my %Recipient = %{ $Param{Recipient} };

    return if $Recipient{Type} eq 'Customer';
    return if !$Recipient{UserID};

    my $ObjectReference;
    if ( $Param{AppointmentID} ) {
        my %Appointment = $Kernel::OM->Get('Kernel::System::Calendar::Appointment')->AppointmentGet(
            AppointmentID => $Param{AppointmentID},
        );
        return if !$Appointment{Title};

        $ObjectReference = $Appointment{Title};
    }
    elsif ( $Param{CalendarID} ) {
        my %Calendar = $Kernel::OM->Get('Kernel::System::Calendar')->CalendarGet(
            CalendarID => $Param{CalendarID},
        );
        return if !$Calendar{CalendarName};

        $ObjectReference = $Calendar{CalendarName};
    }

    my %Notification = %{ $Param{Notification} };

    my $NotificationID = $Kernel::OM->Get('Kernel::System::NotificationView')->NotificationAdd(
        Name            => $Notification{Name},
        Comment         => $Notification{Comment} || '',
        Subject         => $Notification{Subject},
        Body            => $Notification{Body},
        ObjectType      => $ObjectType,
        ObjectID        => $ObjectID,
        ObjectReference => $ObjectReference,
        UserID          => $Recipient{UserID},
        UserType        => $Recipient{Type},
    );

    if ( !$NotificationID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "'$Notification{Name}' notification could not be added to agent '$Recipient{UserID}' ",
        );

        return;
    }

    return 1;
}

sub GetTransportRecipients {
    my ( $Self, %Param ) = @_;

    return;
}

sub TransportSettingsDisplayGet {
    my ( $Self, %Param ) = @_;

    return;
}

sub TransportParamSettingsGet {
    my ( $Self, %Param ) = @_;

    return 1;
}

sub IsUsable {
    my ( $Self, %Param ) = @_;

    return 1;
}

1;
