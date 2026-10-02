# OAuth2 mit Exchange Online

OFORK ruft Postfächer in Exchange Online per IMAP ab und versendet per SMTP. Beide Wege melden sich mit OAuth 2.0 an. Grundlage ist die Microsoft-Dokumentation
[Authenticate an IMAP, POP or SMTP connection using OAuth](https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth),
Abschnitt „Use client credentials grant flow to authenticate SMTP, IMAP, and POP connections“. Die Schritte 1 bis 3 folgen diesem Abschnitt.

## Was Sie damit festlegen

1. **Einrichtung nach Microsoft-Dokumentation.** Es wird kein eigener Weg verwendet: App-Registrierung, `New-ServicePrincipal` und `Add-MailboxPermission` wie bei Microsoft beschrieben.
2. **Shared Mailboxes brauchen keine Lizenz**, solange sie die Grenzen unten einhalten. OFORK meldet sich als App an, nicht als Benutzer.
3. **Die App erhält Zugriff nur auf die Postfächer, die OFORK nutzt, und auf nichts sonst.** Dafür gilt:
   - In Entra nur die Berechtigungen, die gebraucht werden: `IMAP.AccessAsApp` (Abruf per IMAP), `POP.AccessAsApp` (nur bei Abruf per POP3) und `SMTP.SendAsApp` (Versand).
   - In Exchange `FullAccess` je OFORK-Postfach, an den Service Principal der App.
   - Kein `SendAs`, keine Graph-Berechtigungen `Mail.*`, kein `EWS.AccessAsApp`.
   - Mit den Prüfbefehlen in Abschnitt 4 lässt sich das jederzeit nachweisen.

### Lizenz für Shared Mailboxes

