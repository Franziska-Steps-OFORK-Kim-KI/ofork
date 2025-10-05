# --
# Kernel/Language/de_BookingSystem.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_BookingSystem.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_BookingSystem;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Room'} = 'Raum';
    $Self->{Translation}->{'Building'} = 'Gebäude';
    $Self->{Translation}->{'City'} = 'Stadt';
    $Self->{Translation}->{'New room'} = 'Neuer Raum';
    $Self->{Translation}->{'Room edit'} = 'Raum bearbeiten';
    $Self->{Translation}->{'Room category'} = 'Raum-Kategorie';
    $Self->{Translation}->{'Floor'} = 'Stockwerk/Lage';
    $Self->{Translation}->{'Post Code'} = 'PLZ';
    $Self->{Translation}->{'Set-up time'} = 'Vorbereitungs/Rüstzeit';
    $Self->{Translation}->{'In hours'} = 'In Stunden';
    $Self->{Translation}->{'Persons'} = 'Personen';
    $Self->{Translation}->{'Equipment bookable'} = 'Ausstattung buchbar';
    $Self->{Translation}->{'Equipment existing'} = 'Ausstattung vorhanden';
    $Self->{Translation}->{'Booking queue'} = 'Queue für Buchungen';
    $Self->{Translation}->{'Device queue'} = 'Queue für Geräte';
    $Self->{Translation}->{'Catering queue'} = 'Queue für Catering';
    $Self->{Translation}->{'Room add'} = 'Raum hinzufügen';
    $Self->{Translation}->{'Manage rooms'} = 'Räume verwalten';
    $Self->{Translation}->{'Room booking'} = 'Raum buchen';
    $Self->{Translation}->{'Equipment'} = 'Ausstattung';
    $Self->{Translation}->{'Bookingsystem rooms'} = 'Buchungssystem Räume';
    $Self->{Translation}->{'Booking system room management'} = 'Räume anlegen und verwalten';
    $Self->{Translation}->{'Create and manage booking system rooms.'} = 'Räume des Buchungssystem verwalten';
    $Self->{Translation}->{'Room categorys'} = 'Raum-Kategorien';
    $Self->{Translation}->{'Create and manage Room categorys'} = 'Raum-Kategorien verwalten';
    $Self->{Translation}->{'Room Icon'} = 'Raum Icon';
    $Self->{Translation}->{'Create and manage Room Icon'} = 'Raum-Icon verwalten';
    $Self->{Translation}->{'Room equipment'} = 'Auststattung der Räume';
    $Self->{Translation}->{'Create and manage room equipment'} = 'Auststattung der Räume verwalten';
    $Self->{Translation}->{'Room informations'} = 'Raum-Informationen';
    $Self->{Translation}->{'Device'} = 'Gerät';
    $Self->{Translation}->{'1 hour'} = 'pro Stunde';
    $Self->{Translation}->{'1 day'} = 'pro Tag';
    $Self->{Translation}->{'1 piece'} = 'pro Stück';
    $Self->{Translation}->{'flat-rate'} = 'pauschal';
    $Self->{Translation}->{'existing'} = 'vorhanden';
    $Self->{Translation}->{'bookable'} = 'buchbar';
    $Self->{Translation}->{'Price'} = 'Preis';
    $Self->{Translation}->{'Price for'} = 'Preis für';
    $Self->{Translation}->{'Currency'} = 'Währung';
    $Self->{Translation}->{'Bookable'} = 'buchbar oder vorhanden';
    $Self->{Translation}->{'Model'} = 'Modell';
    $Self->{Translation}->{'Quantity'} = 'Menge';
    $Self->{Translation}->{'Equipment type'} = 'Ausstattungstyp';
    $Self->{Translation}->{'Edit Equipment'} = 'Ausstattung bearbeiten';
    $Self->{Translation}->{'Equipment Management'} = 'Ausstattung verwalten';
    $Self->{Translation}->{'Add Equipment'} = 'Ausstattung hinzufügen';
    $Self->{Translation}->{'Room Category Management'} = 'Raum-Kategorien verwalten';
    $Self->{Translation}->{'Add room category'} = 'Raum-Kategorie hinzufügen';
    $Self->{Translation}->{'Room categories'} = 'Raum-Kategorien';
    $Self->{Translation}->{'Edit room category'} = 'Raum-Kategorie bearbeiten';
    $Self->{Translation}->{'Room description'} = 'Raumbeschreibung';
    $Self->{Translation}->{'Calendar language'} = 'Kalendersprache';
    $Self->{Translation}->{'Until'} = 'Bis';
    $Self->{Translation}->{'Number of participants'} = 'Teilnehmeranzahl';
    $Self->{Translation}->{'Participant'} = 'Teilnehmer';
    $Self->{Translation}->{'Topic'} = 'Thema';
    $Self->{Translation}->{'Appointment possible'} = 'Termin möglich ab';
    $Self->{Translation}->{'Rooms'} = 'Räume';
    $Self->{Translation}->{'Number'} = 'Anzahl';
    $Self->{Translation}->{'Invite participants'} = 'Teilnehmer einladen';
    $Self->{Translation}->{'Remarks'} = 'Bemerkungen';
    $Self->{Translation}->{'Delete list'} = 'Liste löschen';
    $Self->{Translation}->{'Date already occupied'} = 'Termin leider schon belegt.';
    $Self->{Translation}->{'Unfortunately, the room is already occupied for this date.'} = 'Zu diesem Termin ist der Raum leider schon belegt.';
    $Self->{Translation}->{'In the calendar overview you can see which appointments are possible.'} = 'In der Kalender Übersicht können Sie sehen welche Termine möglich sind.';
    $Self->{Translation}->{'The appointment is unfortunately outside the opening hours.'} = 'Der Termin liegt leider außerhalb der Öffnungszeiten.';
    $Self->{Translation}->{'Bookable times'} = 'Buchbare Zeiten';
    $Self->{Translation}->{'My bookings'} = 'Meine Buchungen';
    $Self->{Translation}->{'To edit or cancel click on booking.'} = 'Zum Bearbeiten oder Stornieren auf Buchung klicken.';
    $Self->{Translation}->{'Change room booking'} = 'Änderung Raumbuchung';
    $Self->{Translation}->{'Remarks'} = 'Bemerkungen';
    $Self->{Translation}->{'Book a room'} = 'Raumbuchung';
    $Self->{Translation}->{'Create your first booking'} = 'Erstellen Sie Ihre erste Buchung';
    $Self->{Translation}->{'Please click the button below to create your first booking.'} = 'Bitte klicken Sie auf die Schaltfläche unten, um Ihre erste Buchung zu erstellen.';
    $Self->{Translation}->{'Change booking'} = 'Buchung ändern';
    $Self->{Translation}->{'Cancel booking'} = 'Buchung stornieren';
    $Self->{Translation}->{'Cancel room booking'} = 'Buchung wurde storniert';
    $Self->{Translation}->{'Room bookings'} = 'Raumbuchungen';
    $Self->{Translation}->{'There are no bookings available'} = 'Es sind noch keine Buchungen vorhanden';
    $Self->{Translation}->{'AllRooms'} = 'Übersicht';
    $Self->{Translation}->{'RoomBooking'} = 'Raumbuchungen';
    $Self->{Translation}->{'Booking system Administration'} = 'Raumbuchungen Administration';
    $Self->{Translation}->{'Room booking evaluation.'} = 'Statistik Raumbuchungen';
    $Self->{Translation}->{'Room booking evaluation'} = 'Statistik Raumbuchungen';
    $Self->{Translation}->{'Room booking management'} = 'Übersicht Raumbuchungen';
    $Self->{Translation}->{'Equipment updated!'} = 'Ausstattung aktualisiert!';
    $Self->{Translation}->{'PostCode'} = 'Plz';
}

1;
