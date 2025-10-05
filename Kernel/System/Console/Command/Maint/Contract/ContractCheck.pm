# --
# Kernel/System/Console/Command/Maint/Contract/ContractCheck.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: ContractCheck.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::Contract::ContractCheck;

use strict;
use warnings;

use List::Util qw(first);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DateTime',
    'Kernel::System::Ticket',
    'Kernel::System::Time',
    'Kernel::System::Contract',
    'Kernel::System::ContractLicenses',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Triggers contracts escalation events and notification events for escalation.');

    return;
}

# =item Run()
#
# =cut

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Processing contract escalation events ...</yellow>\n");

    # get needed objects
    my $ContractObject         = $Kernel::OM->Get('Kernel::System::Contract');
    my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
    my $QueueObject            = $Kernel::OM->Get('Kernel::System::Queue');
    my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
    my $TimeObject             = $Kernel::OM->Get('Kernel::System::Time');
    my $ContractLicensesObject = $Kernel::OM->Get('Kernel::System::ContractLicenses');
    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Find all contracts which will escalate
    my @Contracts = $ContractObject->ContractEscalationSearch(
        UserID => 1,
    );

    TICKET:
    for my $ContractID (@Contracts) {

        # get data
        my %Contract = $ContractObject->ContractGet(
            ContractID => $ContractID,
        );

        my $SystemTime = $TimeObject->SystemTime();
        
        if ( !$Contract{NotificationTime} ) {
            $Contract{NotificationTime} = '0000-00-00 00:00:00';
        }

        my @NotificationSplit = split(/\ /, $Contract{NotificationTime});
        my @NotificationDateSplit = split(/\-/, $NotificationSplit[0]);
        my @NotificationTimeSplit = split(/\:/, $NotificationSplit[1]);

        my $CheckTime = 31536001;

        if ( $NotificationDateSplit[0] > 0 ) {

            my $NotificationSystemTime = $TimeObject->Date2SystemTime(
                Year   => $NotificationDateSplit[0],
                Month  => $NotificationDateSplit[1],
                Day    => $NotificationDateSplit[2],
                Hour   => $NotificationTimeSplit[0],
                Minute => $NotificationTimeSplit[1],
                Second => $NotificationTimeSplit[2],
            );
    
            $CheckTime = $SystemTime - $NotificationSystemTime;
        }
        
        if ( $CheckTime > 31536000 )  {

            my $CustomerID   = $ConfigObject->Get('AdminEmail');
            my $CustomerUser = $ConfigObject->Get('AdminEmail');

            my $SubjectLang = $LayoutObject->{LanguageObject}->Translate('Reminder contract expiration for contract number ');
            my $Subject = $SubjectLang . $Contract{ContractNumber};

            my $HttpType    = $ConfigObject->Get('HttpType');
            my $FQDN        = $ConfigObject->Get('FQDN');
            my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

            my $BodyLang = $LayoutObject->{LanguageObject}->Translate('To the contract');

            my $Body = $SubjectLang . $Contract{ContractNumber} . "\n\n<br><br>";
            $Body .= "<a href=\"$HttpType://$FQDN" . "/$ScriptAlias" . "index.pl?Action=AdminContract;Subaction=ContractEdit;ContractID=$Contract{ContractID}\">$BodyLang</a>\n\n<br><br>";

            # create new ticket
            my $TicketID = $TicketObject->TicketCreate(
                Title        => $Subject,
                QueueID      => $Contract{QueueID},
                Lock         => 'unlock',
                Priority     => '3 normal',
                State        => 'new',
                CustomerNo   => $CustomerID,
                CustomerUser => $CustomerUser,
                OwnerID      => 1,
                UserID       => 1,
            );

            if ( $TicketID ) {

                my ($Sec, $Min, $Hour, $Day, $Month, $Year, $WeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $TimeObject->SystemTime(),
                );

                my $DateSet = $Year . '-' . $Month . '-' . $Day . ' ' . $Hour . ':' . $Min . ':' . $Sec;

                my $ContractID = $ContractObject->NotificationUpdate(
                    ContractID       => $Contract{ContractID},
                    NotificationTime => $DateSet,
                    UserID           => 1,
                );

                # create new article
                my $ArticleID = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
                    TicketID             => $TicketID,
                    SenderType           => 'agent',
                    IsVisibleForCustomer => 0,
                    From                 => $ConfigObject->Get('AdminEmail'),
                    Subject              => $Subject,
                    Body                 => $Body,
                    Charset              => 'utf-8',
                    MimeType             => 'text/html',
                    HistoryType          => 'AddNote',
                    HistoryComment       => '%%Note',
                    UserID               => 1,
                );
            }
        }
    }

    my %ContractDeviceList = $ContractLicensesObject->ContractDeviceList(
        UserID => 1,
    );

    my %HandoverList = ();

    for my $DeviceID ( keys %ContractDeviceList ) {

        my %Device = $ContractLicensesObject->ContractDeviceGet(
            ContractID => $ContractDeviceList{$DeviceID},
        );

        %HandoverList = $ContractLicensesObject->HandoverList(
            ContractID => $ContractDeviceList{$DeviceID},
            UserID     => 1,
        );

        if (%HandoverList) {

            my $HandoverValue = 0;
            for my $HandoverID ( sort keys %HandoverList ) {
                $HandoverValue ++;
            }

            $Device{HandoverValue} = $HandoverValue;
            $Device{DeviceNumberDiv} = $Device{DeviceNumber} - $HandoverValue;
        }

        if ( $Device{DeviceNumberDiv} <= $Device{TicketCreateBy} && $Device{DeviceNumberDiv} >= 0 && $Device{TicketCreateBy} > 0 ) {

            my $CheckTime = 31536001;
            if ( $Device{NotificationTime} ) {

                my $SystemTime = $TimeObject->SystemTime();
        
                my @NotificationSplit = split(/\ /, $Device{NotificationTime});
                my @NotificationDateSplit = split(/\-/, $NotificationSplit[0]);
                my @NotificationTimeSplit = split(/\:/, $NotificationSplit[1]);

                if ( $NotificationDateSplit[0] > 0 ) {

                    my $NotificationSystemTime = $TimeObject->Date2SystemTime(
                        Year   => $NotificationDateSplit[0],
                        Month  => $NotificationDateSplit[1],
                        Day    => $NotificationDateSplit[2],
                        Hour   => $NotificationTimeSplit[0],
                        Minute => $NotificationTimeSplit[1],
                        Second => $NotificationTimeSplit[2],
                    );
            
                    $CheckTime = $SystemTime - $NotificationSystemTime;
                }
            }
            
            if ( $CheckTime > 31536000 )  {
    
                # get data
                my %Contract = $ContractObject->ContractGet(
                    ContractID => $ContractDeviceList{$DeviceID},
                );
    
                my $CustomerID   = $ConfigObject->Get('AdminEmail');
                my $CustomerUser = $ConfigObject->Get('AdminEmail');
    
                my $SubjectLangA = $LayoutObject->{LanguageObject}->Translate('Reminder minimum number ');
                my $SubjectLangB = $LayoutObject->{LanguageObject}->Translate(' fell short of contract number ');
                my $Subject = $SubjectLangA . $Device{DeviceName} . $SubjectLangB . $Contract{ContractNumber};

                my $HttpType    = $ConfigObject->Get('HttpType');
                my $FQDN        = $ConfigObject->Get('FQDN');
                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
    
                my $BodyLang = $LayoutObject->{LanguageObject}->Translate('To the contract');
    
                my $Body = $SubjectLangA .  $Device{DeviceName} . $SubjectLangB . $Contract{ContractNumber} . "\n\n<br><br>";
                $Body .= "<a href=\"$HttpType://$FQDN" . "/$ScriptAlias" . "index.pl?Action=AdminContractLicenses;Subaction=LicensesEdit;ContractID=$Contract{ContractID}\">$BodyLang</a>\n\n<br><br>";
    
                # create new ticket
                my $TicketID = $TicketObject->TicketCreate(
                    Title        => $Subject,
                    QueueID      => $Device{QueueID},
                    Lock         => 'unlock',
                    Priority     => '3 normal',
                    State        => 'new',
                    CustomerNo   => $CustomerID,
                    CustomerUser => $CustomerUser,
                    OwnerID      => 1,
                    UserID       => 1,
                );
    
                if ( $TicketID ) {
    
                    my ($Sec, $Min, $Hour, $Day, $Month, $Year, $WeekDay) = $TimeObject->SystemTime2Date(
                        SystemTime => $TimeObject->SystemTime(),
                    );
    
                    my $DateSet = $Year . '-' . $Month . '-' . $Day . ' ' . $Hour . ':' . $Min . ':' . $Sec;
    
                    my $ContractID = $ContractLicensesObject->NotificationUpdate(
                        ContractID       => $Contract{ContractID},
                        NotificationTime => $DateSet,
                        UserID           => 1,
                    );
    
                    # create new article
                    my $ArticleID = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
                        TicketID             => $TicketID,
                        SenderType           => 'agent',
                        IsVisibleForCustomer => 0,
                        From                 => $ConfigObject->Get('AdminEmail'),
                        Subject              => $Subject,
                        Body                 => $Body,
                        Charset              => 'utf-8',
                        MimeType             => 'text/html',
                        HistoryType          => 'AddNote',
                        HistoryComment       => '%%Note',
                        UserID               => 1,
                    );
                }
            }
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