Nach Microsoft ([About shared mailboxes](https://learn.microsoft.com/en-us/microsoft-365/admin/email/about-shared-mailboxes), [Exchange Online limits](https://learn.microsoft.com/en-us/office365/servicedescriptions/exchange-online-service-description/exchange-online-limits#mailbox-storage-limits)) braucht eine Shared Mailbox keine eigene Lizenz, mit diesen Ausnahmen:

- mehr als 50 GB Inhalt (Exchange Online Plan 2 nötig, dann 100 GB),
- Archivpostfach (In-Place Archiving),
- Litigation Hold,
- Zusatzfunktionen wie Microsoft Defender for Office 365, eDiscovery (Premium) oder Aufbewahrungsrichtlinien, soweit dafür eine Lizenz verlangt wird.

Ein normales Benutzerpostfach (`UserMailbox`) ist dagegen ein lizenziertes Benutzerkonto. Die Anleitung funktioniert für beide Arten.

## Wie es funktioniert

- OFORK meldet sich als App an (Client Credentials). Es meldet sich kein Benutzer an.
- Die App kommt nur in Postfächer, für die in Exchange ausdrücklich `FullAccess` an ihren Service Principal vergeben wurde.
- Beim Abruf meldet sich OFORK als das Postfach an, das im Mailkonto als Login steht.
- Beim Versand meldet sich OFORK pro Mail als der Absender (Envelope-From) an. Jede Absenderadresse muss also ein freigegebenes Postfach sein.

## Voraussetzungen

- Perl-Module: `Mail::IMAPClient` ab 3.33, `IO::Socket::SSL`, `LWP::Protocol::https` (`bin/ofork.CheckModules.pl`).
- Ausgehende Verbindungen von OFORK zu `login.microsoftonline.com:443`, `outlook.office365.com:993` (IMAP) bzw. `outlook.office365.com:995` (POP3) und `smtp.office365.com:587`.
- Rollen: Anwendungsadministrator (oder höher) in Entra für die App-Registrierung und die Admin-Zustimmung; Exchange-Administrator für die PowerShell-Schritte (liefert `New-ServicePrincipal` einen Fehler, fehlen laut Microsoft meist Rechte in Exchange Online).

## 1. App in Entra registrieren

1. Entra Admin Center → **App registrations** → **New registration**.
   Name z. B. `OFORK Mail`, **Accounts in this organizational directory only**. Keine Redirect URI.
2. Auf der Übersicht notieren: **Application (client) ID** und **Directory (tenant) ID**.
3. **Certificates & secrets** → **New client secret**. Laufzeit wählen, Wert sofort kopieren (er wird nur einmal angezeigt). Ablaufdatum im Kalender eintragen.
4. **API permissions** → **Add a permission** → **APIs my organization uses** → **Office 365 Exchange Online** → **Application permissions**:
   - `IMAP.AccessAsApp`, wenn OFORK per IMAP abruft (Typ `IMAPSOAuth2`)
   - `POP.AccessAsApp`, nur wenn OFORK per POP3 abruft (Typ `POP3SOAuth2`)
   - `SMTP.SendAsApp` für den Versand (`SMTPTLSOAuth2`)
5. Die standardmäßig eingetragene Graph-Berechtigung `User.Read` entfernen. **Keine** weiteren Berechtigungen hinzufügen, insbesondere keine Graph-Berechtigungen `Mail.*` und kein `EWS.AccessAsApp`. Solche Berechtigungen gälten, wenn nicht eigens eingeschränkt, für alle Postfächer im Tenant.
6. **Grant admin consent for <Tenant>** klicken (bei einer App nur für den eigenen Tenant genügt dafür die Seite der App-Konfiguration).

## 2. Service Principal in Exchange registrieren

Die IDs stammen aus **Enterprise applications** (nicht aus App registrations): Entra Admin Center → **Enterprise applications** → `OFORK Mail` → **Application ID** und **Object ID**.

```powershell
Install-Module -Name ExchangeOnlineManagement
Connect-ExchangeOnline

New-ServicePrincipal -AppId <Application ID> -ObjectId <Object ID aus Enterprise applications> -DisplayName "OFORK Mail"
```

Mit der Object-ID aus „App registrations“ schlägt die Anmeldung später fehl (Microsoft weist ausdrücklich darauf hin).

## 3. Postfächer freigeben

Den Service Principal einmal laden und dessen `Identity` für die Rechtevergabe verwenden, so wie es Microsoft im Beispiel zeigt:

```powershell
$SP = Get-ServicePrincipal -Identity "OFORK Mail"
```

Für **jedes** Postfach, das OFORK abruft oder als Absender nutzt:

```powershell
Add-MailboxPermission -Identity "support@example.com" -User $SP.Identity -AccessRights FullAccess -AutoMapping $false
```

`-AutoMapping $false` verhindert, dass das Postfach in Outlook-Profile eingehängt wird. Für eine App ist das ohne Bedeutung, aber unschädlich.

Falls SMTP AUTH im Tenant oder für das Postfach abgeschaltet ist, für die Absender-Postfächer einschalten. Die Einstellung pro Postfach hat Vorrang vor der Einstellung im Tenant ([Microsoft](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission)); der Tenant kann also abgeschaltet bleiben:

```powershell
Get-TransportConfig | Format-List SmtpClientAuthenticationDisabled
Get-CASMailbox -Identity "support@example.com" | Format-List SmtpClientAuthenticationDisabled
Set-CASMailbox -Identity "support@example.com" -SmtpClientAuthenticationDisabled $false
```

Ist die Einstellung im Tenant `True` und soll das auch so bleiben, genügt der `Set-CASMailbox`-Aufruf je Absender-Postfach. Sind in Entra die „Security defaults“ aktiv, ist SMTP AUTH nach Microsoft schon deshalb abgeschaltet.

`SendAs` (`Add-RecipientPermission`) wird **nicht** vergeben. OFORK meldet sich immer als das Absender-Postfach selbst an. Microsoft verlangt `SendAs` nur, wenn mit einem Konto angemeldet und von einer anderen Adresse gesendet wird.

Bis die Rechte greifen, kann es dauern. Microsoft nennt in der Dokumentation zu `Add-MailboxPermission` und zum OAuth-Ablauf keinen festen Wert. Planen Sie nach einer Änderung etwas Wartezeit ein (nach Erfahrung Minuten bis wenige Stunden) und wiederholen Sie den Test.

## 4. Freigaben prüfen

Ziel: Der Service Principal hat genau auf die Postfächer Rechte, die in OFORK als Mailkonto oder Absenderadresse eingetragen sind, und sonst nirgends.

**a) Berechtigungen der App in Entra.** Enterprise applications → `OFORK Mail` → **Permissions**: Es dürfen nur die Einträge aus Schritt 1 stehen, also `IMAP.AccessAsApp` und/oder `POP.AccessAsApp` sowie `SMTP.SendAsApp` (API Office 365 Exchange Online). Alles andere entfernen.

**b) FullAccess in Exchange.** Die Liste muss genau zu den Mailkonten und Absenderadressen in OFORK passen:

