# --
# Kernel/System/Calendar/Event/TicketAppointments.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: TicketAppointments.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Calendar::Event::TicketAppointments;

use strict;
use warnings;

use parent qw(Kernel::System::AsynchronousExecutor);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Calendar',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Event Data Config UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !$Param{Data}->{AppointmentID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need AppointmentID in Data!',
        );
        return;
    }

    # loop protection: prevent from running if update was triggered by the ticket update
    if (
        $Kernel::OM->Get('Kernel::System::Calendar')
        ->{'_TicketAppointments::TicketUpdate'}
        ->{ $Param{Data}->{AppointmentID} }++
        )
    {
        return;
    }

    # run only on ticket appointments (get ticket id)
    my $TicketID = $Kernel::OM->Get('Kernel::System::Calendar')->TicketAppointmentTicketID(
        AppointmentID => $Param{Data}->{AppointmentID},
    );
    return if !$TicketID;

    # update ticket in an asynchronous call
    return $Self->AsyncCall(
        ObjectName     => 'Kernel::System::Calendar',
        FunctionName   => 'TicketAppointmentUpdateTicket',
        FunctionParams => {
            AppointmentID => $Param{Data}->{AppointmentID},
            TicketID      => $TicketID,
        },
    );
}

1;
