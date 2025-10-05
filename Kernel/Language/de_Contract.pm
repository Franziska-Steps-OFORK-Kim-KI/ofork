# --
# Kernel/Language/de_Contract.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_Contract.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Contract;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Payment method'} = 'Zahlungsweise';
    $Self->{Translation}->{'Notice period'} = 'Kündigungsfrist';
    $Self->{Translation}->{'monthly'} = 'monatlich';
    $Self->{Translation}->{'quarterly'} = 'vierteljährlich';
    $Self->{Translation}->{'half-yearly'} = 'halbjährlich';
    $Self->{Translation}->{'yearly'} = 'jährlich';
    $Self->{Translation}->{'1 - monthly'} = 'monatlich';
    $Self->{Translation}->{'2 - quarterly'} = 'vierteljährlich';
    $Self->{Translation}->{'3 - half-yearly'} = 'halbjährlich';
    $Self->{Translation}->{'4 - yearly'} = 'jährlich';
    $Self->{Translation}->{'In days'} = 'In Tagen';
    $Self->{Translation}->{'Ticket create'} = 'Ticket erstellen';
    $Self->{Translation}->{'Licenses or Number of devices'} = 'Lizenzen oder Geräteanzahl';
    $Self->{Translation}->{'Edit licenses or number of devices'} = 'Lizenzen oder Geräteanzahl bearbeiten';
    $Self->{Translation}->{'total - '} = 'gesamt - ';
    $Self->{Translation}->{'in use - '} = 'in Gebrauch - ';
    $Self->{Translation}->{'Licenses or device'} = 'Lizenz oder Gerät';
    $Self->{Translation}->{'Memory'} = 'Erinnerung';
    $Self->{Translation}->{'Before the notice period in days'} = 'Vor der Kündigungsfrist in Tagen';
    $Self->{Translation}->{'Manage Contract'} = 'Verträge anlegen und bearbeiten';
    $Self->{Translation}->{'outgoing'} = 'ausgehend';
    $Self->{Translation}->{'incoming'} = 'eingehend';
    $Self->{Translation}->{'Contract add'} = 'Vertrag hinzufügen';
    $Self->{Translation}->{'Contract number'} = 'Vertragsnummer';
    $Self->{Translation}->{'Contract direction'} = 'Richtung';
    $Self->{Translation}->{'Contract type'} = 'Vertragsart';
    $Self->{Translation}->{'Contractual partner'} = 'Vertragspartner';
    $Self->{Translation}->{'Contract start'} = 'Beginn';
    $Self->{Translation}->{'Contract end'} = 'Ende';
    $Self->{Translation}->{'Contract edit'} = 'Vertrag bearbeiten';
    $Self->{Translation}->{'New Contract'} = 'Neuen Vertrag anlegen';
    $Self->{Translation}->{'Handover to'} = 'Übergabe an';
    $Self->{Translation}->{'License or device name'} = 'Lizenz- oder Gerätename';
    $Self->{Translation}->{'Number of licenses or devices'} = 'Anzahl Lizenzen oder Geräte';
    $Self->{Translation}->{'Create ticket if less than'} = 'Ticket erstellen bei Anzahl';
    $Self->{Translation}->{'Back to overview'} = 'Zurück zur Übersicht';
    $Self->{Translation}->{'consumed'} = 'verbraucht';
    $Self->{Translation}->{'available | '} = 'verfügbar | ';
    $Self->{Translation}->{'available'} = 'verfügbar';
    $Self->{Translation}->{'Used'} = 'verbraucht';
    $Self->{Translation}->{'Available'} = 'verfügbar';
    $Self->{Translation}->{'To the contract'} = 'Zum Vertrag';
    $Self->{Translation}->{'Reminder contract expiration for contract number '} = 'Erinnerung Vertragsablauf zu Vertragsnummer ';
    $Self->{Translation}->{'Reminder minimum number '} = 'Erinnerung Mindestanzahl ';
    $Self->{Translation}->{' fell short of contract number '} = ' unterschritten bei Vertragsnummer ';
    $Self->{Translation}->{'Contract type management.'} = 'Vertragsarten Verwaltung';
    $Self->{Translation}->{'Contract type management'} = 'Vertragsarten Verwaltung';
    $Self->{Translation}->{'Contract Type Management'} = 'Vertragsarten Verwaltung';
    $Self->{Translation}->{'Contract Management'} = 'Vertragsverwaltung';
    $Self->{Translation}->{'Contract'} = 'Verträge';
    $Self->{Translation}->{'Add Contract Type'} = 'Vertragsart hinzufügen';
    $Self->{Translation}->{'Contract type'} = 'Vertragsart';
    $Self->{Translation}->{'Manage contractual partner'} = 'Vertragspartner verwalten';
    $Self->{Translation}->{'Contractual partner add'} = 'Vertragspartner hinzufügen';
    $Self->{Translation}->{'Company'} = 'Firma';
    $Self->{Translation}->{'Contact person'} = 'Kontaktperson';
    $Self->{Translation}->{'Contract Type'} = 'Vertragsart';
    $Self->{Translation}->{'Sub contract type of'} = 'Untervertragsart von';
    $Self->{Translation}->{'Enter handover'} = 'Übergabe eingeben';

}

1;