```powershell
$SP   = Get-ServicePrincipal -Identity "OFORK Mail"
$Keys = @($SP.Identity, $SP.ObjectId, $SP.AppId, $SP.DisplayName) | Where-Object { $_ } | ForEach-Object { "$_" }

Get-EXOMailbox -ResultSize Unlimited | ForEach-Object {
    $Mailbox = $_.PrimarySmtpAddress
    Get-EXOMailboxPermission -Identity $_.UserPrincipalName |
        Where-Object {
            $User = "$($_.User)"
            -not $_.IsInherited -and ($Keys | Where-Object { $User -like "*$_*" })
        } |
        Select-Object @{ n = 'Mailbox'; e = { $Mailbox } }, User, AccessRights
}
```

Hinweis zur Genauigkeit: Microsoft beschreibt das Feld `User` nur als „security principal“ und dokumentiert nicht, in welcher Schreibweise ein Service Principal dort steht. Der Filter vergleicht deshalb gegen mehrere Kennungen des Service Principals. Bleibt die Liste leer, obwohl Rechte vergeben sind, ohne den Filter (`Where-Object`-Block) laufen lassen und in der Ausgabe nach dem Eintrag suchen, der nicht zu einem Benutzer gehört.

**c) Kein SendAs.** Für jedes OFORK-Postfach muss die Ausgabe leer sein. Passen Sie den Suchtext `*OFORK*` an die Schreibweise an, in der der Service Principal in (b) erscheint:

```powershell
Get-EXORecipientPermission -Identity "support@example.com" | Where-Object { "$($_.Trustee)" -like "*OFORK*" }
```

**d) Negativtest.** In OFORK testweise ein Mailkonto vom Typ `IMAPSOAuth2` (bzw. `POP3SOAuth2`) für ein **nicht** freigegebenes Postfach anlegen und abrufen. Der Abruf muss mit `XOAUTH2 authentication … failed (… NO AUTHENTICATE failed.)` (bei POP3 `-ERR Authentication failure`) scheitern (so zeigt es auch die Microsoft-Dokumentation für eine fehlgeschlagene IMAP-Anmeldung). Danach das Testkonto löschen.

Freigabe entfernen, wenn OFORK ein Postfach nicht mehr nutzt:

```powershell
Remove-MailboxPermission -Identity "alt@example.com" -User $SP.Identity -AccessRights FullAccess
```

## 5. OFORK einrichten

### Übersicht: wo was eingestellt wird

| Was | Wo | Gilt für |
|---|---|---|
| Entra-App (Tenant-ID, Client-ID, Client Secret) | Admin → Systemkonfiguration → Gruppe `Core::Email::OAuth2` (`OAuth2::Microsoft::*`) | alle OAuth2-Mailkonten und den OAuth2-Versand, ein Tenant für alles |
| Abruf | Admin → PostMaster E-Mail-Konten, Typ `IMAPSOAuth2` oder `POP3SOAuth2` | pro Mailkonto; Konten mit Passwort (`IMAPS`, `POP3S` usw.) können daneben weiterlaufen |
| Versand | Admin → Systemkonfiguration → `SendmailModule` = `SMTPTLSOAuth2`, `SendmailModule::Host`, `SendmailModule::Port` | **alle** ausgehenden Mails: Antworten, Auto-Antworten, Benachrichtigungen, Kalender |
| Absenderadressen | Admin → E-Mail-Adressen, `NotificationSenderEmail`, ggf. `SendmailNotificationEnvelopeFrom` | jede Adresse muss ein in Schritt 3 freigegebenes Postfach sein; Admin → E-Mail-Adressen prüft das per „Postfach prüfen“ |

