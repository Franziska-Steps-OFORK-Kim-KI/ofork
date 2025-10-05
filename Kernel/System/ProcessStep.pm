# --
# Kernel/System/ProcessStep.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: ProcessStep.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessStep;

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

Kernel::System::ProcessStep - Process step lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add Process step.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $ProcessStepObject = $Kernel::OM->Get('Kernel::System::ProcessStep');

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

    my $ProcessStepID = $ProcessStepObject->ProcessStepAdd(
        ProcessID       => 1,
        Name            => 'Name',
        Color           => 123124,
        ProcessStep     => 1,
        StepNo          => 1,
        StepNoFrom      => 0,
        StepNoTo        => 0,
        Description     => 'Description',
        GroupID         => 123,
        StepArtID       => 1,
        SetArticleID    => 2,
        ApproverGroupID => 123,
        ApproverEmail   => 'approver@email.com',
        NotifyAgent     => 'yes',
        ValidID         => 1,
        UserID          => 123,
    );

=cut

sub ProcessStepAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name ProcessID StepNo ValidID UserID)) {
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
    if ( !$Param{StepNo} ) {
        $Param{StepNo} = 0;
    }
    if ( !$Param{StepNoFrom} ) {
        $Param{StepNoFrom} = 0;
    }
    if ( !$Param{StepNoTo} ) {
        $Param{StepNoTo} = 0;
    }
    if ( !$Param{SetArticleID} ) {
        $Param{SetArticleID} = 2;
    }


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new process step
    return if !$DBObject->Do(
        SQL => 'INSERT INTO process_step (name, process_id, process_step, step_no, step_no_from, step_no_to, process_color, '
            . ' description, group_id, stepart_id, approver_id, approver_email, valid_id, '
            . ' create_time, create_by, change_time, change_by, step_end, setarticle_id, notify_agent)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?, ?, ?)',
        Bind => [
            \$Param{Name}, \$Param{ProcessID}, \$Param{ProcessStep}, \$Param{StepNo}, \$Param{StepNoFrom}, \$Param{StepNoTo}, \$Param{Color},
            \$Param{Description}, \$Param{GroupID}, \$Param{StepArtID}, \$Param{ApproverGroupID}, \$Param{ApproverEmail},
            \$Param{ValidID}, \$Param{UserID}, \$Param{UserID}, \$Param{StepEnd}, \$Param{SetArticleID}, \$Param{NotifyAgent},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT MAX(id) FROM process_step;',
    );

    my $ProcessStepID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;
}

=head2 NextProcessStep()

to add a ProcessStep

    my $ProcessStepID = $ProcessStepObject->NextProcessStep(
        ProcessID       => 1,
        ProcessStepID   => 1,
        ProcessStep     => 1,
        Name            => 'Name',
        StepNo          => 1,
        StepNoFrom      => 0,
        StepNoTo        => 0,
        Description     => 'Description',
        GroupID         => 123,
        StepArtID       => 1,
        SetArticleID    => 2,
        ApproverGroupID => 123,
        ApproverEmail   => 'approver@email.com',
        ValidID         => 1,
        WithConditions  => 1,
        UserID          => 123,
    );

=cut

sub NextProcessStep {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name ProcessID StepNo ValidID UserID)) {
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
    if ( !$Param{ApproverGroupID} ) {
        $Param{ApproverGroupID} = 0;
    }
    if ( !$Param{ApproverGroupID} ) {
        $Param{ApproverGroupID} = 0;
    }
    if ( !$Param{StepEnd} ) {
        $Param{StepEnd} = 0;
    }
    if ( !$Param{StepNoTo} ) {
        $Param{StepNoTo} = 0;
    }
    if ( !$Param{WithConditions} ) {
        $Param{WithConditions} = 0;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');


    # insert new process step
    return if !$DBObject->Do(
        SQL => 'INSERT INTO process_step (name, process_id, process_step, step_no, step_no_from, step_no_to, process_color, '
            . ' description, group_id, stepart_id, approver_id, approver_email, valid_id, '
            . ' create_time, create_by, change_time, change_by, step_end, with_conditions, setarticle_id, notify_agent)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?, ?, ?, ?)',
        Bind => [
            \$Param{Name}, \$Param{ProcessID}, \$Param{ProcessStep}, \$Param{StepNo}, \$Param{StepNoFrom}, \$Param{StepNoTo}, \$Param{Color},
            \$Param{Description}, \$Param{GroupID}, \$Param{StepArtID}, \$Param{ApproverGroupID}, \$Param{ApproverEmail},
            \$Param{ValidID}, \$Param{UserID}, \$Param{UserID}, \$Param{StepEnd}, \$Param{WithConditions}, \$Param{SetArticleID}, \$Param{NotifyAgent},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM process_step WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    my $ProcessStepID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM process_step WHERE id = ? and set_parallel >= 1',
        Bind => [ \$Param{StepNoFrom} ],
    );

    my $CheckParallelStepID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $CheckParallelStepID = $Row[0];
    }

    if ( $CheckParallelStepID ) {

        my $SetParallelEnd = 2;

        # update process step in database
        return if !$DBObject->Do(
            SQL => 'UPDATE process_step SET parallel_se = ? WHERE id = ?',
            Bind => [
                \$SetParallelEnd, \$CheckParallelStepID,
            ],
        );
    }

    if ( $Param{ApprovalSet} ) {

        # update process step in database
        return if !$DBObject->Do(
            SQL => 'UPDATE process_step SET to_id_from_two = ? WHERE id = ?',
            Bind => [
                \$ProcessStepID, \$Param{ProcessStepID},
            ],
        );
    }

    return $ProcessStepID;
}

=head2 NextProcessStepParallel()

to add a ProcessStep

    my $ProcessStepID = $ProcessStepObject->NextProcessStepParallel(
        ProcessID        => 1,
        ProcessStepID    => 1,
        ProcessStep      => 1,
        Name             => 'Name',
        StepNo           => 1,
        StepNoFrom       => 0,
        StepNoTo         => 0,
        Description      => 'Description',
        GroupID          => 123,
        StepArtID        => 1,
        SetArticleID     => 2,
        ApproverGroupID  => 123,
        ApproverEmail    => 'approver@email.com',
        ValidID          => 1,
        WithConditions   => 1,
        ParallelStep     => 1,
        SetFirstParallel => 1,
        SetParallel      => 1,
        ParallelSe       => 1,
        UserID           => 123,
    );

=cut

sub NextProcessStepParallel {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name ProcessID StepNo ValidID UserID)) {
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
    if ( !$Param{ApproverGroupID} ) {
        $Param{ApproverGroupID} = 0;
    }
    if ( !$Param{ApproverGroupID} ) {
        $Param{ApproverGroupID} = 0;
    }
    if ( !$Param{StepEnd} ) {
        $Param{StepEnd} = 0;
    }
    if ( !$Param{StepNoTo} ) {
        $Param{StepNoTo} = 0;
    }
    if ( !$Param{WithConditions} ) {
        $Param{WithConditions} = 0;
    }
    if ( !$Param{ParallelStep} ) {
        $Param{ParallelStep} = 0;
    }    
    if ( !$Param{ParallelSe} ) {
        $Param{ParallelSe} = 0;
    } 
    
    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new process step
    return if !$DBObject->Do(
        SQL => 'INSERT INTO process_step (name, process_id, process_step, step_no, step_no_from, step_no_to, process_color, '
            . ' description, group_id, stepart_id, approver_id, approver_email, valid_id, '
            . ' create_time, create_by, change_time, change_by, step_end, with_conditions, setarticle_id, parallel_step, set_parallel, parallel_se, notify_agent)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?, ?, ?, ?, ?, ?, ?)',
        Bind => [
            \$Param{Name}, \$Param{ProcessID}, \$Param{ProcessStep}, \$Param{StepNo}, \$Param{StepNoFrom}, \$Param{StepNoTo}, \$Param{Color},
            \$Param{Description}, \$Param{GroupID}, \$Param{StepArtID}, \$Param{ApproverGroupID}, \$Param{ApproverEmail},
            \$Param{ValidID}, \$Param{UserID}, \$Param{UserID}, \$Param{StepEnd}, \$Param{WithConditions}, \$Param{SetArticleID},
             \$Param{ParallelStep}, \$Param{SetParallel}, \$Param{ParallelSe}, \$Param{NotifyAgent},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM process_step WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    my $ProcessStepID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET set_parallel = ? WHERE id = ?',
        Bind => [
            \$Param{SetParallel}, \$Param{StepNoFrom},
        ],
    );

    if ( $Param{SetFirstParallel} ) {

        # update process step in database
        return if !$DBObject->Do(
            SQL => 'UPDATE process_step SET parallel_step = ? WHERE id = ?',
            Bind => [
                \$Param{SetFirstParallel}, \$Param{StepNoFrom},
            ],
        );
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

=head2 ProcessStepUpdate()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepUpdate(
        ProcessStepID   => 123,
        Name            => 'Name',
        Color           => 123124,
        Description     => 'Description',
        GroupID         => 123,
        StepArtID       => 1,
        SetArticleID    => 2,
        ApproverGroupID => 123,
        ApproverEmail   => 'approver@email.com',
        NotifyAgent     => 'yes',
        ValidID         => 1,
        UserID          => 123,
    );

=cut

sub ProcessStepUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID Name ValidID UserID)) {
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
    if ( !$Param{ApproverGroupID} ) {
        $Param{ApproverGroupID} = 0;
    }


    # get current Equipment data
    my %ProcessStepData = $Self->ProcessStepGet(
        ID => $Param{ProcessStepID},
    );

    # check if update is required
    my $ChangeRequired;
    KEY:
    for my $Key (qw(Name Color Description GroupID SetArticleID ApproverGroupID ApproverEmail ValidID NotifyAgent)) {

        next KEY if defined $ProcessStepData{$Key} && $ProcessStepData{$Key} eq $Param{$Key};

        $ChangeRequired = 1;

        last KEY;
    }

    return 1 if !$ChangeRequired;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET name = ?, process_color = ?, description = ?, group_id = ?, approver_id = ?, approver_email = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ?, setarticle_id = ?, notify_agent = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Color}, \$Param{Description}, \$Param{GroupID}, \$Param{ApproverGroupID},
            \$Param{ApproverEmail}, \$Param{ValidID}, \$Param{UserID}, \$Param{SetArticleID}, \$Param{NotifyAgent}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ToSelectedProcessStep()

update of a Process Step

    my $Success = $ProcessStepObject->ToSelectedProcessStep(
        ProcessID     => 123,
        ProcessStepID => 123,
        SetNextStepID => 123,
        FromStepNo    => 1,
        UserID        => 123,
    );

=cut

sub ToSelectedProcessStep {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID SetNextStepID FromStepNo UserID)) {
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

    if ( $Param{FromStepNo} == 1 ) {

        # update process step in database
        return if !$DBObject->Do(
            SQL => 'UPDATE process_step SET to_id_from_one = ? WHERE id = ?',
            Bind => [
                \$Param{SetNextStepID}, \$Param{ProcessStepID},
            ],
        );
    }
    else {

        # update process step in database
        return if !$DBObject->Do(
            SQL => 'UPDATE process_step SET to_id_from_two = ? WHERE id = ?',
            Bind => [
                \$Param{SetNextStepID}, \$Param{ProcessStepID},
            ],
        );
    }

    return 1;
}

