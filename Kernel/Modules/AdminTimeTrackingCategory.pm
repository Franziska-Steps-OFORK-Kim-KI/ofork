# --
# Kernel/Modules/AdminTimeTrackingCategory.pm - the admin time tracking category module
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de/
# --
# $Id: AdminTimeTrackingCategory.pm,v 1.1 2018/12/02 08:06:51 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminTimeTrackingCategory;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
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

    # Store last entity screen.
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenEntity',
        Value     => $Self->{RequestedURL},
    );

    my $LayoutObject                 = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TimeTrackingCategoryObject   = $Kernel::OM->Get('Kernel::System::TimeTrackingCategory');

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my %Data = $TimeTrackingCategoryObject->CategoryGet( ID => $ID );
        if ( !%Data ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('Need ID!'),
            );
        }
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Change',
            %Data,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminTimeTrackingCategory',
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
        for my $Parameter (qw(ID Name Text Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check needed data
        for my $Needed (qw(Name ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        my %Data = $TimeTrackingCategoryObject->CategoryGet( ID => $GetParam{ID} );
        if ( !%Data ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('Need ID!'),
            );
        }

        # check if a type exists with this name
        my $NameExists = $TimeTrackingCategoryObject->NameExistsCheck(
            Name => $GetParam{Name},
            ID   => $GetParam{ID}
        );

        if ($NameExists) {
            $Errors{NameExists} = 1;
            $Errors{'NameInvalid'} = 'ServerError';
        }

        # Check if type is present in SysConfig setting
        my $UpdateEntity    = $ParamObject->GetParam( Param => 'UpdateEntity' ) || '';
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        # if no errors occurred
        if ( !%Errors ) {

            # update type
            my $Update = $TimeTrackingCategoryObject->CategoryUpdate(
                %GetParam,
                UserID => $Self->{UserID}
            );

            if ($Update) {

                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                    && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                    )
                {
                    my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Change;ID=$ID"
                    );
                }
                else {

                    # otherwise return to overview
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
                }
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action => 'Change',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminTimeTrackingCategory',
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
            TemplateFile => 'AdminTimeTrackingCategory',
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
        my ( %GetParam, %Errors );
        for my $Parameter (qw(Name Text Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check needed data
        for my $Needed (qw(Name ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # check if a type exists with this name
        my $NameExists = $TimeTrackingCategoryObject->NameExistsCheck( Name => $GetParam{Name} );
        if ($NameExists) {
            $Errors{NameExists} = 1;
            $Errors{'NameInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            # add type
            my $NewCategory = $TimeTrackingCategoryObject->CategoryAdd(
                %GetParam,
                UserID => $Self->{UserID}
            );
            if ($NewCategory) {
                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => Translatable('Category added!') );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminTimeTrackingCategory',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action => 'Add',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminTimeTrackingCategory',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        $Self->_Overview();

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminTimeTrackingCategory',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # get valid list
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    # show appropriate messages for ServerError
    if ( defined $Param{Errors}->{NameExists} && $Param{Errors}->{NameExists} == 1 ) {
        $LayoutObject->Block( Name => 'ExistNameServerError' );
    }
    else {
        $LayoutObject->Block( Name => 'NameServerError' );
    }

    # Several error messages can be used for Name.
    $Param{Errors}->{InSettingNameServerError} //= 'Required';
    $LayoutObject->Block(
        Name => $Param{Errors}->{InSettingNameServerError} . 'NameServerError',
    );

    # Several error messages can be used for Valid option.
    $Param{Errors}->{ValidOptionServerError} //= 'Required';
    $LayoutObject->Block(
        Name => $Param{Errors}->{ValidOptionServerError} . 'ValidOptionServerError',
    );

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    my $TimeTrackingCategoryObject = $Kernel::OM->Get('Kernel::System::TimeTrackingCategory');
    my %List = $TimeTrackingCategoryObject->CategoryList( Valid => 0 );

    # if there are any types, they are shown
    if (%List) {

        # get valid list
        my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

        for my $TypeID ( sort { $List{$a} cmp $List{$b} } keys %List ) {

            my %Data = $TimeTrackingCategoryObject->CategoryGet(
                ID => $TypeID,
            );
            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {
                    Valid => $ValidList{ $Data{ValidID} },
                    %Data,
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
    return 1;
}

1;
