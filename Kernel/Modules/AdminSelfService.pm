# --
# Kernel/Modules/AdminSelfService.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminSelfService.pm,v 1.37 2016/09/20 12:33:43 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminSelfService;

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

    #get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get form id
    $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'FormID' );

    # create form id
    if ( !$Self->{FormID} ) {
        $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCreate();
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my %Error = ();

    my $ParamObject                 = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                 = $Kernel::OM->Get('Kernel::System::Valid');
    my $SelfServiceObject           = $Kernel::OM->Get('Kernel::System::SelfService');
    my $SelfServiceCategoriesObject = $Kernel::OM->Get('Kernel::System::SelfServiceCategories');

    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'SelfServiceEdit' ) {

        # get params
        my %GetParam;

        for my $Param (
            qw(SelfServiceID SelfServiceCategoriesID Headline Schlagwoerter SelfServiceText SelfServiceColor)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            SelfServiceID           => $GetParam{SelfServiceID},
            SelfServiceCategoriesID => $GetParam{SelfServiceCategoriesID},
            %Param,
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'SelfServiceSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for my $Param (

            qw(SelfServiceID SelfServiceCategoriesID Headline Schlagwoerter SelfServiceText SelfServiceColor ValidID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{Headline} ) {
            $Error{'HeadlineInvalid'} = 'ServerError';
        }

        if ( !$GetParam{SelfServiceCategoriesID} ) {
            $Error{'SelfServiceCategoriesIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {

            my %SelfServiceCategoriesData = $SelfServiceCategoriesObject->SelfServiceCategoriesGet(
                SelfServiceCategoriesID => $GetParam{SelfServiceCategoriesID},
                UserID                  => 1,
            );

            if ( $GetParam{SelfServiceID} ) {

                my $SelfServiceID = $SelfServiceObject->SelfServiceUpdate(
                    SelfServiceID           => $GetParam{SelfServiceID},
                    SelfServiceCategoriesID => $GetParam{SelfServiceCategoriesID},
                    SelfServiceCategories   => $SelfServiceCategoriesData{Name},
                    Headline                => $GetParam{Headline},
                    Schlagwoerter           => $GetParam{Schlagwoerter},
                    SelfServiceText         => $GetParam{SelfServiceText},
                    SelfServiceColor        => $GetParam{SelfServiceColor},
                    ValidID                 => $GetParam{ValidID},
                    UserID                  => $Self->{UserID},
                );
            }
            else {

                my $SelfServiceID = $SelfServiceObject->SelfServiceAdd(
                    SelfServiceCategoriesID => $GetParam{SelfServiceCategoriesID},
                    SelfServiceCategories   => $SelfServiceCategoriesData{Name},
                    Headline                => $GetParam{Headline},
                    Schlagwoerter           => $GetParam{Schlagwoerter},
                    SelfServiceText         => $GetParam{SelfServiceText},
                    SelfServiceColor        => $GetParam{SelfServiceColor},
                    ValidID                 => $GetParam{ValidID},
                    UserID                  => $Self->{UserID},
                );
                $GetParam{SelfServiceID} = $SelfServiceID;
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
            SelfServiceID  => $GetParam{SelfServiceID},
            IDError        => $GetParam{IDError},
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

        # get list
        my %SelfServiceList = $SelfServiceObject->SelfServiceList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # get valid list
        my %ValidList = $ValidObject->ValidList();

        if (%SelfServiceList) {
            for my $SelfServiceID ( sort { lc $SelfServiceList{$a} cmp lc $SelfServiceList{$b} } keys %SelfServiceList ) {

                # get the sla data
                my %SelfServiceData = $SelfServiceObject->SelfServiceGet(
                    SelfServiceID => $SelfServiceID,
                    UserID        => $Self->{UserID},
                );

                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => { %SelfServiceData, Valid => $ValidList{ $SelfServiceData{ValidID} }, },
                );
            }
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSelfService',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {

    my ( $Self, %Param ) = @_;

    my $ParamObject                 = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                 = $Kernel::OM->Get('Kernel::System::Valid');
    my $ConfigObject                = $Kernel::OM->Get('Kernel::Config');
    my $UserObject                  = $Kernel::OM->Get('Kernel::System::User');
    my $SelfServiceObject           = $Kernel::OM->Get('Kernel::System::SelfService');
    my $SelfServiceCategoriesObject = $Kernel::OM->Get('Kernel::System::SelfServiceCategories');

    $Param{FormID} = $Self->{FormID};

    # get params
    my %SelfServiceData;
    $SelfServiceData{SelfServiceID} = $Param{SelfServiceID} || '';
    $SelfServiceData{IDError}  = $Param{IDError}  || '';

    if ( $SelfServiceData{SelfServiceID} ) {

        # get the sla data
        %SelfServiceData = $SelfServiceObject->SelfServiceGet(
            SelfServiceID => $SelfServiceData{SelfServiceID},
            UserID        => $Self->{UserID},
        );
    }

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $SelfServiceData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $SelfServiceData{ValidID} || $ValidListReverse{valid},
    );

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%SelfServiceData,
        );
    }

    $LayoutObject->AddJSData(
        Key   => 'FromExternalCustomerEmail',
        Value => 1,
    );

    # build RequestCategories dropdown
    my %SelfServiceCategoriesList = $SelfServiceCategoriesObject->SelfServiceCategoriesList(
        Valid  => 1,
        UserID => $Self->{UserID},
    );

    $SelfServiceData{SelfServiceCategoriesStrg} = $LayoutObject->BuildSelection(
        Name         => 'SelfServiceCategoriesID',
        Data         => \%SelfServiceCategoriesList,
        SelectedID   => $SelfServiceData{SelfServiceCategoriesID},
        Class        => "Modernize",
        PossibleNone => 1,
    );

    # output edit
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, %SelfServiceData, },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    $LayoutObject->Block(
        Name => 'SelfServiceEdit',
        Data => { %Param, %SelfServiceData, },
    );

    # shows header
    if ( $SelfServiceData{SelfServiceID} ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    # get output back
    return $LayoutObject->Output( TemplateFile => 'AdminSelfService', Data => \%Param );
}

1;