=head2 ProcessStepNoApprovalEnd()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepNoApprovalEnd(
        ProcessStepID => 123,
        ProcessID     => 123,
        UserID        => 123,
    );

=cut

sub ProcessStepNoApprovalEnd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{ApprovalEnd} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET not_approved = ?, with_conditions_end = ? WHERE id = ?',
        Bind => [
            \$Param{ApprovalEnd}, \$Param{ApprovalEnd}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessStepApprovalEnd()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepApprovalEnd(
        ProcessStepID => 123,
        ProcessID     => 123,
        UserID        => 123,
    );

=cut

sub ProcessStepApprovalEnd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{ApprovalEnd} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET step_end = ?, without_conditions_end = ? WHERE id = ?',
        Bind => [
            \$Param{ApprovalEnd}, \$Param{ApprovalEnd}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessStepEnd()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepEnd(
        ProcessID     => 123,
        ProcessStepID => 123,
        UserID        => 123,
    );

=cut

sub ProcessStepEnd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{End} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET step_end = ? WHERE id = ?',
        Bind => [
            \$Param{End}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessStepWithoutEnd()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepWithoutEnd(
        ProcessID     => 123,
        ProcessStepID => 123,
        UserID        => 123,
    );

=cut

sub ProcessStepWithoutEnd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{End} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET without_conditions_end = ? WHERE id = ?',
        Bind => [
            \$Param{End}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessStepEndWithConditions()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepEndWithConditions(
        ProcessStepID => 123,
        ProcessID     => 123,
        UserID        => 123,
    );

=cut

sub ProcessStepEndWithConditions {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{WithConditionsEnd} = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET with_conditions_end = ?  WHERE id = ?',
        Bind => [
            \$Param{WithConditionsEnd}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessStepApprovalStopEnd()

update of a Process Step

    my $Success = $ProcessStepObject->ProcessStepApprovalStopEnd(
        ProcessStepID => 123,
        ProcessID     => 123,
        UserID        => 123,
    );

=cut

sub ProcessStepApprovalStopEnd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{ApprovalEnd} = 0;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET not_approved = ? WHERE id = ?',
        Bind => [
            \$Param{ApprovalEnd}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 StepList()

returns a hash of all Step

    my %ProcessStep = $ProcessStepObject->StepList(
        ProcessID => 123,
    );

the result looks like

    %ProcessStep = (
        '1' => 'users',
        '2' => 'admin',
        '3' => 'stats',
        '4' => 'secret',
    );

=cut

sub StepList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name FROM process_step WHERE process_id = ?',
        Bind => [
            \$Param{ProcessID},
        ],
    );

    # fetch the result
    my %StepList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $StepList{$Row[0]} = $Row[1];
    }

    return %StepList;
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
        SQL => 'SELECT id, name, process_id, process_step, step_no, step_no_from, step_no_to, process_color, description, group_id, '
        . 'stepart_id, approver_id, approver_email, valid_id, create_time, create_by, change_time, change_by, step_end, '
        . 'not_approved, to_id_from_one, without_conditions_end, with_conditions, to_id_from_two, with_conditions_end, setarticle_id, parallel_step, set_parallel, parallel_se, notify_agent FROM process_step',
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
            StepNoTo            => $Row[6],
            Color               => $Row[7],
            Description         => $Row[8],
            GroupID             => $Row[9],
            StepArtID           => $Row[10],
            ApproverGroupID     => $Row[11],
            ApproverEmail       => $Row[12],
            ValidID             => $Row[13],
            CreateTime          => $Row[14],
            CreateBy            => $Row[15],
            ChangeTime          => $Row[16],
            ChangeBy            => $Row[17],
            StepEnd             => $Row[18],
            NotApproved         => $Row[19],
            ToIDFromOne         => $Row[20],
            WithoutConditionEnd => $Row[21],
            WithConditions      => $Row[22],
            ToIDFromTwo         => $Row[23],
            WithConditionsEnd   => $Row[24],
            SetArticleID        => $Row[25],
            ParallelStep        => $Row[26],
            SetParallel         => $Row[27],
            ParallelSe          => $Row[28],
            NotifyAgent         => $Row[29],
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
        SQL => 'SELECT id FROM process_step WHERE process_id = ? AND process_step > ? AND id_from_not_approved < 1',
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
        StepNoFrom  => 123,
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
        SQL => 'SELECT id FROM process_step WHERE process_id = ? AND process_step = ? AND step_no = ? AND step_no_from = ?',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStep}, \$Param{StepNo}, \$Param{StepNoFrom},
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
        SQL => 'SELECT id FROM process_step WHERE step_no_from = ? AND process_id = ? AND step_no = ?',
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
        SQL => 'SELECT id FROM process_step WHERE step_no_from = ? AND process_id = ? AND with_conditions = ?',
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
        SQL => 'SELECT id FROM process_step WHERE process_id = ? AND process_step = ? AND step_no_to >= 1',
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
            'SELECT id, name FROM process_step WHERE process_id = ?',
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
            'SELECT id, step_no FROM process_step WHERE process_id = ? AND process_step = ?',
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
            'SELECT process_step FROM process_step WHERE process_id = ?',
        Bind => [ \$Param{ProcessID}, ],
    );

    # fetch the result
    my @ProcessStepValue;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ProcessStepValue, $Row[0];
    }

    return @ProcessStepValue;
}

=item ProcessStepDelete()

delete

    my $Remove = $ProcessStepObject->ProcessStepDelete(
        ProcessStepID => 123,
    );

=cut

sub ProcessStepDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ProcessStepID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need ProcessStepID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL  => 'DELETE FROM process_step WHERE id = ? ',
        Bind => [ \$Param{ProcessStepID}, ],
    );
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM dynamicprocess_fields WHERE processstep_id = ? ',
        Bind => [ \$Param{ProcessStepID}, ],
    );
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM process_conditions WHERE processstep_id = ? ',
        Bind => [ \$Param{ProcessStepID}, ],
    );
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM process_d_conditions WHERE processstep_id = ? ',
        Bind => [ \$Param{ProcessStepID}, ],
    );
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM process_fields WHERE processstep_id = ? ',
        Bind => [ \$Param{ProcessStepID}, ],
    );
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM process_transition WHERE processstep_id = ? ',
        Bind => [ \$Param{ProcessStepID}, ],
    );

    $Param{ToID} = 0;

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_step SET to_id_from_one = ?, to_id_from_two = ? WHERE id = ?',
        Bind => [
            \$Param{ToID}, \$Param{ToID}, \$Param{ProcessStepID},,
        ],
    );

    return 1;
}