Die Einstellungen verweisen in ihren Beschreibungen gegenseitig aufeinander. In der Mailkonto-Maske erscheint bei einem OAuth2-Typ statt des Passworts ein Hinweis mit Link zu `Core::Email::OAuth2`.

### Systemkonfiguration

**Systemkonfiguration → Core::Email::OAuth2:**

| Einstellung | Wert |
|---|---|
| `OAuth2::Microsoft::TenantID` | Directory (tenant) ID |
| `OAuth2::Microsoft::ClientID` | Application (client) ID |
| `OAuth2::Microsoft::ClientSecret` | Wert des Client Secrets |

Mehr ist nicht einzustellen. Token-Endpunkt (`https://login.microsoftonline.com/<Tenant>/oauth2/v2.0/token`) und Scope (`https://outlook.office365.com/.default`) sind von Microsoft vorgegeben; OFORK bildet sie selbst aus der Tenant-ID.

**Abruf: Admin → E-Mail-Konten (PostMaster Mail Accounts)**, je Postfach:

| Feld | Wert |
|---|---|
| Typ | `IMAPSOAuth2` (IMAP, Port 993) oder `POP3SOAuth2` (POP3, Port 995) |
| Benutzername | Adresse des Postfachs, z. B. `support@example.com` |
| Passwort | entfällt (Feld wird ausgeblendet) |
| Host | `outlook.office365.com` |
| IMAP-Ordner | nur bei `IMAPSOAuth2`: `INBOX` oder ein anderer Ordner |

**Versand: Systemkonfiguration → Core::Email:**

| Einstellung | Wert |
|---|---|
| `SendmailModule` | `Kernel::System::Email::SMTPTLSOAuth2` |
| `SendmailModule::Host` | `smtp.office365.com` |
| `SendmailModule::Port` | `587` |
| `SendmailModule::AuthUser` / `AuthPassword` | werden ignoriert |

Jede Systemadresse (Admin → E-Mail-Adressen), die als Absender genutzt wird, muss in Schritt 3 freigegeben sein.

### Einrichtung über den Installer

Bei einer Neuinstallation bietet der Schritt „Mail-Konfiguration“ des Web-Installers den Versandtyp **Exchange Online (OAuth2)** und die Abruftypen `IMAPSOAuth2` und `POP3SOAuth2` an. Sobald einer davon gewählt ist, erscheinen die Felder Tenant-ID, Client-ID und Client Secret; Host, Port und das Abruf-Passwort werden passend vorbelegt bzw. ausgeblendet. Die Prüfung holt ein Token und meldet sich am Abruf-Postfach an. Danach stehen die Werte in der Systemkonfiguration wie oben beschrieben.

### Benachrichtigungen und Absender

- `SendmailEnvelopeFrom` muss **leer** bleiben. Ist sie gesetzt, meldet sich jede Mail als dieses eine Postfach an und alle anderen Absender scheitern mit `5.7.60`.
- Für Antworten und Tickets gilt: Envelope-From ist die Adresse der Systemadresse, die als `From:` der Mail steht.
- Auto-Antworten, Ticket-Benachrichtigungen, Kalender-Benachrichtigungen und Ablehnungen (`NewTicketReject`) haben standardmäßig kein Envelope-From (`SendmailNotificationEnvelopeFrom` ist leer). Mit `SMTPTLSOAuth2` verwendet OFORK dann die Adresse aus dem Header `From:` der Mail, sowohl für die Anmeldung als auch als `MAIL FROM`.
- Deshalb müssen alle dabei vorkommenden Absenderadressen freigegebene Postfächer sein: `NotificationSenderEmail` (bzw. als Rückfall die Adresse aus `AdminEmail`) und die Systemadressen der Queues.
- Ist `SendmailNotificationEnvelopeFrom` gesetzt, muss auch diese Adresse ein freigegebenes Postfach sein.

## Fehlersuche

Meldungen stehen im Kommunikationsprotokoll (Admin → Kommunikation & Benachrichtigungen) und im Systemprotokoll.

