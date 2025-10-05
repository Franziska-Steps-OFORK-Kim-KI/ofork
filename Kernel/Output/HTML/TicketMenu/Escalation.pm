# --
# Kernel/Output/HTML/TicketMenu/Escalation.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: Escalation.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# ---
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::TicketMenu::Escalation;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::Config',
    'Kernel::System::Ticket',
    'Kernel::System::Group',
);

sub Run {
    my ( $Self, %Param ) = @_;

    # get log object
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    if ( !$Param{Ticket} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need Ticket!'
        );
        return;
    }

    # check if frontend module registered, if not, do not show action
    if ( $Param{Config}->{Action} ) {
        my $Module = $Kernel::OM->Get('Kernel::Config')->Get('Frontend::Module')->{ $Param{Config}->{Action} };
        return if !$Module;
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    return {
        %{ $Param{Config} },
        %{ $Param{Ticket} },
        %Param,
        Name        => Translatable('Escalation'),
        Description => Translatable('Escalation'),
        Link =>
            'Action=AgentTicketEscalation;Subaction=Escalation;TicketID=[% Data.TicketID | uri %];[% Env("ChallengeTokenParam") | html %]',
    };
}

1;
