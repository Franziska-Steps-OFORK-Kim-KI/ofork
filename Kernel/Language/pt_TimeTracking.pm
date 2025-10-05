# --
# Kernel/Language/pt_TimeTracking.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: pt_TimeTracking.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::pt_TimeTracking;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Time tracking category management'} = '';
    $Self->{Translation}->{'Add time tracking category'} = '';
    $Self->{Translation}->{'Edit time tracking category'} = '';
    $Self->{Translation}->{'Time tracking'} = '';
    $Self->{Translation}->{'Finish & close'} = '';
    $Self->{Translation}->{'Amount'} = '';
    $Self->{Translation}->{'Total time units'} = '';
    $Self->{Translation}->{'Time tracking evaluation'} = '';
    $Self->{Translation}->{'Time tracking category'} = '';
    $Self->{Translation}->{'Create and manage time tracking category.'} = '';
    $Self->{Translation}->{'Time tracking evaluation.'} = '';
    $Self->{Translation}->{'Amount'} = '';
    $Self->{Translation}->{'Time tracking Administration'} = '';
    $Self->{Translation}->{'Category added!'} = '';
    $Self->{Translation}->{'Change time tracking'} = '';
    $Self->{Translation}->{'Only numbers are allowed.'} = '';

}

1;
