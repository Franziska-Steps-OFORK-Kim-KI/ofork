# --
# Kernel/Language/de_KPI.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_KPI.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_KPI;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Hide filters'} = 'Filter ausblenden';
    $Self->{Translation}->{'Do not use date fields'} = 'Datum-Felder nicht benutzen';
    $Self->{Translation}->{'Starting year created/closed tickets per year'} = 'Start-Jahr erstellte/geschlossene Tickets pro Jahr';
    $Self->{Translation}->{'Remove filter'} = 'Filter entfernen';
}

1;
