# --
# Kernel/Modules/AdminRequestCategories.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminRequestCategories.pm,v 1.3 2016/09/20 12:34:27 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminRequestCategories;

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

    my $ParamObject             = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RequestCategoriesObject = $Kernel::OM->Get('Kernel::System::RequestCategories');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');

    # ------------------------------------------------------------ #
    # RequestCategories edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'RequestCategoriesEdit' ) {

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
    # RequestCategories save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'RequestCategoriesSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for (qw(RequestCategoriesID ParentID Name ValidID Comment ImageID)) {
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
            if ( $GetParam{RequestCategoriesID} eq 'NEW' ) {
                $GetParam{RequestCategoriesID}
                    = $RequestCategoriesObject->RequestCategoriesAdd(
                    %GetParam,
                    UserID => $Self->{UserID},
                    );
                if ( !$GetParam{RequestCategoriesID} ) {
                    $Error{Message} = $Kernel::OM->Get('Kernel::System::Log')->GetLogEntry(
                        Type => 'Error',
                        What => 'Message',
                    );
                }
            }
            else {
                my $Success = $RequestCategoriesObject->RequestCategoriesUpdate(
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
                my %RequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
                    RequestCategoriesID => $GetParam{RequestCategoriesID},
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
    # RequestCategories overview
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
        my %RequestCategoriesList = $RequestCategoriesObject->RequestCategoriesList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # if there are any RequestCategories defined, they are shown
        if (%RequestCategoriesList) {

            # get valid list
            my %ValidList = $ValidObject->ValidList();

            # add suffix for correct sorting
            for ( keys %RequestCategoriesList ) {
                $RequestCategoriesList{$_} .= '::';
            }
            for my $RequestCategoriesID (
                sort { $RequestCategoriesList{$a} cmp $RequestCategoriesList{$b} }
                keys %RequestCategoriesList
                )
            {

                # get RequestCategories data
                my %RequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
                    RequestCategoriesID => $RequestCategoriesID,
                    UserID             => $Self->{UserID},
                );

                # output row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => {
                        %RequestCategoriesData,
                        Valid => $ValidList{ $RequestCategoriesData{ValidID} },
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
            TemplateFile => 'AdminRequestCategories',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my %RequestCategoriesData;

    my $ParamObject             = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RequestCategoriesObject = $Kernel::OM->Get('Kernel::System::RequestCategories');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
    my $RequestCategoriesIconObject = $Kernel::OM->Get('Kernel::System::RequestCategoriesIcon');

    # get params
    $RequestCategoriesData{RequestCategoriesID}
        = $ParamObject->GetParam( Param => "RequestCategoriesID" );
    if ( $RequestCategoriesData{RequestCategoriesID} ne 'NEW' ) {
        %RequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
            RequestCategoriesID => $RequestCategoriesData{RequestCategoriesID},
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
    my %RequestCategoriesList = $RequestCategoriesObject->RequestCategoriesList(
        Valid  => 0,
        UserID => $Self->{UserID},
    );
    $RequestCategoriesData{ParentOptionStrg} = $LayoutObject->BuildSelection(
        Data           => \%RequestCategoriesList,
        Name           => 'ParentID',
        SelectedID     => $Param{ParentID} || $RequestCategoriesData{ParentID},
        PossibleNone   => 1,
        DisabledBranch => $RequestCategoriesData{Name},
        Translation    => 0,
        Max            => 50,
    );

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $RequestCategoriesData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data                => \%ValidList,
        Name                => 'ValidID',
        RequestCategoriesID => $RequestCategoriesData{ValidID} || $ValidListReverse{valid},
    );

    # output service edit
    $LayoutObject->Block(
        Name => 'RequestCategoriesEdit',
        Data => { %Param, %RequestCategoriesData, },
    );

    # shows header
    if ( $RequestCategoriesData{RequestCategoriesID} ne 'NEW' ) {
        $LayoutObject->Block(
            Name => 'HeaderEdit',
            Data => {%RequestCategoriesData},
        );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    my %List = $RequestCategoriesIconObject->RequestCategoriesIconList(
        UserID => 1,
        Valid  => 1,
    );

    # if there are any results, they are shown
    if (%List) {

        # get valid list
        for my $ID ( sort { $List{$a} cmp $List{$b} } keys %List ) {
            my %Data = $RequestCategoriesIconObject->RequestCategoriesIconGet(
                ID => $ID,
            );

            $Data{Content} = encode_base64($Data{Content});
            if ( $ID == $RequestCategoriesData{ImageID} ) {
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
    return $LayoutObject->Output( TemplateFile => 'AdminRequestCategories', Data => \%Param );
}
1;
