# --
# Kernel/Modules/AgentAppointmentTeamUser.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: AgentAppointmentTeamUser.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentAppointmentTeamUser;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    # Get user's permissions to associated modules which are displayed as links.
    for my $Module (qw(AgentAppointmentTeam)) {
        my $ModuleGroups = $ConfigObject->Get('Frontend::Module')->{$Module}->{Group} // [];

        if ( IsArrayRefWithData($ModuleGroups) ) {
            MODULE_GROUP:
            for my $ModuleGroup ( @{$ModuleGroups} ) {
                my $HasPermission = $GroupObject->PermissionCheck(
                    UserID    => $Self->{UserID},
                    GroupName => $ModuleGroup,
                    Type      => 'rw',
                );
                if ($HasPermission) {
                    $Param{ModulePermissions}->{$Module} = 1;
                    last MODULE_GROUP;
                }
            }
        }

        # Always allow links if no groups are specified.
        else {
            $Param{ModulePermissions}->{$Module} = 1;
        }
    }

    # get local objects
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TeamObject   = $Kernel::OM->Get('Kernel::System::Calendar::Team');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');

    # ------------------------------------------------------------ #
    # Team <-> user interface to assign users to a team.
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Team' ) {

        # Get Team data.
        my $ID = $ParamObject->GetParam( Param => 'ID' );

        my %TeamData = $TeamObject->TeamGet(
            TeamID => $ID,
            UserID => $Self->{UserID},
        );

        # Get user list, with the full name in the value.
        my %UserData = $UserObject->UserList( Valid => 1 );

        for my $UserID ( sort keys %UserData ) {
            my %User = $UserObject->GetUserData( UserID => $UserID );
            $UserData{$UserID} = "$User{UserLastname} $User{UserFirstname} ($User{UserLogin})";
        }

        # Get members of the the Team.
        my %Member = $TeamObject->TeamUserList(
            TeamID => $ID,
            UserID => $Self->{UserID},
        );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_Change(
            Selected => \%Member,
            Data     => \%UserData,
            ID       => $TeamData{ID},
            Name     => $TeamData{Name},
            Type     => 'Team',
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # Add or remove users to a Team.
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeTeam' ) {

        # Challenge token check for write action.
        $LayoutObject->ChallengeTokenCheck();

        # To be set members of the team.
        my %NewUsers = map { $_ => $_ } $ParamObject->GetArray( Param => 'Team' );

        # Get the team id.
        my $ID = $ParamObject->GetParam( Param => 'ID' );

        # Get user list.
        my %TeamUsers = $TeamObject->TeamUserList(
            TeamID => $ID,
            UserID => $Self->{UserID},
        );

        USERID:
        for my $UserID ( sort keys %NewUsers ) {

            next USERID if !$UserID;              # for select all check-box with ID 0
            next USERID if $TeamUsers{$UserID};

            my $Value = $TeamObject->TeamUserAdd(
                TeamUserID => $UserID,
                TeamID     => $ID,
                UserID     => $Self->{UserID},
            );
        }

        USERID:
        for my $UserID ( sort keys %TeamUsers ) {

            next USERID if $NewUsers{$UserID};

            $TeamObject->TeamUserRemove(
                TeamUserID => $UserID,
                TeamID     => $ID,
                UserID     => $Self->{UserID},
            );
        }

        # If the user would like to continue editing the state, just redirect to the edit screen.
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action};Subaction=Team;ID=$ID"
            );
        }
        else {

            # otherwise return to overview
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action}"
            );
        }
    }

    # ------------------------------------------------------------ #
    # User <-> team interface to assign teams to a user.
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'User' ) {

        # Get user data.
        my $UserID = $ParamObject->GetParam( Param => 'ID' );

        my %UserData = $UserObject->GetUserData(
            UserID => $UserID,
        );

        $UserData{Name} = "$UserData{UserLastname} $UserData{UserFirstname} ($UserData{UserLogin})";

        # Get a list of teams.
        my %TeamList = $TeamObject->AllowedTeamList(
            UserID => $Self->{UserID},
        );

        # Get members of the the Team.
        my %Member = $TeamObject->UserTeamList(
            UserID => $UserID,
        );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_Change(
            Selected => \%Member,
            Data     => \%TeamList,
            ID       => $UserData{UserID},
            Name     => $UserData{Name},
            Type     => 'User',
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # Add or remove users to a Team.
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeUser' ) {

        # Challenge token check for write action.
        $LayoutObject->ChallengeTokenCheck();

        # To set the new team assignments for the user.
        my %NewTeams = map { $_ => $_ } $ParamObject->GetArray( Param => 'User' );

        # Get the user id.
        my $ID = $ParamObject->GetParam( Param => 'ID' );

        # Get a list of teams.
        my %TeamList = $TeamObject->AllowedTeamList(
            UserID => $Self->{UserID},
        );

        TEAMID:
        for my $TeamID ( sort keys %NewTeams ) {

            next TEAMID if !$TeamID;
            next TEAMID if !$TeamList{$TeamID};

            my $Value = $TeamObject->TeamUserAdd(
                TeamUserID => $ID,
                TeamID     => $TeamID,
                UserID     => $Self->{UserID},
            );
        }

        TEAMID:
        for my $TeamID ( sort keys %TeamList ) {

            next TEAMID if $NewTeams{$TeamID};

            $TeamObject->TeamUserRemove(
                TeamUserID => $ID,
                TeamID     => $TeamID,
                UserID     => $Self->{UserID},
            );
        }

        # If the user would like to continue editing the state, just redirect to the edit screen.
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action};Subaction=User;ID=$ID",
            );
        }
        else {

            # Otherwise return to overview.
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action}"
            );
        }
    }

    # ------------------------------------------------------------ #
    # Overview
    # ------------------------------------------------------------ #
    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $Self->_Overview(%Param);
    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _Change {
    my ( $Self, %Param ) = @_;

    my %Data        = %{ $Param{Data} };
    my $Type        = $Param{Type} || 'User';
    my $NeType      = $Type eq 'Team' ? 'User' : 'Team';
    my $AdminAction = $Type eq 'Team' ? 'AdminUser' : 'AgentAppointmentTeam';

    my %VisibleType = (
        Team => Translatable('Team'),
        User => Translatable('Agent'),
    );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Change',
        Data => {
            %Param,
            ActionHome    => 'Admin' . $Type,
            NeType        => $NeType,
            VisibleType   => $VisibleType{$Type},
            VisibleNeType => $VisibleType{$NeType},
        },
    );

    $LayoutObject->Block(
        Name => 'ChangeHeader' . $Type,
        Data => \%Param,
    );

    # Send data to JS.
    $LayoutObject->AddJSData(
        Key   => 'CheckboxDataType',
        Value => $Type,
    );

    $LayoutObject->Block(
        Name => 'ChangeHeader',
        Data => {
            %Param,
            Type   => $Type,
            NeType => $NeType,
        },
    );

    for my $ID ( sort { uc( $Data{$a} ) cmp uc( $Data{$b} ) } keys %Data ) {

        # Set output class.
        my $Selected = $Param{Selected}->{$ID} ? ' checked="checked"' : '';

        $LayoutObject->Block(
            Name => 'ChangeRow',
            Data => {
                %Param,
                Name        => $Param{Data}->{$ID},
                NeType      => $NeType,
                Type        => $Type,
                ID          => $ID,
                Selected    => $Selected,
                AdminAction => $AdminAction,
            },
        );
    }

    return $LayoutObject->Output(
        TemplateFile => 'AgentAppointmentTeamUser',
        Data         => \%Param,
    );
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            %Param,
        },
    );

    $LayoutObject->Block(
        Name => 'OverviewResult',
    );

    my $TeamObject = $Kernel::OM->Get('Kernel::System::Calendar::Team');

    # Get team data.
    my %TeamData = $TeamObject->AllowedTeamList(
        UserID => $Self->{UserID}
    );
    if (%TeamData) {

        TEAMID:
        for my $TeamID ( sort { uc( $TeamData{$a} ) cmp uc( $TeamData{$b} ) } keys %TeamData ) {

            my %Team = $TeamObject->TeamGet(
                TeamID => $TeamID,
                UserID => $Self->{UserID},
            );

            next TEAMID if !IsHashRefWithData( \%Team );

            $LayoutObject->Block(
                Name => 'ListTeams',
                Data => {
                    Subaction => 'Team',
                    %Team,
                },
            );
        }
    }
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # Get a list of all valid users.
    my %UserData = $UserObject->UserList(
        Valid => 1,
    );

    # Get user name.
    USERID:
    for my $UserID ( sort keys %UserData ) {

        my $UserName = $UserObject->UserName( UserID => $UserID );

        next USERID if !$UserName;

        $UserData{$UserID} .= " ($UserName)";
    }

    USERID:
    for my $UserID ( sort { uc( $UserData{$a} ) cmp uc( $UserData{$b} ) } keys %UserData ) {

        next USERID if !$UserID;

        # Set output class.
        $LayoutObject->Block(
            Name => 'ListUsers',
            Data => {
                Name      => $UserData{$UserID},
                Subaction => 'User',
                ID        => $UserID,
            },
        );
    }

    # Return output.
    return $LayoutObject->Output(
        TemplateFile => 'AgentAppointmentTeamUser',
        Data         => \%Param,
    );
}

1;
