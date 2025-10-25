# --
# Kernel/Modules/AgentProcessTicketSelection.pm - to handle process ticket selection
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AgentProcessTicketSelection.pm,v 1.21 2016/11/20 19:35:56 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentProcessTicketSelection;

use strict;
use warnings;

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

    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessesObject = $Kernel::OM->Get('Kernel::System::Processes');

    # get params
    my %GetParam;
    for my $Key (qw( ID TicketID)) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    if ( !$Self->{Subaction} ) {

        # print form ...
        my $Output .= $LayoutObject->Header();
        $Output    .= $LayoutObject->NavigationBar();
        $Output    .= $Self->_MaskNew(
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'StoreNew' ) {

        my %Error;

        # check subject
        if ( !$GetParam{ID} ) {
            $Error{ID} = 'ServerError';
        }

        if (%Error) {

            # html output
            my $Output .= $LayoutObject->Header();
            $Output    .= $LayoutObject->NavigationBar();
            $Output    .= $Self->_MaskNew(
                %GetParam,
                Errors => \%Error,
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        if ( $GetParam{TicketID} ) {

            my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
            my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');

            my %Ticket = $TicketObject->TicketGet( TicketID => $GetParam{TicketID} );

            my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                User => $Ticket{CustomerUserID},
            );

            # redirect
            return $LayoutObject->Redirect(
                OP => "Action=AgentProcessTicket;ID=$GetParam{ID};FromTicketID=$GetParam{TicketID};Subaction=StoreNew;ChallengeToken=$Self->{UserChallengeToken};CustomerSelected=1;CustomerKey_1=$Ticket{CustomerUserID};SelectedCustomerUser=$Ticket{CustomerUserID};CustomerID=$Ticket{CustomerID};CustomerTicketCounterFromCustomer=1;ExpandCustomerName=3",
            );
        }
        else {

            # redirect
            return $LayoutObject->Redirect(
                OP => "Action=AgentProcessTicket;ID=$GetParam{ID};FromTicketID=$GetParam{TicketID}",
            );
        }
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessesObject = $Kernel::OM->Get('Kernel::System::Processes');

    my %Processes = $ProcessesObject->ProcessesList(
        Valid => 1,
    );

    if ( %Processes ) {

        $Param{ProcessesStrg} = $LayoutObject->BuildSelection(
            Data         => \%Processes,
            Name         => 'ID',
            SelectedID   => $Param{ID},
            PossibleNone => 1,
            Translation  => 0,
            Max          => 200,
        );

        $LayoutObject->Block(
            Name => 'Processes',
            Data => \%Param,
        );

    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentProcessTicketSelection',
        Data         => \%Param,
    );
}

1;
