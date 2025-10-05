# --
# Kernel/System/RequestGroup.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: RequestGroup.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RequestGroup;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::User',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::RequestGroup - group and roles lib

=head1 DESCRIPTION

All group functions. E. g. to add groups or to get a member list of a group.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $RequestGroupObject = $Kernel::OM->Get('Kernel::System::RequestGroup');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 GroupLookup()

get id or name for group

    my $Group = $RequestGroupObject->GroupLookup(
        GroupID => $GroupID,
    );

    my $GroupID = $RequestGroupObject->GroupLookup(
        Group => $Group,
    );

=cut

sub GroupLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Group} && !$Param{GroupID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Group or GroupID!',
        );
        return;
    }

    # get group list
    my %GroupList = $Self->GroupList(
        Valid => 0,
    );

    return $GroupList{ $Param{GroupID} } if $Param{GroupID};

    # create reverse list
    my %GroupListReverse = reverse %GroupList;

    return $GroupListReverse{ $Param{Group} };
}

=head2 GroupAdd()

to add a group

    my $ID = $RequestGroupObject->GroupAdd(
        Name    => 'example-group',
        Comment => 'comment describing the group',   # optional
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub GroupAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %ExistingGroups = reverse $Self->GroupList( Valid => 0 );
    if ( defined $ExistingGroups{ $Param{Name} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A group with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new group
    return if !$DBObject->Do(
        SQL => 'INSERT INTO request_groups (name, comments, valid_id, '
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{Comment}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new group id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM request_groups WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    my $GroupID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $GroupID = $Row[0];
    }

    return $GroupID;
}

=head2 GroupGet()

returns a hash with group data

    my %GroupData = $RequestGroupObject->GroupGet(
        ID => 2,
    );

This returns something like:

    %GroupData = (
        'Name'       => 'admin',
        'ID'         => 2,
        'ValidID'    => '1',
        'CreateTime' => '2010-04-07 15:41:15',
        'ChangeTime' => '2010-04-07 15:41:15',
        'Comment'    => 'Group of all administrators.',
    );

=cut

sub GroupGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # get group list
    my %GroupList = $Self->GroupDataList(
        Valid => 0,
    );

    # extract group data
    my %Group;
    if ( $GroupList{ $Param{ID} } && ref $GroupList{ $Param{ID} } eq 'HASH' ) {
        %Group = %{ $GroupList{ $Param{ID} } };
    }

    return %Group;
}

=head2 GroupUpdate()

update of a group

    my $Success = $RequestGroupObject->GroupUpdate(
        ID      => 123,
        Name    => 'example-group',
        Comment => 'comment describing the group',   # optional
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub GroupUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Name ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %ExistingGroups = reverse $Self->GroupList( Valid => 0 );
    if ( defined $ExistingGroups{ $Param{Name} } && $ExistingGroups{ $Param{Name} } != $Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A group with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # set default value
    $Param{Comment} ||= '';

    # get current group data
    my %GroupData = $Self->GroupGet(
        ID => $Param{ID},
    );

    # check if update is required
    my $ChangeRequired;
    KEY:
    for my $Key (qw(Name Comment ValidID)) {

        next KEY if defined $GroupData{$Key} && $GroupData{$Key} eq $Param{$Key};

        $ChangeRequired = 1;

        last KEY;
    }

    return 1 if !$ChangeRequired;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update group in database
    return if !$DBObject->Do(
        SQL => 'UPDATE request_groups SET name = ?, comments = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Comment}, \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    return 1 if $GroupData{ValidID} eq $Param{ValidID};

    return 1;
}

=head2 GroupList()

returns a hash of all groups

    my %Groups = $RequestGroupObject->GroupList(
        Valid => 1,   # (optional) default 0
    );

the result looks like

    %Groups = (
        '1' => 'users',
        '2' => 'admin',
        '3' => 'stats',
        '4' => 'secret',
    );

=cut

sub GroupList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} ? 1 : 0;

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # get group data list
    my %GroupDataList = $Self->GroupDataList();

    my %GroupListValid;
    my %GroupListAll;
    KEY:
    for my $Key ( sort keys %GroupDataList ) {

        next KEY if !$Key;

        # add group to the list of all groups
        $GroupListAll{$Key} = $GroupDataList{$Key}->{Name};

        my $Match;
        VALIDID:
        for my $ValidID (@ValidIDs) {

            next VALIDID if $ValidID ne $GroupDataList{$Key}->{ValidID};

            $Match = 1;

            last VALIDID;
        }

        next KEY if !$Match;

        # add group to the list of valid groups
        $GroupListValid{$Key} = $GroupDataList{$Key}->{Name};
    }

    return %GroupListValid if $Valid;
    return %GroupListAll;
}

=head2 GroupDataList()

returns a hash of all group data

    my %GroupDataList = $RequestGroupObject->GroupDataList();

the result looks like

    %GroupDataList = (
        1 => {
            ID         => 1,
            Name       => 'Group 1',
            Comment    => 'The Comment of Group 1',
            ValidID    => 1,
            CreateTime => '2014-01-01 00:20:00',
            CreateBy   => 1,
            ChangeTime => '2014-01-02 00:10:00',
            ChangeBy   => 1,
        },
        2 => {
            ID         => 2,
            Name       => 'Group 2',
            Comment    => 'The Comment of Group 2',
            ValidID    => 1,
            CreateTime => '2014-11-01 10:00:00',
            CreateBy   => 1,
            ChangeTime => '2014-11-02 01:00:00',
            ChangeBy   => 1,
        },
    );

=cut

sub GroupDataList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all group data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, comments, valid_id, create_time, create_by, change_time, change_by FROM request_groups',
    );

    # fetch the result
    my %GroupDataList;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        $GroupDataList{ $Row[0] } = {
            ID         => $Row[0],
            Name       => $Row[1],
            Comment    => $Row[2] || '',
            ValidID    => $Row[3],
            CreateTime => $Row[4],
            CreateBy   => $Row[5],
            ChangeTime => $Row[6],
            ChangeBy   => $Row[7],
        };
    }

    return %GroupDataList;
}



1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
