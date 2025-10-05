# --
# Kernel/Language/de_CalendarResourcePlanning.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_CalendarResourcePlanning.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_CalendarResourcePlanning;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Resource Overview'} = 'Ressourcenübersicht';
    $Self->{Translation}->{'Manage Teams'} = 'Teams verwalten';
    $Self->{Translation}->{'Manage Team Agents'} = 'Team-Agenten verwalten';
    $Self->{Translation}->{'No teams found.'} = 'Keine Teams gefunden.';
    $Self->{Translation}->{'Please add a team first by using Manage Teams page.'} = 'Bitte erstellen Sie zuerst ein Team über die Teamverwaltungsseite.';
    $Self->{Translation}->{'No team agents found.'} = 'Keine Teamagenten gefunden.';
    $Self->{Translation}->{'Please assign agents to a team first by using Manage Team Agents page.'} = 'Bitte ordnen Sie einem Team über die Teamverwaltungsseite zunächst Agenten zu.';
    $Self->{Translation}->{'Add Team'} = 'Team hinzufügen';
    $Self->{Translation}->{'Team Import'} = 'Team-Import';
    $Self->{Translation}->{'Here you can upload a configuration file to import a team to your system. The file needs to be in .yml format as exported by team management module.'} = 'Hier können Sie eine Konfigurations-Datei zum Importieren eines Teams hochladen. Die Datei muss im .yml-Format vorliegen, so wie sie auch im Team-Verwaltungs-Modul exportiert wird.';
    $Self->{Translation}->{'Upload team configuration'} = 'Team-Konfiguration hochladen.';
    $Self->{Translation}->{'Import team'} = 'Team importieren';
    $Self->{Translation}->{'Filter for teams'} = 'Filter für Teams';
    $Self->{Translation}->{'Export team'} = 'Team exportieren';
    $Self->{Translation}->{'Edit Team'} = 'Team bearbeiten';
    $Self->{Translation}->{'Team with same name already exists.'} = 'Ein Team mit diesem Namen existiert bereits.';
    $Self->{Translation}->{'Filter for agents'} = 'Filter für Agenten';
    $Self->{Translation}->{'Teams'} = 'Teams';
    $Self->{Translation}->{'Manage Team-Agent Relations'} = 'Team-Agent-Beziehungen verwalten';
    $Self->{Translation}->{'Change Agent Relations for Team'} = 'Agenten-Beziehungen für Team verwalten';
    $Self->{Translation}->{'Change Team Relations for Agent'} = 'Team-Beziehungen für Agent verwalten';
    $Self->{Translation}->{'Shown resources'} = 'Angezeigte Ressourcen';
    $Self->{Translation}->{'Available Resources'} = 'Verfügbare Ressourcen';
    $Self->{Translation}->{'Filter available resources'} = '';
    $Self->{Translation}->{'Visible Resources (order by drag & drop)'} = 'Sichtbare Ressourcen (anordnen über Drag-&-Drop)';
    $Self->{Translation}->{'Need TeamID!'} = 'Benötige TeamID!';
    $Self->{Translation}->{'Invalid GroupID!'} = 'Ungültige GruppenID!';
    $Self->{Translation}->{'Couldn\'t read team configuration file. Please make sure you file is valid.'} = '';
    $Self->{Translation}->{'Could not import the team!'} = '';
    $Self->{Translation}->{'Team imported!'} = '';
    $Self->{Translation}->{'Could not retrieve data for given TeamID %s!'} = '';
    $Self->{Translation}->{'Unassigned'} = 'Nicht zugewiesen';
    $Self->{Translation}->{'is occupied during this period.'} = 'ist in diesem Zeitraum belegt.';
    $Self->{Translation}->{'Manage team agents.'} = '';
    $Self->{Translation}->{'Resource overview page.'} = 'Ressourcenübersicht-Seite';
    $Self->{Translation}->{'Resource overview screen.'} = 'Ressourcenübersicht-Bildschirm';
    $Self->{Translation}->{'Resources list.'} = 'Ressourcenliste';
    $Self->{Translation}->{'Team agents management screen.'} = '';
    $Self->{Translation}->{'Team list'} = '';
    $Self->{Translation}->{'Team management screen.'} = '';
    $Self->{Translation}->{'Team management.'} = '';
    $Self->{Translation}->{'If a ticket is to be created for this appointment, a notification must be entered below and the two following fields filled in, as well as a description above.'} = 'Wenn für diesen Termin ein Ticket erstellt werden soll, muss unten eine Benachrichtigung eingegeben und die beiden folgenden Felder ausgefüllt werden, sowie oben eine Beschreibung eingetragen werden.';

    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Available Resources',
    'Filter available resources',
    'Shown resources',
    'Visible Resources (order by drag & drop)',
    );
}

1;
