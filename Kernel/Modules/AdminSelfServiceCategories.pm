# --
# Kernel/Modules/AdminSelfServiceCategories.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminSelfServiceCategories.pm,v 1.3 2016/09/20 12:34:27 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminSelfServiceCategories;

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

    my $ParamObject                 = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SelfServiceCategoriesObject = $Kernel::OM->Get('Kernel::System::SelfServiceCategories');
    my $ValidObject                 = $Kernel::OM->Get('Kernel::System::Valid');

    # ------------------------------------------------------------ #
    # SelfServiceCategories edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'SelfServiceCategoriesEdit' ) {

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
    # SelfServiceCategories save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'SelfServiceCategoriesSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for (qw(SelfServiceCategoriesID ParentID Name SelfServiceColor ValidID Comment ImageID)) {
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
            if ( $GetParam{SelfServiceCategoriesID} eq 'NEW' ) {
                $GetParam{SelfServiceCategoriesID}
                    = $SelfServiceCategoriesObject->SelfServiceCategoriesAdd(
                    %GetParam,
                    UserID => $Self->{UserID},
                    );
                if ( !$GetParam{SelfServiceCategoriesID} ) {
                    $Error{Message} = $Kernel::OM->Get('Kernel::System::Log')->GetLogEntry(
                        Type => 'Error',
                        What => 'Message',
                    );
                }
            }
            else {
                my $Success = $SelfServiceCategoriesObject->SelfServiceCategoriesUpdate(
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
                my %SelfServiceCategoriesData = $SelfServiceCategoriesObject->SelfServiceCategoriesGet(
                    SelfServiceCategoriesID => $GetParam{SelfServiceCategoriesID},
                    UserID                  => $Self->{UserID},
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
    # SelfServiceCategories overview
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
        my %SelfServiceCategoriesList = $SelfServiceCategoriesObject->SelfServiceCategoriesList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # if there are any SelfServiceCategories defined, they are shown
        if (%SelfServiceCategoriesList) {

            # get valid list
            my %ValidList = $ValidObject->ValidList();

            # add suffix for correct sorting
            for ( keys %SelfServiceCategoriesList ) {
                $SelfServiceCategoriesList{$_} .= '::';
            }
            for my $SelfServiceCategoriesID (
                sort { $SelfServiceCategoriesList{$a} cmp $SelfServiceCategoriesList{$b} }
                keys %SelfServiceCategoriesList
                )
            {

                # get SelfServiceCategories data
                my %SelfServiceCategoriesData = $SelfServiceCategoriesObject->SelfServiceCategoriesGet(
                    SelfServiceCategoriesID => $SelfServiceCategoriesID,
                    UserID                  => $Self->{UserID},
                );

                # output row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => {
                        %SelfServiceCategoriesData,
                        Valid => $ValidList{ $SelfServiceCategoriesData{ValidID} },
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
            TemplateFile => 'AdminSelfServiceCategories',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my %SelfServiceCategoriesData;

    my $ParamObject                     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SelfServiceCategoriesObject     = $Kernel::OM->Get('Kernel::System::SelfServiceCategories');
    my $ValidObject                     = $Kernel::OM->Get('Kernel::System::Valid');
    my $SelfServiceCategoriesIconObject = $Kernel::OM->Get('Kernel::System::SelfServiceCategoriesIcon');

    # get params
    $SelfServiceCategoriesData{SelfServiceCategoriesID}
        = $ParamObject->GetParam( Param => "SelfServiceCategoriesID" );
    if ( $SelfServiceCategoriesData{SelfServiceCategoriesID} ne 'NEW' ) {
        %SelfServiceCategoriesData = $SelfServiceCategoriesObject->SelfServiceCategoriesGet(
            SelfServiceCategoriesID => $SelfServiceCategoriesData{SelfServiceCategoriesID},
            UserID                  => $Self->{UserID},
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
    my %SelfServiceCategoriesList = $SelfServiceCategoriesObject->SelfServiceCategoriesList(
        Valid  => 0,
        UserID => $Self->{UserID},
    );
    $SelfServiceCategoriesData{ParentOptionStrg} = $LayoutObject->BuildSelection(
        Data           => \%SelfServiceCategoriesList,
        Name           => 'ParentID',
        SelectedID     => $Param{ParentID} || $SelfServiceCategoriesData{ParentID},
        PossibleNone   => 1,
        DisabledBranch => $SelfServiceCategoriesData{Name},
        Translation    => 0,
        Max            => 50,
    );

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $SelfServiceCategoriesData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data                    => \%ValidList,
        Name                    => 'ValidID',
        SelfServiceCategoriesID => $SelfServiceCategoriesData{ValidID} || $ValidListReverse{valid},
    );

    # output service edit
    $LayoutObject->Block(
        Name => 'SelfServiceCategoriesEdit',
        Data => { %Param, %SelfServiceCategoriesData, },
    );

    # shows header
    if ( $SelfServiceCategoriesData{SelfServiceCategoriesID} ne 'NEW' ) {
        $LayoutObject->Block(
            Name => 'HeaderEdit',
            Data => {%SelfServiceCategoriesData},
        );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    my %List = $SelfServiceCategoriesIconObject->SelfServiceCategoriesIconList(
        UserID => 1,
        Valid  => 1,
    );

    # if there are any results, they are shown
    if (%List) {

        # get valid list
        for my $ID ( sort { $List{$a} cmp $List{$b} } keys %List ) {
            my %Data = $SelfServiceCategoriesIconObject->SelfServiceCategoriesIconGet(
                ID => $ID,
            );

            $Data{Content} = encode_base64($Data{Content});
            if ( $ID == $SelfServiceCategoriesData{ImageID} ) {
                $Data{CheckedImageID} = 'checked="checked"';
                $Data{ColorImageID} = 'green 2px solid';
            }
            else {
                $Data{ColorImageID} = '#c1e6f5 2px solid';
            }

            $LayoutObject->Block(
                Name => 'CategoryIcons',
                Data => { %Param, %Data, },
            );
        }
    }

    # generate output
    return $LayoutObject->Output( TemplateFile => 'AdminSelfServiceCategories', Data => \%Param );
}
1;