=head2 SearchParallelStep()

returns a hash of all Equipment data

    my $ProcessStepID = $ProcessStepObject->SearchParallelStep(
        ProcessID   => 123,
    );

=cut

sub SearchParallelStep {
    my ( $Self, %Param ) = @_;

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
        SQL => 'SELECT id FROM process_step WHERE process_id = ? AND parallel_step >= 1',
        Bind => [
            \$Param{ProcessID},
        ],
        Limit => 1,
    );

    # fetch the result
    my $ProcessStepID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepID = $Row[0];
    }

    return $ProcessStepID;

}

=head2 ProcessStepProcessList()

returns a hash of all Step

    my %ProcessStep = $ProcessStepObject->ProcessStepProcessList(
        Valid     => 1,   # (optional) default 0
        ProcessID => 123,
    );

the result looks like

    %ProcessStep = (
        '1' => 'users',
        '2' => 'admin',
        '3' => 'stats',
        '4' => 'secret',
    );

=cut

sub ProcessStepProcessList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} ? 1 : 0;

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # get Equipment data list
    my %ProcessStepDataList = $Self->ProcessStepDataProcessList(
        ProcessID => $Param{ProcessID},
    );

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

=head2 ProcessStepDataProcessList()

returns a hash of all Equipment data

    my %ProcessStepDataList = $ProcessStepObject->ProcessStepDataProcessList(
        ProcessID => 123,
    );

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

