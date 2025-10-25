# --
# Kernel/Output/HTML/ToolBar/TicketSearchFulltext.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: TicketSearchFulltext.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ToolBar::TicketSearchFulltext;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

sub Run {
    my ( $Self, %Param ) = @_;

    my $Priority = $Param{Config}->{'Priority'};
    my %Return   = ();
    $Return{ $Priority++ } = {
        Block       => $Param{Config}->{Block},
        Description => $Param{Config}->{Description},
        Name        => $Param{Config}->{Name},
        Size        => $Param{Config}->{Size},
        Fulltext    => '',
        Image       => '',
        AccessKey   => '',
    };
    return %Return;
}

1;
