# --
# Kernel/System/TicketProcessStep.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: TicketProcessStep.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketProcessStep;

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

Kernel::System::TicketProcessStep - TicketProcess step lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add TicketProcess step.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketProcessStepObject = $Kernel::OM->Get('Kernel::System::TicketProcessStep');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessStepLookup()

get id or name for Processes

    my $ProcessStep = $ProcessStepObject->ProcessLookup(
        ProcessStepID => 1,
    );

    my $ProcessStepID = $ProcessStepObject->ProcessLookup(
        ProcessStep => 'Process Step Name',
    );

=cut

sub ProcessStepLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ProcessStep} && !$Param{ProcessStepID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStep or ProcessStepID!',
        );
        return;
    }

    # get Equipment list
    my %ProcessStepList = $Self->ProcessStepList(
        Valid => 0,
    );

    return $ProcessStepList{ $Param{ProcessStepID} } if $Param{ProcessStepID};

    # create reverse list
    my %ProcessStepListReverse = reverse %ProcessStepList;

    return $ProcessStepListReverse{ $Param{ProcessStep} };
}

=head2 ProcessStepAdd()

to add a ProcessStep

    my $ProcessStepID = $TicketProcessStepObject->ProcessStepAdd(
        Name                => 'Name',
        ProcessID           => 1,
        ProcessStep         => 1,
        StepNo              => 1,
        StepNoFrom          => 1,
        StepNoTo            => 1,
        Color               => 123124,
        Description         => 'Description',
        GroupID             => 1,
        StepArtID           => 1,
        ApproverGroupID     => 1,
        ApproverEmail       => 'approver@email.com',
        NotifyAgent         => 'yes',
        ValidID             => 1,
        StepEnd             => 1,
        NotApproved         => 1,
        ToIDFromOne         => 1,
        WithoutConditionEnd => 1,
        WithConditions      => 1,
        ToIDFromTwo         => 1,
        WithConditionsEnd   => 1,
        TicketID            => 123,
        SetArticleID        => 2,
        UserID              => 123,
    );
=cut

sub ProcessStepAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name ProcessID StepNo TicketID ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !$Param{StepNoFrom} ) {
        $Param{StepNoFrom} = 0;
    }
    if ( !$Param{StepNoTo} ) {
        $Param{StepNoTo} = 0;
    }
    if ( !$Param{ApproverGroupID} ) {
        $Param{ApproverGroupID} = 0;
    }
    if ( !$Param{StepEnd} ) {
        $Param{StepEnd} = 0;
    }
    if ( !$Param{StepActive} ) {
        $Param{StepActive} = 0;
    }
    if ( !$Param{Ready} ) {
        $Param{Ready} = 0;
    }
    if ( !$Param{SetArticleID} ) {
        $Param{SetArticleID} = 2;
    }
#    if ( $Param{ParallelStep} ) {
#        $Param{StepActive} = 1;
#    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new process step
    return if !$DBObject->Do(
        SQL => 'INSERT INTO t_process_step (name, process_id, process_step, step_no, step_no_from, step_no_to, process_color, '
            . ' description, group_id, stepart_id, approver_id, approver_email, valid_id, '
            . ' create_time, create_by, change_time, change_by, step_end, not_approved, to_id_from_one, '
            . ' without_conditions_end, with_conditions, to_id_from_two, with_conditions_end, ticket_id, ready, step_active, setarticle_id, parallel_step, set_parallel, notify_agent)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        Bind => [
            \$Param{Name}, \$Param{ProcessID}, \$Param{ProcessStep}, \$Param{StepNo}, \$Param{StepNoFrom}, \$Param{StepNoTo}, \$Param{Color},
            \$Param{Description}, \$Param{GroupID}, \$Param{StepArtID}, \$Param{ApproverGroupID}, \$Param{ApproverEmail},
            \$Param{ValidID}, \$Param{UserID}, \$Param{UserID}, \$Param{StepEnd}, \$Param{NotApproved}, \$Param{ToIDFromOne}, \$Param{WithoutConditionEnd},
            \$Param{WithConditions}, \$Param{ToIDFromTwo}, \$Param{WithConditionsEnd}, \$Param{TicketID}, \$Param{Ready}, \$Param{StepActive}, \$Param{SetArticleID}, \$Param{ParallelStep}, \$Param{SetParallel}, \$Param{NotifyAgent},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT MAX(id) FROM t_process_step;',
    );

    my $ProcessStepID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;
}

=head2 ProcessStepGet()

returns a hash with data

    my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
        ID => 2,
    );

This returns something like:

    %ProcessStepData = (
        'ID'         => 2,
        'Name'       => 'Name',
        'ValidID'    => '1',
        'CreateTime' => '2010-04-07 15:41:15',
        'ChangeTime' => '2010-04-07 15:41:15',
    );

=cut

sub ProcessStepGet {
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
    my %ProcessStepList = $Self->ProcessStepDataList(
        Valid => 0,
    );

    # extract Equipment data
    my %ProcessStepData;
    if ( $ProcessStepList{ $Param{ID} } && ref $ProcessStepList{ $Param{ID} } eq 'HASH' ) {
        %ProcessStepData = %{ $ProcessStepList{ $Param{ID} } };
    }

    return %ProcessStepData;
}

=head2 ProcessStepList()

returns a hash of all Step

    my %ProcessStep = $ProcessStepObject->ProcessStepList(
        Valid    => 1,   # (optional) default 0
    );

the result looks like

    %ProcessStep = (
        '1' => 'users',
        '2' => 'admin',
        '3' => 'stats',
        '4' => 'secret',
    );

=cut

