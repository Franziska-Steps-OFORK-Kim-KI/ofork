# --
# Kernel/Language/de_TimeTracking.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_TimeTracking.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_TimeTracking;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Time tracking category management'} = 'Zeiterfassung Kategorie erstellen und bearbeiten';
    $Self->{Translation}->{'Add time tracking category'} = 'Zeiterfassung Kategorie hinzufügen';
    $Self->{Translation}->{'Edit time tracking category'} = 'Zeiterfassung Kategorie bearbeiten';
    $Self->{Translation}->{'Time tracking'} = 'Zeiterfassung';
    $Self->{Translation}->{'Finish & close'} = 'Beenden & schließen';
    $Self->{Translation}->{'Amount'} = 'Anzahl';
    $Self->{Translation}->{'Total time units'} = 'Zeiteinheiten gesamt';
    $Self->{Translation}->{'Time tracking evaluation'} = 'Zeiterfassung Auswertung';
    $Self->{Translation}->{'Time tracking category'} = 'Zeiterfassung Kategorie';
    $Self->{Translation}->{'Create and manage time tracking category.'} = 'Zeiterfassung Kategorie erstellen und bearbeiten';
    $Self->{Translation}->{'Time tracking evaluation.'} = 'Zeiterfassung Auswertung.';
    $Self->{Translation}->{'Amount'} = 'Anzahl';
    $Self->{Translation}->{'Time tracking Administration'} = 'Zeiterfassung Administration';
    $Self->{Translation}->{'Category added!'} = 'Kategorie hinzugefügt!';
    $Self->{Translation}->{'Change time tracking'} = 'Veränderung Zeiterfassung';
    $Self->{Translation}->{'Only numbers are allowed.'} = 'Es sind nur Zahlen erlaubt.';
    $Self->{Translation}->{'Customer signature'} = 'Unterschrift';

}

1;
