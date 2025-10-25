# --
# Kernel/Modules/AgentAppointmentTeam.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: AgentAppointmentTeam.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentAppointmentTeam;

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

    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Get user's permissions to associated modules which are displayed as links.
    for my $Module (qw(AgentAppointmentTeamUser)) {
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

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TeamObject   = $Kernel::OM->Get('Kernel::System::Calendar::Team');

    # ------------------------------------------------------------ #
    # Change screen.
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {

        my %GetParam = ();

        $GetParam{TeamID} = $ParamObject->GetParam( Param => 'TeamID' ) || '';
        if ( !$GetParam{TeamID} ) {
            return $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Need %s!', 'TeamID' ),
            );
        }

        my $HasAdminPermission = $GroupObject->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => 'admin',
            Type      => 'rw',
        );
        if (
            !$HasAdminPermission
            && !$Self->_CheckPermission( TeamID => $GetParam{TeamID} )
            )
        {
            return $LayoutObject->FatalError(
                Message => Translatable('No Permission!'),
            );
        }

        my %TeamData = $TeamObject->TeamGet(
            TeamID => $GetParam{TeamID},
            UserID => $Self->{UserID},
        );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Change',
            %TeamData,
            %GetParam,
        );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AgentAppointmentTeam',
            Data         => \%Param,
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # Change action.
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # Challenge token check for write action.
        $LayoutObject->ChallengeTokenCheck();

        my ( %GetParam, %Errors );

        # Get params.
        for my $Parameter (qw(TeamID Name GroupID Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        if ( !$GetParam{TeamID} ) {
            return $LayoutObject->FatalError(
                Message => Translatable('Need TeamID!'),
            );
        }

        my $HasAdminPermission = $GroupObject->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => 'admin',
            Type      => 'rw',
        );
        if (
            !$HasAdminPermission
            && !$Self->_CheckPermission( TeamID => $GetParam{TeamID} )
            )
        {
            return $LayoutObject->FatalError(
                Message => Translatable('No Permission!'),
            );
        }

        # Check if group ID is valid.
        my $Group = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
            GroupID => $GetParam{GroupID},
        );
        if ( !$Group ) {
            return $LayoutObject->FatalError(
                Message => Translatable('Invalid GroupID!'),
            );
        }

        my $HasGroupPermission = $GroupObject->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => $Group,
            Type      => 'rw',
        );

        # Check if user is part of specified group.
        if ( !$HasAdminPermission && !$HasGroupPermission ) {

            return $LayoutObject->FatalError(
                Message => Translatable('No Permission!'),
            );
        }

        # Check needed data.
        for my $Needed (qw(Name GroupID ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # Check if there is a team with same name.
        my %Team = $TeamObject->TeamGet(
            Name   => $GetParam{Name},
            UserID => $Self->{UserID},
        );
        if ( %Team && $Team{ID} != $GetParam{TeamID} ) {
            $Errors{NameInvalid} = "ServerError";
            $Errors{NameExists}  = 1;
        }

        # If no errors occurred.
        if ( !%Errors ) {

            # Update Team.
            my $Update = $TeamObject->TeamUpdate( %GetParam, UserID => $Self->{UserID} );

            if ($Update) {

                # If the user would like to continue editing the state, just redirect to the edit screen.
                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                    && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                    )
                {
                    my $ID = $ParamObject->GetParam( Param => 'TeamID' ) || '';
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Change;TeamID=$ID"
                    );
                }
                else {

                    # Otherwise return to overview.
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action}"
                    );
                }
            }
        }

        # Something has gone wrong.
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Team => 'Error' );
        $Self->_Edit(
            Action => 'Change',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AgentAppointmentTeam',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # Add screen.
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AgentAppointmentTeam',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # Add action.
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # Challenge token check for write action.
        $LayoutObject->ChallengeTokenCheck();

        my ( %GetParam, %Errors );

        # Get params.
        for my $Parameter (qw(Name GroupID Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # Check needed data.
        for my $Needed (qw(Name GroupID ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # Check if group ID is valid.
        my $Group = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
            GroupID => $GetParam{GroupID},
        );
        if ( !$Group ) {
            return $LayoutObject->FatalError(
                Message => Translatable('Invalid GroupID!'),
            );
        }

        my $HasAdminPermission = $GroupObject->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => 'admin',
            Type      => 'rw',
        );
        my $HasGroupPermission = $GroupObject->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => $Group,
            Type      => 'rw',
        );

        # Check if user is part of specified group.
        if ( !$HasAdminPermission && !$HasGroupPermission ) {
            return $LayoutObject->FatalError(
                Message => Translatable('No Permission!'),
            );
        }

        # Check if there is a team with same name.
        my %Team = $TeamObject->TeamGet(
            Name   => $GetParam{Name},
            UserID => $Self->{UserID},
        );
        if (%Team) {
            $Errors{NameInvalid} = "ServerError";
            $Errors{NameExists}  = 1;
        }

        # If no errors occurred.
        if ( !%Errors ) {

            my $NewTeam = $TeamObject->TeamAdd(
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($NewTeam) {
                $Self->_Overview(%Param);
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => 'Team added!' );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AgentAppointmentTeam',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # Something has gone wrong.
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Team => 'Error' );
        $Self->_Edit(
            Action => 'Add',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AgentAppointmentTeam',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # Team import
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'TeamImport' ) {

        # Challenge token check for write action.
        $LayoutObject->ChallengeTokenCheck();

        # Get the uploaded file content.
        my $FormID      = $ParamObject->GetParam( Param => 'FormID' ) || '';
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'FileUpload',
        );
        my $Content = $UploadStuff{Content};

        # Check for overwriting option.
        my $OverwriteExistingEntities = $ParamObject->GetParam( Param => 'OverwriteExistingEntities' ) || 0;

        # extract the team data from the uploaded file
        my $TeamData = $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => $Content );
        if ( ref $TeamData ne 'HASH' ) {
            return (
                Message => Translatable('Couldn\'t read team configuration file. Please make sure you file is valid.'),
            );
        }

        # Check if group ID is valid.
        my $Group = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
            GroupID => $TeamData->{GroupID},
        );
        if ( !$Group ) {
            return $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Need %s!', 'GroupID' ),
            );
        }

        my $HasAdminPermission = $GroupObject->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => 'admin',
            Type      => 'rw',
        );
        my $HasGroupPermission = $GroupObject->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => $Group,
            Type      => 'rw',
        );

        # Check if user is part of specified group.
        if ( !$HasAdminPermission && !$HasGroupPermission ) {
            return $LayoutObject->FatalError(
                Message => Translatable('No Permission!'),
            );
        }

        # Import the team.
        my $Success = $TeamObject->TeamImport(
            TeamData                  => $TeamData,
            OverwriteExistingEntities => $OverwriteExistingEntities,
            UserID                    => $Self->{UserID},
        );

        if ( !$Success ) {

            $Self->_Overview(%Param);
            my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $LayoutObject->Notify(
                Priority => 'Error',
                Info     => Translatable('Could not import the team!'),
            );
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AgentAppointmentTeam',
                Data         => \%Param,
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }
        else {

            $Self->_Overview(%Param);
            my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $LayoutObject->Notify(
                Info => Translatable('Team imported!'),
            );
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AgentAppointmentTeam',
                Data         => \%Param,
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }
    }

    # ------------------------------------------------------------ #
    # Team export
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'TeamExport' ) {

        # Check for TeamID.
        my $TeamID = $ParamObject->GetParam( Param => 'TeamID' ) || '';
        if ( !$TeamID ) {
            return $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Need %s!', 'TeamID' ),
            );
        }

        my $HasAdminPermission = $GroupObject->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => 'admin',
            Type      => 'rw',
        );

        if ( !$HasAdminPermission && !$Self->_CheckPermission( TeamID => $TeamID ) ) {
            return $LayoutObject->FatalError(
                Message => Translatable('No Permission!'),
            );
        }

        # Get team data.
        my %TeamData = $TeamObject->TeamGet(
            TeamID => $TeamID,
            UserID => $Self->{UserID},
        );

        if ( !IsHashRefWithData( \%TeamData ) ) {
            return $LayoutObject->ErrorScreen(
                Message =>
                    $LayoutObject->{LanguageObject}
                    ->Translate( 'Could not retrieve data for given TeamID %s!', $TeamID ),
            );
        }

        # Get team user list.
        my %TeamUserList = $TeamObject->TeamUserList(
            TeamID => $TeamID,
            UserID => $Self->{UserID},
        );

        # Get a local user object.
        my $UserObject = $Kernel::OM->Get('Kernel::System::User');

        my %PreparedUsers;

        USERID:
        for my $UserID ( sort keys %TeamUserList ) {

            next USERID if !$UserID;

            # Get user login by user id.
            my $UserLogin = $UserObject->UserLookup(
                UserID => $UserID,
            );

            next USERID if !$UserLogin;

            # Save user id and user login.
            $PreparedUsers{$UserID} = $UserLogin;
        }

        $TeamData{UserList} = \%PreparedUsers;

        # Convert the team data hash to string.
        my $TeamDataYAML = $Kernel::OM->Get('Kernel::System::YAML')->Dump( Data => \%TeamData );

        # Prepare team name to be part of the filename.
        my $TeamName = $TeamData{Name};
        $TeamName =~ s/\s+/_/g;

        # Send the result to the browser.
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $TeamDataYAML,
            Type        => 'attachment',
            Filename    => 'Export_Team_' . $TeamName . '.yml',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------
    # Overview screen.
    # ------------------------------------------------------------
    else {
        $Self->_Overview(%Param);
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AgentAppointmentTeam',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # Get valid list.
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required '
            . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );

    # Get group list.
    my %GroupList = $Kernel::OM->Get('Kernel::System::Group')->GroupList(
        Valid => 1,
    );

    my $HasAdminPermission = $GroupObject->PermissionCheck(
        UserID    => $Self->{UserID},
        GroupName => 'admin',
        Type      => 'rw',
    );

    # Show only groups user is part of, if user is not an admin.
    if ( !$HasAdminPermission ) {
        for my $GroupID ( sort keys %GroupList ) {
            my $HasPermission = $GroupObject->PermissionCheck(
                UserID    => $Self->{UserID},
                GroupName => $GroupList{$GroupID},
                Type      => 'rw',
            );
            if ( !$HasPermission ) {
                delete $GroupList{$GroupID};
            }
        }
    }

    $Param{GroupOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%GroupList,
        Name       => 'GroupID',
        SelectedID => $Param{GroupID} || '',
        Class      => 'Modernize Validate_Required '
            . ( $Param{Errors}->{'GroupIDInvalid'} || '' ),
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => { %Param, %{ $Param{Errors} }, },
    );

    # Shows header.
    if ( $Param{Action} eq 'Change' ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $Output = '';

    # Get a local layout object.
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block(
        Name => 'ActionList',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionImport' );
    $LayoutObject->Block( Name => 'ActionAdd' );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    # Get a local team object.
    my $TeamObject = $Kernel::OM->Get('Kernel::System::Calendar::Team');

    my $HasAdminPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
        UserID    => $Self->{UserID},
        GroupName => 'admin',
        Type      => 'rw',
    );

    # If user is part of the admin group, get list of all defined teams in the system.
    my %TeamList;
    if ($HasAdminPermission) {
        %TeamList = $TeamObject->TeamList(
            Valid => 0,
        );
    }

    # Otherwise, get list of teams for current user. User must have at least RO access to the same
    #   group as defined team (see bug#12414 for more information).
    else {
        %TeamList = $TeamObject->AllowedTeamList(
            UserID => $Self->{UserID},
            Valid  => 0,
        );
    }

    # If there are any teams defined, they are shown.
    if (%TeamList) {

        # Get valid list.
        my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

        for my $TeamID ( sort { $a <=> $b } keys %TeamList ) {

            # Get Team data.
            my %TeamData = $TeamObject->TeamGet(
                TeamID => $TeamID,
                UserID => $Self->{UserID},
            );

            # Group lookup.
            $TeamData{GroupName} = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
                GroupID => $TeamData{GroupID},
            );

            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {
                    %TeamData,
                    TeamID => $TeamID,
                    Valid  => $ValidList{ $TeamData{ValidID} },
                },
            );
        }
    }

    # Otherwise a no data found message is displayed.
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }
    return 1;
}

sub _CheckPermission {
    my ( $Self, %Param ) = @_;

    return if !$Param{TeamID};

    # Get list of teams for current user, including invalid teams. User must have at least RO access
    #   to the same group as defined team (see bug#12414 for more information).
    my %TeamList = $Kernel::OM->Get('Kernel::System::Calendar::Team')->AllowedTeamList(
        UserID => $Self->{UserID},
        Valid  => 0,
    );

    return defined $TeamList{ $Param{TeamID} };
}

1;