sub ProcessStepList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} ? 1 : 0;

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # get Equipment data list
    my %ProcessStepDataList = $Self->ProcessStepDataList();

    my %ProcessStepListValid;
    my %ProcessStepListAll;
    KEY:
    for my $Key ( sort keys %ProcessStepDataList ) {

        next KEY if !$Key;

        # add process to the list of all processes
        $ProcessStepListAll{$Key} = $ProcessStepDataList{$Key}->{Name};

        my $Match;
        VALIDID:
        for my $ValidID (@ValidIDs) {

            next VALIDID if $ValidID ne $ProcessStepDataList{$Key}->{ValidID};

            $Match = 1;

            last VALIDID;
        }

        next KEY if !$Match;

        # add Equipment to the list of valid Equipments
        $ProcessStepListValid{$Key} = $ProcessStepDataList{$Key}->{Name};
    }

    return %ProcessStepListValid if $Valid;
    return %ProcessStepListAll;
}

=head2 ProcessStepDataList()

returns a hash of all Equipment data

    my %ProcessStepDataList = $ProcessStepObject->ProcessStepDataList();

the result looks like

    %ProcessStepDataList = (
        1 => {
            ID          => 1,
            Name        => 'Name',
            ValidID     => 1,
            CreateTime  => '2014-01-01 00:20:00',
            CreateBy    => 1,
            ChangeTime  => '2014-01-02 00:10:00',
            ChangeBy    => 1,
        },
        2 => {
            ID          => 2,
            Name        => 'Name',
            ValidID     => 1,
            CreateTime  => '2014-11-01 10:00:00',
            CreateBy    => 1,
            ChangeTime  => '2014-11-02 01:00:00',
            ChangeBy    => 1,
        },
    );

=cut

sub ProcessStepDataList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, process_id, process_step, step_no, step_no_from, to_id_from_one, to_id_from_two, step_no_to, '
        . 'process_color, description, group_id, stepart_id, step_end, with_conditions_end, without_conditions_end, not_approved, approver_id, '
        . 'approver_email, valid_id, create_time, create_by, change_time, change_by, with_conditions, ticket_id, ready, step_active, setarticle_id, parallel_step, set_parallel, notify_agent FROM t_process_step',
    );

    # fetch the result
    my %ProcessStepDataList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepDataList{ $Row[0] } = {
            ProcessStepID       => $Row[0],
            Name                => $Row[1],
            ProcessID           => $Row[2],
            ProcessStep         => $Row[3],
            StepNo              => $Row[4],
            StepNoFrom          => $Row[5],
            ToIDFromOne         => $Row[6],
            ToIDFromTwo         => $Row[7],
            StepNoTo            => $Row[8],
            Color               => $Row[9],
            Description         => $Row[10],
            GroupID             => $Row[11],
            StepArtID           => $Row[12],
            StepEnd             => $Row[13],
            WithConditionsEnd   => $Row[14],
            WithoutConditionEnd => $Row[15],
            NotApproved         => $Row[16],
            ApproverGroupID     => $Row[17],
            ApproverEmail       => $Row[18],
            ValidID             => $Row[19],
            CreateTime          => $Row[20],
            CreateBy            => $Row[21],
            ChangeTime          => $Row[22],
            ChangeBy            => $Row[23],
            WithConditions      => $Row[24],
            TicketID            => $Row[25],
            Ready               => $Row[26],
            StepActive          => $Row[27],
            SetArticleID        => $Row[28],
            ParallelStep        => $Row[29],
            SetParallel         => $Row[30],
            NotifyAgent         => $Row[31],
        };
    }

    return %ProcessStepDataList;
}

=head2 SearchNextProcessStep()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SearchNextProcessStep(
        ProcessStep => 123,
        ProcessID   => 123,
    );

=cut

sub SearchNextProcessStep {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ProcessStep} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStep!',
        );
        return;
    }

    # check needed stuff
    if ( !$Param{ProcessID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id FROM t_process_step WHERE process_id = ? AND process_step > ? AND id_from_not_approved < 1',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStep},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;

}

=head2 SearchNextProcessStepApproval()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SearchNextProcessStepApproval(
        ProcessID   => 123,
        ProcessStep => 123,
        StepNo      => 1,
    );

=cut

sub SearchNextProcessStepApproval {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ProcessStep} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStep!',
        );
        return;
    }

    # check needed stuff
    if ( !$Param{ProcessID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id FROM t_process_step WHERE process_id = ? AND process_step = ? AND step_no = ?',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStep}, \$Param{StepNo},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;

}

=head2 SearchNextStepNoFrom()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SearchNextStepNoFrom(
        ProcessID  => 123,
        StepNoFrom => 123,
        StepNo     => 1,
    );

=cut

sub SearchNextStepNoFrom {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{StepNoFrom} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStep!',
        );
        return;
    }

    $Param{StepNo} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id FROM t_process_step WHERE step_no_from = ? AND process_id = ? AND step_no = ?',
        Bind => [
            \$Param{StepNoFrom}, \$Param{ProcessID}, \$Param{StepNo},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;

}

=head2 SearchNextProcessStepWithConditions()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SearchNextProcessStepWithConditions(
        ProcessID  => 123,
        StepNoFrom => 123,
    );

=cut

sub SearchNextProcessStepWithConditions {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{StepNoFrom} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStep!',
        );
        return;
    }

    $Param{WithConditions} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id FROM t_process_step WHERE step_no_from = ? AND process_id = ? AND with_conditions = ?',
        Bind => [
            \$Param{StepNoFrom}, \$Param{ProcessID}, \$Param{WithConditions},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;
}


=head2 SearchNextProcessStepTo()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SearchNextProcessStepTo(
        ProcessStep => 123,
        ProcessID   => 123,
    );

=cut

sub SearchNextProcessStepTo {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ProcessStep} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStep!',
        );
        return;
    }

    # check needed stuff
    if ( !$Param{ProcessID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id FROM t_process_step WHERE process_id = ? AND process_step = ? AND step_no_to >= 1',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStep},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;

}

=item ProcessStepTicketList()

return a hash list of processes

    my %ProcessStepTicketList = $TicketProcessStepObject->ProcessStepTicketList(
        TicketID => 123,
    );

=cut

sub ProcessStepTicketList {
    my ( $Self, %Param ) = @_;


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, name FROM t_process_step WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID}, ],
    );

    # fetch the result
    my %ProcessStepTicketList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepTicketList{ $Row[0] } = $Row[1];
    }

    return %ProcessStepTicketList;
}

