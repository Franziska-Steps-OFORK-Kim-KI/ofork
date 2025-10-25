# --
# Kernel/System/CustomerRequestGroup.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: CustomerRequestGroup.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::CustomerRequestGroup;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::CustomerCompany',
    'Kernel::System::CustomerGroup',
    'Kernel::System::CustomerUser',
    'Kernel::System::DB',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::CustomerRequestGroup - customer requestgroup lib

=head1 DESCRIPTION

All customer group functions. E. g. to add groups or to get a member list of a group.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CustomerRequestGroupObject = $Kernel::OM->Get('Kernel::System::CustomerRequestGroup');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'CustomerGroup';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 GroupMemberAdd()

to add a member to a group

    Permission: ro,move_into,priority,create,rw

    my $Success = $CustomerRequestGroupObject->GroupMemberAdd(
        GID => 12,
        UID => 6,
        Permission => {
            ro        => 1,
            move_into => 1,
            create    => 1,
            owner     => 1,
            priority  => 0,
            rw        => 0,
        },
        UserID => 123,
    );

=cut

sub GroupMemberAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(UID GID UserID Permission)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    # check rw rule (set only rw and remove rest, because it's including all in rw)
    if ( $Param{Permission}->{rw} ) {
        $Param{Permission} = { rw => 1 };
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update permission
    TYPE:
    for my $Type ( sort keys %{ $Param{Permission} } ) {

        # delete existing permission
        $DBObject->Do(
            SQL => 'DELETE FROM request_group_customer_user WHERE '
                . ' group_id = ? AND user_id = ? AND permission_key = ?',
            Bind => [ \$Param{GID}, \$Param{UID}, \$Type ],
        );

        # debug
        if ( $Self->{Debug} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'notice',
                Message =>
                    "Add UID:$Param{UID} to GID:$Param{GID}, $Type:$Param{Permission}->{$Type}!",
            );
        }

        # insert new permission (if needed)
        next TYPE if !$Param{Permission}->{$Type};

        $DBObject->Do(
            SQL => 'INSERT INTO request_group_customer_user '
                . '(user_id, group_id, permission_key, permission_value, '
                . 'create_time, create_by, change_time, change_by) '
                . 'VALUES (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$Param{UID}, \$Param{GID}, \$Type, \$Param{Permission}->{$Type}, \$Param{UserID},
                \$Param{UserID},
            ],
        );
    }

    return 1;
}

=head2 GroupMemberList()

Get users of the given group.

    my %Users = $CustomerRequestGroupObject->GroupMemberList(
        GroupID        => '123',
        Type           => 'move_into', # ro|move_into|priority|create|rw
        Result         => 'HASH',      # return hash of user id => user name entries
        RawPermissions => 0,           # 0 (return inherited permissions from CustomerCompany), default
                                       # 1 (return only direct permissions)
    );

or

    my @UserIDs = $CustomerRequestGroupObject->GroupMemberList(
        GroupID        => '123',
        Type           => 'move_into', # ro|move_into|priority|create|rw
        Result         => 'ID',        # return array of user ids
        RawPermissions => 0,           # 0 (return inherited permissions from CustomerCompany), default
                                       # 1 (return only direct permissions)
    );

or

    my @UserNames = $CustomerRequestGroupObject->GroupMemberList(
        GroupID        => '123',
        Type           => 'move_into', # ro|move_into|priority|create|rw
        Result         => 'Name',        # return array of user names
        RawPermissions => 0,           # 0 (return inherited permissions from CustomerCompany), default
                                       # 1 (return only direct permissions)
    );

Get groups of given user.

    my %Groups = $CustomerGroupObject->GroupMemberList(
        UserID         => '123',
        Type           => 'move_into', # ro|move_into|priority|create|rw
        Result         => 'HASH',      # return hash of group id => group name entries
        RawPermissions => 0,           # 0 (return inherited permissions from CustomerCompany), default
                                       # 1 (return only direct permissions)
    );

or

    my @GroupIDs = $CustomerRequestGroupObject->GroupMemberList(
        UserID         => '123',
        Type           => 'move_into', # ro|move_into|priority|create|rw
        Result         => 'ID',        # return array of group ids
        RawPermissions => 0,           # 0 (return inherited permissions from CustomerCompany), default
                                       # 1 (return only direct permissions)
    );

or

    my @GroupNames = $CustomerRequestGroupObject->GroupMemberList(
        UserID         => '123',
        Type           => 'move_into', # ro|move_into|priority|create|rw
        Result         => 'Name',        # return array of group names
        RawPermissions => 0,           # 0 (return inherited permissions from CustomerCompany), default
                                       # 1 (return only direct permissions)
    );

=cut

