# --
# Kernel/Modules/AdminChecklist.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminChecklist.pm,v 1.37 2016/09/20 12:33:43 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminChecklist;

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

    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');
    my $QueueObject          = $Kernel::OM->Get('Kernel::System::Queue');
    my $TypeObject           = $Kernel::OM->Get('Kernel::System::Type');
    my $ServiceObject        = $Kernel::OM->Get('Kernel::System::Service');
    my $ChecklistObject      = $Kernel::OM->Get('Kernel::System::Checklist');
    my $ChecklistFieldObject = $Kernel::OM->Get('Kernel::System::ChecklistField');

    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ChecklistEdit' ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ChecklistID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            ChecklistID => $GetParam{ChecklistID},
            %Param,
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChecklistSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        for my $Param (
            qw(ChecklistID Name SetArticle ValidID Comment)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my @QueueIDs = $ParamObject->GetArray( Param => 'QueueID' );
        $GetParam{QueueIDs} = '';
        for my $QueueIDs (@QueueIDs) {
            $GetParam{QueueIDs} .= "$QueueIDs,";
        }

        my @ServiceIDs = $ParamObject->GetArray( Param => 'ServiceID' );
        $GetParam{ServiceIDs} = '';
        for my $ServiceIDs (@ServiceIDs) {
            $GetParam{ServiceIDs} .= "$ServiceIDs,";
        }

        my @TypeIDs = $ParamObject->GetArray( Param => 'TypeID' );
        $GetParam{TypeIDs} = '';
        for my $TypeIDs (@TypeIDs) {
            $GetParam{TypeIDs} .= "$TypeIDs,";
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{Name} ) {
            $Error{'NameInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( !$GetParam{QueueIDs} ) {
                $GetParam{QueueIDs} = 0;
            }
            if ( !$GetParam{TypeIDs} ) {
                $GetParam{TypeIDs} = 0;
            }
            if ( !$GetParam{ServiceIDs} ) {
                $GetParam{ServiceIDs} = 0;
            }
            if ( !$GetParam{Comment} ) {
                $GetParam{Comment} = '-';
            }

            if ( $GetParam{ChecklistID} ) {

                my $ChecklistID = $ChecklistObject->ChecklistUpdate(
                    ChecklistID => $GetParam{ChecklistID},
                    Name        => $GetParam{Name},
                    QueueID     => 0,
                    TypeID      => 0,
                    ServiceID   => 0,
                    QueueIDs    => $GetParam{QueueIDs},
                    TypeIDs     => $GetParam{TypeIDs},
                    ServiceIDs  => $GetParam{ServiceIDs},
                    SetArticle  => $GetParam{SetArticle},
                    ValidID     => $GetParam{ValidID},
                    Comment     => $GetParam{Comment},
                    UserID      => $Self->{UserID},
                );
            }
            else {

                my $ChecklistID = $ChecklistObject->ChecklistAdd(
                    Name        => $GetParam{Name},
                    QueueID     => 0,
                    TypeID      => 0,
                    ServiceID   => 0,
                    QueueIDs    => $GetParam{QueueIDs},
                    TypeIDs     => $GetParam{TypeIDs},
                    ServiceIDs  => $GetParam{ServiceIDs},
                    SetArticle  => $GetParam{SetArticle},
                    ValidID     => $GetParam{ValidID},
                    Comment     => $GetParam{Comment},
                    UserID      => $Self->{UserID},
                    UserID      => $Self->{UserID},
                );

                $GetParam{ChecklistID} = $ChecklistID;
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
    elsif ( $Self->{Subaction} eq 'ChecklistFieldDelete' ) {

        # get params
        my %GetParam;
        for my $Param (

            qw(ChecklistID ChecklistFieldID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my $Sucess = $ChecklistFieldObject->ChecklistFieldDelete( ChecklistFieldID => $GetParam{ChecklistFieldID}, );
        $GetParam{ChecklistFieldID} = '';

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            ChecklistID => $GetParam{ChecklistID},
            %Param,
            %GetParam,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    #  delete
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChecklistFieldEdit' ) {

        # get params
        my %GetParam;
        for my $Param (

            qw(ChecklistID ChecklistFieldID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            ChecklistID => $GetParam{ChecklistID},
            %Param,
            %GetParam,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }


    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChecklistFieldSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;
        for my $Param (
            qw(ID ChecklistID ChecklistFieldID Task Order FieldType)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{ChecklistID} ) {
            $Error{'ChecklistIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {
            if ( $GetParam{ChecklistFieldID} ) {
                my $ChecklistFieldID = $ChecklistFieldObject->ChecklistFieldUpdate(
                    ID          => $GetParam{ID},
                    ChecklistID => $GetParam{ChecklistID},
                    Task        => $GetParam{Task},
                    Order       => $GetParam{Order},
                    FieldType   => $GetParam{FieldType},
                    UserID      => $Self->{UserID},
                );
            }
            else {
                my $ChecklistFieldID = $ChecklistFieldObject->ChecklistFieldAdd(
                    ChecklistID => $GetParam{ChecklistID},
                    Task        => $GetParam{Task},
                    Order       => $GetParam{Order},
                    FieldType   => $GetParam{FieldType},
                    UserID      => $Self->{UserID},
                );
            }
        }

        my $ChecklistIDGet = $GetParam{ChecklistID};
        my $IDError        = $GetParam{IDError};
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
            ChecklistID => $ChecklistIDGet,
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
            qw(ChecklistID ChecklistFieldID ChecklistFormIDs)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my @ChecklistFormIDArray = split( /,/, $GetParam{ChecklistFormIDs} );
        my $OrderGet = '';

        for my $NewValue (@ChecklistFormIDArray) {

            $OrderGet = 'Order' . $NewValue;
            $GetParam{$OrderGet} = $ParamObject->GetParam( Param => $OrderGet );

            my $Success = $ChecklistFieldObject->ChecklistOrderUpdate(
                ChecklistID => $NewValue,
                Order       => $GetParam{$OrderGet},
                UserID      => $Self->{UserID},
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
        my %ChecklistList = $ChecklistObject->ChecklistList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # get valid list
        my %ValidList = $ValidObject->ValidList();

        if (%ChecklistList) {
            for my $ChecklistID ( sort { lc $ChecklistList{$a} cmp lc $ChecklistList{$b} } keys %ChecklistList )
            {

                # get the sla data
                my %ChecklistData = $ChecklistObject->ChecklistGet(
                    ChecklistID => $ChecklistID,
                    UserID      => $Self->{UserID},
                );

                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => { %ChecklistData, Valid => $ValidList{ $ChecklistData{ValidID} }, },
                );
            }
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminChecklist',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {

    my ( $Self, %Param ) = @_;

    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');
    my $QueueObject          = $Kernel::OM->Get('Kernel::System::Queue');
    my $TypeObject           = $Kernel::OM->Get('Kernel::System::Type');
    my $ServiceObject        = $Kernel::OM->Get('Kernel::System::Service');
    my $ChecklistObject      = $Kernel::OM->Get('Kernel::System::Checklist');
    my $ChecklistFieldObject = $Kernel::OM->Get('Kernel::System::ChecklistField');
    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');

    # get params
    my %ChecklistData;
    $ChecklistData{ChecklistID} = $Param{ChecklistID} || '';
    $ChecklistData{IDError}     = $Param{IDError}  || '';

    if ( $ChecklistData{ChecklistID} ) {

        # get the sla data
        %ChecklistData = $ChecklistObject->ChecklistGet(
            ChecklistID => $ChecklistData{ChecklistID},
            UserID   => $Self->{UserID},
        );
    }

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $ChecklistData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        Class      => "Modernize",
        SelectedID => $Param{ValidID} || $ChecklistData{ValidID} || $ValidListReverse{valid},
    );

    my %QueueList = $QueueObject->QueueList(
        Valid => 1,
    );
    my @QueueIDs = split( /,/, $ChecklistData{QueueIDs} );
    $ChecklistData{QueueStrg} = $LayoutObject->BuildSelection(
        Data         => \%QueueList,
        PossibleNone => 1,
        Name         => 'QueueID',
        Class        => "Modernize",
        Multiple     => 1,
        Size         => 7,
        SelectedID   => \@QueueIDs,
    );

    my %ServiceList = $ServiceObject->ServiceList(
        Valid  => 1,
        UserID => 1,
    );
    my @ServiceIDs = split( /,/, $ChecklistData{ServiceIDs} );
    $ChecklistData{ServiceStrg} = $LayoutObject->BuildSelection(
        Data         => \%ServiceList,
        PossibleNone => 1,
        Name         => 'ServiceID',
        Class        => "Modernize",
        Multiple     => 1,
        Size         => 7,
        SelectedID   => \@ServiceIDs,
    );

    if ( $ConfigObject->Get('Ticket::Type') ) {

        my %TypeList = $TypeObject->TypeList( Valid => 1 );
        my @TypeIDs = split( /,/, $ChecklistData{TypeIDs} );
        $ChecklistData{TypeStrg} = $LayoutObject->BuildSelection(
            Data         => \%TypeList,
            PossibleNone => 1,
            Name         => 'TypeID',
            Class        => "Modernize",
            Multiple     => 1,
            Size         => 7,
            SelectedID   => \@TypeIDs,
        );

        $LayoutObject->Block(
            Name => 'TicketType',
            Data => {%Param, %ChecklistData,},
        );
    }

    my %SetArticleYesNo = ( '1' => 'yes', '2' => 'no' );
    $ChecklistData{SetArticleStrg} = $LayoutObject->BuildSelection(
        Name       => 'SetArticle',
        Data       => \%SetArticleYesNo,
        Class      => "Modernize",
        SelectedID => $ChecklistData{SetArticle} || 2,
    );

    # output edit
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, %ChecklistData, },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    $LayoutObject->Block(
        Name => 'ChecklistEdit',
        Data => { %Param, %ChecklistData, },
    );

    my $LastOrder = 0;
    if ( !$ChecklistData{ChecklistID} ) {
        $ChecklistData{Order} = 1;
    }
    else {
        $LastOrder = $ChecklistFieldObject->ChecklistFieldLastOrder(
            ChecklistID => $ChecklistData{ChecklistID},
        );
        $ChecklistData{Order} = $LastOrder + 1;
    }

    # show header
    if ( $ChecklistData{ChecklistID} ) {

        my %ChecklistField;
        if ( $Param{ChecklistFieldID} ) {
            %ChecklistField = $ChecklistFieldObject->ChecklistFieldGet(
                ChecklistFieldID => $Param{ChecklistFieldID},
            );
        }

        $LayoutObject->Block( Name => 'HeaderEdit' );

        if ( $Param{ChecklistFieldID} && $ChecklistField{FieldType} eq "Task" ) {
            $LayoutObject->Block(
                Name => 'FieldAdd',
                Data => { %Param, %ChecklistData, %ChecklistField, },
            );
            $LayoutObject->Block(
                Name => 'FieldHeaderEdit',
                Data => { %Param, %ChecklistData, },
            );
        }

        elsif ( $Param{ChecklistFieldID} && $ChecklistField{FieldType} eq "Headline" ) {
            $LayoutObject->Block(
                Name => 'FieldHeadlineAdd',
                Data => { %Param, %ChecklistData, %ChecklistField, },
            );
            $LayoutObject->Block(
                Name => 'FieldHeadlineHeaderEdit',
                Data => { %Param, %ChecklistData, },
            );
        }

        else {
            $LayoutObject->Block(
                Name => 'FieldAdd',
                Data => { %Param, %ChecklistData, %ChecklistField, },
            );
            $LayoutObject->Block(
                Name => 'FieldHeadlineAdd',
                Data => { %Param, %ChecklistData, },
            );

            $LayoutObject->Block(
                Name => 'FieldHeaderAdd',
                Data => { %Param, %ChecklistData, },
            );
            $LayoutObject->Block(
                Name => 'FieldHeadlineHeaderAdd',
                Data => { %Param, %ChecklistData, },
            );
        }

    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }


    if ( $Param{ChecklistID} ) {

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewFieldList',
            Data => { %Param, },
        );

        my %ChecklistFieldList = $ChecklistFieldObject->ChecklistFieldList(
            ChecklistID => $Param{ChecklistID},
        );

        my $ChecklistFormIDs = '';
        for my $ChecklistFieldListID ( sort { $ChecklistFieldList{$a} <=> $ChecklistFieldList{$b} } keys %ChecklistFieldList ) {

            $LayoutObject->Block(
                Name => 'OverviewListFieldRow',
                Data => { %Param, },
            );

            my %ChecklistField = $ChecklistFieldObject->ChecklistFieldGet(
                ChecklistFieldID => $ChecklistFieldListID,
            );

            $ChecklistField{FeldAktuellID} = $ChecklistFieldListID;
            $ChecklistFormIDs .= "$ChecklistFieldListID,";

            if ( $ChecklistField{FieldType} eq "Task" ) {
                $LayoutObject->Block(
                    Name => 'OverviewListFieldTask',
                    Data => { %Param, %ChecklistField, },
                );
            }

            if ( $ChecklistField{FieldType} eq "Headline" ) {
                $LayoutObject->Block(
                    Name => 'OverviewListFieldHeadline',
                    Data => { %Param, %ChecklistField, },
                );
            }
        }

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewListFieldChecklistFormIDs',
            Data => { ChecklistFormIDs => $ChecklistFormIDs, %Param, },
        );

    }


    # get output back
    return $LayoutObject->Output( TemplateFile => 'AdminChecklist', Data => \%Param );
}

1;
