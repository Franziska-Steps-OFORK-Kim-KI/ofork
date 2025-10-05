# --
# Kernel/Modules/AdminRequestForm.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AdminRequestForm.pm,v 1.37 2016/09/20 12:33:43 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminRequestForm;

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

    my $ParamObject             = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
    my $RequestObject           = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFieldsObject     = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestFormObject       = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $RequestFormBlockObject  = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $GroupObject             = $Kernel::OM->Get('Kernel::System::Group');
    my $QueueObject             = $Kernel::OM->Get('Kernel::System::Queue');
    my $RequestCategoriesObject = $Kernel::OM->Get('Kernel::System::RequestCategories');
    my $TypeObject              = $Kernel::OM->Get('Kernel::System::Type');

    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'RequestEdit' ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(RequestID RequestFormID RequestFormBlockID RequestFormValueID RequestFormValueText RequestFormLabel)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            RequestID            => $GetParam{RequestID},
            RequestFormID        => $GetParam{RequestFormID},
            RequestFormBlockID   => $GetParam{RequestFormBlockID},
            RequestFormValueID   => $GetParam{RequestFormValueID},
            RequestFormValueText => $GetParam{RequestFormValueText},
            RequestFormLabel     => $GetParam{RequestFormLabel},
            %Param,
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'RequestSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        my @ShowConfigItems = $ParamObject->GetArray( Param => 'ShowConfigItem' );
        $GetParam{ShowConfigItems} = '';
        for my $ShowConfigItems (@ShowConfigItems) {
            $GetParam{ShowConfigItems} .= "$ShowConfigItems,";
        }

        for my $Param (

            qw(RequestID Name Queue Type NewOwnerID NewResponsibleID RequestCategoriesID ValidID ProcessID Comment ImageID Subject ShowAttachment RequestGroup SubjectChangeable)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{Name} ) {
            $Error{'NameInvalid'} = 'ServerError';
        }

        if ( !$GetParam{Subject} ) {
            $GetParam{Subject} = 'No subject yet';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( !$GetParam{Queue} ) {
                $GetParam{Queue} = 0;
            }
            if ( !$GetParam{Type} ) {
                $GetParam{Type} = 0;
            }
            if ( !$GetParam{NewOwnerID} ) {
                $GetParam{NewOwnerID} = 0;
            }
            if ( !$GetParam{NewResponsibleID} ) {
                $GetParam{NewResponsibleID} = 0;
            }
            if ( !$GetParam{ImageID} ) {
                $GetParam{ImageID} = 0;
            }
            if ( !$GetParam{Comment} ) {
                $GetParam{Comment} = '-';
            }
            if ( !$GetParam{RequestGroup} ) {
                $GetParam{RequestGroup} = 0;
            }
            if ( $GetParam{ShowConfigItems} ) {
                $GetParam{ShowConfigItem} = 1;
            }
            else {
                $GetParam{ShowConfigItem} = 0;
            }
            if ( !$GetParam{ProcessID} ) {
                $GetParam{ProcessID} = 0;
            }

            if ( $GetParam{RequestID} ) {

                if ( $GetParam{RequestCategoriesID} ) {

                    my $TemplateKategorienID  = $RequestCategoriesObject->RequestCategoriesTemplateGet(
                        TemplateID => $GetParam{RequestID},
                        UserID     => $Self->{UserID},
                    );

                    if ($TemplateKategorienID) {
                        my $RequestCategoriesTemplateID = $RequestCategoriesObject->RequestCategoriesTemplateUpdate(
                            TemplateID          => $GetParam{RequestID},
                            RequestCategoriesID => $GetParam{RequestCategoriesID},
                            UserID              => $Self->{UserID},
                        );
                    }
                    else {
                        my $RequestCategoriesTemplateID = $RequestCategoriesObject->RequestCategoriesTemplateAdd(
                            TemplateID          => $GetParam{RequestID},
                            RequestCategoriesID => $GetParam{RequestCategoriesID},
                            UserID              => $Self->{UserID},
                        );
                    }
                }

                my $RequestID = $RequestObject->RequestUpdate(
                    RequestID         => $GetParam{RequestID},
                    Name              => $GetParam{Name},
                    Subject           => $GetParam{Subject},
                    SubjectChangeable => $GetParam{SubjectChangeable},
                    Queue             => $GetParam{Queue},
                    Type              => $GetParam{Type},
                    ValidID           => $GetParam{ValidID},
                    ProcessID         => $GetParam{ProcessID},
                    Comment           => $GetParam{Comment},
                    ImageID           => $GetParam{ImageID},
                    ShowConfigItem    => $GetParam{ShowConfigItem},
                    ShowConfigItems   => $GetParam{ShowConfigItems},
                    OwnerID           => $GetParam{NewOwnerID},
                    ResponsibleID     => $GetParam{NewResponsibleID},
                    ShowAttachment    => $GetParam{ShowAttachment},
                    RequestGroup      => $GetParam{RequestGroup},
                    UserID            => $Self->{UserID},
                );
            }
            else {

                my $RequestID = $RequestObject->RequestAdd(
                    Name              => $GetParam{Name},
                    Queue             => $GetParam{Queue},
                    Subject           => $GetParam{Subject},
                    SubjectChangeable => $GetParam{SubjectChangeable},
                    Type              => $GetParam{Type},
                    ValidID           => $GetParam{ValidID},
                    ProcessID         => $GetParam{ProcessID},
                    Comment           => $GetParam{Comment},
                    ImageID           => $GetParam{ImageID},
                    ShowConfigItem    => $GetParam{ShowConfigItem},
                    ShowConfigItems   => $GetParam{ShowConfigItems},
                    OwnerID           => $GetParam{NewOwnerID},
                    ResponsibleID     => $GetParam{NewResponsibleID},
                    ShowAttachment    => $GetParam{ShowAttachment},
                    RequestGroup      => $GetParam{RequestGroup},
                    UserID            => $Self->{UserID},
                );

                $GetParam{RequestID} = $RequestID;

                if ( $GetParam{RequestCategoriesID} ) {
                    my $RequestCategoriesTemplateID = $RequestCategoriesObject->RequestCategoriesTemplateAdd(
                        TemplateID          => $RequestID,
                        RequestCategoriesID => $GetParam{RequestCategoriesID},
                        UserID              => $Self->{UserID},
                    );
                }
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
            RequestID => $GetParam{RequestID},
            IDError  => $GetParam{IDError},
            %Param,
            %GetParam,
            %Error,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    #  delete
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'RequestFieldDelete' ) {

        # get params
        my %GetParam;
        for my $Param (

            qw(RequestID RequestFormID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my $Sucess
            = $RequestFormObject->RequestFieldDelete( RequestFormID => $GetParam{RequestFormID}, );
        $GetParam{RequestFormID} = '';

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            RequestID => $GetParam{RequestID},
            %Param,
            %GetParam,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    #  delete
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'RequestFieldBlockDelete' ) {

        # get params
        my %GetParam;
        for my $Param (

            qw(RequestFormValueID RequestFormBlockID RequestID RequestFormID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my $Sucess = $RequestFormBlockObject->RequestFieldBlockDelete(
            RequestFormBlockID => $GetParam{RequestFormBlockID},
        );
        $GetParam{RequestFormBlockID} = '';

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            RequestID => $GetParam{RequestID},
            %Param,
            %GetParam,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'FieldsSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;
        for my $Param (
            qw(RequestFormID RequestID FeldID RequiredField Order MoveOver ValidID ToolTipUnder)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{RequestID} ) {
            $Error{'RequestIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {
            if ( $GetParam{RequestFormID} ) {
                my $RequestFormID = $RequestFormObject->RequestFormUpdate(
                    RequestFormID => $GetParam{RequestFormID},
                    RequestID     => $GetParam{RequestID},
                    FeldID        => $GetParam{FeldID},
                    RequiredField   => $GetParam{RequiredField},
                    Order   => $GetParam{Order},
                    ToolTip       => $GetParam{MoveOver},
                    ValidID       => $GetParam{ValidID},
                    ToolTipUnder  => $GetParam{ToolTipUnder},
                    UserID        => $Self->{UserID},
                );
            }
            else {
                my $RequestFormID = $RequestFormObject->RequestFormAdd(
                    RequestID   => $GetParam{RequestID},
                    FeldID      => $GetParam{FeldID},
                    RequiredField => $GetParam{RequiredField},
                    Order => $GetParam{Order},
                    ToolTip     => $GetParam{MoveOver},
                    ValidID     => $GetParam{ValidID},
                    ToolTipUnder  => $GetParam{ToolTipUnder},
                    UserID      => $Self->{UserID},
                );
            }
        }

        my $RequestIDGet = $GetParam{RequestID};
        my $IDError     = $GetParam{IDError};
        %GetParam = ();
        %Param    = ();

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
            RequestID => $RequestIDGet,
            IDError  => $IDError,
            %Param,
            %GetParam,
            %Error,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save block
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'FieldsSaveBlock' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;
        my @AgentenRollenArray;
        for my $Param (
            qw(RequestFormID RequestID RequestFormBlockID RequestFormValueID FeldIDBlock RequiredFieldBlock OrderBlock MoveOverBlock  ValidID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{RequestID} ) {
            $Error{'RequestIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {
            if ( $GetParam{RequestFormBlockID} ) {
                my $RequestFormBlockID = $RequestFormBlockObject->RequestFormBlockUpdate(
                    RequestFormBlockID => $GetParam{RequestFormBlockID},
                    RequestFormID      => $GetParam{RequestFormID},
                    RequestFormValueID => $GetParam{RequestFormValueID},
                    RequestID          => $GetParam{RequestID},
                    FeldID             => $GetParam{FeldIDBlock},
                    RequiredField      => $GetParam{RequiredFieldBlock},
                    Order              => $GetParam{OrderBlock},
                    ToolTip            => $GetParam{MoveOverBlock},
                    ValidID            => $GetParam{ValidID},
                    UserID             => $Self->{UserID},
                );
            }
            else {
                my $RequestFormBlockID = $RequestFormBlockObject->RequestFormBlockAdd(
                    RequestFormID      => $GetParam{RequestFormID},
                    RequestFormValueID => $GetParam{RequestFormValueID},
                    RequestID          => $GetParam{RequestID},
                    FeldID             => $GetParam{FeldIDBlock},
                    RequiredField      => $GetParam{RequiredFieldBlock},
                    Order              => $GetParam{OrderBlock},
                    ToolTip            => $GetParam{MoveOverBlock},
                    ValidID            => $GetParam{ValidID},
                    UserID             => $Self->{UserID},
                );
                if ( $RequestFormBlockID eq "Exists" ) {
                    $GetParam{RequestFormBlockIDError} = $RequestFormBlockID;
                    $GetParam{RequestFormBlockID}      = '';
                }
                else {
                    $GetParam{RequestFormBlockID}      = $RequestFormBlockID;
                    $GetParam{RequestFormBlockIDError} = 1;
                }
            }
        }
        my $RequestIDGet = $GetParam{RequestID};
        my $IDError     = $GetParam{IDError};
        %GetParam = ();
        %Param    = ();

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
            RequestID => $RequestIDGet,
            IDError  => $IDError,
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
    elsif ( $Self->{Subaction} eq 'OrderEdit' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;
        for my $Param (
            qw(RequestID RequestFormIDs RequestFormIDsBlock)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my @RequestFormIDArray = split( /,/, $GetParam{RequestFormIDs} );
        my $OrderGet = '';
        for my $NewValue (@RequestFormIDArray) {
            $OrderGet = 'Order' . $NewValue;
            $GetParam{$OrderGet} = $ParamObject->GetParam( Param => $OrderGet );

            my $Success = $RequestFormObject->RequestFormOrderUpdate(
                RequestFormID => $NewValue,
                Order         => $GetParam{$OrderGet},
                UserID        => $Self->{UserID},
            );
        }

        my @RequestFormIDBlockArray = split( /,/, $GetParam{RequestFormIDsBlock} );
        my $OrderGetBlock = '';
        for my $NewValue (@RequestFormIDBlockArray) {
            $OrderGetBlock = 'OrderBlock' . $NewValue;
            $GetParam{$OrderGetBlock} = $ParamObject->GetParam( Param => $OrderGetBlock );

            my $Success = $RequestFormBlockObject->RequestFormOrderUpdate(
                RequestFormID => $NewValue,
                Order         => $GetParam{$OrderGetBlock},
                UserID        => $Self->{UserID},
            );
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            RequestID => $GetParam{RequestID},
            %Param,
            %GetParam,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'HeadlineSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;
        my @AgentenRollenArray;
        for my $Param (
            qw(RequestFormID RequestID Headline HeadArt DescriptionField Order)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{RequestID} ) {
            $Error{'RequestIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( $GetParam{RequestFormID} ) {
                my $RequestFormID = $RequestFormObject->RequestFormHeadlineUpdate(
                    RequestFormID => $GetParam{RequestFormID},
                    RequestID     => $GetParam{RequestID},
                    Headline      => $GetParam{Headline},
                    Description   => $GetParam{DescriptionField},
                    Order         => $GetParam{Order},
                    UserID        => $Self->{UserID},
                );
            }
            else {
                my $RequestFormID = $RequestFormObject->RequestFormHeadlineAdd(
                    RequestID     => $GetParam{RequestID},
                    Headline      => $GetParam{Headline},
                    Description   => $GetParam{DescriptionField},
                    Order         => $GetParam{Order},
                    UserID        => $Self->{UserID},
                );
            }
        }

        $GetParam{RequestFormID} = '';
        $GetParam{Headline}     = '';
        $GetParam{HeadArt}      = '';
        $GetParam{Order}  = '';

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
            RequestID => $GetParam{RequestID},
            IDError  => $GetParam{IDError},
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
    elsif ( $Self->{Subaction} eq 'HeadlineSaveBlock' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;
        my @AgentenRollenArray;
        for my $Param (
            qw(RequestFormValueID RequestFormBlockID RequestFormID RequestID HeadlineBlock HeadArtBlock DescriptionFieldBlock OrderBlock)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{RequestID} ) {
            $Error{'RequestIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( $GetParam{RequestFormBlockID} ) {
                my $RequestFormID = $RequestFormBlockObject->RequestFormHeadlineBlockUpdate(
                    RequestFormBlockID => $GetParam{RequestFormBlockID},
                    RequestFormValueID => $GetParam{RequestFormValueID},
                    RequestFormID      => $GetParam{RequestFormID},
                    RequestID          => $GetParam{RequestID},
                    Headline           => $GetParam{HeadlineBlock},
                    Description        => $GetParam{DescriptionFieldBlock},
                    Order              => $GetParam{OrderBlock},
                    UserID             => $Self->{UserID},
                );
            }
            else {
                my $RequestFormID = $RequestFormBlockObject->RequestFormHeadlineBlockAdd(
                    RequestFormValueID => $GetParam{RequestFormValueID},
                    RequestFormID      => $GetParam{RequestFormID},
                    RequestID          => $GetParam{RequestID},
                    Headline           => $GetParam{HeadlineBlock},
                    Description        => $GetParam{DescriptionFieldBlock},
                    Order              => $GetParam{OrderBlock},
                    UserID             => $Self->{UserID},
                );
            }
        }

        $GetParam{RequestFormBlockID} = '';
        $GetParam{HeadlineBlock}      = '';
        $GetParam{OrderBlock}         = '';

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
            RequestID => $GetParam{RequestID},
            IDError  => $GetParam{IDError},
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
        my %RequestList = $RequestObject->RequestList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # get valid list
        my %ValidList = $ValidObject->ValidList();

        if (%RequestList) {
            for my $RequestID ( sort { lc $RequestList{$a} cmp lc $RequestList{$b} } keys %RequestList )
            {

                # get the sla data
                my %RequestData = $RequestObject->RequestGet(
                    RequestID => $RequestID,
                    UserID   => $Self->{UserID},
                );

                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => { %RequestData, Valid => $ValidList{ $RequestData{ValidID} }, },
                );
            }
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminRequestForm',
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
    my $RequestObject               = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFieldsObject         = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestFormObject           = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $RequestFormBlockObject      = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $GroupObject                 = $Kernel::OM->Get('Kernel::System::Group');
    my $QueueObject                 = $Kernel::OM->Get('Kernel::System::Queue');
    my $RequestCategoriesObject     = $Kernel::OM->Get('Kernel::System::RequestCategories');
    my $TypeObject                  = $Kernel::OM->Get('Kernel::System::Type');
    my $ConfigObject                = $Kernel::OM->Get('Kernel::Config');
    my $UserObject                  = $Kernel::OM->Get('Kernel::System::User');
    my $RequestCategoriesIconObject = $Kernel::OM->Get('Kernel::System::RequestCategoriesIcon');
    my $RequestGroupObject          = $Kernel::OM->Get('Kernel::System::RequestGroup');

    # get params
    my %RequestData;
    $RequestData{RequestID} = $Param{RequestID} || '';
    $RequestData{IDError}  = $Param{IDError}  || '';

    if ( $RequestData{RequestID} ) {

        # get the sla data
        %RequestData = $RequestObject->RequestGet(
            RequestID => $RequestData{RequestID},
            UserID   => $Self->{UserID},
        );
    }

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $RequestData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $RequestData{ValidID} || $ValidListReverse{valid},
    );

    my %SubjectChangeableYesNo = ( '1' => 'yes', '2' => 'no' );
    $RequestData{SubjectChangeableStrg} = $LayoutObject->BuildSelection(
        Name       => 'SubjectChangeable',
        Data       => \%SubjectChangeableYesNo,
        Class      => "Modernize",
        SelectedID => $RequestData{SubjectChangeable} || 2,
    );

    my %QueueList = $QueueObject->QueueList( Valid => 1 );
    $RequestData{QueueStrg} = $LayoutObject->BuildSelection(
        Data         => \%QueueList,
        PossibleNone => 1,
        Name         => 'Queue',
        Class        => "Validate_Required Modernize " . ( $Param{Errors}->{QueueInvalid} || '' ),
        SelectedID   => $RequestData{Queue},
    );

    my %RequestGroupList = $RequestGroupObject->GroupList( Valid => 1 );
    $RequestData{RequestGroupStrg} = $LayoutObject->BuildSelection(
        Data         => \%RequestGroupList,
        PossibleNone => 1,
        Name         => 'RequestGroup',
        Class        => "Modernize",
        SelectedID   => $RequestData{RequestGroup},
    );

    # build RequestCategories dropdown
    my %RequestCategoriesList = $RequestCategoriesObject->RequestCategoriesList(
        Valid  => 1,
        UserID => $Self->{UserID},
    );

    my $TemplateKategorienID = '';
    if ( $RequestData{RequestID} ) {
        $TemplateKategorienID = $RequestCategoriesObject->RequestCategoriesTemplateGet(
            TemplateID => $RequestData{RequestID},
            UserID     => $Self->{UserID},
        );
    }

    $RequestData{RequestCategoriesStrg} = $LayoutObject->BuildSelection(
        Name         => 'RequestCategoriesID',
        Data         => \%RequestCategoriesList,
        SelectedID   => $TemplateKategorienID,
        Translation  => 1,
        Class        => "Validate_Required Modernize " . ( $Param{Errors}->{RequestCategoriesIDInvalid} || '' ),
        PossibleNone => 1,
    );

    my $ProcessesObject = $Kernel::OM->Get('Kernel::System::Processes');
    my %Processes = $ProcessesObject->ProcessesList(
        Valid    => 1,   # (optional) default 0
    );
    $RequestData{ProcessStrg} = $LayoutObject->BuildSelection(
        Data         => \%Processes,
        Name         => 'ProcessID',
        Class        => "Modernize",
        PossibleNone => 1,
        SelectedID   => $RequestData{ProcessID},
    );

    my %ShowAttachmentYesNo = ( '1' => 'yes', '2' => 'no' );
    $RequestData{ShowAttachmentStrg} = $LayoutObject->BuildSelection(
        Name       => 'ShowAttachment',
        Data       => \%ShowAttachmentYesNo,
        Class      => "Modernize",
        SelectedID => $RequestData{ShowAttachment} || 1,
    );

    my %NewOwner = $UserObject->UserList(
        Type  => 'Long',
        Valid => 1,
    );
    $RequestData{OwnerStrg} = $LayoutObject->BuildSelection(
        Data         => \%NewOwner,
        Name         => 'NewOwnerID',
        Class        => "Modernize",
        PossibleNone => 1,
        SelectedID   => $RequestData{OwnerID},
    );

    my %NewResponsible = $UserObject->UserList(
        Type  => 'Long',
        Valid => 1,
    );
    $RequestData{ResponsibleStrg} = $LayoutObject->BuildSelection(
        Data         => \%NewResponsible,
        Name         => 'NewResponsibleID',
        Class        => "Modernize",
        PossibleNone => 1,
        SelectedID   => $RequestData{ResponsibleID},
    );

    # output edit
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, %RequestData, },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    $LayoutObject->Block(
        Name => 'RequestEdit',
        Data => { %Param, %RequestData, },
    );

    # shows header
    if ( $RequestData{RequestID} ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    if ( $ConfigObject->Get('Ticket::Type') ) {

        my %TypeList = $TypeObject->TypeList( Valid => 1 );

        $RequestData{TypeStrg} = $LayoutObject->BuildSelection(
            Data         => \%TypeList,
            PossibleNone => 1,
            Name         => 'Type',
            SelectedID   => $RequestData{Type},
        );

        $LayoutObject->Block(
            Name => 'TicketType',
            Data => {%Param, %RequestData,},
        );
    }

    my $ShowConfigItem = $ConfigObject->Get('Ticket::Frontend::ConfigItemZoomSearch');
    if ( $ShowConfigItem && $ShowConfigItem >= 1 ) {


        my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
        my $ClassList = $GeneralCatalogObject->ItemList(
            Class => 'ITSM::ConfigItem::Class',
            Valid => 1,
        );

        my @ShowConfigItems = split( /,/, $RequestData{ShowConfigItems} );
        $RequestData{ShowConfigItemStrg} = $LayoutObject->BuildSelection(
            Data         => \%{$ClassList},
            Name         => 'ShowConfigItem',
            Multiple     => 1,
            Size         => 7,
            Class        => "",
            PossibleNone => 0,
            SelectedID   => \@ShowConfigItems,
        );

        # output edit
        $LayoutObject->Block(
            Name => 'ShowConfigItem',
            Data => { %Param, %RequestData, },
        );
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
            if ( $ID == $RequestData{ImageID} ) {
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


    # Beginn neues Feld
    my %RequestFields;
    my %RequestFieldsList = $RequestFieldsObject->RequestFieldsAdminList(
        Valid  => 1,
        UserID => $Self->{UserID},
    );

    my %RequestFormEdit;
    if ( $Param{RequestFormID} ) {

        #get RequestForm
        %RequestFormEdit = $RequestFormObject->RequestFormGet( RequestFormID => $Param{RequestFormID}, );
    }

    my %RequestFormEditHead;
    if ( $RequestFormEdit{Headline} ) {
        %RequestFormEditHead = %RequestFormEdit;
        %RequestFormEdit     = ();
    }
    else {
        $RequestFields{Order} = $RequestFormEdit{Order};
        $RequestFields{MoveOver}    = $RequestFormEdit{ToolTip};
        %RequestFormEditHead        = ();
    }

    $RequestFields{NeuesFeldStrg} = $LayoutObject->BuildSelection(
        Data           => \%RequestFieldsList,
        Name           => 'FeldID',
        PossibleNone   => 1,
        SelectedID     => $RequestFormEdit{FeldID},
        Translation    => 0,
        Max            => 500,
        Class          => 'Validate_Required',
        Sort           => 'IndividualKey',
        SortIndividual => [ '(Dropdown)', '(Text)', '(Multiselect)', '(TextArea)', '(Date)' ]
    );

    if ( $RequestFormEdit{ToolTipUnder} ) {
        $RequestFields{ToolTipUnderChecked} = "checked=\"checked\"";
    }

    $RequestFields{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $RequestFormEdit{ValidID},
    );

    my %FrageList = ( '0' => '-', '1' => 'ja', '2' => 'nein', );
    if ( $RequestFormEdit{Headline} ) {
        $RequestFields{RequiredFieldStrg} = $LayoutObject->BuildSelection(
            Data       => \%FrageList,
            Name       => 'RequiredField',
            Class      => 'Validate_Required',
            SelectedID => $RequestFormEditHead{RequiredField},
        );
    }
    else {
        $RequestFields{RequiredFieldStrg} = $LayoutObject->BuildSelection(
            Data       => \%FrageList,
            Name       => 'RequiredField',
            Class      => 'Validate_Required',
            SelectedID => $RequestFormEdit{RequiredField},
        );
    }

    my $LastOrder = 0;
    if ( !$Param{RequestID} ) {
        $RequestFields{Order} = 1;
    }
    elsif ( $Param{RequestID} && $Param{RequestFormID} ) {
        if ( $RequestFormEditHead{Headline} ) {
            $LastOrder
                = $RequestFormObject->RequestFormLastOrder(
                RequestID => $RequestData{RequestID},
                );
            $RequestFields{Order} = $LastOrder + 1;
        }
        else {
            $RequestFields{Order} = $RequestFormEdit{Order};
        }
    }
    elsif ( $Param{RequestID} && !$Param{RequestFormID} ) {
        $LastOrder =
            $RequestFormObject->RequestFormLastOrder( RequestID => $RequestData{RequestID}, );
        $RequestFields{Order} = $LastOrder + 1;
    }

    if ( $Param{RequestID} ) {

        $LayoutObject->Block(
            Name => 'FeldAdd',
            Data => { %Param, %RequestFields, },
        );
    }

    # shows header
    if ( $Param{RequestFormID} && $RequestFormEdit{FeldID} ) {
        $LayoutObject->Block(
            Name => 'FeldHeaderEdit',
            Data => { %Param, %RequestFields, },
        );
    }
    else {
        $LayoutObject->Block( Name => 'FeldHeaderAdd' );
    }

    if ( $RequestFormEditHead{Headline} ) {
        $RequestFields{HeadArtUeberschrift} = 'checked="checked"';
        $RequestFields{Headline}    = $RequestFormEditHead{Headline};
        $RequestFields{Order}       = $RequestFormEditHead{Order};
        $RequestFields{Description} = $RequestFormEditHead{Description};

        if ( $RequestFields{Description} ) {
             $RequestFields{Headline} = $RequestFields{Headline} . '<br>' . $RequestFields{Description};
             $RequestFields{Description} = '';
        }

        my $LastOrder               = $RequestFormObject->RequestFormLastOrder( RequestID => $RequestData{RequestID}, );
        $RequestFields{Order}       = $LastOrder + 1;
    }

    $RequestFields{RequiredFieldStrg} = $LayoutObject->BuildSelection(
        Data       => \%FrageList,
        Name       => 'RequiredField',
        SelectedID => $RequestFormEditHead{RequiredField},
    );

    if ( $Param{RequestID} ) {

        $LayoutObject->Block(
            Name => 'FeldHeadlineAdd',
            Data => { %Param, %RequestFields, },
        );
    }

    # shows header
    if ( $Param{RequestFormID} && !$RequestFormEdit{FeldID} ) {
        $LayoutObject->Block(
            Name => 'FeldHeadlineHeaderEdit',
            Data => { %Param, %RequestFields, },
        );
    }
    else {
        $LayoutObject->Block( Name => 'FeldHeadlineHeaderAdd' );
    }

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%RequestFields,
        );
    }
    # Ende neues Feld

    # Beginn neues Feld Block
    if ( $Param{RequestFormID} && $Param{RequestFormValueID} ) {

        my %RequestFieldsBlock;
        my %RequestFieldsListBlock = $RequestFieldsObject->RequestFieldsAdminList(
            Valid  => 1,
            UserID => $Self->{UserID},
        );

        my %RequestFormEditBlock;
        if ( $Param{RequestFormBlockID} ) {

            #get RequestForm
            %RequestFormEditBlock = $RequestFormBlockObject->RequestFormBlockGet(
                RequestFormID => $Param{RequestFormBlockID},
            );
        }

        my %RequestFormEditHeadBlock;
        if ( $RequestFormEditBlock{Headline} || $RequestFormEditBlock{Beteiligte} ) {
            %RequestFormEditHeadBlock = %RequestFormEditBlock;
            %RequestFormEditBlock     = ();
        }
        else {
            $RequestFieldsBlock{OrderBlock} = $RequestFormEditBlock{Order};
            $RequestFieldsBlock{MoveOverBlock}    = $RequestFormEditBlock{ToolTip};
            %RequestFormEditHeadBlock             = ();
        }

        $RequestFieldsBlock{NeuesFeldStrg} = $LayoutObject->BuildSelection(
            Data           => \%RequestFieldsListBlock,
            Name           => 'FeldIDBlock',
            PossibleNone   => 1,
            SelectedID     => $RequestFormEditBlock{FeldID},
            Translation    => 0,
            Max            => 500,
            Class          => 'Validate_Required',
            Sort           => 'IndividualKey',
            SortIndividual => [ '(Dropdown)', '(Text)', '(Multiselect)', '(TextArea)', '(Date)' ]
        );

        my @DefaultvalueValueEditBlock;

        $RequestFieldsBlock{ValidOptionStrg} = $LayoutObject->BuildSelection(
            Data       => \%ValidList,
            Name       => 'ValidID',
            SelectedID => $Param{ValidID} || $RequestFormEditBlock{ValidID},
        );

        my %FrageListBlock = ( '0' => '-', '1' => 'ja', '2' => 'nein', );

        if ( $RequestFormEditBlock{Headline} || $RequestFormEditBlock{Beteiligte} ) {
            $RequestFieldsBlock{RequiredFieldBlockStrg} = $LayoutObject->BuildSelection(
                Data       => \%FrageListBlock,
                Name       => 'RequiredFieldBlock',
                Class      => 'Validate_Required',
                SelectedID => $RequestFormEditHeadBlock{RequiredField},
            );
        }
        else {
            $RequestFieldsBlock{RequiredFieldBlockStrg} = $LayoutObject->BuildSelection(
                Data       => \%FrageListBlock,
                Name       => 'RequiredFieldBlock',
                Class      => 'Validate_Required',
                SelectedID => $RequestFormEditBlock{RequiredField},
            );
        }

        if ( !$Param{RequestID} ) {
            $RequestFieldsBlock{OrderBlock} = 1;
        }
        elsif ( $Param{RequestID} && $Param{RequestFormBlockID} ) {
            if ( $RequestFormEditHeadBlock{Headline} ) {
                my $LastOrderBlock = $RequestFormBlockObject->RequestFormLastOrderBlock(
                    RequestID          => $RequestData{RequestID},
                    RequestFormValueID => $Param{RequestFormValueID},
                );
                $RequestFieldsBlock{OrderBlock} = $LastOrderBlock + 1;
            }
            else {
                $RequestFieldsBlock{OrderBlock} = $RequestFormEditBlock{Order};
            }
        }
        elsif ( $Param{RequestID} && !$Param{RequestFormBlockID} ) {
            my $LastOrderBlock = $RequestFormBlockObject->RequestFormLastOrderBlock(
                RequestID          => $RequestData{RequestID},
                RequestFormValueID => $Param{RequestFormValueID},
            );
            $RequestFieldsBlock{OrderBlock} = $LastOrderBlock + 1;
        }

        $LayoutObject->Block(
            Name => 'FeldAddBlock',
            Data => { %Param, %RequestFieldsBlock, },
        );

        if (
            $Param{RequestFormBlockID}
            && $RequestFormEditBlock{FeldID}
            && $Param{RequestFormValueID}
            )
        {
            $LayoutObject->Block(
                Name => 'FeldHeaderEditBlock',
                Data => { %Param, %RequestFieldsBlock, },
            );
        }
        if (
            !$Param{RequestFormBlockID}
            && !$RequestFormEditBlock{FeldID}
            && $Param{RequestFormValueID}
            )
        {
            $LayoutObject->Block(
                Name => 'FeldHeaderAddBlock',
                Data => { %Param, %RequestFieldsBlock, },
            );
        }

        if ( $RequestFormEditHeadBlock{Headline}) {
            $RequestFieldsBlock{HeadArtUeberschriftBlock} = 'checked="checked"';
            $RequestFieldsBlock{HeadlineBlock}            = $RequestFormEditHeadBlock{Headline};
            $RequestFieldsBlock{OrderBlock}         = $RequestFormEditHeadBlock{Order};
            $RequestFieldsBlock{DescriptionBlock}        = $RequestFormEditHeadBlock{Description};
            my $LastOrder = $RequestFormBlockObject->RequestFormLastOrderBlock(
                RequestID          => $RequestData{RequestID},
                RequestFormValueID => $Param{RequestFormValueID},
            );
            $RequestFieldsBlock{OrderBlock} = $LastOrder + 1;
        }

        $RequestFields{RequiredFieldStrg} = $LayoutObject->BuildSelection(
            Data       => \%FrageList,
            Name       => 'RequiredFieldBlock',
            SelectedID => $RequestFormEditHeadBlock{RequiredField},
        );

        $LayoutObject->Block(
            Name => 'FeldHeadlineBlockAdd',
            Data => { %Param, %RequestFieldsBlock, },
        );

        # shows header
        if ( $Param{RequestFormID} && !$RequestFormEditBlock{FeldID} ) {
            $LayoutObject->Block(
                Name => 'FeldHeadlineHeaderBlockEdit',
                Data => { %Param, %RequestFields, },
            );
        }
        else {
            $LayoutObject->Block( Name => 'FeldHeadlineHeaderBlockAdd' );
        }

        # add rich text editor
        if ( $LayoutObject->{BrowserRichText} ) {

            # set up rich text editor
            $LayoutObject->SetRichTextParameters(
                Data => \%RequestFieldsBlock,
            );
        }

    }

    # Ende neues Feld Block

    my %RequestFormListDetails;
    $RequestFormListDetails{RequestName}    = $RequestData{Name};
    $RequestFormListDetails{RequestFormIDs} = '';

    if ( $Param{RequestID} ) {

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewFieldsList',
            Data => { %RequestFormListDetails, %Param, },
        );
    }

    my %RequestFormList = ();
    if ( $RequestData{RequestID} ) {
        %RequestFormList = $RequestFormObject->RequestFormList(
            RequestID => $RequestData{RequestID},
            UserID    => $Self->{UserID},
        );
    }

    for my $RequestFormListID (
        sort { $RequestFormList{$a} <=> $RequestFormList{$b} }
        keys %RequestFormList
        )
    {

        $RequestFormListDetails{FeldAktuellID} = $RequestFormListID;

        #get RequestForm
        my %RequestForm = $RequestFormObject->RequestFormGet( RequestFormID => $RequestFormListID, );

        $LayoutObject->Block(
            Name => 'OverviewListFieldsRow',
            Data => { %Param, },
        );

        $RequestFormListDetails{Order}  = $RequestForm{Order};
        $RequestFormListDetails{ToolTip}      = $RequestForm{ToolTip};
        $RequestFormListDetails{RequestFormID} = $RequestFormListID;

        $RequestFormListDetails{RequestFormIDs} .= "$RequestFormListID,";

        $RequestFormListDetails{ValidID} = $RequestForm{ValidID};

        if ( !$RequestForm{Headline} && !$RequestForm{Description} ) {

            #get RequestFeld
            my %RequestFields
                = $RequestFieldsObject->RequestFieldsGet( RequestFieldsID => $RequestForm{FeldID}, );

            #get RequestFieldsWerte
            my %RequestFieldsWerte
                = $RequestFieldsObject->RequestFieldsWerteGet( ID => $RequestFields{ID}, );

            #get list
            my %RequestFieldsListe
                = $RequestFieldsObject->RequestFieldsWerteList( FeldID => $RequestForm{FeldID}, );

            my %RequestWerteDropdown = ();
            if (%RequestFieldsListe) {
                for my $RequestFieldsWerteID ( sort keys %RequestFieldsListe ) {

                    #get RequestFieldsWerte
                    my %RequestFieldsWerte
                        = $RequestFieldsObject->RequestFieldsWerteGet( ID => $RequestFieldsWerteID, );
                    $RequestWerteDropdown{ $RequestFieldsWerte{Schluessel} }
                        = $RequestFieldsWerte{Inhalt};
                }
            }

            $RequestFormListDetails{FieldLabeling} = $RequestFields{Labeling};
            $RequestFormListDetails{FieldName}         = $RequestFields{Name};

            if ( $RequestFields{Typ} eq "Multiselect" && $RequestForm{RequiredField} == 1 ) {

                my @DefaultvalueValue;
                if ( $RequestFields{Defaultvalue} ) {
                    @DefaultvalueValue = split( /,/, $RequestFields{Defaultvalue} );
                }

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                #generate output
                $RequestFormListDetails{FieldNameStrg} = $LayoutObject->BuildSelection(
                    Data         => \%RequestWerteDropdown,
                    Name         => $RequestFields{Name},
                    PossibleNone => $RequestFields{LeerWert},
                    Multiple     => 1,
                    Size         => 5,
                    Class        => '',
                    SelectedID   => \@DefaultvalueValue,
                    Translation  => 1,
                    Max          => 200,
                );

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsMultiselectRequired',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
            if ( $RequestFields{Typ} eq "Multiselect" && $RequestForm{RequiredField} == 2 ) {

                my @DefaultvalueValue;
                if ( $RequestFields{Defaultvalue} ) {
                    @DefaultvalueValue = split( /,/, $RequestFields{Defaultvalue} );
                }

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                #generate output
                $RequestFormListDetails{FieldNameStrg} = $LayoutObject->BuildSelection(
                    Data         => \%RequestWerteDropdown,
                    Name         => $RequestFields{Name},
                    PossibleNone => $RequestFields{LeerWert},
                    Multiple     => 1,
                    Size         => 5,
                    Class        => '',
                    SelectedID   => \@DefaultvalueValue,
                    Translation  => 1,
                    Max          => 200,
                );

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsMultiselect',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }

            if ( $RequestFields{Typ} eq "Dropdown" && $RequestForm{RequiredField} == 1 ) {

                if ( $Param{RequestFormValueID} ) {
                    $RequestFields{Defaultvalue} = $Param{RequestFormValueID};
                }

                #generate output
                $RequestFormListDetails{FieldNameStrg} = $LayoutObject->BuildSelection(
                    Data         => \%RequestWerteDropdown,
                    Name         => $RequestFields{Name},
                    PossibleNone => $RequestFields{LeerWert},
                    Size         => 1,
                    Class        => '',
                    SelectedID   => $RequestFields{Defaultvalue},
                    Translation  => 1,
                    Max          => 200,
                );

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsDropdownRequired',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
            if ( $RequestFields{Typ} eq "Dropdown" && $RequestForm{RequiredField} == 2 ) {

                if ( $Param{RequestFormValueID} ) {
                    $RequestFields{Defaultvalue} = $Param{RequestFormValueID};
                }

                #generate output
                $RequestFormListDetails{FieldNameStrg} = $LayoutObject->BuildSelection(
                    Data         => \%RequestWerteDropdown,
                    Name         => $RequestFields{Name},
                    PossibleNone => $RequestFields{LeerWert},
                    Size         => 1,
                    Class        => '',
                    SelectedID   => $RequestFields{Defaultvalue},
                    Translation  => 1,
                    Max          => 200,
                );

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsDropdown',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }

            if ( $RequestFields{Typ} eq "Text" && $RequestForm{RequiredField} == 1 ) {

                #generate output
                $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                $RequestFormListDetails{FieldName}         = $RequestFields{Name};

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsTextRequired',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
            if ( $RequestFields{Typ} eq "Text" && $RequestForm{RequiredField} == 2 ) {

                #generate output
                $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                $RequestFormListDetails{FieldName}         = $RequestFields{Name};

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsText',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }

            if ( $RequestFields{Typ} eq "TextArea" && $RequestForm{RequiredField} == 1 ) {

                #generate output
                $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                $RequestFormListDetails{FieldName}         = $RequestFields{Name};
                $RequestFormListDetails{FeldRows}         = $RequestFields{Rows};
                $RequestFormListDetails{FeldCols}         = $RequestFields{Cols};

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsTextAreaRequired',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
            if ( $RequestFields{Typ} eq "TextArea" && $RequestForm{RequiredField} == 2 ) {

                #generate output
                $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                $RequestFormListDetails{FieldName}         = $RequestFields{Name};
                $RequestFormListDetails{FeldRows}         = $RequestFields{Rows};
                $RequestFormListDetails{FeldCols}         = $RequestFields{Cols};

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsTextArea',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }

            if ( $RequestFields{Typ} eq "Checkbox" && $RequestForm{RequiredField} == 1 ) {

                #generate output
                $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                $RequestFormListDetails{FieldName}         = $RequestFields{Name};
                if ( $RequestFields{Defaultvalue} == 1 ) {
                    $RequestFormListDetails{FeldChecked} = 'checked="checked"';
                }

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsCheckboxRequired',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
            if ( $RequestFields{Typ} eq "Checkbox" && $RequestForm{RequiredField} == 2 ) {

                #generate output
                $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                $RequestFormListDetails{FieldName}         = $RequestFields{Name};
                if ( $RequestFields{Defaultvalue} == 1 ) {
                    $RequestFormListDetails{FeldChecked} = 'checked="checked"';
                }

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsCheckbox',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }

            if ( $RequestFields{Typ} eq "Date" && $RequestForm{RequiredField} == 1 ) {

                # date data string
                $Param{FieldNameString} = $LayoutObject->BuildDateSelection(
                    %Param,
                    Format           => 'DateInputFormatLong',
                    YearPeriodPast   => 0,
                    YearPeriodFuture => 5,
                    DiffTime         => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime')
                        || 0,
                    Class                => $Param{Errors}->{DateInvalid},
                    Validate             => 1,
                    ValidateDateInFuture => 1,
                );

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsDateRequired',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
            if ( $RequestFields{Typ} eq "Date" && $RequestForm{RequiredField} == 2 ) {

                # date data string
                $Param{FieldNameString} = $LayoutObject->BuildDateSelection(
                    %Param,
                    Format           => 'DateInputFormatLong',
                    YearPeriodPast   => 0,
                    YearPeriodFuture => 5,
                    DiffTime         => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime')
                        || 0,
                    Class                => $Param{Errors}->{DateInvalid},
                    Validate             => 1,
                    ValidateDateInFuture => 1,
                );

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsDate',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }

            if ( $RequestFields{Typ} eq "DateShort" && $RequestForm{RequiredField} == 1 ) {

                # date data string
                $Param{FieldNameString} = $LayoutObject->BuildDateSelection(
                    %Param,
                    Format           => 'DateInputFormat',
                    YearPeriodPast   => 0,
                    YearPeriodFuture => 5,
                    DiffTime         => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime')
                        || 0,
                    Class                => $Param{Errors}->{DateInvalid},
                    Validate             => 1,
                    ValidateDateInFuture => 1,
                );

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsDateShortRequired',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
            if ( $RequestFields{Typ} eq "DateShort" && $RequestForm{RequiredField} == 2 ) {

                # date data string
                $Param{FieldNameString} = $LayoutObject->BuildDateSelection(
                    %Param,
                    Format           => 'DateInputFormat',
                    YearPeriodPast   => 0,
                    YearPeriodFuture => 5,
                    DiffTime         => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime')
                        || 0,
                    Class                => $Param{Errors}->{DateInvalid},
                    Validate             => 1,
                    ValidateDateInFuture => 1,
                );

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsDateShort',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
        }

        if ( $RequestForm{Headline} ) {

            $RequestFormListDetails{Headline} = $RequestForm{Headline};
            $Param{Headline}                 = $RequestForm{Headline};
            if ( $RequestFormListDetails{Order} ) {
                $Param{Order} = $RequestFormListDetails{Order};
            }

            if ( $RequestForm{Description} ) {
                $RequestForm{Description} =~ s/(.*)<(.*)>/$2/ig;
                $RequestForm{Description} =~ s/</&lt;/ig;
                $RequestForm{Description} =~ s/>/&gt;/ig;
                $RequestForm{Description} =~ s/\n/<br\/>/ig;
                $Param{Description}                 = $RequestForm{Description};
                $RequestFormListDetails{Description} = $RequestForm{Description};
            }

            if ( $Param{Description} ) {
                 $Param{Headline} = $Param{Headline} . '<br>' . $Param{Description};
                 $Param{Description} = '';
            }

            $LayoutObject->Block(
                Name => 'OverviewListFieldsHeadline',
                Data => { %RequestFormListDetails, %Param, },
            );
            $Param{Description}                 = '';
            $RequestFormListDetails{Description} = '';
        }

    }

    # output overview result
    $LayoutObject->Block(
        Name => 'OverviewListFieldsRequestFormIDs',
        Data => { %RequestFormListDetails, %Param, },
    );

    if ( $RequestData{IDError} && $RequestData{IDError} eq "Exists" ) {

        # output sla edit
        $LayoutObject->Block(
            Name => 'DoppeltError',
            Data => { %Param, %RequestData, },
        );
    }

    # get output back
    return $LayoutObject->Output( TemplateFile => 'AdminRequestForm', Data => \%Param );
}

1;
