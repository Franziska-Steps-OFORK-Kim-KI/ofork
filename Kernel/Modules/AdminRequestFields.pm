# --
# Kernel/Modules/AdminRequestFields.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminRequestFields.pm,v 1.6 2016/11/20 19:57:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminRequestFields;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

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

    my $ParamObject         = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RequestFieldsObject = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $ValidObject         = $Kernel::OM->Get('Kernel::System::Valid');

    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'AntragEdit' ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            ID => $GetParam{ID},
            %Param,
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    #  typ
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AntragTyp' ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(Typ)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            Typ => $GetParam{Typ},
            %Param,
            %GetParam,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AntragSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;
        my @DefaultvalueArray;
        for my $Param (
            qw(ID Typ Name Labeling Rows Cols LeerWert ValidID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }
        for my $ParamNew (
            qw(Defaultvalue)
            )
        {
            if ( $GetParam{Typ} eq "Multiselect" ) {
                @DefaultvalueArray = $ParamObject->GetArray( Param => 'Defaultvalue' );
            }
            else {
                $GetParam{$ParamNew} = $ParamObject->GetParam( Param => $ParamNew ) || '';
            }
        }

        if ( $GetParam{Typ} eq "Multiselect" ) {
            for my $NewValue (@DefaultvalueArray) {
                $GetParam{Defaultvalue} .= "$NewValue,";
            }
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{Name} ) {
            $Error{'NameInvalid'} = 'ServerError';
        }

        if ( $GetParam{Name} =~ /[^A-Za-z0-9]/ ) {
            $Error{'NameInvalid'} = 'Error';
        }

        if ( !$GetParam{Labeling} ) {
            $Error{'LabelingInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( $GetParam{ID} ) {
                my $RequestFieldsID = $RequestFieldsObject->RequestFieldsUpdate(
                    ID           => $GetParam{ID},
                    Typ          => $GetParam{Typ},
                    Name         => $GetParam{Name},
                    Labeling     => $GetParam{Labeling},
                    Defaultvalue => $GetParam{Defaultvalue},
                    Rows         => $GetParam{Rows},
                    Cols         => $GetParam{Cols},
                    LeerWert     => $GetParam{LeerWert},
                    ValidID      => $GetParam{ValidID},
                    UserID       => $Self->{UserID},
                );

                if ( $RequestFieldsID eq 'Exists' ) {
                    $Error{NameInvalid}            = 'ServerError';
                    $Error{NameServerErrorMessage} = Translatable('There is another field with the same name.');
                }
            }
            else {

                my $RequestFieldsID = $RequestFieldsObject->RequestFieldsAdd(
                    Typ          => $GetParam{Typ},
                    Name         => $GetParam{Name},
                    Labeling     => $GetParam{Labeling},
                    Defaultvalue => $GetParam{Defaultvalue},
                    Rows         => $GetParam{Rows},
                    Cols         => $GetParam{Cols},
                    LeerWert     => $GetParam{LeerWert},
                    ValidID      => $GetParam{ValidID},
                    UserID       => $Self->{UserID},
                );

                if ( $RequestFieldsID eq 'Exists' ) {
                    $Error{NameInvalid}            = 'ServerError';
                    $Error{NameServerErrorMessage} = Translatable('There is another field with the same name.');
                }
                $GetParam{ID} = $RequestFieldsID;
            }
        }

        # header
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
            ID => $GetParam{ID},
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
            Data => {
                %Param,
            },
        );

        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionAdd' );

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewList',
            Data => {
                %Param,
            },
        );

        # get  list
        my %RequestFieldsList = $RequestFieldsObject->RequestFieldsList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # get valid list
        my %ValidList = $ValidObject->ValidList();

        if (%RequestFieldsList) {
            for my $RequestFieldsID (
                sort { lc $RequestFieldsList{$a} cmp lc $RequestFieldsList{$b} }
                keys %RequestFieldsList
                )
            {

                # get the sla data
                my %RequestFieldsData = $RequestFieldsObject->RequestFieldsGet(
                    RequestFieldsID => $RequestFieldsID,
                    UserID         => $Self->{UserID},
                );

                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => {
                        %RequestFieldsData,
                        Valid => $ValidList{ $RequestFieldsData{ValidID} },
                    },
                );
            }
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminRequestFields',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {

    my ( $Self, %Param ) = @_;

    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RequestFieldsObject = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $ValidObject        = $Kernel::OM->Get('Kernel::System::Valid');

    # get params
    my %RequestFieldsData;
    $RequestFieldsData{ID} = $ParamObject->GetParam( Param => 'ID' ) || '';

    if ( !$RequestFieldsData{ID} && $Param{ID} ) {
        $RequestFieldsData{ID} = $Param{ID};
    }

    if ( $RequestFieldsData{ID} ) {

        # get the sla data
        %RequestFieldsData = $RequestFieldsObject->RequestFieldsGet(
            RequestFieldsID => $RequestFieldsData{ID},
            UserID         => $Self->{UserID},
        );
    }

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $RequestFieldsData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $RequestFieldsData{ValidID} || $ValidListReverse{valid},
    );

    my %TypList = (
        ''            => '-',
        'Text'        => 'Text',
        'TextArea'    => 'TextArea',
        'Dropdown'    => 'Dropdown',
        'Multiselect' => 'Multiselect',
        'Date'        => 'Date',
        'DateShort'   => 'Date short',
        'Checkbox'    => 'Checkbox'
    );
    $RequestFieldsData{TypOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%TypList,
        Name       => 'Typ',
        SelectedID => $Param{Typ} || $RequestFieldsData{Typ},
    );

    my %LeerWertList = ( '1' => 'ja', '2' => 'nein', );
    $RequestFieldsData{LeerWertOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%LeerWertList,
        Name       => 'LeerWert',
        SelectedID => $Param{LeerWert} || $RequestFieldsData{LeerWert},
    );

    # output sla edit
    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            %Param,
            %RequestFieldsData,
        },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    $LayoutObject->Block(
        Name => 'AntragEdit',
        Data => {
            %Param,
            %RequestFieldsData,
        },
    );

    if (
        ( $Param{Typ} && $Param{Typ} eq "Text" )
        || ( $RequestFieldsData{Typ} && $RequestFieldsData{Typ} eq "Text" )
        )
    {

        # output typ edit
        $LayoutObject->Block(
            Name => 'FeldText',
            Data => {
                %Param,
                %RequestFieldsData,
            },
        );
    }
    elsif (
        ( $Param{Typ} && $Param{Typ} eq "TextArea" )
        || ( $RequestFieldsData{Typ} && $RequestFieldsData{Typ} eq "TextArea" )
        )
    {

        # output typ edit
        $LayoutObject->Block(
            Name => 'FeldTextArea',
            Data => {
                %Param,
                %RequestFieldsData,
            },
        );
    }
    elsif (
        ( $Param{Typ} && $Param{Typ} eq "Dropdown" )
        || ( $RequestFieldsData{Typ} && $RequestFieldsData{Typ} eq "Dropdown" )
        )
    {

        # output typ edit
        $LayoutObject->Block(
            Name => 'FeldDropdown',
            Data => {
                %Param,
                %RequestFieldsData,
            },
        );
    }
    elsif (
        ( $Param{Typ} && $Param{Typ} eq "Multiselect" )
        || ( $RequestFieldsData{Typ} && $RequestFieldsData{Typ} eq "Multiselect" )
        )
    {

        # output typ edit
        $LayoutObject->Block(
            Name => 'MultiSelect',
            Data => {
                %Param,
                %RequestFieldsData,
            },
        );
    }
    elsif (
        ( $Param{Typ} && $Param{Typ} eq "Date" )
        || ( $RequestFieldsData{Typ} && $RequestFieldsData{Typ} eq "Date" )
        )
    {

        # output typ edit
        $LayoutObject->Block(
            Name => 'FeldDate',
            Data => {
                %Param,
                %RequestFieldsData,
            },
        );
    }
    elsif (
        ( $Param{Typ} && $Param{Typ} eq "DateShort" )
        || ( $RequestFieldsData{Typ} && $RequestFieldsData{Typ} eq "DateShort" )
        )
    {

        # output typ edit
        $LayoutObject->Block(
            Name => 'FeldDateShort',
            Data => {
                %Param,
                %RequestFieldsData,
            },
        );
    }
    elsif (
        ( $Param{Typ} && $Param{Typ} eq "Checkbox" )
        || ( $RequestFieldsData{Typ} && $RequestFieldsData{Typ} eq "Checkbox" )
        )
    {

        my %StandardWertList = ( '1' => 'Checked', '2' => 'Unchecked', );
        $RequestFieldsData{DefaultvalueStrg} = $LayoutObject->BuildSelection(
            Data       => \%StandardWertList,
            Name       => 'Defaultvalue',
            SelectedID => $Param{Defaultvalue} || $RequestFieldsData{Defaultvalue},
        );

        # output typ edit
        $LayoutObject->Block(
            Name => 'Checkbox',
            Data => {
                %Param,
                %RequestFieldsData,
            },
        );
    }

    # shows header
    if ( $RequestFieldsData{ID} ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    # get output back
    return $LayoutObject->Output( TemplateFile => 'AdminRequestFields', Data => \%Param );
}

1;
