# --
# Kernel/Modules/AdminContractType.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminContractType.pm,v 1.3 2016/09/20 12:34:27 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminContractType;

use strict;
use warnings;

use MIME::Base64;

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

    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ContractTypeObject = $Kernel::OM->Get('Kernel::System::ContractType');
    my $ValidObject        = $Kernel::OM->Get('Kernel::System::Valid');

    # ------------------------------------------------------------ #
    # ContractType edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ContractTypeEdit' ) {

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            %Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # ContractType save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ContractTypeSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for (qw(ContractTypeID ParentID Name ValidID Comment)) {
            $GetParam{$_} = $ParamObject->GetParam( Param => $_ ) || '';
        }

        my %Error;

        if ( !$GetParam{Name} ) {
            $Error{'NameInvalid'} = 'ServerError';
        }

        if ( !%Error ) {

            # save to database
            if ( $GetParam{ContractTypeID} eq 'NEW' ) {
                $GetParam{ContractTypeID}
                    = $ContractTypeObject->ContractTypeAdd(
                    %GetParam,
                    UserID => $Self->{UserID},
                    );
                if ( !$GetParam{ContractTypeID} ) {
                    $Error{Message} = $Kernel::OM->Get('Kernel::System::Log')->GetLogEntry(
                        Type => 'Error',
                        What => 'Message',
                    );
                }
            }
            else {
                my $Success = $ContractTypeObject->ContractTypeUpdate(
                    %GetParam,
                    UserID => $Self->{UserID},
                );
                if ( !$Success ) {
                    $Error{Message} = $Kernel::OM->Get('Kernel::System::Log')->GetLogEntry(
                        Type => 'Error',
                        What => 'Message',
                    );
                }
            }

            if ( !%Error ) {

                # update preferences
                my %ContractTypeData = $ContractTypeObject->ContractTypeGet(
                    ContractTypeID => $GetParam{ContractTypeID},
                    UserID         => $Self->{UserID},
                );

                # redirect to overview
                return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
            }
        }

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Error{Message}
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Error{Message},
            )
            : '';

        # html output
        $Output .= $Self->_MaskNew(
            %Error,
            %GetParam,
            %Param,
        );
        $Output .= $LayoutObject->Footer();

    }

    # ------------------------------------------------------------ #
    # ContractType overview
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

        # get service list
        my %ContractTypeList = $ContractTypeObject->ContractTypeList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # if there are any ContractType defined, they are shown
        if (%ContractTypeList) {

            # get valid list
            my %ValidList = $ValidObject->ValidList();

            # add suffix for correct sorting
            for ( keys %ContractTypeList ) {
                $ContractTypeList{$_} .= '::';
            }
            for my $ContractTypeID (
                sort { $ContractTypeList{$a} cmp $ContractTypeList{$b} }
                keys %ContractTypeList
                )
            {

                # get RequestCategories data
                my %ContractTypeData = $ContractTypeObject->ContractTypeGet(
                    ContractTypeID => $ContractTypeID,
                    UserID         => $Self->{UserID},
                );

                # output row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => {
                        %ContractTypeData,
                        Valid => $ValidList{ $ContractTypeData{ValidID} },
                    },
                );
            }

        }

        # otherwise a no data found msg is displayed
        else {
            $LayoutObject->Block(
                Name => 'NoDataFoundMsg',
                Data => {},
            );
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminContractType',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my %ContractTypeData;

    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ContractTypeObject = $Kernel::OM->Get('Kernel::System::ContractType');
    my $ValidObject        = $Kernel::OM->Get('Kernel::System::Valid');

    # get params
    $ContractTypeData{ContractTypeID}
        = $ParamObject->GetParam( Param => "ContractTypeID" );
    if ( $ContractTypeData{ContractTypeID} ne 'NEW' ) {
        %ContractTypeData = $ContractTypeObject->ContractTypeGet(
            ContractTypeID => $ContractTypeData{ContractTypeID},
            UserID         => $Self->{UserID},
        );
    }

    # output overview
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # generate ParentOptionStrg
    my %ContractTypeList = $ContractTypeObject->ContractTypeList(
        Valid  => 0,
        UserID => $Self->{UserID},
    );
    $ContractTypeData{ParentOptionStrg} = $LayoutObject->BuildSelection(
        Data           => \%ContractTypeList,
        Name           => 'ParentID',
        SelectedID     => $Param{ParentID} || $ContractTypeData{ParentID},
        PossibleNone   => 1,
        DisabledBranch => $ContractTypeData{Name},
        Translation    => 0,
        Max            => 50,
    );

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $ContractTypeData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data           => \%ValidList,
        Name           => 'ValidID',
        ContractTypeID => $ContractTypeData{ValidID} || $ValidListReverse{valid},
    );

    # output service edit
    $LayoutObject->Block(
        Name => 'ContractTypeEdit',
        Data => { %Param, %ContractTypeData, },
    );

    # shows header
    if ( $ContractTypeData{ContractTypeID} ne 'NEW' ) {
        $LayoutObject->Block(
            Name => 'HeaderEdit',
            Data => {%ContractTypeData},
        );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    # generate output
    return $LayoutObject->Output( TemplateFile => 'AdminContractType', Data => \%Param );
}
1;
