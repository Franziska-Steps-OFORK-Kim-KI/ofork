# --
# Kernel/Modules/AgentTicketEscalation.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AgentTicketEscalation.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketEscalation;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check needed stuff
    if ( !$Self->{TicketID} ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Can\'t lock Ticket, no TicketID is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # start with actions
    if ( $Self->{Subaction} eq 'Escalation' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
        my $SystemTime = $TimeObject->SystemTime();

        my $Success = $TicketObject->TicketEscalationSet(
            TicketID   => $Self->{TicketID},
            SystemTime => $SystemTime,
            UserID     => $Self->{UserID},
        );

    }

    # redirect
    return $LayoutObject->Redirect(
        OP => "Action=AgentTicketZoom;TicketID=$Self->{TicketID}",
    );
}

1;