sub GroupMemberList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Result Type)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }
    if ( !$Param{UserID} && !$Param{GroupID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID or GroupID!'
        );
        return;
    }

    my %Data;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # if it's active, return just the permitted groups
    my $SQL =
        'SELECT g.id, g.name, gu.permission_key, gu.permission_value, gu.user_id'
        . ' FROM request_groups g, request_group_customer_user gu'
        . ' WHERE g.valid_id IN ( ' . join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet() . ')'
        . ' AND g.id = gu.group_id AND gu.permission_value = 1'
        . " AND gu.permission_key IN (?, 'rw')";
    my @Bind = ( \$Param{Type} );

    if ( $Param{UserID} ) {
        $SQL .= ' AND gu.user_id = ?';
        push @Bind, \$Param{UserID};
    }
    else {
        $SQL .= ' AND gu.group_id = ?';
        push @Bind, \$Param{GroupID};
    }

    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{UserID} ) {
            $Data{ $Row[0] } = $Row[1];
        }
        else {
            $Data{ $Row[4] } = $Row[1];
        }
    }

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    for my $Key ( sort keys %Data ) {

        # Bugfix #12285 - Check if customer user is valid.
        if ( $Param{GroupID} ) {

            my %User = $CustomerUserObject->CustomerUserDataGet(
                User => $Key,
            );

            if ( defined $User{ValidID} && $User{ValidID} != 1 ) {
                delete $Data{$Key};
            }
        }
    }

    # add always groups if groups are requested
    if (
        $Param{UserID}
        && $Kernel::OM->Get('Kernel::Config')->Get('CustomerGroupAlwaysGroups')
        )
    {
        my %Groups = $Kernel::OM->Get('Kernel::System::RequestGroup')->GroupList( Valid => 1 );
        my %GroupsReverse = reverse %Groups;
        ALWAYSGROUP:
        for my $AlwaysGroup ( @{ $Kernel::OM->Get('Kernel::Config')->Get('CustomerGroupAlwaysGroups') } ) {
            next ALWAYSGROUP if !$GroupsReverse{$AlwaysGroup};
            next ALWAYSGROUP if $Data{ $GroupsReverse{$AlwaysGroup} };
            $Data{ $GroupsReverse{$AlwaysGroup} } = $AlwaysGroup;
        }
    }

    # return data depending on requested result
    if ( $Param{Result} eq 'HASH' ) {
        return %Data;
    }
    elsif ( $Param{Result} eq 'ID' ) {
        return ( sort keys %Data );
    }
    elsif ( $Param{Result} eq 'Name' ) {
        return ( sort values %Data );
    }
    return;
}


=head2 GroupContextNameGet()

Helper function to get currently configured name of a specific group access context

    my $ContextName = $CustomerRequestGroupObject->GroupContextNameGet(
        SysConfigName => '100-CustomerID-other', # optional, defaults to '001-CustomerID-same'
    );

=cut

sub GroupContextNameGet {
    my ( $Self, %Param ) = @_;

    # get config name
    # fallback to 'normal' group permission config
    $Param{SysConfigName} ||= '001-CustomerID-same';

    my $ContextConfig = $Kernel::OM->Get('Kernel::Config')->Get('CustomerGroupPermissionContext');
    return if !IsHashRefWithData($ContextConfig);
    return if !IsHashRefWithData( $ContextConfig->{ $Param{SysConfigName} } );

    return $ContextConfig->{ $Param{SysConfigName} }->{Value};
}

=head2 GroupContextNameList()

Helper function to get the names of all configured group access contexts

    my @ContextNames = $CustomerRequestGroupObject->GroupContextNameList();

=cut

sub GroupContextNameList {
    my ( $Self, %Param ) = @_;

    my $ContextConfig = $Kernel::OM->Get('Kernel::Config')->Get('CustomerGroupPermissionContext');
    return () if !IsHashRefWithData($ContextConfig);

    # fill list
    my @ContextNames;
    CONTEXT:
    for my $Item ( sort keys %{$ContextConfig} ) {
        next CONTEXT if !IsHashRefWithData( $ContextConfig->{$Item} );
        next CONTEXT if !$ContextConfig->{$Item}->{Value};

        push @ContextNames, $ContextConfig->{$Item}->{Value};
    }

    return @ContextNames;
}


=head2 GroupLookup()

get id or name for group

    my $Group = $CustomerRequestGroupObject->GroupLookup(GroupID => $GroupID);

    my $GroupID = $CustomerRequestGroupObject->GroupLookup(Group => $Group);

=cut

sub GroupLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Group} && !$Param{GroupID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Got no Group or GroupID!',
        );
        return;
    }


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get data
    my $SQL;
    my @Bind;
    my $Suffix;
    if ( $Param{Group} ) {
        $Param{What} = $Param{Group};
        $Suffix      = 'GroupID';
        $SQL         = 'SELECT id FROM request_groups WHERE name = ?';
        push @Bind, \$Param{Group};
    }
    else {
        $Param{What} = $Param{GroupID};
        $Suffix      = 'Group';
        $SQL         = 'SELECT name FROM request_groups WHERE id = ?';
        push @Bind, \$Param{GroupID};
    }
    return if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    my $Result;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        # store result
        $Result = $Row[0];
    }

    # check if data exists
    if ( !$Result ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Found no \$$Suffix for $Param{What}!",
        );
        return;
    }

    return $Result;
}

=head2 PermissionCheck()

Check if a customer user has a certain permission for a certain group.

    my $HasPermission = $CustomerRequestGroupObject->PermissionCheck(
        UserID    => $UserID,
        GroupName => $GroupName,
        Type      => 'move_into',
    );

=cut

sub PermissionCheck {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(UserID GroupName Type)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    my %GroupMemberList = reverse $Self->GroupMemberList(
        UserID => $Param{UserID},
        Type   => $Param{Type},
        Result => 'HASH',
    );

    return $GroupMemberList{ $Param{GroupName} } ? 1 : 0;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
