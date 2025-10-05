# --
# Kernel/System/Calendar/Team.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Team.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Calendar::Team;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::DB',
    'Kernel::System::Group',
    'Kernel::System::Cache',
    'Kernel::System::Valid',
    'Kernel::System::User',
);

=head1 NAME

Kernel::System::Calendar::Team - Team lib

=head1 DESCRIPTION

All Team functions.

=head1 PUBLIC INTERFACE


=head2 new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TeamObject = $Kernel::OM->Get('Kernel::System::Calendar::Team');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # set cache type and ttl
    $Self->{CacheType} = 'Team';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 TeamList()

return a Team list as hash

    my %List = $TeamObject->TeamList(
        Valid  => 0,     # (optional)
        UserID => 1,     # (optional)
    );

=cut

sub TeamList {
    my ( $Self, %Param ) = @_;

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # create cache key
    my $CacheKey;
    if ( $Param{Valid} ) {
        $CacheKey = 'TeamList::Valid';
    }
    else {
        $CacheKey = 'TeamList::All';
    }

    # check UserID
    return if ( $Param{UserID} && !IsInteger( $Param{UserID} ) );

    if ( $Param{UserID} ) {
        $CacheKey .= '::' . $Param{UserID};
    }

    # get local cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $Cache = $CacheObject->Get(
        Key  => $CacheKey,
        Type => $Self->{CacheType},
    );
    return %{$Cache} if $Cache;

    # create sql
    my @Bind;
    my $SQL = 'SELECT id, name FROM calendar_team
        WHERE 1=1 ';
    if ( $Param{Valid} ) {
        $SQL .= "AND valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} ) ";
    }
    if ( $Param{UserID} ) {
        $SQL .= 'AND create_by = ?';
        push @Bind, \$Param{UserID};
    }

    # get local database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[1];
    }

    # set cache
    $CacheObject->Set(
        Key   => $CacheKey,
        Value => \%Data,
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
    );

    return %Data;
}

=head2 TeamGet()

get a Team

    my %Team = $TeamObject->TeamGet(
        TeamID => 123,              # required
                                    # or
        Name => 'Some Team Name',   # required

        UserID => 1,                # required
    );

=cut

sub TeamGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( ( !$Param{TeamID} && !$Param{Name} ) || !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TeamID or Name and UserID!',
        );
        return;
    }

    # get local cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $CacheKey = $Param{TeamID} || $Param{Name};
    my $Cache    = $CacheObject->Get(
        Key  => 'TeamGet' . $CacheKey,
        Type => $Self->{CacheType},
    );
    return %{$Cache} if $Cache;

    # get local database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my @Bind;
    my $SQL = 'SELECT id, name, group_id, comments, valid_id, create_time, create_by, change_time, change_by
        FROM calendar_team
        WHERE 1=1 ';

    if ( $Param{TeamID} ) {
        $SQL .= 'AND id = ?';
        push @Bind, \$Param{TeamID};
    }
    elsif ( $Param{Name} ) {
        $SQL .= 'AND name = ?';
        push @Bind, \$Param{Name};
    }

    # ask database
    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@Bind,
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}         = $Row[0];
        $Data{Name}       = $Row[1];
        $Data{GroupID}    = $Row[2];
        $Data{Comment}    = $Row[3];
        $Data{ValidID}    = $Row[4];
        $Data{CreateTime} = $Row[5];
        $Data{CreateBy}   = $Row[6];
        $Data{ChangeTime} = $Row[7];
        $Data{ChangeBy}   = $Row[8];
    }

    # set cache
    $CacheObject->Set(
        Key   => 'TeamGet' . $CacheKey,
        Value => \%Data,
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
    );

    return %Data;
}

=head2 TeamAdd()

add a team

    my $True = $TeamObject->TeamAdd(
        Name    => 'Some Team Name',
        GroupID => 5,
        Comment => 'My comment',
        ValidID => 1,
        UserID  => 1,
    );

=cut

sub TeamAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name GroupID ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # check if team with same name exists
    return if $Self->TeamGet(
        Name   => $Param{Name},
        UserID => $Param{UserID},
    );

    # check group
    return if !$Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
        GroupID => $Param{GroupID},
    );

    # get local database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO calendar_team
                   (name, group_id, comments, valid_id, create_time, create_by, change_time, change_by)
                   VALUES
                   (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{GroupID}, \$Param{Comment}, \$Param{ValidID}, \$Param{UserID},
            \$Param{UserID},
        ],
    );

    # get new team id
    return if !$DBObject->Prepare(
        SQL => 'SELECT id
                      FROM calendar_team
                      WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return if !$ID;

    # delete cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

    return $ID;
}