| Meldung | Ursache |
|---|---|
| `SysConfig setting 'OAuth2::Microsoft::…' is not configured` | Einstellung in Schritt 5 fehlt |
| `AADSTS7000215` (Invalid client secret provided) | Client Secret falsch, oft die Secret-ID statt des Werts kopiert |
| `AADSTS7000222` | Client Secret abgelaufen, neues anlegen |
| `AADSTS700016` | Anwendung im Tenant nicht gefunden: Client-ID oder Tenant-ID falsch |
| `XOAUTH2 authentication for mailbox … failed` | Postfach nicht freigegeben (Schritt 3), falsche Object-ID bei `New-ServicePrincipal` (Schritt 2), Rechte noch nicht wirksam, IMAP bzw. POP für das Postfach abgeschaltet oder bei `POP3SOAuth2` die Berechtigung `POP.AccessAsApp` fehlt (Schritt 1) |
| `SMTP XOAUTH2 authentication for sender … failed (SMTP code: 535 …)` | wie oben, oder SMTP AUTH für das Postfach abgeschaltet (Schritt 3) |
| `5.7.60 … not have permissions to send as this sender` | Absenderadresse der Mail weicht vom angemeldeten Postfach ab, z. B. weil `SendmailEnvelopeFrom` gesetzt ist. Microsoft würde dafür `SendAs` verlangen; das wird hier bewusst nicht vergeben. Stattdessen `SendmailEnvelopeFrom` leeren und die Absenderadresse der Systemadresse auf ein freigegebenes Postfach ändern. |
| `Mail has no envelope sender` | Weder Envelope-From noch ein `From:`-Header mit Adresse vorhanden, z. B. falsch konfigurierte Systemadresse |
| `430 4.2.0 STOREDRV; mailbox logon failure` | Das Absender-Postfach ist nicht freigegeben (Schritt 3) oder die Freigabe ist noch nicht wirksam. Exchange nimmt die SMTP-Anmeldung auch ohne FullAccess an und lehnt erst die Mail selbst ab. Weil der Code vorübergehend ist (4xx), versucht OFORK die Mail einige Male erneut. |
| `NO User is authenticated but not connected` (IMAP) | Token gültig, aber kein Zugriff auf das Postfach: FullAccess fehlt oder ist noch nicht wirksam |

**Neu angelegte Postfächer und frische Freigaben:** In der ersten Zeit (im Test bis etwa eine halbe Stunde) kann Exchange den Zugriff abwechselnd erlauben und ablehnen, bis Postfach und Rechte überall verteilt sind. Erst danach ist das Ergebnis verlässlich.

**Prüfen ohne Senden:** Admin → E-Mail-Adressen zeigt bei aktivem `SMTPTLSOAuth2` die Spalte „Exchange Online (OAuth2)“. „Postfach prüfen“ holt ein Token, meldet sich per IMAP (oder POP3) am Postfach an, was nur mit FullAccess gelingt, und prüft die SMTP-AUTH-Anmeldung. Es wird keine Mail gesendet und nichts verändert.

Nach einem Anmeldefehler `535` wird die Mail nicht erneut versucht (wie beim Versand mit Passwort gilt ein 5xx-Fehler als dauerhaft). Erst die Rechte korrigieren (Schritt 3), dann die Mail erneut senden.

Das Access Token liegt bis kurz vor Ablauf (ca. 55 Minuten) im OFORK-Cache unter `var/tmp`. Es wird nach einem Anmeldefehler gelöscht. Client Secret und Token stehen nie im Log.

## Quellen

- [Authenticate an IMAP, POP or SMTP connection using OAuth](https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth)
- [New-ServicePrincipal](https://learn.microsoft.com/en-us/powershell/module/exchange/new-serviceprincipal), [Get-ServicePrincipal](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-serviceprincipal)
- [Add-MailboxPermission](https://learn.microsoft.com/en-us/powershell/module/exchange/add-mailboxpermission), [Get-EXOMailboxPermission](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-exomailboxpermission)
- [Enable or disable authenticated client SMTP submission (SMTP AUTH)](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission)
- [About shared mailboxes in Microsoft 365](https://learn.microsoft.com/en-us/microsoft-365/admin/email/about-shared-mailboxes)
- [Fix issues with printers, scanners, and LOB apps (5.7.60)](https://learn.microsoft.com/en-us/troubleshoot/exchange/email-delivery/fix-issues-with-printers-scanners-and-lob-applications-that-send-email-using-off)
