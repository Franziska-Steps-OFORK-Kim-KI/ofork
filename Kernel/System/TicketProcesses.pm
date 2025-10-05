# --
# Kernel/System/TicketProcesses.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: TicketProcesses.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketProcesses;

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

Kernel::System::TicketProcesses - TicketProcesses lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add TicketProcesses.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketProcessesObject = $Kernel::OM->Get('Kernel::System::TicketProcesses');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessLookup()

get id or name for Processes

    my $Process = $TicketProcessesObject->ProcessLookup(
        ProcessID => 1,
    );

    my $ProcessID = $TicketProcessesObject->ProcessLookup(
        Process => 'Process Name',
    );

=cut

sub ProcessLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Process} && !$Param{ProcessID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Process or ProcessID!',
        );
        return;
    }

    # get Equipment list
    my %ProcessesList = $Self->ProcessesList(
        Valid => 0,
    );

    return $ProcessesList{ $Param{ProcessID} } if $Param{ProcessID};

    # create reverse list
    my %ProcessesListReverse = reverse %ProcessesList;

    return $ProcessesListReverse{ $Param{Process} };
}

=head2 ProcessAdd()

to add a Process

    my $ID = $TicketProcessesObject->ProcessAdd(
        Name         => 'Name',
        Description  => 'Description',
        QueueID      => 123,
        SetArticleID => 2,
        ValidID      => 1,
        UserID       => 123,
        TicketID     => 123,
    );

=cut

sub ProcessAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name Description QueueID TicketID ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( !$Param{SetArticleID} ) {
        $Param{SetArticleID} = 2;
    }

    # insert new Equipment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO t_process_list (name, description, queue_id, valid_id, '
            . ' create_time, create_by, change_time, change_by, ticket_id, setarticle_id)'
            . ' VALUES (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?, ?)',
        Bind => [
            \$Param{Name}, \$Param{Description}, \$Param{QueueID}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID}, \$Param{TicketID}, \$Param{SetArticleID},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM t_process_list WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    my $ProcessID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessID = $Row[0];
    }

    return $ProcessID;
}

=head2 ProcessGet()

returns a hash with Equipment data

    my %ProcessData = $TicketProcessesObject->ProcessGet(
        ID => 2,
    );

This returns something like:

    %ProcessData = (
        'ID'         => 2,
        'Name'       => 'Name',
        'ValidID'    => '1',
        'CreateTime' => '2010-04-07 15:41:15',
        'ChangeTime' => '2010-04-07 15:41:15',
    );

=cut

sub ProcessGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # get Equipment list
    my %ProcessList = $Self->ProcessDataList(
        Valid => 0,
    );

    # extract Equipment data
    my %ProcessData;
    if ( $ProcessList{ $Param{ID} } && ref $ProcessList{ $Param{ID} } eq 'HASH' ) {
        %ProcessData = %{ $ProcessList{ $Param{ID} } };
    }

    return %ProcessData;
}

=head2 ProcessesList()

returns a hash of all Equipments

    my %Processes = $TicketProcessesObject->ProcessesList(
        Valid    => 1,   # (optional) default 0
    );

the result looks like

    %Processes = (
        '1' => 'users',
        '2' => 'admin',
        '3' => 'stats',
        '4' => 'secret',
    );

=cut

sub ProcessesList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} ? 1 : 0;

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # get Equipment data list
    my %ProcessDataList = $Self->ProcessDataList();

    my %ProcessListValid;
    my %ProcessListAll;
    KEY:
    for my $Key ( sort keys %ProcessDataList ) {

        next KEY if !$Key;

        # add process to the list of all processes
        $ProcessListAll{$Key} = $ProcessDataList{$Key}->{Name};

        my $Match;
        VALIDID:
        for my $ValidID (@ValidIDs) {

            next VALIDID if $ValidID ne $ProcessDataList{$Key}->{ValidID};

            $Match = 1;

            last VALIDID;
        }

        next KEY if !$Match;

        # add Equipment to the list of valid Equipments
        $ProcessListValid{$Key} = $ProcessDataList{$Key}->{Name};
    }

    return %ProcessListValid if $Valid;
    return %ProcessListAll;
}

=head2 ProcessDataList()

returns a hash of all Equipment data

    my %ProcessDataList = $TicketProcessesObject->ProcessDataList();

the result looks like

    %ProcessDataList = (
        1 => {
            ID          => 1,
            Name        => 'Name',
            Description => 'Description',
            ValidID     => 1,
            CreateTime  => '2014-01-01 00:20:00',
            CreateBy    => 1,
            ChangeTime  => '2014-01-02 00:10:00',
            ChangeBy    => 1,
            TicketID    => 123,
        },
        2 => {
            ID          => 2,
            Name        => 'Name',
            Description => 'Description',
            ValidID     => 1,
            CreateTime  => '2014-11-01 10:00:00',
            CreateBy    => 1,
            ChangeTime  => '2014-11-02 01:00:00',
            ChangeBy    => 1,
            TicketID    => 123,
        },
    );

=cut

sub ProcessDataList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, description, queue_id, valid_id, create_time, create_by, change_time, change_by, ticket_id, ready, setarticle_id FROM t_process_list',
    );

    # fetch the result
    my %ProcessDataList;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        $ProcessDataList{ $Row[0] } = {
            ID           => $Row[0],
            Name         => $Row[1],
            Description  => $Row[2],
            QueueID      => $Row[3],
            ValidID      => $Row[4],
            CreateTime   => $Row[5],
            CreateBy     => $Row[6],
            ChangeTime   => $Row[7],
            ChangeBy     => $Row[8],
            TicketID     => $Row[9],
            Ready        => $Row[10],
            SetArticleID => $Row[11],
        };
    }

    return %ProcessDataList;
}

=head2 ProcessEnd()

to end a Process

    my $Success = $TicketProcessesObject->ProcessEnd(
        ProcessID => 123,
        TicketID  => 123,
    );

=cut

sub ProcessEnd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID ProcessID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{Ready} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE t_process_list SET ready = ? WHERE ticket_id = ? AND id = ?',
        Bind => [
            \$Param{Ready}, \$Param{TicketID}, \$Param{ProcessID},
        ],
    );

    return 1;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