=head2 TeamUpdate()

update an existing Team

    my $True = $TeamObject->TeamUpdate(
        TeamID         => 123,
        Name           => 'New Name',
        GroupID        => 4,
        Comment        => 'Some comment',
        ValidID        => 1,
        UserID         => 1,
    );

=cut

sub TeamUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TeamID Name GroupID ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # check if team with same name exists
    my %Team = $Self->TeamGet(
        Name   => $Param{Name},
        UserID => $Param{UserID},
    );
    if (%Team) {
        return if $Team{ID} != $Param{TeamID};
    }

    # check group
    return if !$Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
        GroupID => $Param{GroupID},
    );

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE calendar_team
                    SET name = ?, group_id = ?, comments = ?, valid_id = ?,
                    change_time = current_timestamp, change_by = ?
                WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{GroupID}, \$Param{Comment}, \$Param{ValidID}, \$Param{UserID},
            \$Param{TeamID},
        ],
    );

    # delete cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

    return 1;
}

=head2 TeamImport()

import a team

    my $True = $TeamObject->TeamImport(
        TeamData                  => {
            'ValidID' => '1',
            'ChangeBy' => '2',
            'CreateBy' => '2',
            'ID' => '1',
            'CreateTime' => '2016-05-10 10:32:40',
            'ChangeTime' => '2016-05-10 10:32:40',
            'UserList' => {
                '2' => 'agent_login1',
                '3' => 'agent_login2',
                '4' => 'agent_login3',
            },
            'Name' => 'MyTeamName',
            'GroupID' => '2',
            'Comment' => ''
        },
        OverwriteExistingEntities => 0,  # 0 || 1,
        UserID                    => 1,
    );

=cut

sub TeamImport {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    return if !IsHashRefWithData( $Param{TeamData} );

    # check for an existing team
    my %ExistingTeam = $Self->TeamGet(
        Name   => $Param{TeamData}->{Name},
        UserID => $Param{UserID},
    );

    my $Success;

    # import the team
    if ( !IsHashRefWithData( \%ExistingTeam ) ) {

        $Success = $Self->TeamAdd(
            %{ $Param{TeamData} },
            UserID => $Param{UserID},
        );

        $Param{TeamData}->{ID} = $Success;
    }
    else {

        if ( !$Param{OverwriteExistingEntities} ) {
            return 1;
        }

        $Success = $Self->TeamUpdate(
            %{ $Param{TeamData} },
            TeamID => $ExistingTeam{ID},
            UserID => $Param{UserID},
        );

        $Param{TeamData}->{ID} = $ExistingTeam{ID};
    }

    # get a team user list and remove the user assignment
    # from the (now) existing team
    my %TeamUserList = $Self->TeamUserList(
        TeamID => $Param{TeamData}->{ID},
        UserID => $Param{UserID},
    );

    if ( IsHashRefWithData( \%TeamUserList ) ) {

        USERID:
        for my $UserID ( sort keys %TeamUserList ) {

            next USERID if !$UserID;

            my $True = $Self->TeamUserRemove(
                TeamID     => $Param{TeamData}->{ID},
                TeamUserID => $UserID,
                UserID     => $Param{UserID},
            );
        }
    }

    # get a local user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # setup new team user assignments
    USERID:
    for my $UserID ( sort keys %{ $Param{TeamData}->{UserList} } ) {

        next USERID if !$UserID;

        my $NewUserID = $UserObject->UserLookup(
            UserLogin => $Param{TeamData}->{UserList}->{$UserID},
        );

        next USERID if !$NewUserID;

        my $True = $Self->TeamUserAdd(
            TeamID     => $Param{TeamData}->{ID},
            TeamUserID => $NewUserID,
            UserID     => $Param{UserID},
        );
    }

    return 1;
}

=head2 AllowedTeamList()

return allowed, valid Teams list as hash

    my %List = $TeamObject->AllowedTeamList(
        UserID       => 123,    # (required) UserID
        Valid        => 0,      # (optional) Return valid teams only, default: 1
        PreventEmpty => 1,      # (optional) Just return teams with assigned users, default: 0
    );

