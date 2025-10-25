# --
# Kernel/Modules/AdminRoomEquipment.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminRoomEquipment.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminRoomEquipment;

use strict;
use warnings;

use Kernel::System::Valid;
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

    my $ParamObject         = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RoomEquipmentObject  = $Kernel::OM->Get('Kernel::System::RoomEquipment');
    my $LogObject           = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
    my $Notification        = $ParamObject->GetParam( Param => 'Notification' ) || '';

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'EquipmentID' )
            || '';
        my %Data = $RoomEquipmentObject->EquipmentGet( ID => $ID );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Equipment updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_Edit(
            Action => 'Change',
            %Data,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminRoomEquipment',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Note = '';
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Quantity EquipmentType Price PriceFor Currency Model Bookable Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        if ( !$GetParam{Name} ) {
            $Errors{EquipmentNameInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            if ( !$GetParam{EquipmentType} ) {
                $GetParam{EquipmentType} = 0;
            }
            if ( !$GetParam{PriceFor} ) {
                $GetParam{PriceFor} = 0;
            }
            if ( !$GetParam{Bookable} ) {
                $GetParam{Bookable} = 0;
            }

            # update Equipment
            my $EquipmentUpdate = $RoomEquipmentObject->EquipmentUpdate(
                %GetParam,
                UserID => $Self->{UserID}
            );

            if ($EquipmentUpdate) {

                # if the user would like to continue editing the Equipment, just redirect to the edit screen
                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                    && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                    )
                {
                    my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Change;ID=$GetParam{ID};Notification=Update"
                    );
                }
                else {

                    # otherwise return to overview
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Notification=Update" );
                }
            }
            else {
                $Note = $LogObject->GetLogEntry(
                    Type => 'Error',
                    What => 'Message',
                );
            }
        }

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Note
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Note,
            )
            : '';
        $Self->_Edit(
            Action => 'Change',
            %GetParam,
            %Errors,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminRoomEquipment',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my %GetParam = ();

        $GetParam{Name} = $ParamObject->GetParam( Param => 'Name' );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminRoomEquipment',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Note = '';
        my $EquipmentID;
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Quantity EquipmentType Price PriceFor Currency Model Bookable Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        if ( !$GetParam{Name} ) {
            $Errors{EquipmentNameInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            if ( !$GetParam{EquipmentType} ) {
                $GetParam{EquipmentType} = 0;
            }
            if ( !$GetParam{PriceFor} ) {
                $GetParam{PriceFor} = 0;
            }
            if ( !$GetParam{Bookable} ) {
                $GetParam{Bookable} = 0;
            }

            # add Equipment
            $EquipmentID = $RoomEquipmentObject->EquipmentAdd(
                %GetParam,
                UserID => $Self->{UserID}
            );

            if ($EquipmentID) {

                # redirect
                return $LayoutObject->Redirect(
                    OP => 'Action=AdminRoomEquipment',
                );
            }
            else {
                $Note = $LogObject->GetLogEntry(
                    Type => 'Error',
                    What => 'Message',
                );
            }
        }

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Note
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Note,
            )
            : '';
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
            %Errors,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminRoomEquipment',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Equipment updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminRoomEquipment',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject  = $Kernel::OM->Get('Kernel::System::Valid');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    my %EquipmentType = ( '1' => 'Device', '2' => 'Catering' );
    $Param{EquipmentTypeStrg} = $LayoutObject->BuildSelection(
        Name         => 'EquipmentType',
        Data         => \%EquipmentType,
        SelectedID   => $Param{EquipmentType},
        Class        => "Modernize",
        Translation  => 1,
        PossibleNone => 1,
    );

    my %PriceFor = ( '1' => '1 hour', '2' => '1 day', '3' => '1 piece' );
    $Param{PriceForStrg} = $LayoutObject->BuildSelection(
        Name         => 'PriceFor',
        Data         => \%PriceFor,
        SelectedID   => $Param{PriceFor},
        Class        => "Modernize",
        Translation  => 1,
        PossibleNone => 1,
    );

    my %Bookable = ( '1' => 'existing', '2' => 'bookable' );
    $Param{BookableStrg} = $LayoutObject->BuildSelection(
        Name         => 'Bookable',
        Data         => \%Bookable,
        SelectedID   => $Param{Bookable},
        Class        => "Modernize",
        Translation  => 1,
        PossibleNone => 1,
    );

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        Class      => 'Modernize',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => \%Param,
    );

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RoomEquipmentObject  = $Kernel::OM->Get('Kernel::System::RoomEquipment');
    my $ValidObject         = $Kernel::OM->Get('Kernel::System::Valid');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    my %List = $RoomEquipmentObject->EquipmentList(
        ValidID => 0,
    );
    my $ListSize = keys %List;
    $Param{AllItemsCount} = $ListSize;

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    # get valid list
    my %ValidList = $ValidObject->ValidList();
    for my $ListKey ( sort { $List{$a} cmp $List{$b} } keys %List ) {

        my %Data = $RoomEquipmentObject->EquipmentGet(
            ID => $ListKey,
        );
        $LayoutObject->Block(
            Name => 'OverviewResultRow',
            Data => {
                Valid => $ValidList{ $Data{ValidID} },
                %Data,
            },
        );
    }
    return 1;
}

1;
