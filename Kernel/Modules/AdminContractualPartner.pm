# --
# Kernel/Modules/AdminContractualPartner.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AdminContractualPartner.pm,v 1.37 2016/09/20 12:33:43 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminContractualPartner;

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
    my $ContractualPartnerObject = $Kernel::OM->Get('Kernel::System::ContractualPartner');

    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ContractualPartnerEdit' ) {

        # get params
        my %GetParam;

        for my $Param (
            qw(ContractualPartnerID Company Street PostCode City Country Phone ContactPerson eMail Description ValidID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            ContractualPartnerID => $GetParam{ContractualPartnerID},
            %Param,
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ContractualPartnerSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for my $Param (
            qw(ContractualPartnerID Company Street PostCode City Country Phone ContactPerson eMail Description ValidID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{Company} ) {
            $Error{'CompanyInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( $GetParam{ContractualPartnerID} ) {

                my $ContractualPartnerID = $ContractualPartnerObject->ContractualPartnerUpdate(
                    ContractualPartnerID => $GetParam{ContractualPartnerID},
                    Company              => $GetParam{Company},
                    Street               => $GetParam{Street},
                    PostCode             => $GetParam{PostCode},
                    City                 => $GetParam{City},
                    Country              => $GetParam{Country},
                    Phone                => $GetParam{Phone},
                    ContactPerson        => $GetParam{ContactPerson},
                    eMail                => $GetParam{eMail},
                    Description          => $GetParam{Description},
                    ValidID              => $GetParam{ValidID},
                    UserID               => $Self->{UserID},
                );
            }
            else {

                my $ContractualPartnerID = $ContractualPartnerObject->ContractualPartnerAdd(
                    Company              => $GetParam{Company},
                    Street               => $GetParam{Street},
                    PostCode             => $GetParam{PostCode},
                    City                 => $GetParam{City},
                    Country              => $GetParam{Country},
                    Phone                => $GetParam{Phone},
                    ContactPerson        => $GetParam{ContactPerson},
                    eMail                => $GetParam{eMail},
                    Description          => $GetParam{Description},
                    ValidID              => $GetParam{ValidID},
                    UserID               => $Self->{UserID},
                );
                $GetParam{ContractualPartnerID} = $ContractualPartnerID;
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
            ContractualPartnerID  => $GetParam{ContractualPartnerID},
            IDError => $GetParam{IDError},
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

        # get  list
        my %ContractualPartnerList = $ContractualPartnerObject->ContractualPartnerList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # get valid list
        my %ValidList = $ValidObject->ValidList();

        if (%ContractualPartnerList) {
            for my $ContractualPartnerID ( sort { lc $ContractualPartnerList{$a} cmp lc $ContractualPartnerList{$b} } keys %ContractualPartnerList ) {

                # get the sla data
                my %ContractualPartnerData = $ContractualPartnerObject->ContractualPartnerGet(
                    ContractualPartnerID => $ContractualPartnerID,
                    UserID               => $Self->{UserID},
                );

                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => { %ContractualPartnerData, Valid => $ValidList{ $ContractualPartnerData{ValidID} }, },
                );
            }
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminContractualPartner',
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
    my $ContractualPartnerObject = $Kernel::OM->Get('Kernel::System::ContractualPartner');

    # get params
    my %ContractualPartnerData;
    $ContractualPartnerData{ContractualPartnerID} = $Param{ContractualPartnerID} || '';

    if ( $ContractualPartnerData{ContractualPartnerID} ) {

        # get the sla data
        %ContractualPartnerData = $ContractualPartnerObject->ContractualPartnerGet(
            ContractualPartnerID => $ContractualPartnerData{ContractualPartnerID},
            UserID               => $Self->{UserID},
        );
    }

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $ContractualPartnerData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ContractualPartnerData{ValidID} || $ValidListReverse{valid},
    );

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%ContractualPartnerData,
        );
    }

    # build Country string
    my $CountryList = $Kernel::OM->Get('Kernel::System::ReferenceData')->CountryList();
    $Param{CountryStrg} = $LayoutObject->BuildSelection(
        Data         => $CountryList,
        PossibleNone => 1,
        Sort         => 'AlphanumericValue',
        Name         => 'Country',
        Class        => '',
        SelectedID   => $ContractualPartnerData{Country},
    );

    # output edit
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, %ContractualPartnerData, },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    $LayoutObject->Block(
        Name => 'ContractualPartnerEdit',
        Data => { %Param, %ContractualPartnerData, },
    );

    # shows header
    if ( $ContractualPartnerData{ContractualPartnerID} ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    # get output back
    return $LayoutObject->Output( TemplateFile => 'AdminContractualPartner', Data => \%Param );
}

1;
