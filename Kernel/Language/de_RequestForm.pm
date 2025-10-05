# --
# Kernel/Language/de_RequestForm.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_RequestForm.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_RequestForm;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Subject changeable'} = 'Betreff änderbar';
    $Self->{Translation}->{'Request categories'} = 'Formular Kategorien';
    $Self->{Translation}->{'Create and manage request categories.'} = 'Formular-Kategorien erstellen und bearbeiten';
    $Self->{Translation}->{'Request form management'} = 'Formulare erstellen und bearbeiten';
    $Self->{Translation}->{'Create and manage request forms.'} = 'Formulare erstellen und bearbeiten';
    $Self->{Translation}->{'Request fields'} = 'Formularfelder';
    $Self->{Translation}->{'Create and manage request fields.'} = 'Formularfelder erstellen und bearbeiten';
    $Self->{Translation}->{'Manage requests.'} = 'Formulare erstellen und bearbeiten';
    $Self->{Translation}->{'Request add'} = 'Formular hinzufügen';
    $Self->{Translation}->{'Request'} = 'Formular';
    $Self->{Translation}->{'New Request'} = 'Neues Formular';
    $Self->{Translation}->{'Request edit'} = 'Formular bearbeiten';
    $Self->{Translation}->{'Request category'} = 'Formular Kategorie';
    $Self->{Translation}->{'Field assign'} = 'Feld zuweisen';
    $Self->{Translation}->{'Required field'} = 'Pflichtfeld';
    $Self->{Translation}->{'Headline assign'} = 'Überschrift zuweisen';
    $Self->{Translation}->{'Headline'} = 'Überschrift';
    $Self->{Translation}->{'Description of headline'} = 'Beschreibung zur Überschrift';
    $Self->{Translation}->{'Request: '} = 'Formular: ';
    $Self->{Translation}->{'Order edit'} = 'Reihenfolge ändern';
    $Self->{Translation}->{'Request Category Management'} = 'Kategorien erstellen und bearbeiten';
    $Self->{Translation}->{'Add request category'} = 'Kategorie hinzufügen';
    $Self->{Translation}->{'Sub request category of'} = 'Unterkategorie von';
    $Self->{Translation}->{'Edit request category'} = 'Kategorie bearbeiten';
    $Self->{Translation}->{'Approval'} = 'Genehmigungspflichtig';
    $Self->{Translation}->{'Add RequestCategory'} = 'Kategorie hinzufügen';
    $Self->{Translation}->{'Requestform Administration'} = 'Formular Administration';
    $Self->{Translation}->{'Fiels edit'} = 'Feld bearbeiten';
    $Self->{Translation}->{'New Field'} = 'Neues Feld';
    $Self->{Translation}->{'Tool-Tip direct under fieldname'} = 'Tool-Tip direkt unter Feldnamen';
    $Self->{Translation}->{'Categories'} = 'Kategorien';
    $Self->{Translation}->{'Requests'} = 'Anträge';
    $Self->{Translation}->{'Subcategories'} = 'Unterkategorien';
    $Self->{Translation}->{'Request Icon'} = 'Formular Icon';
    $Self->{Translation}->{'Create and manage Request Icon.'} = 'Formular-Icons erstellen und bearbeiten';
    $Self->{Translation}->{'Add Icon'} = 'Icon hinzufügen';
    $Self->{Translation}->{'Edit Icon'} = 'Icon bearbeiten';
    $Self->{Translation}->{'No subcategories available'} = 'Keine Unterkategorien verfügbar';
    $Self->{Translation}->{'No requests available'} = 'Keine Anträge verfügbar';
    $Self->{Translation}->{'New standard Ticket'} = 'Neues Standard-Ticket';
    $Self->{Translation}->{'No subject yet'} = 'Kein Betreff vorhanden';
    $Self->{Translation}->{'New article'} = 'Neuer Artikel';
    $Self->{Translation}->{'New search'} = 'Neue Suche';
    $Self->{Translation}->{'Customer User ↔ Request Groups'} = 'Kundenbenutzer ↔ Formulargruppen';
    $Self->{Translation}->{'Link customer users to request groups.'} = 'Kundenbenutzer zu Formulargruppen zuordnen';
    $Self->{Translation}->{'Request Groups'} = 'Formulargruppen';
    $Self->{Translation}->{'Create and manage request groups.'} = 'Formulargruppen erstellen und bearbeiten';
    $Self->{Translation}->{'View the admin manual on OFORK'} = 'Administratorhandbuch auf OFORK';
    $Self->{Translation}->{'Request group'} = 'Formulargruppe';
    $Self->{Translation}->{'Show ConfigItem'} = 'Zeige CMDB Items';
    $Self->{Translation}->{'Ticket type'} = 'Ticket Typ';
    $Self->{Translation}->{'Request Field Management'} = 'Formularfelder erstellen und bearbeiten';
    $Self->{Translation}->{'Group Form Management'} = 'Formulargruppen';
    $Self->{Translation}->{'Request Form Management'} = 'Formulare erstellen und bearbeiten';
    $Self->{Translation}->{'Icon Management'} = 'Icons verwalten';
    $Self->{Translation}->{'Filter for Icons'} = 'Filter für Icons';
    $Self->{Translation}->{'Hint'} = 'Tipp';
    $Self->{Translation}->{'Create new form ticket.'} = 'Neues Formularticket erstellen';
    $Self->{Translation}->{'New form ticket'} = 'Neues Formularticket';
    $Self->{Translation}->{'Please specify a customer for the ticket.'} = 'Bitte geben Sie einen Kunden für das Ticket an.';
    $Self->{Translation}->{'Headline edit'} = 'Überschrift bearbeiten';
    $Self->{Translation}->{'Problem with '} = 'Problem mit ';
    $Self->{Translation}->{'Manage request fields'} = 'Antragsfelder verwalten';
    $Self->{Translation}->{'Add request field'} = 'Antragsfeld hinzufügen';
    $Self->{Translation}->{'New request field'} = 'Neues Antragsfeld';
    $Self->{Translation}->{'Edit request field'} = 'Antragsfeld bearbeiten';
    $Self->{Translation}->{'Text field'} = 'Textfeld';  
    $Self->{Translation}->{'Name of database field'} = 'Name Datenbankfeld';  
    $Self->{Translation}->{'Must be clear and must only consist of letters and numbers.'} = 'Muss eindeutig sein und darf nur aus Buchstaben und Zahlen bestehen.';  
    $Self->{Translation}->{'This name will be shown in the request form as the labeling of the respective field.'} = 'Dieser Name wird auf dem Antrag als Feld-Labeling angezeigt.';  
    $Self->{Translation}->{'Default value'} = 'Defaultwert';  
    $Self->{Translation}->{'Text area field'} = 'TextArea-Feld';  
    $Self->{Translation}->{'Number of lines'} = 'Anzahl der Zeilen';  
    $Self->{Translation}->{'Shows the number of lines for this field.'} = 'Gibt die Anzahl der Zeilen für dieses Feld an.';  
    $Self->{Translation}->{'Number of columns'} = 'Anzahl der Spalten';  
    $Self->{Translation}->{'Shows the width of this field in letters.'} = 'Gibt die Breite in Zeichen für dieses Feld an.';  
    $Self->{Translation}->{'Dropdown field'} = 'Dropdownfeld';  
    $Self->{Translation}->{'Add or delete value'} = 'Wert hinzufügen/löschen';  
    $Self->{Translation}->{'Add empty value'} = 'Leeren Wert hinzufügen';  
    $Self->{Translation}->{'Next'} = 'Weiter';  
    $Self->{Translation}->{'Multiselect field'} = 'MultiSelect-Feld';  
    $Self->{Translation}->{'Date field'} = 'Datumsfeld';  
    $Self->{Translation}->{'Checkbox field'} = 'Checkbox-Feld';  
    $Self->{Translation}->{'Database value: '} = 'Datenbank-Wert: ';  
    $Self->{Translation}->{'Value shown: '} = 'Angezeigter Wert: ';  
    $Self->{Translation}->{'Add value'} = 'Wert hinzufügen';  
    $Self->{Translation}->{'Delete value'} = 'Wert löschen';  
    $Self->{Translation}->{'edit'} = 'bearbeiten';  
    $Self->{Translation}->{'Request Field ↔ Templates'} = 'Formularfeld ↔ Vorlagen';
    $Self->{Translation}->{'Link request field to templates.'} = 'Formularfelder zu Vorlagen zuordnen.';
    $Self->{Translation}->{'Request Field'} = 'Formularfeld';
    $Self->{Translation}->{'Filter for Request Field'} = 'Filter für  Formularfeld';
    $Self->{Translation}->{'Date short'} = 'Datum kurz';  

}

1;
