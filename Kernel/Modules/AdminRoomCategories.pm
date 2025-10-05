# --
# Kernel/Modules/AdminRoomCategories.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AdminRoomCategories.pm,v 1.3 2016/09/20 12:34:27 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminRoomCategories;

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

    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RoomCategoriesObject = $Kernel::OM->Get('Kernel::System::RoomCategories');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');

    # ------------------------------------------------------------ #
    # RoomCategories edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'RoomCategoriesEdit' ) {

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
    # RoomCategories save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'RoomCategoriesSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for (qw(RoomCategoriesID ParentID Name ValidID Comment ImageID)) {
            $GetParam{$_} = $ParamObject->GetParam( Param => $_ ) || '';
        }

        my %Error;

        if ( !$GetParam{Name} ) {
            $Error{'NameInvalid'} = 'ServerError';
        }
        if ( !$GetParam{ImageID} ) {
            $GetParam{ImageID} = '0';
        }

        if ( !%Error ) {

            # save to database
            if ( $GetParam{RoomCategoriesID} eq 'NEW' ) {
                $GetParam{RoomCategoriesID}
                    = $RoomCategoriesObject->RoomCategoriesAdd(
                    %GetParam,
                    UserID => $Self->{UserID},
                    );
                if ( !$GetParam{RoomCategoriesID} ) {
                    $Error{Message} = $Kernel::OM->Get('Kernel::System::Log')->GetLogEntry(
                        Type => 'Error',
                        What => 'Message',
                    );
                }
            }
            else {
                my $Success = $RoomCategoriesObject->RoomCategoriesUpdate(
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
                my %RoomCategoriesData = $RoomCategoriesObject->RoomCategoriesGet(
                    RoomCategoriesID => $GetParam{RoomCategoriesID},
                    UserID             => $Self->{UserID},
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
    # RoomCategories overview
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
        my %RoomCategoriesList = $RoomCategoriesObject->RoomCategoriesList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # if there are any RoomCategories defined, they are shown
        if (%RoomCategoriesList) {

            # get valid list
            my %ValidList = $ValidObject->ValidList();

            # add suffix for correct sorting
            for ( keys %RoomCategoriesList ) {
                $RoomCategoriesList{$_} .= '::';
            }
            for my $RoomCategoriesID (
                sort { $RoomCategoriesList{$a} cmp $RoomCategoriesList{$b} }
                keys %RoomCategoriesList
                )
            {

                # get RoomCategories data
                my %RoomCategoriesData = $RoomCategoriesObject->RoomCategoriesGet(
                    RoomCategoriesID => $RoomCategoriesID,
                    UserID             => $Self->{UserID},
                );

                # output row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => {
                        %RoomCategoriesData,
                        Valid => $ValidList{ $RoomCategoriesData{ValidID} },
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
            TemplateFile => 'AdminRoomCategories',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my %RoomCategoriesData;

    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RoomCategoriesObject = $Kernel::OM->Get('Kernel::System::RoomCategories');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');

    # Roomams
    $RoomCategoriesData{RoomCategoriesID}
        = $ParamObject->GetParam( Param => "RoomCategoriesID" );
    if ( $RoomCategoriesData{RoomCategoriesID} ne 'NEW' ) {
        %RoomCategoriesData = $RoomCategoriesObject->RoomCategoriesGet(
            RoomCategoriesID => $RoomCategoriesData{RoomCategoriesID},
            UserID             => $Self->{UserID},
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
    my %RoomCategoriesList = $RoomCategoriesObject->RoomCategoriesList(
        Valid  => 0,
        UserID => $Self->{UserID},
    );
    $RoomCategoriesData{ParentOptionStrg} = $LayoutObject->BuildSelection(
        Data           => \%RoomCategoriesList,
        Name           => 'ParentID',
        SelectedID     => $Param{ParentID} || $RoomCategoriesData{ParentID},
        PossibleNone   => 1,
        DisabledBranch => $RoomCategoriesData{Name},
        Translation    => 0,
        Max            => 50,
    );

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $RoomCategoriesData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data                => \%ValidList,
        Name                => 'ValidID',
        RoomCategoriesID => $RoomCategoriesData{ValidID} || $ValidListReverse{valid},
    );

    # output service edit
    $LayoutObject->Block(
        Name => 'RoomCategoriesEdit',
        Data => { %Param, %RoomCategoriesData, },
    );

    # shows header
    if ( $RoomCategoriesData{RoomCategoriesID} ne 'NEW' ) {
        $LayoutObject->Block(
            Name => 'HeaderEdit',
            Data => {%RoomCategoriesData},
        );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }


    # generate output
    return $LayoutObject->Output( TemplateFile => 'AdminRoomCategories', Data => \%Param );
}
1;