sub ProcessStepDataProcessList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, process_id, process_step, step_no, step_no_from, step_no_to, process_color, description, group_id, '
        . 'stepart_id, approver_id, approver_email, valid_id, create_time, create_by, change_time, change_by, step_end, '
        . 'not_approved, to_id_from_one, without_conditions_end, with_conditions, to_id_from_two, with_conditions_end, setarticle_id, parallel_step FROM process_step WHERE process_id = ?',
        Bind => [
            \$Param{ProcessID},
        ],
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
            StepNoTo            => $Row[6],
            Color               => $Row[7],
            Description         => $Row[8],
            GroupID             => $Row[9],
            StepArtID           => $Row[10],
            ApproverGroupID     => $Row[11],
            ApproverEmail       => $Row[12],
            ValidID             => $Row[13],
            CreateTime          => $Row[14],
            CreateBy            => $Row[15],
            ChangeTime          => $Row[16],
            ChangeBy            => $Row[17],
            StepEnd             => $Row[18],
            NotApproved         => $Row[19],
            ToIDFromOne         => $Row[20],
            WithoutConditionEnd => $Row[21],
            WithConditions      => $Row[22],
            ToIDFromTwo         => $Row[23],
            WithConditionsEnd   => $Row[24],
            SetArticleID        => $Row[25],
            ParallelStep        => $Row[26],
        };
    }

    return %ProcessStepDataList;
}

=item ProcessStepParallelSe()

return a hash list of processes

    my %ProcessParallelSeList = $ProcessStepObject->ProcessStepParallelSe(
        ProcessID => 123,
    );

=cut

sub ProcessStepParallelSe {
    my ( $Self, %Param ) = @_;


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, process_step FROM process_step WHERE process_id = ? AND parallel_se = 2',
        Bind => [ \$Param{ProcessID}, ],
    );

    # fetch the result
    my %ProcessStepList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessStepList{ $Row[0] } = $Row[1];
    }

    return %ProcessStepList;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
