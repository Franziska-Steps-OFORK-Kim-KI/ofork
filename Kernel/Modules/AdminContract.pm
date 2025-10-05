# --
# Kernel/Modules/AdminContract.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AdminContract.pm,v 1.37 2016/09/20 12:33:43 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminContract;

use strict;
use warnings;

use MIME::Base64;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my %Error = ();

    my $ParamObject              = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject              = $Kernel::OM->Get('Kernel::System::Valid');
    my $ContractObject           = $Kernel::OM->Get('Kernel::System::Contract');
    my $ContractTypeObject       = $Kernel::OM->Get('Kernel::System::ContractType');
    my $ContractualPartnerObject = $Kernel::OM->Get('Kernel::System::ContractualPartner');
    my $CustomerUserObject       = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $CustomerCompanyObject    = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    my $ContractLicensesObject   = $Kernel::OM->Get('Kernel::System::ContractLicenses');
    my $TimeObject               = $Kernel::OM->Get('Kernel::System::Time');

    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ContractEdit' ) {

        # get params
        my %GetParam;

        for my $Param (
            qw(ContractID ContractualPartnerID CustomerID CustomerUserID ContractDirection ContractTypeID ContractNumber Description ContractStart ContractEnd ServiceID SLAID Price PaymentMethod NoticePeriod TicketCreate Memory QueueID ValidID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            ContractID => $GetParam{ContractID},
            %Param,
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ContractSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for my $Param (
            qw(ContractID ContractualPartnerID CustomerID FromCustomer ContractDirection ContractTypeID ContractNumber Description FromDateYear FromDateMonth FromDateDay ToDateYear ToDateMonth ToDateDay ServiceID SLAID Price PaymentMethod NoticePeriod TicketCreate Memory QueueID ValidID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        $GetParam{ContractStart} = $GetParam{FromDateYear} . '-' . $GetParam{FromDateMonth} . '-' . $GetParam{FromDateDay} . ' 00:00:01';
        $GetParam{ContractEnd} = $GetParam{ToDateYear} . '-' . $GetParam{ToDateMonth} . '-' . $GetParam{ToDateDay} . ' 23:59:59';

        if ( $GetParam{FromCustomer} ) {

            my @FromCustomerSplit = split(/\</, $GetParam{FromCustomer});

            my $FromCustomerMail = $FromCustomerSplit[1];
            $FromCustomerMail =~ s/\>//ig;

            my %CustomerUser = $CustomerUserObject->CustomerSearch(
                PostMasterSearch => $FromCustomerMail,
                Valid            => 1,
            );

            for my $Customer ( keys %CustomerUser ) {
                $GetParam{CustomerUserID} = $Customer;
            }
        }

        if ( !$GetParam{NoticePeriod} ) {
            $GetParam{NoticePeriod} = 1;
        }
        if ( !$GetParam{Memory} ) {
            $GetParam{Memory} = 1;
        }

        my $EndSystemTime = $TimeObject->Date2SystemTime(
            Year   => $GetParam{ToDateYear},
            Month  => $GetParam{ToDateMonth},
            Day    => $GetParam{ToDateDay},
            Hour   => 23,
            Minute => 59,
            Second => 59,
        );

        my $MemoryTimeDays = $GetParam{NoticePeriod} + $GetParam{Memory};
        my $MemoryTimeSek = $MemoryTimeDays * 86400;
        my $MemorySystemTime = $EndSystemTime - $MemoryTimeSek;

        my ($MemorySec, $MemoryMin, $MemoryHour, $MemoryDay, $MemoryMonth, $MemoryYear, $MemoryWeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $MemorySystemTime,
        );
        $GetParam{MemoryTime} = $MemoryYear . '-' . $MemoryMonth . '-' . $MemoryDay . ' 23:59:59';

        # if no errors occurred
        if ( !%Error ) {

            if ( $GetParam{ContractID} ) {

                my $ContractID = $ContractObject->ContractUpdate(
                    ContractID           => $GetParam{ContractID},
                    ContractualPartnerID => $GetParam{ContractualPartnerID},
                    CustomerID           => $GetParam{CustomerID},
                    CustomerUserID       => $GetParam{CustomerUserID},
                    ContractDirection    => $GetParam{ContractDirection},
                    ContractTypeID       => $GetParam{ContractTypeID},
                    ContractNumber       => $GetParam{ContractNumber},
                    Description          => $GetParam{Description},
                    ContractStart        => $GetParam{ContractStart},
                    ContractEnd          => $GetParam{ContractEnd},
                    ServiceID            => $GetParam{ServiceID},
                    SLAID                => $GetParam{SLAID},
                    Price                => $GetParam{Price},
                    PaymentMethod        => $GetParam{PaymentMethod},
                    NoticePeriod         => $GetParam{NoticePeriod},
                    TicketCreate         => $GetParam{TicketCreate},
                    Memory               => $GetParam{Memory},
                    MemoryTime           => $GetParam{MemoryTime},
                    QueueID              => $GetParam{QueueID},
                    ValidID              => $GetParam{ValidID},
                    UserID               => $Self->{UserID},
                );
            }
            else {

                my $ContractID = $ContractObject->ContractAdd(
                    ContractualPartnerID => $GetParam{ContractualPartnerID},
                    CustomerID           => $GetParam{CustomerID},
                    CustomerUserID       => $GetParam{CustomerUserID},
                    ContractDirection    => $GetParam{ContractDirection},
                    ContractTypeID       => $GetParam{ContractTypeID},
                    ContractNumber       => $GetParam{ContractNumber},
                    Description          => $GetParam{Description},
                    ContractStart        => $GetParam{ContractStart},
                    ContractEnd          => $GetParam{ContractEnd},
                    ServiceID            => $GetParam{ServiceID},
                    SLAID                => $GetParam{SLAID},
                    Price                => $GetParam{Price},
                    PaymentMethod        => $GetParam{PaymentMethod},
                    NoticePeriod         => $GetParam{NoticePeriod},
                    TicketCreate         => $GetParam{TicketCreate},
                    Memory               => $GetParam{Memory},
                    MemoryTime           => $GetParam{MemoryTime},
                    QueueID              => $GetParam{QueueID},
                    ValidID              => $GetParam{ValidID},
                    UserID               => $Self->{UserID},
                );
                $GetParam{ContractID} = $ContractID;
            }
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .=
            $Error{Message}
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Error{Message},
            )
            : '';

        # html output
        $Output .= $Self->_MaskNew(
            ContractID  => $GetParam{ContractID},
            IDError => $GetParam{IDError},
            %Param,
            %GetParam,
            %Error,
        );

        $Output .= $LayoutObject->Footer();

        # redirect
        return $LayoutObject->Redirect(
            OP => "Action=AdminContract",
        );


    }

    # ------------------------------------------------------------ #
    # doenload
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Download' ) {

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => { %Param, },
        );

        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionAdd' );

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewList',
            Data => { %Param, },
        );

        # get valid list
        my %ValidList = $ValidObject->ValidList();

        my $CSVObject = $Kernel::OM->Get('Kernel::System::CSV');

        # get list
        my %ContractList = $ContractObject->ContractList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        my $CSVContent = '';

        if (%ContractList) {
            
            my $ValueNum = 0;
            my @PackageData = ();
            my $Contractnumber = $LayoutObject->{LanguageObject}->Translate("Contract number");
            my $Contractdirection = $LayoutObject->{LanguageObject}->Translate("Contract direction");
            my $Contracttype = $LayoutObject->{LanguageObject}->Translate("Contract type");
            my $Contractualpartner = $LayoutObject->{LanguageObject}->Translate("Contractual partner");
            my $Contractstart = $LayoutObject->{LanguageObject}->Translate("Contract start");
            my $Contractend = $LayoutObject->{LanguageObject}->Translate("Contract end");
            my $Price = $LayoutObject->{LanguageObject}->Translate("Price");
            my $Paymentmethod = $LayoutObject->{LanguageObject}->Translate("Payment method");
            my $Valid = $LayoutObject->{LanguageObject}->Translate("Valid");
            my $Licensesordevice = $LayoutObject->{LanguageObject}->Translate("Licenses or device");
            my $Total = $LayoutObject->{LanguageObject}->Translate("Total");
            my $Used = $LayoutObject->{LanguageObject}->Translate("Used");
            my $Available = $LayoutObject->{LanguageObject}->Translate("Available");

            for my $ContractID ( sort { lc $ContractList{$a} cmp lc $ContractList{$b} } keys %ContractList ) {

                $ValueNum ++;

                # get the sla data
                my %ContractData = $ContractObject->ContractGet(
                    ContractID => $ContractID,
                    UserID     => $Self->{UserID},
                );

                if ( $ContractData{ContractualPartnerID} ) {

                    my %ContractualPartner = $ContractualPartnerObject->ContractualPartnerGet(
                        ContractualPartnerID => $ContractData{ContractualPartnerID},
                    );
                    $ContractData{ContractualPartner} = $ContractualPartner{Company};
                }

                if ( $ContractData{CustomerID} ) {

                    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
                        CustomerID => $ContractData{CustomerID},
                    );
                    $ContractData{ContractualPartner} = $CustomerCompany{CustomerCompanyName};
                }

                if ( $ContractData{ContractTypeID} ) {

                    my %ContractTypeData = $ContractTypeObject->ContractTypeGet(
                        ContractTypeID => $ContractData{ContractTypeID},
                        UserID         => 1,
                    );
                    $ContractData{ContractType} = $ContractTypeData{Name};
                }

                my @StartSplit = split(/\ /, $ContractData{ContractStart});
                my @StartDetailSplit = split(/\-/, $StartSplit[0]);
                $ContractData{ContractStart} = $StartDetailSplit[2] . '.' . $StartDetailSplit[1] . '.' . $StartDetailSplit[0];

                my @EndSplit = split(/\ /, $ContractData{ContractEnd});
                my @EndDetailSplit = split(/\-/, $EndSplit[0]);
                $ContractData{ContractEnd} = $EndDetailSplit[2] . '.' . $EndDetailSplit[1] . '.' . $EndDetailSplit[0];

                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => { %ContractData, Valid => $ValidList{ $ContractData{ValidID} }, },
                );

                my %Device = $ContractLicensesObject->ContractDeviceGet(
                    ContractID => $ContractID,
                );

                my %HandoverList = $ContractLicensesObject->HandoverList(
                    ContractID => $ContractID,
                    UserID     => $Self->{UserID},
                );

                $ContractData{HandoverValue} = 0;
                $ContractData{DeviceNumberDiv} = $Device{DeviceNumber};
                $ContractData{DeviceNumber} = $Device{DeviceNumber};
                $ContractData{DeviceName} = '-';

                if (%HandoverList) {
        
                    my $HandoverValue = 0;
                    for my $HandoverID ( sort keys %HandoverList ) {
        
                        $HandoverValue ++;
                    }
        
                    $ContractData{HandoverValue} = $HandoverValue;
                    $ContractData{DeviceNumberDiv} = $Device{DeviceNumber} - $HandoverValue;
                }

                $ContractData{DeviceName} = $Device{DeviceName};

                if ( $ValueNum == 1 )  {

                    @PackageData = (
                        [
                            $Contractnumber,
                            $Contractdirection,
                            $Contracttype,
                            $Contractualpartner,
                            $Contractstart,
                            $Contractend,
                            $Price,
                            $Paymentmethod,
                            $Valid,
                            $Licensesordevice,
                            $Total,
                            $Used,
                            $Available,
                        ],
                        [
                            $ContractData{ContractNumber},
                            $ContractData{ContractDirection},
                            $ContractData{ContractType},
                            $ContractData{ContractualPartner},
                            $ContractData{ContractStart},
                            $ContractData{ContractEnd},
                            $ContractData{Price},
                            $ContractData{PaymentMethod},
                            $ContractData{Valid},
                            $ContractData{DeviceName},
                            $ContractData{DeviceNumber},
                            $ContractData{HandoverValue},
                            $ContractData{DeviceNumberDiv},
                        ],
                    );
                }
                else {

                    @PackageData = (
                        [
                            $ContractData{ContractNumber},
                            $ContractData{ContractDirection},
                            $ContractData{ContractType},
                            $ContractData{ContractualPartner},
                            $ContractData{ContractStart},
                            $ContractData{ContractEnd},
                            $ContractData{Price},
                            $ContractData{PaymentMethod},
                            $ContractData{Valid},
                            $ContractData{DeviceName},
                            $ContractData{DeviceNumber},
                            $ContractData{HandoverValue},
                            $ContractData{DeviceNumberDiv},
                        ],
                    );
                }

                # convert data into CSV string
                $CSVContent .= $CSVObject->Array2CSV(
                    Data => \@PackageData,
                );
            }
        }

        return $LayoutObject->Attachment(
            Filename    => 'Contracts.csv',
            ContentType => 'application/octet-stream; charset=' . $LayoutObject->{UserCharset},
            Content     => $CSVContent,
        );
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => { %Param, },
        );

        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionAdd' );

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewList',
            Data => { %Param, },
        );

        # get valid list
        my %ValidList = $ValidObject->ValidList();

        # get list
        my %ContractList = $ContractObject->ContractList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        if (%ContractList) {
            
            for my $ContractID ( sort { lc $ContractList{$a} cmp lc $ContractList{$b} } keys %ContractList ) {

                # get the sla data
                my %ContractData = $ContractObject->ContractGet(
                    ContractID => $ContractID,
                    UserID     => $Self->{UserID},
                );

                if ( $ContractData{ContractualPartnerID} ) {

                    my %ContractualPartner = $ContractualPartnerObject->ContractualPartnerGet(
                        ContractualPartnerID => $ContractData{ContractualPartnerID},
                    );
                    $ContractData{ContractualPartner} = $ContractualPartner{Company};
                }

                if ( $ContractData{CustomerID} ) {

                    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
                        CustomerID => $ContractData{CustomerID},
                    );
                    $ContractData{ContractualPartner} = $CustomerCompany{CustomerCompanyName};
                }

                if ( $ContractData{ContractTypeID} ) {

                    my %ContractTypeData = $ContractTypeObject->ContractTypeGet(
                        ContractTypeID => $ContractData{ContractTypeID},
                        UserID         => 1,
                    );
                    $ContractData{ContractType} = $ContractTypeData{Name};
                }

                my @StartSplit = split(/\ /, $ContractData{ContractStart});
                my @StartDetailSplit = split(/\-/, $StartSplit[0]);
                $ContractData{ContractStart} = $StartDetailSplit[2] . '.' . $StartDetailSplit[1] . '.' . $StartDetailSplit[0];

                my @EndSplit = split(/\ /, $ContractData{ContractEnd});
                my @EndDetailSplit = split(/\-/, $EndSplit[0]);
                $ContractData{ContractEnd} = $EndDetailSplit[2] . '.' . $EndDetailSplit[1] . '.' . $EndDetailSplit[0];

                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => { %ContractData, Valid => $ValidList{ $ContractData{ValidID} }, },
                );

                my %Device = $ContractLicensesObject->ContractDeviceGet(
                    ContractID => $ContractID,
                );

                my %HandoverList = $ContractLicensesObject->HandoverList(
                    ContractID => $ContractID,
                    UserID     => $Self->{UserID},
                );

                $ContractData{HandoverValue} = 0;
                $ContractData{DeviceNumberDiv} = $Device{DeviceNumber};
                $ContractData{DeviceNumber} = $Device{DeviceNumber};
                $ContractData{DeviceName} = '-';

                if (%HandoverList) {
        
                    my $HandoverValue = 0;
                    for my $HandoverID ( sort keys %HandoverList ) {
        
                        $HandoverValue ++;
                    }
        
                    $ContractData{HandoverValue} = $HandoverValue;
                    $ContractData{DeviceNumberDiv} = $Device{DeviceNumber} - $HandoverValue;
                }

                $ContractData{DeviceName} = $Device{DeviceName};

                if ( $ContractData{DeviceNumber} > 0 ) {

                    # output overview list row
                    $LayoutObject->Block(
                        Name => 'DeviceValue',
                        Data => { %ContractData, },
                    );
                }
                else {

                    # output overview list row
                    $LayoutObject->Block(
                        Name => 'DeviceValueNone',
                        Data => { %ContractData, },
                    );
                }
            }
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminContract',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {

    my ( $Self, %Param ) = @_;

    my $ParamObject              = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject              = $Kernel::OM->Get('Kernel::System::Valid');
    my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
    my $UserObject               = $Kernel::OM->Get('Kernel::System::User');
    my $ContractObject           = $Kernel::OM->Get('Kernel::System::Contract');
    my $ContractTypeObject       = $Kernel::OM->Get('Kernel::System::ContractType');
    my $ContractualPartnerObject = $Kernel::OM->Get('Kernel::System::ContractualPartner');
    my $QueueObject              = $Kernel::OM->Get('Kernel::System::Queue');
    my $CustomerUserObject       = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $CustomerCompanyObject    = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    my $ServiceObject            = $Kernel::OM->Get('Kernel::System::Service');
    my $SLAObject                = $Kernel::OM->Get('Kernel::System::SLA');

    # get params
    my %ContractData;

    if ( $Param{ContractID} ) {

        %ContractData = $ContractObject->ContractGet(
            ContractID => $Param{ContractID},
        );
    }

    $ContractData{FromCustomer} =  $ContractData{CustomerUserID};

    my %ContractualPartnerList = $ContractualPartnerObject->ContractualPartnerList(
        Valid  => 1,
        UserID => 1,
    );
    $ContractData{ContractualPartnerStrg} = $LayoutObject->BuildSelection(
        Data         => \%ContractualPartnerList,
        PossibleNone => 1,
        Name         => 'ContractualPartnerID',
        Class        => "Modernize",
        SelectedID   => $ContractData{ContractualPartnerID} || $Param{ContractualPartnerID},
    );

    my %ContractDirection = ( 'outgoing' => 'outgoing', 'incoming' => 'incoming' );
    $ContractData{ContractDirectionStrg} = $LayoutObject->BuildSelection(
        Data         => \%ContractDirection,
        PossibleNone => 1,
        Name         => 'ContractDirection',
        Class        => "Modernize",
        SelectedID   => $ContractData{ContractDirection} || $Param{ContractDirection} || 'Yes',
        Sort         => 'AlphanumericKey',
        Translation  => 1,
    );

    my %ContractTypeList = $ContractTypeObject->ContractTypeList(
        Valid  => 1,
        UserID => 1,
    );
    $ContractData{ContractTypeStrg} = $LayoutObject->BuildSelection(
        Data         => \%ContractTypeList,
        PossibleNone => 1,
        Name         => 'ContractTypeID',
        Class        => "Modernize",
        SelectedID   => $ContractData{ContractTypeID} || $Param{ContractTypeID},
    );

    my @StartSplit = split(/\ /, $ContractData{ContractStart});
    my @StartDetailSplit = split(/\-/, $StartSplit[0]);

    $Param{FromDateString} = $LayoutObject->BuildDateSelection(
        Prefix               => 'FromDate',
        FromDateYear         => $StartDetailSplit[0] || $Param{FromDateYear},
        FromDateMonth        => $StartDetailSplit[1] || $Param{FromDateMonth},
        FromDateDay          => $StartDetailSplit[2] || $Param{FromDateDay},
        Format               => 'DateInputFormat',
        YearPeriodPast       => 10,
        YearPeriodFuture     => 1,
        DiffTime             => 0,
        Class                => $Param{Errors}->{FromDateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 0,
    );

    my @EndSplit = split(/\ /, $ContractData{ContractEnd});
    my @EndDetailSplit = split(/\-/, $EndSplit[0]);

    $Param{ToDateString} = $LayoutObject->BuildDateSelection(
        Prefix               => 'ToDate',
        ToDateYear           => $EndDetailSplit[0] || $Param{ToDateYear},
        ToDateMonth          => $EndDetailSplit[1] || $Param{ToDateMonth},
        ToDateDay            => $EndDetailSplit[2] || $Param{ToDateDay},
        Format               => 'DateInputFormat',
        YearPeriodPast       => 0,
        YearPeriodFuture     => 10,
        DiffTime             => 3600,
        Class                => $Param{Errors}->{ToDateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 0,
    );

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    my %PaymentMethod = ( 'monthly' => '1 - monthly', 'quarterly' => '2 - quarterly', 'half-yearly' => '3 - half-yearly', 'yearly' => '4 - yearly' );
    $ContractData{PaymentMethodStrg} = $LayoutObject->BuildSelection(
        Data         => \%PaymentMethod,
        PossibleNone => 1,
        Name         => 'PaymentMethod',
        Class        => "Modernize",
        SelectedID   => $ContractData{PaymentMethod} || $Param{PaymentMethod},
        Sort         => 'NumericKey',
        Translation  => 1,
    );

    my %TicketCreate = ( 'Yes' => 'Yes', 'No' => 'No' );
    $ContractData{TicketCreateStrg} = $LayoutObject->BuildSelection(
        Data         => \%TicketCreate,
        PossibleNone => 1,
        Name         => 'TicketCreate',
        Class        => "Modernize",
        SelectedID   => $ContractData{TicketCreate} || $Param{TicketCreate} || 'Yes',
        Sort         => 'AlphanumericKey',
        Translation  => 1,
    );

    my %QueueList = $QueueObject->QueueList( Valid => 1 );
    $ContractData{QueueIDStrg} = $LayoutObject->BuildSelection(
        Data         => \%QueueList,
        PossibleNone => 1,
        Name         => 'QueueID',
        Class        => "Modernize",
        SelectedID   => $ContractData{QueueID} || $Param{QueueID},
    );

    $Param{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data           => \%ValidList,
        Name           => 'ValidID',
        ContractTypeID => $ContractData{ValidID} || $Param{ValidID} || $ValidListReverse{valid},
    );

    # output edit
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, %ContractData, },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    $LayoutObject->Block(
        Name => 'ContractEdit',
        Data => { %Param, %ContractData, },
    );

    # build service string
    if ( $ConfigObject->Get('Ticket::Service') ) {

        my %ServiceList = $ServiceObject->ServiceList(
            Valid  => 1,
            UserID => 1,
        );
        $Param{ServiceStrg} = $LayoutObject->BuildSelection(
            Data         => \%ServiceList,
            Name         => 'ServiceID',
            Class        => 'Modernize ',
            SelectedID   => $ContractData{ServiceID} || $Param{ServiceID},
            PossibleNone => 1,
            Translation  => 0,
            Max          => 200,
        );
        $LayoutObject->Block(
            Name => 'TicketService',
            Data => {
                %Param,
            },
        );

        my %SLAList = $SLAObject->SLAList(
            Valid     => 1,
            UserID    => 1,
        );
        $Param{SLAStrg} = $LayoutObject->BuildSelection(
            Data         => \%SLAList,
            Name         => 'SLAID',
            SelectedID   => $ContractData{SLAID} || $Param{SLAID},
            Class        => 'Modernize ',
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
            Max          => 200,
        );
        $LayoutObject->Block(
            Name => 'TicketSLA',
            Data => {
                %Param
            },
        );
    }

    # shows header
    if ( $ContractData{ContractID} ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    # get output back
    return $LayoutObject->Output( TemplateFile => 'AdminContract', Data => \%Param );
}

1;
