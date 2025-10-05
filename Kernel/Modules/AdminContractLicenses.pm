# --
# Kernel/Modules/AdminContractLicenses.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AdminContractLicenses.pm,v 1.37 2016/09/20 12:33:43 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminContractLicenses;

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

    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'LicensesEdit' ) {

        # get params
        my %GetParam;

        for my $Param (
            qw(ContractID DeviceName DeviceNumber TicketCreateBy QueueID)
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
    elsif ( $Self->{Subaction} eq 'ContractDeviceSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for my $Param (
            qw(DeviceID ContractID DeviceName DeviceNumber TicketCreateBy QueueID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( $GetParam{DeviceID} ) {

                my $DeviceID= $ContractLicensesObject->ContractDeviceUpdate(
                    DeviceID       => $GetParam{DeviceID},
                    ContractID     => $GetParam{ContractID},
                    DeviceName     => $GetParam{DeviceName},
                    DeviceNumber   => $GetParam{DeviceNumber},
                    TicketCreateBy => $GetParam{TicketCreateBy},
                    QueueID        => $GetParam{QueueID},
                    UserID         => $Self->{UserID},
                );
            }
            else {

                my $DeviceID = $ContractLicensesObject->ContractDeviceAdd(
                    ContractID     => $GetParam{ContractID},
                    DeviceName     => $GetParam{DeviceName},
                    DeviceNumber   => $GetParam{DeviceNumber},
                    TicketCreateBy => $GetParam{TicketCreateBy},
                    QueueID        => $GetParam{QueueID},
                    UserID         => $Self->{UserID},
                );
                $GetParam{DeviceID} = $DeviceID;
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
            DeviceID    => $GetParam{DeviceID},
            ContractID  => $GetParam{ContractID},
            IDError     => $GetParam{IDError},
            %Param,
            %GetParam,
            %Error,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'HandoverAdd' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for my $Param (
            qw(DeviceID ContractID Handover HandoverDateYear HandoverDateMonth HandoverDateDay)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( $GetParam{ContractID} ) {

                $GetParam{HandoverDate} = $GetParam{HandoverDateYear} . '-' . $GetParam{HandoverDateMonth} . '-' . $GetParam{HandoverDateDay} . ' 00:00:01';

                my $DeviceID= $ContractLicensesObject->HandoverAdd(
                    ContractID   => $GetParam{ContractID},
                    Handover     => $GetParam{Handover},
                    HandoverDate => $GetParam{HandoverDate},
                    UserID       => $Self->{UserID},
                );
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
            DeviceID    => $GetParam{DeviceID},
            ContractID  => $GetParam{ContractID},
            IDError     => $GetParam{IDError},
            %Param,
            %GetParam,
            %Error,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        # get params
        my %GetParam;

        for my $Param (
            qw(ContractID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # output header
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
    my $ContractLicensesObject   = $Kernel::OM->Get('Kernel::System::ContractLicenses');

    # get params
    my %ContractData;
    my %Device;

    if ( $Param{ContractID} ) {

        %ContractData = $ContractObject->ContractGet(
            ContractID => $Param{ContractID},
        );

        %Device = $ContractLicensesObject->ContractDeviceGet(
            ContractID => $Param{ContractID},
        );
    }

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    my %QueueList = $QueueObject->QueueList( Valid => 1 );
    $ContractData{QueueIDStrg} = $LayoutObject->BuildSelection(
        Data         => \%QueueList,
        PossibleNone => 1,
        Name         => 'QueueID',
        Class        => "Modernize",
        SelectedID   => $Device{QueueID} || $Param{QueueID},
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

    # output
    $LayoutObject->Block(
        Name => 'ActionList',
        Data => { %ContractData, },
    );

    $LayoutObject->Block( Name => 'ActionOverview' );

    $LayoutObject->Block(
        Name => 'ContractEdit',
        Data => { %Param, %ContractData, %Device, },
    );


    if ( %Device ) {

        $Param{HandoverDateString} = $LayoutObject->BuildDateSelection(
            Prefix               => 'HandoverDate',
            Format               => 'DateInputFormat',
            YearPeriodPast       => 10,
            YearPeriodFuture     => 1,
            DiffTime             => 0,
            Class                => $Param{Errors}->{HandoverDateInvalid},
            Validate             => 1,
            ValidateDateInFuture => 0,
        );

        $LayoutObject->Block(
            Name => 'LicenseEdit',
            Data => { %Param, %Device, },
        );

        my %HandoverList = $ContractLicensesObject->HandoverList(
            ContractID => $Param{ContractID},
            UserID     => $Self->{UserID},
        );

        if (%HandoverList) {

            my $HandoverValue = 0;
            for my $HandoverID ( sort keys %HandoverList ) {

                $HandoverValue ++;
            }

            $Device{HandoverValue} = $HandoverValue;
            $Device{DeviceNumberDiv} = $Device{DeviceNumber} - $HandoverValue;
        }

        $LayoutObject->Block(
            Name => 'LicenseOverview',
            Data => { %Param, %Device, },
        );

        # get  list
        my %ContractList = $ContractObject->ContractList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        if (%HandoverList) {

            my $HandoverValue = 0;
            for my $HandoverID ( sort keys %HandoverList ) {

                # get the sla data
                my %HandovertData = $ContractLicensesObject->HandoverGet(
                    HandoverID => $HandoverID,
                    UserID     => $Self->{UserID},
                );

                $HandoverValue ++;

                my @StartSplit = split(/\ /, $HandovertData{HandoverDate});
                my @StartDetailSplit = split(/\-/, $StartSplit[0]);
                $HandovertData{HandoverDate} = $StartDetailSplit[2] . '.' . $StartDetailSplit[1] . '.' . $StartDetailSplit[0];

                my @CreateTimeSplit = split(/\ /, $HandovertData{CreateTime});
                my @CreateTimeDetailSplit = split(/\-/, $CreateTimeSplit[0]);
                $HandovertData{CreateTime} = $CreateTimeDetailSplit[2] . '.' . $CreateTimeDetailSplit[1] . '.' . $CreateTimeDetailSplit[0];


                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => { %HandovertData, },
                );
            }
        }
    }


    # shows header
    if ( $ContractData{ContractID} ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    # get output back
    return $LayoutObject->Output( TemplateFile => 'AdminContractLicenses', Data => \%Param );
}

1;
