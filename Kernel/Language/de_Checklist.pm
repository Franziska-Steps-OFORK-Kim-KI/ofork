# --
# Kernel/Language/de_Checklist.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_Checklist.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Checklist;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Checklist'} = 'Checkliste';
    $Self->{Translation}->{'Not required'} = 'Nicht benötigt';
    $Self->{Translation}->{'from'} = 'von';
    $Self->{Translation}->{'Checklists'} = 'Checklisten';
    $Self->{Translation}->{'Create and manage Checklists.'} = 'Checklisten erstellen und bearbeiten.';
    $Self->{Translation}->{'Checklist edit'} = 'Checkliste bearbeiten';
    $Self->{Translation}->{'bearbeiten'} = 'Artikel erstellen';
    $Self->{Translation}->{'Checklists management'} = 'Checklisten erstellen und bearbeiten';
    $Self->{Translation}->{'Checklist add'} = 'Checkliste erstellen';
    $Self->{Translation}->{'Task assign'} = 'Aufgabe zuweisen';
    $Self->{Translation}->{'Task'} = 'Aufgabe';
    $Self->{Translation}->{'New checklist'} = 'Neue Checkliste';
    $Self->{Translation}->{'The task '} = 'Die Aufgabe ';
    $Self->{Translation}->{' has been completed.'} = ' wurde fertig gestellt.';
    $Self->{Translation}->{' is not needed.'} = ' wird nicht benötigt.';
    $Self->{Translation}->{'Checklist edit'} = 'Checkliste bearbeiten';
    $Self->{Translation}->{'Set article'} = 'Artikel erzeugen';
    $Self->{Translation}->{'Checklists Administration'} = 'Checklisten Administration';

}

1;