=cut

sub AllowedTeamList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{Valid}        //= 1;
    $Param{PreventEmpty} //= 0;

    my @Groups = $Kernel::OM->Get('Kernel::System::Group')->GroupMemberList(
        UserID => $Param{UserID},
        Type   => 'ro',
        Result => 'ID',
    );

    # abort if user is not a member of any group
    return if !scalar @Groups;

    # create cache key
    my $CacheKey = "AllowedTeamList::$Param{Valid}::$Param{PreventEmpty}::" . join( '::', sort @Groups );

    # get local cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $Cache = $CacheObject->Get(
        Key  => $CacheKey,
        Type => $Self->{CacheType},
    );
    return %{$Cache} if $Cache;

    # get local database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # create sql
    my $SQL = '';

    if ( $Param{PreventEmpty} ) {
        $SQL = "
            SELECT DISTINCT st.id, st.name
            FROM calendar_team st
            JOIN calendar_team_user stu ON stu.team_id = st.id
            WHERE st.group_id IN ( ${\(join ', ', @Groups)} )
        ";
    }
    else {
        $SQL = "
            SELECT id, name
            FROM calendar_team
            WHERE group_id IN ( ${\(join ', ', @Groups)} )
        ";
    }

    if ( $Param{Valid} ) {
        $SQL .= "
            AND valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )
        ";
    }

    return if !$DBObject->Prepare( SQL => $SQL );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[1];
    }

    # set cache
    $CacheObject->Set(
        Key   => $CacheKey,
        Value => \%Data,
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
    );

    return %Data;
}

=head2 TeamUserAdd()

add an agent to a team

    my $True = $TeamObject->TeamUserAdd(
        TeamID     => 4,
        TeamUserID => 5,
        UserID     => 1,
    );

=cut

sub TeamUserAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TeamID TeamUserID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # TODO
    # implement TeamID, TeamUserID, permission? check (enforced by constraint on DB level)

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO calendar_team_user
               (team_id, user_id, create_time, create_by, change_time, change_by)
               VALUES
               (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TeamID}, \$Param{TeamUserID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # delete cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

    return 1;
}

=head2 TeamUserRemove()

remove an agent from a team

    my $True = $TeamObject->TeamUserRemove(
        TeamID     => 4,
        TeamUserID => 5,
        UserID     => 1,
    );

=cut

sub TeamUserRemove {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TeamID TeamUserID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # TODO
    # implement TeamID, TeamUserID, permission? check (enforced by constraint on DB level)

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'DELETE FROM calendar_team_user
                   WHERE team_id = ?
                   AND user_id = ?',
        Bind => [
            \$Param{TeamID}, \$Param{TeamUserID},
        ],
    );

    # delete cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

    return 1;
}

=head2 TeamUserList()

return agents list for a team as a hash

    my %List = $TeamObject->TeamUserList(
        TeamID => 42,
        UserID => 123,
    );

=cut

sub TeamUserList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TeamID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # create cache key
    my $CacheKey = "TeamUserList::$Param{TeamID}";

    # get local cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $Cache = $CacheObject->Get(
        Key  => $CacheKey,
        Type => $Self->{CacheType},
    );
    return %{$Cache} if $Cache;

    # get local database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => 'SELECT user_id
                    FROM calendar_team_user
                    WHERE team_id = ?',
        Bind => [ \$Param{TeamID}, ],
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[0];
    }

    # set cache
    $CacheObject->Set(
        Key   => $CacheKey,
        Value => \%Data,
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
    );

    return %Data;
}

=head2 UserTeamList()

return team list for a user as a hash

    my %List = $TeamObject->UserTeamList(
        UserID => 123,
    );

=cut

sub UserTeamList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # create cache key
    my $CacheKey = "UserTeamList::$Param{UserID}";

    # get local cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $Cache = $CacheObject->Get(
        Key  => $CacheKey,
        Type => $Self->{CacheType},
    );
    return %{$Cache} if $Cache;

    # get local database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => 'SELECT team_id
                    FROM calendar_team_user
                    WHERE user_id = ?',
        Bind => [ \$Param{UserID}, ],
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[0];
    }

    # set cache
    $CacheObject->Set(
        Key   => $CacheKey,
        Value => \%Data,
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
    );

    return %Data;
}

1;