=item ProcessStepListTo()

return a hash list of processes

    my %ProcessStepListTo = $ProcessStepObject->ProcessStepListTo(
        ProcessID   => 123,
        ProcessStep => 123,
    );

=cut

sub ProcessStepListTo {
    my ( $Self, %Param ) = @_;


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, name FROM t_process_step WHERE process_id = ?',
        Bind => [ \$Param{ProcessID}, ],
    );

    # fetch the result
    my %ProcessStepListTo;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepListTo{ $Row[0] } = $Row[1];
    }

    return %ProcessStepListTo;
}

=item ProcessStepListValue()

return a hash list of processes

    my %ProcessStepList = $ProcessStepObject->ProcessStepListValue(
        ProcessID => 123,
        Value     => 123,
    );

=cut

sub ProcessStepListValue {
    my ( $Self, %Param ) = @_;


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, step_no FROM t_process_step WHERE process_id = ? AND process_step = ?',
        Bind => [ \$Param{ProcessID}, \$Param{Value}, ],
    );

    # fetch the result
    my %ProcessStepList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepList{ $Row[0] } = $Row[1];
    }

    return %ProcessStepList;
}

=item ProcessStepValue()

return a array of processes

    my @ProcessStepValue = $ProcessStepObject->ProcessStepValue(
        ProcessID => 123,
    );

=cut

sub ProcessStepValue {
    my ( $Self, %Param ) = @_;


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT process_step FROM t_process_step WHERE process_id = ?',
        Bind => [ \$Param{ProcessID}, ],
    );

    # fetch the result
    my @ProcessStepValue;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ProcessStepValue, $Row[0];
    }

    return @ProcessStepValue;
}

=head2 SearchToIDFromOne()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SearchToIDFromOne(
        ProcessStepID => 123,
        StepNo        => 1,
        TicketID      => 123,
    );

=cut

sub SearchToIDFromOne {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ProcessStepID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStepID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id FROM t_process_step WHERE step_no_from = ? AND step_no = ? AND ticket_id = ?',
        Bind => [
            \$Param{ProcessStepID}, \$Param{StepNo}, \$Param{TicketID},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;

}

=head2 SearchToIDFromTwo()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SearchToIDFromTwo(
        ProcessStepID => 123,
        StepNo        => 2,
        TicketID      => 123,
    );

=cut

sub SearchToIDFromTwo {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ProcessStepID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStepID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id FROM t_process_step WHERE step_no_from = ? AND step_no = ? AND ticket_id = ?',
        Bind => [
            \$Param{ProcessStepID}, \$Param{StepNo}, \$Param{TicketID},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;

}

=head2 ProcessStepReadyUpdate()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepReadyUpdate(
        ProcessStepID => 123,
        StepActive    => 1,
        TicketID      => 123,
    );

=cut

sub ProcessStepReadyUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID StepActive)) {
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

    my $ProcessStepID = 0;

    if ( $Param{TicketID} ) {

        # get all Equipment data from database
        return if !$DBObject->Prepare(
            SQL => 'SELECT id FROM t_process_step WHERE ticket_id = ? AND id < ? AND ready < 1',
            Bind => [
                \$Param{TicketID}, \$Param{ProcessStepID},
            ],
        );

        # fetch the result
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $ProcessStepID = $Row[0];
        }
    }

    if ( $ProcessStepID <= 0 ) {

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE t_process_step SET step_active = ? WHERE id = ?',
        Bind => [
            \$Param{StepActive}, \$Param{ProcessStepID},
        ],
    );
    }

    return 1;
}

=head2 ProcessStepReadyEnd()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepReadyEnd(
        ProcessStepID => 123,
        Ready         => 1,
    );

=cut

