# --
# Kernel/Language/de_OAuth2.pm
# Copyright (C) 2010-2026 OFORK, https://o-fork.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_OAuth2;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    # Templates
    $Self->{Translation}->{'Exchange Online (OAuth2)'}
        = 'Exchange Online (OAuth2)';
    $Self->{Translation}->{'Authentication'}
        = 'Anmeldung';
    $Self->{Translation}->{'OAuth2 (Exchange Online): no password is needed. The Entra app from %s is used.'}
        = 'OAuth2 (Exchange Online): Es wird kein Passwort benötigt. Verwendet wird die Entra-App aus %s.';
    $Self->{Translation}->{'Use the address of the mailbox as login and outlook.office365.com as host. The mailbox needs FullAccess for the Exchange service principal of the app (Add-MailboxPermission).'}
        = 'Als Benutzername die Adresse des Postfachs und als Host outlook.office365.com eintragen. Das Postfach braucht FullAccess für den Exchange-Service-Principal der App (Add-MailboxPermission).';
    $Self->{Translation}->{'Exchange Online with OAuth2: choose the type IMAPSOAuth2 or POP3SOAuth2 and set the Entra app in %s. For sending, set SendmailModule to SMTPTLSOAuth2.'}
        = 'Exchange Online mit OAuth2: Typ IMAPSOAuth2 oder POP3SOAuth2 wählen und die Entra-App in der %s einstellen. Für den Versand SendmailModule auf SMTPTLSOAuth2 setzen.';
    $Self->{Translation}->{'Used by the outbound mail type "Exchange Online (OAuth2)" and the inbound mail types IMAPSOAuth2 and POP3SOAuth2. Stored in the system configuration (group Core::Email::OAuth2). The Entra app needs the application permissions IMAP.AccessAsApp, POP.AccessAsApp (only for POP3) and SMTP.SendAsApp, and every mailbox needs FullAccess for its Exchange service principal.'}
        = 'Wird vom Versandtyp "Exchange Online (OAuth2)" und den Abruftypen IMAPSOAuth2 und POP3SOAuth2 verwendet und in der Systemkonfiguration (Gruppe Core::Email::OAuth2) gespeichert. Die Entra-App braucht die Anwendungsberechtigungen IMAP.AccessAsApp, POP.AccessAsApp (nur für POP3) und SMTP.SendAsApp, und jedes Postfach braucht FullAccess für ihren Exchange-Service-Principal.';
    $Self->{Translation}->{'Tenant ID'}
        = 'Tenant-ID';
    $Self->{Translation}->{'Directory (tenant) ID of the Microsoft Entra tenant.'}
        = 'Verzeichnis-ID (Tenant-ID) des Microsoft-Entra-Tenants.';
    $Self->{Translation}->{'Client ID'}
        = 'Client-ID';
    $Self->{Translation}->{'Application (client) ID of the Entra app registration.'}
        = 'Anwendungs-ID (Client-ID) der App-Registrierung in Entra.';
    $Self->{Translation}->{'Client secret'}
        = 'Geheimer Clientschlüssel';
    $Self->{Translation}->{'Value of the client secret of the Entra app registration.'}
        = 'Wert des geheimen Clientschlüssels der App-Registrierung in Entra.';

    # SysConfig
    $Self->{Translation}->{'Specifies the email address that should be used by the application when sending notifications. The email address is used to build the complete display name for the notification master (i.e. "OFORK Notifications" ofork@your.example.com). You can use the OFORK_CONFIG_FQDN variable as set in your configuation, or choose another email address. With "SMTPTLSOAuth2" (Exchange Online) this address must be a mailbox the Entra app has FullAccess to.'}
        = 'Legt die E-Mail-Adresse fest, die zum Versenden von E-Mails durch die Applikation verwendet werden soll. Die Adresse wird genutzt, um den vollständigen Anzeigenamen des Benachrichtigungs-Masters zu bilden (z. B. "OFORK Notifications ofork@your.example.com). Sie können die OFORK_CONFIG_FQDN-Variable nutzen, die Sie in der Konfiguration festgelegt haben, oder eine andere E-Mail-Adresse wählen. Bei "SMTPTLSOAuth2" (Exchange Online) muss diese Adresse ein Postfach sein, auf das die Entra-App FullAccess hat.';
    $Self->{Translation}->{'Application (client) ID of the Microsoft Entra app registration for Exchange Online with OAuth2. See "OAuth2::Microsoft::TenantID" for where it is used.'}
        = 'Anwendungs-ID (Client-ID) der App-Registrierung in Microsoft Entra für Exchange Online mit OAuth2. Wo sie verwendet wird, steht bei "OAuth2::Microsoft::TenantID".';
    $Self->{Translation}->{'Client secret (the value, not the secret ID) of the Microsoft Entra app registration for Exchange Online with OAuth2. See "OAuth2::Microsoft::TenantID" for where it is used.'}
        = 'Geheimer Clientschlüssel (der Wert, nicht die Geheimnis-ID) der App-Registrierung in Microsoft Entra für Exchange Online mit OAuth2. Wo er verwendet wird, steht bei "OAuth2::Microsoft::TenantID".';
    $Self->{Translation}->{'Tenant ID (or primary domain) of the Microsoft Entra tenant for Exchange Online with OAuth2 (client credentials, Modern Authentication). Used together with "OAuth2::Microsoft::ClientID" and "OAuth2::Microsoft::ClientSecret" by the mail account types "IMAPSOAuth2" and "POP3SOAuth2" (Admin > PostMaster Mail Accounts) and by the sendmail module "SMTPTLSOAuth2" (setting "SendmailModule"). Every mailbox used for fetching or as sender must have FullAccess for the Exchange service principal of the app, see doc/OAuth2-ExchangeOnline.md.'}
        = 'Tenant-ID (oder primäre Domain) des Microsoft-Entra-Tenants für Exchange Online mit OAuth2 (Client Credentials, Modern Authentication). Wird zusammen mit "OAuth2::Microsoft::ClientID" und "OAuth2::Microsoft::ClientSecret" von den Mailkonto-Typen "IMAPSOAuth2" und "POP3SOAuth2" (Admin > PostMaster E-Mail-Konten) und vom Versandmodul "SMTPTLSOAuth2" (Einstellung "SendmailModule") verwendet. Jedes Postfach, das abgerufen oder als Absender genutzt wird, braucht FullAccess für den Exchange-Service-Principal der App, siehe doc/OAuth2-ExchangeOnline.md.';
    $Self->{Translation}->{'If set, this address is used as envelope sender in outgoing messages (not notifications - see below). If no address is specified, the envelope sender is equal to queue e-mail address. Leave it empty with "SMTPTLSOAuth2" (Exchange Online): every mail would then authenticate as this one mailbox, and Exchange Online rejects mails whose sender is another address.'}
        = 'Wenn gesetzt, wird diese Adresse als Envelope-Sender-Header in ausgehenden Nachrichten (nicht Benachrichtigungen, siehe unten) genutzt. Ist keine Adresse angegeben, entspricht der Envelope-Sender der an der Queue hinterlegten E-Mail-Adresse. Bei "SMTPTLSOAuth2" (Exchange Online) leer lassen: Sonst meldet sich jede Mail als dieses eine Postfach an, und Exchange Online lehnt Mails mit einem anderen Absender ab.';
    $Self->{Translation}->{'Defines the module to send emails. "Sendmail" directly uses the sendmail binary of your operating system. Any of the "SMTP" mechanisms use a specified (external) mailserver. "SMTPTLSOAuth2" sends through Exchange Online with OAuth2 (Modern Authentication): the Entra app is set in "OAuth2::Microsoft::TenantID", "OAuth2::Microsoft::ClientID" and "OAuth2::Microsoft::ClientSecret" (group Core::Email::OAuth2), every mail authenticates as its sender mailbox, and "SendmailModule::AuthUser" and "SendmailModule::AuthPassword" are not used. "DoNotSendEmail" doesn\'t send emails and it is useful for test systems.'}
        = 'Legt das Modul zum Versenden von E-Mails fest. "Sendmail" nutzt das Sendmail-Binary Ihres Betriebssystems. Jeder der SMTP-Mechanismen nutzt einen zu definierenden (externen) Mailserver. "SMTPTLSOAuth2" versendet über Exchange Online mit OAuth2 (Modern Authentication): Die Entra-App wird in "OAuth2::Microsoft::TenantID", "OAuth2::Microsoft::ClientID" und "OAuth2::Microsoft::ClientSecret" (Gruppe Core::Email::OAuth2) eingestellt, jede Mail meldet sich als ihr Absender-Postfach an, und "SendmailModule::AuthUser" und "SendmailModule::AuthPassword" werden nicht verwendet. "DoNotSendEmail" versendet keine E-Mails und ist deshalb nützlich für Testsysteme.';
    $Self->{Translation}->{'If any of the "SMTP" mechanisms was selected as SendmailModule, and authentication to the mail server is needed, a password must be specified. Not used by "SMTPTLSOAuth2", which authenticates with the Entra app from "OAuth2::Microsoft::TenantID", "OAuth2::Microsoft::ClientID" and "OAuth2::Microsoft::ClientSecret".'}
        = 'Wenn einer der SMTP-Mechanismen als SendmailModule ausgewählt wurde und der Mailserver eine Anmeldung verlangt, muss hier ein Passwort angegeben werden. Wird von "SMTPTLSOAuth2" nicht verwendet; dieses meldet sich mit der Entra-App aus "OAuth2::Microsoft::TenantID", "OAuth2::Microsoft::ClientID" und "OAuth2::Microsoft::ClientSecret" an.';
    $Self->{Translation}->{'If any of the "SMTP" mechanisms was selected as SendmailModule, and authentication to the mail server is needed, an username must be specified. Not used by "SMTPTLSOAuth2", which authenticates with the Entra app from "OAuth2::Microsoft::TenantID", "OAuth2::Microsoft::ClientID" and "OAuth2::Microsoft::ClientSecret".'}
        = 'Wenn einer der SMTP-Mechanismen als SendmailModule ausgewählt wurde und der Mailserver eine Anmeldung verlangt, muss hier ein Benutzername angegeben werden. Wird von "SMTPTLSOAuth2" nicht verwendet; dieses meldet sich mit der Entra-App aus "OAuth2::Microsoft::TenantID", "OAuth2::Microsoft::ClientID" und "OAuth2::Microsoft::ClientSecret" an.';
    $Self->{Translation}->{'If any of the "SMTP" mechanisms was selected as SendmailModule, the mailhost that sends out the mails must be specified. For "SMTPTLSOAuth2" (Exchange Online) use smtp.office365.com.'}
        = 'Wenn einer der SMTP-Mechanismen als SendmailModule ausgewählt wurde, muss hier der Mailhost, der die Mails versendet, angegeben werden. Für "SMTPTLSOAuth2" (Exchange Online) smtp.office365.com verwenden.';
    $Self->{Translation}->{'If any of the "SMTP" mechanisms was selected as SendmailModule, the port where your mailserver is listening for incoming connections must be specified. For "SMTPTLSOAuth2" (Exchange Online) use 587.'}
        = 'Wenn einer der SMTP-Mechanismen als SendmailModule ausgewählt wurde, muss hier der Port angegeben werden, auf dem der Mailserver eingehende Verbindungen annimmt. Für "SMTPTLSOAuth2" (Exchange Online) 587 verwenden.';
    $Self->{Translation}->{'If set, this address is used as envelope sender header in outgoing notifications. If no address is specified, the envelope sender header is empty (unless SendmailNotificationEnvelopeFrom::FallbackToEmailFrom is set). With "SMTPTLSOAuth2" (Exchange Online) the address must be a mailbox released for the Entra app; if it is empty, the From address of the notification is used to authenticate.'}
        = 'Wenn gesetzt, wird diese Adresse als Envelope-Sender-Header in ausgehenden Benachrichtigungen genutzt. Ist keine Adresse angegeben, bleibt der Envelope-Sender-Header leer (außer SendmailNotificationEnvelopeFrom::FallbackToEmailFrom ist gesetzt). Bei "SMTPTLSOAuth2" (Exchange Online) muss die Adresse ein für die Entra-App freigegebenes Postfach sein; ist sie leer, meldet sich die Mail mit ihrer From-Adresse an.';

    # Admin > System Email Addresses, mailbox check
    $Self->{Translation}->{'Check mailbox'} = 'Postfach prüfen';
    $Self->{Translation}->{'Checking...'}   = 'Prüfe ...';
    $Self->{Translation}->{'Settings: %s and %s.'} = 'Einstellungen: %s und %s.';
    $Self->{Translation}->{'Outgoing mail is sent with OAuth2 (SendmailModule SMTPTLSOAuth2). Every address here sends as its own Exchange Online mailbox: it must be a mailbox with FullAccess for the Entra app and SMTP AUTH enabled. "Check mailbox" in the list verifies this without sending a mail.'}
        = 'Ausgehende Mails werden mit OAuth2 versendet (SendmailModule SMTPTLSOAuth2). Jede Adresse hier sendet als eigenes Exchange-Online-Postfach: Sie muss ein Postfach mit FullAccess für die Entra-App und eingeschaltetem SMTP AUTH sein. "Postfach prüfen" in der Liste prüft das, ohne eine Mail zu senden.';
    $Self->{Translation}->{'To send through Exchange Online with OAuth2, set SendmailModule to SMTPTLSOAuth2. Then every address here sends as its own Exchange Online mailbox.'}
        = 'Für den Versand über Exchange Online mit OAuth2 SendmailModule auf SMTPTLSOAuth2 setzen. Dann sendet jede Adresse hier als eigenes Exchange-Online-Postfach.';
    $Self->{Translation}->{'"%s" is not a valid email address.'} = '"%s" ist keine gültige E-Mail-Adresse.';
    $Self->{Translation}->{'Token received, application permissions: %s.'}
        = 'Token erhalten, Anwendungsberechtigungen: %s.';
    $Self->{Translation}->{'The Entra app has neither IMAP.AccessAsApp nor POP.AccessAsApp, so the mailbox access can\'t be checked.'}
        = 'Die Entra-App hat weder IMAP.AccessAsApp noch POP.AccessAsApp, deshalb lässt sich der Zugriff auf das Postfach nicht prüfen.';
    $Self->{Translation}->{'Mailbox is released for the Entra app (login via %s successful).'}
        = 'Postfach ist für die Entra-App freigegeben (Anmeldung per %s erfolgreich).';
    $Self->{Translation}->{'Mailbox is not released for the Entra app (login via %s failed: %s). Grant FullAccess with Add-MailboxPermission; right after a change, Exchange may need some time.'}
        = 'Postfach ist nicht für die Entra-App freigegeben (Anmeldung per %s fehlgeschlagen: %s). FullAccess mit Add-MailboxPermission vergeben; direkt nach einer Änderung braucht Exchange etwas Zeit.';
    $Self->{Translation}->{'The Entra app has no SMTP.SendAsApp, so OFORK can\'t send as this address.'}
        = 'Die Entra-App hat kein SMTP.SendAsApp, deshalb kann OFORK nicht als diese Adresse senden.';
    $Self->{Translation}->{'SMTP AUTH login successful.'} = 'SMTP-AUTH-Anmeldung erfolgreich.';
    $Self->{Translation}->{'SMTP AUTH login failed: %s. Enable it with Set-CASMailbox -SmtpClientAuthenticationDisabled $false.'}
        = 'SMTP-AUTH-Anmeldung fehlgeschlagen: %s. Mit Set-CASMailbox -SmtpClientAuthenticationDisabled $false einschalten.';

    push @{ $Self->{JavaScriptStrings} ||= [] }, (
        'Checking...',
    );

    return 1;
}

1;
