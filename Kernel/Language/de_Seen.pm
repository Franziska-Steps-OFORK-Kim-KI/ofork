# --
# Kernel/Language/de_Seen.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# $Id: de_Seen.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Seen;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    # SysConfig
    $Self->{Translation}->{"Defines the config parameters available in the preferences view. The default redirect URL from SysConfig 'MarkTicketUnseenRedirectDefaultURL' is used if no selection is made by the agent."}
        = "Definiert die zur Verfügung stehenden Konfigurationsparameter in der Einstellungsansicht. Der Standard-Umleitungs-URL der SysConfig-Einstellung 'MarkTicketUnseenRedirectDefaultURL' wird verwendet, falls der Agent keine Auswahl getroffen hat.";
    $Self->{Translation}->{"Defines the redirect URL for setting a ticket article to 'unseen'."}
        = "Definiert den URL, zu dem umgeleitet wird, nachdem ein Artikel auf 'ungelesen' gesetzt wurde.";
    $Self->{Translation}->{"Defines the config parameters available in the preferences view. The default redirect URL from SysConfig 'MarkTicketSeenRedirectDefaultURL' is used if no selection is made by the agent."}
        = "Definiert die zur Verfügung stehenden Konfigurationsparameter in der Einstellungsansicht. Der Standard-Umleitungs-URL der SysConfig-Einstellung 'MarkTicketSeenRedirectDefaultURL' wird verwendet, falls der Agent keine Auswahl getroffen hat.";
    $Self->{Translation}->{"Defines the redirect URL for setting a ticket article to 'seen'."}
        = "Definiert den URL, zu dem umgeleitet wird, nachdem ein Artikel auf 'gelesen' gesetzt wurde.";
    $Self->{Translation}->{'Registers a link in the ticket menu to mark a ticket as unseen.'}
        = 'Registriert einen Link im Ticketmenü, um ein Ticket als ungelesen zu markieren.';
    $Self->{Translation}->{'Registers a link in the ticket menu to mark a ticket as seen.'}
        = 'Registriert einen Link im Ticketmenü, um ein Ticket als gelesen zu markieren.';
    $Self->{Translation}->{'Registers a link in the ticket menu of ticket overviews to mark all articles of the ticket as unseen.'}
        = 'Registriert einen Link im Ticketmenü von Ticketübersichten, um ein Ticket als ungelesen zu markieren.';
    $Self->{Translation}->{'Registers a link in the ticket menu of ticket overviews to mark all articles of the ticket as seen.'}
        = 'Registriert einen Link im Ticketmenü von Ticketübersichten, um ein Ticket als gelesen zu markieren.';
    $Self->{Translation}->{"Registers an output filter that adds a 'Mark article as unseen' link to the article menu."}
        = 'Registriert einen Output-Filter, der einen Link zur Markierung eines Artikels als ungelesen zum Artikelmenü hinzufügt.';
    $Self->{Translation}->{"Registers an output filter that adds the 'Mark tickets as unseen' selection to the bulk view."}
        = 'Registriert einen Output-Filter, der die Auswahl für als ungelesen zu markierende Tickets zur Sammelaktion-Ansicht hinzufügt.';
    $Self->{Translation}->{'Mark ticket article(s) as (un)seen'}
        = 'Ticketartikel als (un)gelesen markieren';
    $Self->{Translation}->{'Mark ticket as (un)seen'}
        = 'Ticket als (un)gelesen markieren';
    $Self->{Translation}->{'Screen after marking as seen'}
        = 'Ansicht nachdem als gelesen markiert wurde';
    $Self->{Translation}->{'Configure which screen should be shown after marking a ticket or article as seen.'} = 'Konfigurieren Sie, welche Oberfläche angezeigt werden soll, nachdem ein Ticket oder Artikel als gelesen markiert wurde.';
    $Self->{Translation}->{'Screen after marking as unseen'}
        = 'Ansicht nachdem als ungelesen markiert wurde';
    $Self->{Translation}->{'Configure which screen should be shown after marking a ticket or article as unseen.'} = 'Konfigurieren Sie, welche Oberfläche angezeigt werden soll, nachdem ein Ticket oder Artikel als ungelesen markiert wurde.';
    $Self->{Translation}->{'Mark as unseen'} = 'Ungelesen markieren';
    $Self->{Translation}->{'Mark as seen'} = 'Als gelesen markieren';
    $Self->{Translation}->{'Mark ticket as unseen'} = 'Ticket als ungelesen markieren';
    $Self->{Translation}->{'Mark ticket as seen'} = 'Ticket als gelesen markieren';
    $Self->{Translation}->{'Last viewed screen'} = 'Zuletzt angesehene Aktion';
    $Self->{Translation}->{'Last viewed overview'} = 'Zuletzt angesehene Ansicht';

    # Templates and output filters
    $Self->{Translation}->{'Mark article as unseen'} = 'Artikel als ungelesen markieren';
    $Self->{Translation}->{'Mark tickets as seen'} = 'Tickets als gelesen markieren';
    $Self->{Translation}->{'Mark tickets as unseen'} = 'Tickets als ungelesen markieren';

    return 1;
}

1;