sub ProcessStepReadyEnd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID Ready)) {
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

    # update process step in database
    return if !$DBObject->Do(
        SQL  => 'UPDATE t_process_step SET ready = ? WHERE id = ?',
        Bind => [
            \$Param{Ready}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessStepReadyUpdateParallel()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepReadyUpdateParallel(
        ProcessStepID     => 123,
        ProcessStepIDNext => 123,
        StepActive        => 1,
    );

=cut

sub ProcessStepReadyUpdateParallel {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID ProcessStepIDNext StepActive)) {
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

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE t_process_step SET step_active = ? WHERE id >= ? AND id < ?',
        Bind => [
            \$Param{StepActive}, \$Param{ProcessStepID}, \$Param{ProcessStepIDNext},
        ],
    );

    return 1;
}

=head2 ApprovStep()

update of a Process Step

    my $Success = $ProcessStepObject->ApprovStep(
        ProcessID     => 123,
        ProcessStepID => 123,
        TicketID      => 123,
        Art           => 'genehmigt,
    );

=cut

sub ApprovStep {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID TicketID Art Report)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %ProcessStepData = $Self->ProcessStepGet(
        ID => $Param{ProcessStepID},
    );

    if ( $Param{Art} eq 'genehmigt' ) {
        $Param{StepApproval} = 1;
    }
    else {
        $Param{StepApproval} = 2;
    }

    if ( !$Param{Report} || $Param{Report} eq '' ) {
        $Param{Report} = 'Es wurde keine Bemerkungen eingegeben.';
    }

    my $TicketProcessStepValueObject = $Kernel::OM->Get('Kernel::System::TicketProcessStepValue');
    my $TicketProcessTransitionObject = $Kernel::OM->Get('Kernel::System::TicketProcessTransition');

    my $Sucess = $TicketProcessStepValueObject->ProcessFieldValueAdd(
        ProcessID     => $Param{ProcessID},
        ProcessStepID => $Param{ProcessStepID},
        TicketID      => $Param{TicketID},
        Report        => 'Genehmigung per Email - ' . $Param{Art} . '<br><br>' . $Param{Report},
        Approval      => $Param{StepApproval},
        UserID        => 1,
    );

    my $TicketProcessesObject = $Kernel::OM->Get('Kernel::System::TicketProcesses');

    my %ProcessDataCheck = $TicketProcessesObject->ProcessGet(
        ID => $Param{ProcessID},
    ); 

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my %CheckTicket = $TicketObject->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 0,
        UserID        => 1,
        Silent        => 1,
    );

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my @Articles      = $ArticleObject->ArticleList(
        TicketID  => $Param{TicketID},
        OnlyFirst => 1,
    );
    my $SetArticleID = 0;
    for my $ArticleIDHash (@Articles) {
        for my $ArticleID ( keys %{$ArticleIDHash} ) {
            if ( $ArticleID eq "ArticleID" ) {
                $SetArticleID = ${$ArticleIDHash}{$ArticleID};
            }
        }
    }
    my $ArticleBackendObject
        = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle(
        TicketID  => $Param{TicketID},
        ArticleID => $SetArticleID,
        );
    my %ArticleCheck = $ArticleBackendObject->ArticleGet(
        TicketID  => $Param{TicketID},
        ArticleID => $SetArticleID,
    );
    $ArticleCheck{Body} =~ s/\n/<br>/g;
    $ArticleCheck{Body} =~ s/\r/<br>/g;
    my $ArticleBody = $ArticleCheck{Body};

    if ( $ProcessDataCheck{SetArticleID} && $ProcessDataCheck{SetArticleID} == 1 ) {

        my %ProcessStepDataCheck = $Self->ProcessStepGet(
            ID => $Param{ProcessStepID},
        );  

        my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );
        my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');

        my $FromEmailArt = $ConfigObject->Get('NotificationSenderEmail');
        my $FromArt = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmailArt . '>';

        my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
        my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
            User => $CheckTicket{CustomerUserID},
        );
        my $To = $CustomerUser{UserEmail};

        my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessStepDataCheck{Name} . ' - Genehmigung';

        my $NotificationBodyPre = 'Prozess: ' . $ProcessDataCheck{Name};
        $NotificationBodyPre .= '<br>';
        $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepDataCheck{Name};
        $NotificationBodyPre .= '<br><br>';
        $NotificationBodyPre .= $ArticleBody;
        $NotificationBodyPre .= '<br><br>';

        my $HttpType         = $ConfigObject->Get('HttpType');
        my $FQDN             = $ConfigObject->Get('FQDN');
        my $ScriptAlias      = $ConfigObject->Get('ScriptAlias');
        my $NotificationBody = '';

        if ( $Param{StepApproval} && $Param{StepApproval} == 1 ) {

            $NotificationBody = "<!DOCTYPE html>
            <html lang=\"de-DE\">
            <head>
            <meta charset=\"utf-8\">
            </head>
            <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
    
            <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
            Ihr Antrag wurde genehmigt.\n<br><br>
    
            $Param{Report}\n<br><br>
    
            </div>
    
            <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
            Es wurde folgende Anfrage gestellt:\n\n<br><br>
    
            $NotificationBodyPre
            ";
    
            $NotificationBody .= "
            </div>
    
            </body>
            </html>
            ";
        }
        else {

            $NotificationBody = "<!DOCTYPE html>
            <html lang=\"de-DE\">
            <head>
            <meta charset=\"utf-8\">
            </head>
            <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
    
            <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
            Ihr Antrag wurde abgelehnt.\n<br><br>
    
            $Param{Report}\n<br><br>
    
            </div>
    
            <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
            Es wurde folgende Anfrage gestellt:\n\n<br><br>
    
            $NotificationBodyPre
            ";
    
            $NotificationBody .= "
            </div>
    
            </body>
            </html>
            ";
        }

        my $ArticleID = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Email')->ArticleSend(
            TicketID         => $Param{TicketID},
            SenderType           => 'system',
            From             => $FromArt,
            To                   => $To,
            Subject              => $NotificationSubject,
            Body                 => $NotificationBody,
            MimeType         => 'text/html',
            Charset          => 'utf8',
            UserID           => 1,
            HistoryType      => 'AddNote',
            HistoryComment       => 'New process step' || '%%',
            UnlockOnAway         => 0,
            IsVisibleForCustomer => 1,
            %Param,
        );
    }

    if ( $Param{StepApproval} && $Param{StepApproval} == 1 ) {

        my %CheckProcessStepData = $Self->ProcessStepGet(
            ID => $Param{ProcessStepID},
        );  

        my $ProcessStepID = '';
        my $ProcessEnd    = 0;
        if ( $CheckProcessStepData{WithoutConditionEnd} && $CheckProcessStepData{WithoutConditionEnd} == 1 ) {

            my $TicketProcessesObject = $Kernel::OM->Get('Kernel::System::TicketProcesses');
            my $SuccessEnd = $TicketProcessesObject->ProcessEnd(
                ProcessID => $Param{ProcessID},
                TicketID  => $Param{TicketID},
            );

            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
            my $StateID = $StateObject->StateLookup(
                State => 'closed successful',
            );

            my $StateSuccess = $TicketObject->TicketStateSet(
                StateID      => $StateID,
                TicketID     => $Param{TicketID},
                NoPermission => 1,
                UserID       => 1,
            );

            $TicketObject->TicketLockSet(
                TicketID => $Param{TicketID},
                Lock     => 'unlock',
                UserID   => 1,
            );

            $ProcessStepID = $Param{ProcessStepID};

            my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                ProcessStepID => $Param{ProcessStepID},
                TicketID      => $Param{TicketID},
            );

            if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
    
                my $TypeSuccess = $TicketObject->TicketTypeSet(
                    TypeID   => $TicketTransition{TypeID},
                    TicketID => $Param{TicketID},
                    UserID   => 1,
                );
            }

            if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {

                my $QueueSuccess = $TicketObject->TicketQueueSet(
                    QueueID  => $TicketTransition{QueueID},
                    TicketID => $Param{TicketID},
                    UserID   => 1,
                );
            }
        }
        else {

            $ProcessStepID = $Self->SearchToIDFromOne(
                ProcessStepID => $Param{ProcessStepID},
                StepNo        => 1,
                TicketID      => $Param{TicketID},
            );
    
            if ( !$ProcessStepID || $ProcessStepID == 0 ) {

                $ProcessStepID = $Self->SearchToIDFromOneNext(
                    ProcessStepID => $Param{ProcessStepID},
                    TicketID      => $Param{TicketID},
                );
            }

            my $ProcessStepIDNext = $TicketProcessTransitionObject->SearchNextParallel(
                ProcessStepID => $ProcessStepID,
                TicketID      => $Param{TicketID},
            );
            my $ProcessStepIDCheck = $Self->SearchNextProcessStepParallel(
                ProcessStepID => $ProcessStepIDNext,
                TicketID      => $Param{TicketID},
            );

            for my $SetNextStep ( $ProcessStepID .. $ProcessStepIDCheck ) {

            my $Success = $Self->ProcessStepReadyUpdate(
                    ProcessStepID => $SetNextStep,
                StepActive    => 1,
            );

            my %ProcessStepData = $Self->ProcessStepGet(
                    ID => $SetNextStep,
            );   

            my $TicketProcessesObject = $Kernel::OM->Get('Kernel::System::TicketProcesses');
            my %ProcessDataTransver = $TicketProcessesObject->ProcessGet(
                ID => $Param{ProcessID},
            ); 

            if ( $ProcessStepData{StepArtID} == 2) {

                # get needed objects
                my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
                my $TicketObject        = $Kernel::OM->Get('Kernel::System::Ticket');

                my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';

                my $To = $ProcessStepData{ApproverEmail};

                if ( $ProcessStepData{ApproverGroupID} && $ProcessStepData{ApproverGroupID} == 1 )  {

                    my %Ticket = $TicketObject->TicketGet(
                        TicketID      => $Param{TicketID},
                        DynamicFields => 0,
                        UserID        => 1,
                        Silent        => 1,
                    );

                    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

                    my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                        User => $Ticket{CustomerUserID},
                    );

                    if ( $To ) {
                        $To .= ',' . $CustomerUser{UserEmail};
                    }
                    else {
                        $To .= $CustomerUser{UserEmail};
                    }
                }

                if ( !$ProcessStepData{NotifyAgent} ) {
                    $ProcessStepData{NotifyAgent} = 'yes';
                }

                if ( $ProcessStepData{NotifyAgent} eq "yes" )  {
                if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {

                    my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                        GroupID => $ProcessStepData{GroupID},
                        Type    => 'ro',
                    );

                    for my $UserLogin ( keys %ApproverUsers ) {
                       
                        if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {

                            my %ApproverUser = $UserObject->GetUserData(
                                UserID => $UserLogin,
                            );

                            if ( $To ) {
                                $To .= ',' . $ApproverUser{UserEmail};
                            }
                            else {
                                $To .= $ApproverUser{UserEmail};
                            }
                        }
                    }
                }
                }

                my %CheckTicket = $TicketObject->TicketGet(
                    TicketID      => $Param{TicketID},
                    DynamicFields => 0,
                    UserID        => 1,
                    Silent        => 1,
                );

                my $SetFullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                    UserLogin => $CheckTicket{CustomerUserID},
                );

                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - approval required';

                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Genehmigung erforderlich.<br>Bitte klicken Sie auf eine Entscheidung.';
                $NotificationBodyPre .= '<br><br>';

                $NotificationBodyPre .= 'Antragsteller: ' . $SetFullName;
                $NotificationBodyPre .= '<br><br>';

                $NotificationBodyPre .= $ArticleBody;
                $NotificationBodyPre .= '<br><br>';

                my $HttpType    = $ConfigObject->Get('HttpType');
                my $FQDN        = $ConfigObject->Get('FQDN');
                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

                my $NotificationBody = "<!DOCTYPE html>
                <html lang=\"de-DE\">
                <head>
                <meta charset=\"utf-8\">
                </head>
                <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
    
                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
                Es wurde eine Anfrage eingereicht welche genehmigungspflichtig ist.\n<br>
                Zum Genehmigen oder Ablehnen bitte einen der nachstehenden links klicken.\n<br><br>

                </div>

                <div style=\"color:blue;width:100%;font-size:16px;font-family:Helvetica, Arial, sans-serif;font-weight:bold;\">

                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                    . "ProcessApproval.pl?ProcessID=$Param{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$Param{TicketID};Art=genehmigt\">Genehmigen</a>
                \n<br>\n<br>oder\n<br>\n<br>
                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                    . "ProcessApproval.pl?ProcessID=$Param{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$Param{TicketID};Art=abgelehnt\">Ablehnen</a>
                \n\n<br><br>
    
                </div>

                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">

                Es wurde folgende Anfrage gestellt:\n\n<br><br>
    
                $NotificationBodyPre
                ";

                if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {

                    $NotificationBody .= "
                    <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                        . "index.pl?Action=AgentTicketZoom;TicketID=$Param{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                        . "index.pl?Action=AgentTicketZoom;TicketID=$Param{TicketID}</a>
                    \n\n<br><br>
                    ";

                }

                $NotificationBody .= "
                </div>

                </body>
                </html>
                ";

                if ( $To ne '' ) {

                my $Sent = $EmailObject->Send(
                    From          => $From,
                    To            => $To,
                    Subject       => $NotificationSubject,
                    MimeType      => 'text/html',
                    Charset       => 'utf-8',
                    Body          => $NotificationBody,
                );

                    my $Success = $TicketObject->HistoryAdd(
                        Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                        HistoryType  => 'SendAgentNotification',
                        TicketID     => $Param{TicketID},
                        CreateUserID => 1,
                    );

                }
            }
            else {

                # get needed objects
                my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
                my $TicketObject        = $Kernel::OM->Get('Kernel::System::Ticket');

                my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';

                my $To = '';

                my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                    GroupID => $ProcessStepData{GroupID},
                    Type    => 'ro',
                );

                if ( !$ProcessStepData{NotifyAgent} ) {
                    $ProcessStepData{NotifyAgent} = 'yes';
                }

                if ( $ProcessStepData{NotifyAgent} eq "yes" )  {
                my $GroupUserValue = 0;
                for my $UserLogin ( keys %ApproverUsers ) {
                   
                    if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {

                       $GroupUserValue ++;

                        my %ApproverUser = $UserObject->GetUserData(
                            UserID => $UserLogin,
                        );

                        if ( $GroupUserValue == 1 ) {
                            $To .= $ApproverUser{UserEmail};
                        }
                        else {
                                $To .= ',' . $ApproverUser{UserEmail};
                        }
                    }
                }
                }

                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - ' . $ProcessStepData{Name};

                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Aktion erforderlich.';
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= $ArticleBody;
                $NotificationBodyPre .= '<br><br>';

                my $HttpType    = $ConfigObject->Get('HttpType');
                my $FQDN        = $ConfigObject->Get('FQDN');
                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

                my $NotificationBody = "<!DOCTYPE html>
                <html lang=\"de-DE\">
                <head>
                <meta charset=\"utf-8\">
                </head>
                <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
    
                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
                Es wurde eine Anfrage eingereicht welche bearbeitet werden muss.\n<br>

                Es wurde folgende Anfrage gestellt:\n\n<br><br>
    
                $NotificationBodyPre
    
                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                    . "index.pl?Action=AgentTicketZoom;TicketID=$Param{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                    . "index.pl?Action=AgentTicketZoom;TicketID=$Param{TicketID}</a>
                \n\n<br><br>

                </div>

                </body>
                </html>
                ";

                if ( $To ne '' ) {

                my $Sent = $EmailObject->Send(
                    From          => $From,
                    To            => $To,
                    Subject       => $NotificationSubject,
                    MimeType      => 'text/html',
                    Charset       => 'utf-8',
                    Body          => $NotificationBody,
                );

                    my $Success = $TicketObject->HistoryAdd(
                        Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                        HistoryType  => 'SendAgentNotification',
                        TicketID     => $Param{TicketID},
                        CreateUserID => 1,
                    );

                    }
                }
            }
        }

        my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
            ProcessStepID => $ProcessStepID,
            TicketID      => $Param{TicketID},
        );

        if ( $TicketTransition{StateID} && $TicketTransition{StateID} >= 1 ) {

            my $StateSuccess = $TicketObject->TicketStateSet(
                StateID      => $TicketTransition{StateID},
                TicketID     => $Param{TicketID},
                NoPermission => 1,
                UserID       => 1,
            );
        }

        if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {

            my $TypeSuccess = $TicketObject->TicketTypeSet(
                TypeID   => $TicketTransition{TypeID},
                TicketID => $Param{TicketID},
                UserID   => 1,
            );
        }

        if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {

            my $QueueSuccess = $TicketObject->TicketQueueSet(
                QueueID  => $TicketTransition{QueueID},
                TicketID => $Param{TicketID},
                UserID   => 1,
            );
        }

    }

    if ( $Param{StepApproval} && $Param{StepApproval} == 2 ) {

        my %CheckProcessStepData = $Self->ProcessStepGet(
            ID => $Param{ProcessStepID},
        );  

        my $ProcessStepID = '';
        my $ProcessEnd    = 0;
        if ( $CheckProcessStepData{WithConditionsEnd} && $CheckProcessStepData{WithConditionsEnd} == 1 ) {

            my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

            my $TicketProcessesObject = $Kernel::OM->Get('Kernel::System::TicketProcesses');
            my $SuccessEnd = $TicketProcessesObject->ProcessEnd(
                ProcessID => $Param{ProcessID},
                TicketID  => $Param{TicketID},
            );

            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
            my $StateID = $StateObject->StateLookup(
                State => 'closed successful',
            );

            my $StateSuccess = $TicketObject->TicketStateSet(
                StateID      => $StateID,
                TicketID     => $Param{TicketID},
                NoPermission => 1,
                UserID       => 1,
            );

            $TicketObject->TicketLockSet(
                TicketID => $Param{TicketID},
                Lock     => 'unlock',
                UserID   => 1,
            );

            $ProcessStepID = $Param{ProcessStepID};

            my $TicketProcessTransitionObject = $Kernel::OM->Get('Kernel::System::TicketProcessTransition');
            my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                ProcessStepID => $Param{ProcessStepID},
                TicketID      => $Param{TicketID},
            );

            if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
    
                my $TypeSuccess = $TicketObject->TicketTypeSet(
                    TypeID   => $TicketTransition{TypeID},
                    TicketID => $Param{TicketID},
                    UserID   => 1,
                );
            }

            if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {

                my $QueueSuccess = $TicketObject->TicketQueueSet(
                    QueueID  => $TicketTransition{QueueID},
                    TicketID => $Param{TicketID},
                    UserID   => 1,
                );
            }
        }
        else {

            $ProcessStepID = $Self->SearchToIDFromTwo(
                ProcessStepID => $Param{ProcessStepID},
                StepNo        => 2,
                TicketID      => $Param{TicketID},
            );
    
            my $Success = $Self->ProcessStepReadyUpdate(
                ProcessStepID => $ProcessStepID,
                StepActive    => 1,
            );

            my %ProcessStepData = $Self->ProcessStepGet(
                ID => $ProcessStepID,
            );    

            my $TicketProcessesObject = $Kernel::OM->Get('Kernel::System::TicketProcesses');
            my %ProcessDataTransver = $TicketProcessesObject->ProcessGet(
                ID => $Param{ProcessID},
            );   

            if ( $ProcessStepData{StepArtID} == 2 ) {

                # get needed objects
                my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
                my $TicketObject        = $Kernel::OM->Get('Kernel::System::Ticket');

                my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';

                my $To = $ProcessStepData{ApproverEmail};

                if ( $ProcessStepData{ApproverGroupID} && $ProcessStepData{ApproverGroupID} == 1 )  {

                    my %Ticket = $TicketObject->TicketGet(
                        TicketID      => $Param{TicketID},
                        DynamicFields => 0,
                        UserID        => 1,
                        Silent        => 1,
                    );

                    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

                    my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                        User => $Ticket{CustomerUserID},
                    );

                    if ( $To ) {
                        $To .= ',' . $CustomerUser{UserEmail};
                    }
                    else {
                        $To .= $CustomerUser{UserEmail};
                    }
                }

                if ( !$ProcessStepData{NotifyAgent} ) {
                    $ProcessStepData{NotifyAgent} = 'yes';
                }

                if ( $ProcessStepData{NotifyAgent} eq "yes" )  {
                if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {

                    my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                        GroupID => $ProcessStepData{GroupID},
                        Type    => 'ro',
                    );

                    for my $UserLogin ( keys %ApproverUsers ) {
                       
                        if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {

                            my %ApproverUser = $UserObject->GetUserData(
                                UserID => $UserLogin,
                            );

                            if ( $To ) {
                                $To .= ',' . $ApproverUser{UserEmail};
                            }
                            else {
                                $To .= $ApproverUser{UserEmail};
                            }
                        }
                    }
                }
                }

                my %CheckTicket = $TicketObject->TicketGet(
                    TicketID      => $Param{TicketID},
                    DynamicFields => 0,
                    UserID        => 1,
                    Silent        => 1,
                );

                my $SetFullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                    UserLogin => $CheckTicket{CustomerUserID},
                );

                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - approval required';

                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Genehmigung erforderlich.<br>Bitte klicken Sie auf eine Entscheidung.';
                $NotificationBodyPre .= '<br><br>';

                $NotificationBodyPre .= 'Antragsteller: ' . $SetFullName;
                $NotificationBodyPre .= '<br><br>';

                $NotificationBodyPre .= $ArticleBody;
                $NotificationBodyPre .= '<br><br>';

                my $HttpType    = $ConfigObject->Get('HttpType');
                my $FQDN        = $ConfigObject->Get('FQDN');
                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

                my $NotificationBody = "<!DOCTYPE html>
                <html lang=\"de-DE\">
                <head>
                <meta charset=\"utf-8\">
                </head>
                <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
    
                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
                Es wurde eine Anfrage eingereicht welche genehmigungspflichtig ist.\n<br>
                Zum Genehmigen oder Ablehnen bitte einen der nachstehenden links klicken.\n<br><br>

                </div>

                <div style=\"color:blue;width:100%;font-size:16px;font-family:Helvetica, Arial, sans-serif;font-weight:bold;\">

                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                    . "ProcessApproval.pl?ProcessID=$Param{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$Param{TicketID};Art=genehmigt\">Genehmigen</a>
                \n<br>\n<br>oder\n<br>\n<br>
                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                    . "ProcessApproval.pl?ProcessID=$Param{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$Param{TicketID};Art=abgelehnt\">Ablehnen</a>
                \n\n<br><br>
    
                </div>

                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">

                Es wurde folgende Anfrage gestellt:\n\n<br><br>
    
                $NotificationBodyPre
                ";

                if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {

                    $NotificationBody .= "
                    <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                        . "index.pl?Action=AgentTicketZoom;TicketID=$Param{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                        . "index.pl?Action=AgentTicketZoom;TicketID=$Param{TicketID}</a>
                    \n\n<br><br>
                    ";

                }

                $NotificationBody .= "
                </div>

                </body>
                </html>
                ";

                if ( $To ne '' ) {

                my $Sent = $EmailObject->Send(
                    From          => $From,
                    To            => $To,
                    Subject       => $NotificationSubject,
                    MimeType      => 'text/html',
                    Charset       => 'utf-8',
                    Body          => $NotificationBody,
                );

                    my $Success = $TicketObject->HistoryAdd(
                        Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                        HistoryType  => 'SendAgentNotification',
                        TicketID     => $Param{TicketID},
                        CreateUserID => 1,
                    );

                }
            }
            else {

                # get needed objects
                my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                my $UserObject          = $Kernel::OM->Get('Kernel::System::User');

                my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';

                my $To = '';

                my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                    GroupID => $ProcessStepData{GroupID},
                    Type    => 'ro',
                );

                if ( !$ProcessStepData{NotifyAgent} ) {
                    $ProcessStepData{NotifyAgent} = 'yes';
                }

                if ( $ProcessStepData{NotifyAgent} eq "yes" )  {
                my $GroupUserValue = 0;
                for my $UserLogin ( keys %ApproverUsers ) {
                   
                    if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {

                       $GroupUserValue ++;

                        my %ApproverUser = $UserObject->GetUserData(
                            UserID => $UserLogin,
                        );

                        if ( $GroupUserValue == 1 ) {
                            $To .= $ApproverUser{UserEmail};
                        }
                        else {
                                $To .= ',' . $ApproverUser{UserEmail};
                        }
                    }
                }
                }

                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - ' . $ProcessStepData{Name};

                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= 'Aktion erforderlich.';
                $NotificationBodyPre .= '<br><br>';
                $NotificationBodyPre .= $ArticleBody;
                $NotificationBodyPre .= '<br><br>';

                my $HttpType    = $ConfigObject->Get('HttpType');
                my $FQDN        = $ConfigObject->Get('FQDN');
                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

                my $NotificationBody = "<!DOCTYPE html>
                <html lang=\"de-DE\">
                <head>
                <meta charset=\"utf-8\">
                </head>
                <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
    
                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
                Es wurde eine Anfrage eingereicht welche bearbeitet werden muss.\n<br>

                Es wurde folgende Anfrage gestellt:\n\n<br><br>
    
                $NotificationBodyPre
    
                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                    . "index.pl?Action=AgentTicketZoom;TicketID=$Param{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                    . "index.pl?Action=AgentTicketZoom;TicketID=$Param{TicketID}</a>
                \n\n<br><br>

                </div>

                </body>
                </html>
                ";

                if ( $To ne '' ) {

                my $Sent = $EmailObject->Send(
                    From          => $From,
                    To            => $To,
                    Subject       => $NotificationSubject,
                    MimeType      => 'text/html',
                    Charset       => 'utf-8',
                    Body          => $NotificationBody,
                );

                    my $Success = $TicketObject->HistoryAdd(
                        Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                        HistoryType  => 'SendAgentNotification',
                        TicketID     => $Param{TicketID},
                        CreateUserID => 1,
                    );

                }
            }

            my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                ProcessStepID => $ProcessStepID,
                TicketID      => $Param{TicketID},
            );

            if ( $TicketTransition{StateID} && $TicketTransition{StateID} >= 1 ) {

                my $StateSuccess = $TicketObject->TicketStateSet(
                    StateID      => $TicketTransition{StateID},
                    TicketID     => $Param{TicketID},
                    NoPermission => 1,
                    UserID       => 1,
                );
            }

            if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
    
                my $TypeSuccess = $TicketObject->TicketTypeSet(
                    TypeID   => $TicketTransition{TypeID},
                    TicketID => $Param{TicketID},
                    UserID   => 1,
                );
            }

            if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {

                my $QueueSuccess = $TicketObject->TicketQueueSet(
                    QueueID  => $TicketTransition{QueueID},
                    TicketID => $Param{TicketID},
                    UserID   => 1,
                );
            }
        }
    }

    return 1;
}

