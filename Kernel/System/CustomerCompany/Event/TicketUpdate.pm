# --
# Kernel/System/CustomerCompany/Event/TicketUpdate.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: TicketUpdate.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::CustomerCompany::Event::TicketUpdate;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
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
    for (qw( Data Event Config UserID )) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }
    for (qw( CustomerID OldCustomerID )) {
        if ( !$Param{Data}->{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_ in Data!"
            );
            return;
        }
    }

    # only update if CustomerID has really changed
    return 1 if $Param{Data}->{CustomerID} eq $Param{Data}->{OldCustomerID};

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # create ticket object and perform search
    my @Tickets = $TicketObject->TicketSearch(
        Result        => 'ARRAY',
        Limit         => 100_000,
        CustomerIDRaw => $Param{Data}->{OldCustomerID},
        ArchiveFlags  => [ 'y', 'n' ],
        UserID        => 1,
    );

    # update the customer ID of tickets
    for my $TicketID (@Tickets) {
        $TicketObject->TicketCustomerSet(
            No       => $Param{Data}->{CustomerID},
            TicketID => $TicketID,
            UserID   => $Param{UserID},
        );
    }

    return 1;
}

1;
