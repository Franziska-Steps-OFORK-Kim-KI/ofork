# --
# Kernel/Language/pt_Checklist.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: pt_Checklist.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::pt_Checklist;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Checklist'} = '';
    $Self->{Translation}->{'Not required'} = '';
    $Self->{Translation}->{'from'} = '';
    $Self->{Translation}->{'Checklists'} = '';
    $Self->{Translation}->{'Create and manage Checklists.'} = '';
    $Self->{Translation}->{'Checklist edit'} = '';
    $Self->{Translation}->{'bearbeiten'} = '';
    $Self->{Translation}->{'Checklists management'} = '';
    $Self->{Translation}->{'Checklist add'} = '';
    $Self->{Translation}->{'Task assign'} = '';
    $Self->{Translation}->{'Task'} = '';
    $Self->{Translation}->{'New checklist'} = '';
    $Self->{Translation}->{'The task '} = '';
    $Self->{Translation}->{' has been completed.'} = '';
    $Self->{Translation}->{' is not needed.'} = '';
    $Self->{Translation}->{'Checklist edit'} = '';
    $Self->{Translation}->{'Set article'} = '';
    $Self->{Translation}->{'Checklists Administration'} = '';

}

1;