=head2 ApprovStepCheck()

update of a Process Step

    my $Success = $ProcessStepObject->ApprovStepCheck(
        ProcessID     => 123,
        ProcessStepID => 123,
        TicketID      => 123,
        Art           => 'genehmigt,
    );

=cut

sub ApprovStepCheck {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID TicketID Art)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %ProcessStepData = $Self->ProcessStepGet(
        ID => $Param{ProcessStepID},
    );

    if ( $ProcessStepData{Ready} && $ProcessStepData{Ready} == 1 ) {
        $Param{StepApproval} = 2;
    }
    else {
        $Param{StepApproval} = 1;
    }

    return $Param{StepApproval};
}

=head2 ProcessStepReadyReset()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepReadyReset(
        ToProcessStepID => 123,
        TicketID        => 123,
    );

=cut

sub ProcessStepReadyReset {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ToProcessStepID TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{Ready}      = 0;
    $Param{StepActive} = 0;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE t_process_step SET ready = ? WHERE id = ? AND ticket_id = ?',
        Bind => [
            \$Param{Ready}, \$Param{ToProcessStepID}, \$Param{TicketID},
        ],
    );

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE t_process_step SET step_active = ? WHERE id = ? AND ticket_id = ?',
        Bind => [
            \$Param{StepActive}, \$Param{ToProcessStepID}, \$Param{TicketID},
        ],
    );

    # sql
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM t_process_fields_value WHERE process_step_id >= ? AND ticket_id = ?',
        Bind => [ \$Param{ToProcessStepID}, \$Param{TicketID}, ],
    );

    return 1;
}

