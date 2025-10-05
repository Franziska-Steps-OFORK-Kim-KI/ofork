# --
# Kernel/Language/de_Processes.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_Processes.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Processes;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Create and manage processes.'} = 'Prozesse erstellen und verwalten';
    $Self->{Translation}->{'Add process'} = 'Prozess hinzufügen';
    $Self->{Translation}->{'Work step'} = 'Prozess-Schritt'; 
    $Self->{Translation}->{'name of the process step'} = 'Name Prozess-Schritt';
    $Self->{Translation}->{'type of work step: '} = 'Typ Prozess-Schritt: ';
    $Self->{Translation}->{'Fields for the process step'} = 'Felder für den Schritt';
    $Self->{Translation}->{'Define the next step'} = 'Definiere den nächsten Schritt';
    $Self->{Translation}->{'Define the next step with conditions'} = 'Definiere den nächsten Schritt mit Bedingungen';
    $Self->{Translation}->{'Or end process'} = 'Oder Prozess beenden';
    $Self->{Translation}->{'type of step'} = 'Typ Prozess-Schritt';
    $Self->{Translation}->{'Next step without conditions'} = 'Nächster Schritt ohne Bedingungen';
    $Self->{Translation}->{'To next step'} = 'Zum nächsten Schritt';
    $Self->{Translation}->{'Next step with conditions'} = 'Nächster Schritt mit Bedingungen';
    $Self->{Translation}->{'Select if necessary'} = 'Auswählen, falls benötigt';
    $Self->{Translation}->{'Edit general information'} = 'Allgemeine Informationen bearbeiten';
    $Self->{Translation}->{'Create first process step'} = 'Ersten Prozess-Schritt erstellen';
    $Self->{Translation}->{'Number of fields: '} = 'Anzahl Felder: ';
    $Self->{Translation}->{'Edit process step'} = 'Prozess-Schritt bearbeiten';
    $Self->{Translation}->{'Approver group'} = 'Genehmigungs-Gruppe';
    $Self->{Translation}->{'Email to approvers'} = 'E-Mail an Genehmiger';
    $Self->{Translation}->{'Please enter the email(s) of the approver(s) separated by ;'} = 'Bitte die E-Mailadresse(n) getrennt durch ; hier eingeben.';
    $Self->{Translation}->{'Go to process overview'} = 'Zur Prozess-Übersicht';
    $Self->{Translation}->{'With conditions'} = 'Mit Bedingung';
    $Self->{Translation}->{'The process ends here'} = 'Der Prozess endet hier';
    $Self->{Translation}->{'Work step ends here without conditions'} = 'Der Prozess-Schritt endet hier ohne Bedingungen';
    $Self->{Translation}->{'Subject to approval'} = 'Genehmigungspflichtig';
    $Self->{Translation}->{'Not required with approval'} = 'Nicht benötigt';
    $Self->{Translation}->{'Define the next step if approved'} = 'Nächsten Schritt festlegen, falls genehmigt';
    $Self->{Translation}->{'Define the next step if not approved'} = 'Nächsten Schritt festlegen, falls nicht genehmigt';
    $Self->{Translation}->{'Next step if approved'} = 'Nächster Schritt, falls genehmigt';
    $Self->{Translation}->{'Next step if not approved'} = 'Nächster Schritt, falls nicht genehmigt';
    $Self->{Translation}->{'Type of approval'} = 'Art der Genehmigung';
    $Self->{Translation}->{'Transition action'} = 'Übergangsaktion';
    $Self->{Translation}->{'Not required if subject to approval'} = 'Nicht benötigt, wenn genehmigungspflichtig';
    $Self->{Translation}->{': The process step '} = ': Der Prozess-Schritt ';
    $Self->{Translation}->{' is not complete. Please inform your admin.'} = ' ist nicht vollständig. Bitte informieren Sie Ihren Admin.';
    $Self->{Translation}->{'Ends at not approved'} = 'Prozess endet mit nicht genehmigt';
    $Self->{Translation}->{'New form process ticket - NEWt'} = 'Neues Prozess-Formular';
    $Self->{Translation}->{'Approved'} = 'Genehmigt';
    $Self->{Translation}->{'Not approved'} = 'nicht genehmigt';
    $Self->{Translation}->{'Report'} = 'Bericht';
    $Self->{Translation}->{'Create new process ticket'} = 'Neues Prozess-Ticket erstellen';
    $Self->{Translation}->{'Process step '} = 'Prozess-Schritt ';
    $Self->{Translation}->{'Process: '} = 'Prozess: ';
    $Self->{Translation}->{'Customer has to approve'} = 'Kunde muss genehmigen';
    $Self->{Translation}->{'Ready'} = 'Fertig';
    $Self->{Translation}->{'Edit process'} = 'Prozess bearbeiten';
    $Self->{Translation}->{'Process step has ended'} = 'Prozess-Schritt ist beendet';
    $Self->{Translation}->{'Approval'} = 'Genehmigung';
    $Self->{Translation}->{'Process end'} = 'Prozessende';
    $Self->{Translation}->{'type of process step'} = 'Typ Prozess-Schritt';
    $Self->{Translation}->{': The process step '} = ': Der Prozess-Schritt ';
    $Self->{Translation}->{' is not complete. Please inform your admin'} = ' ist nicht komplett. Bitte informieren Sie Ihren Administrator.';
    $Self->{Translation}->{'Work step '} = 'Prozess-Schritt '; 
    $Self->{Translation}->{'Create new process ticket - NEW.'} = 'Prozess-Ticket erstellen - NEU'; 
    $Self->{Translation}->{'Create new process ticket - NEW'} = 'Prozess-Ticket erstellen - NEU'; 
    $Self->{Translation}->{'Process Management - New'} = 'Process Management - Neu'; 
    $Self->{Translation}->{'Next step'} = 'nächster Schritt'; 
    $Self->{Translation}->{'Should an article be created from each work step?'} = 'Sollte bei jedem Arbeitsschritt ein Artikel erstellt werden?'; 
    $Self->{Translation}->{'Should the text be transmitted from the previous work step?'} = 'Soll der Text aus dem vorherigen Arbeitsschritt übertragen werden?'; 
    $Self->{Translation}->{'Parallel step'} = 'Parallel Schritt'; 
    $Self->{Translation}->{'Agent notification'} = 'Agenten benachrichtigen'; 

}

1;
