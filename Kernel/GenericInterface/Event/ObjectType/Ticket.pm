# --
# Kernel/GenericInterface/Event/ObjectType/Ticket.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Ticket.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Event::ObjectType::Ticket;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

=head1 NAME

Kernel::GenericInterface::Event::ObjectType::Ticket - GenericInterface event data handler

=head1 SYNOPSIS

This event handler gathers data from objects.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub DataGet {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    for my $Needed (qw(Data)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $ID = $Param{Data}->{TicketID};

    if ( !$ID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need TicketID!",
        );
        return;
    }

    if (
        defined $Param{InvokerType}
        && $Param{InvokerType} eq 'Ticket::Generic'
        )
    {
        my %Ticket = $TicketObject->TicketDeepGet(
            TicketID => $ID,
            UserID   => 1,
        );
        return %Ticket;
    }

    my %ObjectData = $TicketObject->TicketGet(
        TicketID      => $ID,
        DynamicFields => 1,
        UserID        => 1,
        Silent        => 0,
        Extended      => 1,
    );

    return %ObjectData;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