=head2 ProcessStepReadyResetForward()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepReadyResetForward(
        ToProcessStepID => 123,
        TicketID        => 123,
    );

=cut

sub ProcessStepReadyResetForward {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ToProcessStepID TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{Ready}      = 1;
    $Param{StepActive} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE t_process_step SET ready = ? WHERE id < ? AND ticket_id = ?',
        Bind => [
            \$Param{Ready}, \$Param{ToProcessStepID}, \$Param{TicketID},
        ],
    );

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE t_process_step SET step_active = ? WHERE id = ? AND ticket_id = ?',
        Bind => [
            \$Param{StepActive}, \$Param{ToProcessStepID}, \$Param{TicketID},
        ],
    );

    return 1;
}

=head2 SearchNextProcessStepParallel()

returns a hash of all Equipment data

    my $ProcessStepIDCheck = $ProcessStepObject->SearchNextProcessStepParallel(
        ProcessStepID => 123,
        TicketID      => 123,
    );

=cut

sub SearchNextProcessStepParallel {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!',
        );
        return;
    }

    # check needed stuff
    if ( !$Param{ProcessStepID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStepID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id FROM t_process_step WHERE ticket_id = ? AND id < ? AND ready < 1 AND step_active = 0',
        Bind => [
            \$Param{TicketID}, \$Param{ProcessStepID},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;
}

=item ProcessStepParallelBetweenList()

return a hash list of processes

    my @ProcessStepListBetween = $TicketProcessStepObject->ProcessStepParallelBetweenList(
        ProcessStepID     => 123,
        ProcessStepIDNext => 123,
    );

=cut

sub ProcessStepParallelBetweenList {
    my ( $Self, %Param ) = @_;


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id FROM t_process_step WHERE id >= ? AND id < ?',
        Bind => [ \$Param{ProcessStepID}, \$Param{ProcessStepIDNext}, ],
    );

    # fetch the result
    my @ProcessStepList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ProcessStepList, $Row[0];
    }

    return @ProcessStepList;
}

=item ProcessStepParallelEndList()

return a hash list of processes

    my @ProcessStepListEnd = $TicketProcessStepObject->ProcessStepParallelEndList(
        ProcessStepID => 123,
        ProcessID     => 123,
    );

=cut

sub ProcessStepParallelEndList {
    my ( $Self, %Param ) = @_;


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id FROM t_process_step WHERE id > ? and process_id = ? and ready = 0',
        Bind => [ \$Param{ProcessStepID}, \$Param{ProcessID}, ],
    );

    # fetch the result
    my @ProcessStepList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ProcessStepList, $Row[0];
    }

    return @ProcessStepList;
}

=head2 SeachAllReadySteps()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SeachAllReadySteps(
        ProcessStepID => 123,
        ProcessID     => 123,
    );

=cut

sub SeachAllReadySteps {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ProcessStepID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessStepID!',
        );
        return;
    }

    # check needed stuff
    if ( !$Param{ProcessID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ProcessID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id FROM t_process_step WHERE process_id = ? AND id < ? AND ready = 0',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStepID},
        ],
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;

}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
