# --
# Kernel/System/ProcessTransition.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: ProcessTransition.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessTransition;

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

Kernel::System::ProcessTransition - ProcessTransition lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add ProcessTransition.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $ProcessTransitionObject = $Kernel::OM->Get('Kernel::System::ProcessTransition');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessTransitionAdd()

to add a Process Transition

    my $Success = $ProcessTransitionObject->ProcessTransitionAdd(
        ProcessID     => 123,
        ProcessStepID => 123,
        ProcessStepNo => 123,
        StepNo        => 123,
        TypeID        => 1,
        StateID       => 1,
        QueueID       => 1,
        ServiceID     => 1,
        SLAID         => 1,
        UserID        => 123,
    );

=cut

sub ProcessTransitionAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID ProcessStepNo UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !$Param{TypeID} ) {
        $Param{TypeID} = 0;
    }
    if ( !$Param{StateID} ) {
        $Param{StateID} = 0;
    }
    if ( !$Param{QueueID} ) {
        $Param{QueueID} = 0;
    }
    if ( !$Param{ServiceID} ) {
        $Param{ServiceID} = 0;
    }
    if ( !$Param{SLAID} ) {
        $Param{SLAID} = 0;
    }
    if ( !$Param{StepNo} ) {
        $Param{StepNo} = 0;
    }


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new Equipment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO process_transition (process_id, processstep_id, processstep_no, step_no, type_id, state_id, queue_id, service_id, sla_id,'
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{ProcessStepNo}, \$Param{StepNo}, \$Param{TypeID}, \$Param{StateID}, \$Param{QueueID},
            \$Param{ServiceID}, \$Param{SLAID}, \$Param{UserID}, \$Param{UserID},
        ],
    );


    return 1;
}

=head2 ProcessTransitionUpdate()

update of a Process Step

    my $Success = $ProcessTransitionObject->ProcessTransitionUpdate(
        ProcessStepID => 123,
        StateID       => 1,
        QueueID       => 1,
        UserID        => 123,
    );

=cut

sub ProcessTransitionUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessStepID QueueID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !$Param{StateID} ) {
        $Param{StateID} = 0;
    }
    if ( !$Param{QueueID} ) {
        $Param{QueueID} = 0;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE process_transition SET state_id = ?, queue_id = ? WHERE processstep_id = ?',
        Bind => [
            \$Param{StateID}, \$Param{QueueID}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessTransitionGet()

get a process Transition

    my %List = $ProcessTransitionObject->ProcessTransitionGet(
        ProcessTransitionID => 123,
    );

=cut

sub ProcessTransitionGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ProcessTransitionID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, process_id, processstep_id, processstep_no, step_no, type_id, state_id, queue_id, service_id, sla_id, create_time, create_by, change_time, change_by '
            . 'FROM process_transition WHERE id = ?',
        Bind  => [ \$Param{ProcessTransitionID} ],
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}            = $Row[0];
        $Data{ProcessID}     = $Row[1];
        $Data{ProcessStepID} = $Row[2];
        $Data{ProcessStepNo} = $Row[3];
        $Data{StepNo}        = $Row[4];
        $Data{TypeID}        = $Row[5];
        $Data{StateID}       = $Row[6];
        $Data{QueueID}       = $Row[7];
        $Data{ServiceID}     = $Row[8];
        $Data{SLAID}         = $Row[9];
        $Data{CreateTime}    = $Row[10];
        $Data{CreateBy}      = $Row[11];
        $Data{ChangeTime}    = $Row[12];
        $Data{ChangeBy}      = $Row[13];
    }
    return %Data;
}

=head2 ProcessStepTransitionGet()

get a process Transition

    my %List = $ProcessTransitionObject->ProcessStepTransitionGet(
        ProcessStepID => 123,
    );

=cut

sub ProcessStepTransitionGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ProcessStepID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, process_id, processstep_id, processstep_no, step_no, type_id, state_id, queue_id, service_id, sla_id, create_time, create_by, change_time, change_by '
            . 'FROM process_transition WHERE processstep_id = ?',
        Bind  => [ \$Param{ProcessStepID} ],
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}            = $Row[0];
        $Data{ProcessID}     = $Row[1];
        $Data{ProcessStepID} = $Row[2];
        $Data{ProcessStepNo} = $Row[3];
        $Data{StepNo}        = $Row[4];
        $Data{TypeID}        = $Row[5];
        $Data{StateID}       = $Row[6];
        $Data{QueueID}       = $Row[7];
        $Data{ServiceID}     = $Row[8];
        $Data{SLAID}         = $Row[9];
        $Data{CreateTime}    = $Row[10];
        $Data{CreateBy}      = $Row[11];
        $Data{ChangeTime}    = $Row[12];
        $Data{ChangeBy}      = $Row[13];
    }
    return %Data;
}

=head2 ProcessTransitionDelete()

to delete a Process Transition

    my $Sucess = $ProcessTransitionObject->ProcessTransitionDelete(
        ProcessTransitionID => 123,
    );

=cut

sub ProcessTransitionDelete{
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessTransitionID)) {
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

    # sql
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM process_transition WHERE id = ?',
        Bind => [ \$Param{ProcessTransitionID} ],
    );

    return 1;
}


=head2 ProcessTransitionList()

returns a hash of all process Conditions

    my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionList(
        ProcessID     => 123,
        ProcessStepID => 123,
        ProcessStepNo => 123,
    );


=cut

sub ProcessTransitionList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID)) {
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

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, processstep_id FROM process_transition WHERE process_id = ? AND processstep_id = ? AND processstep_no = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{ProcessStepNo}, ],
    );

    # fetch the result
    my %ProcessTransitionList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessTransitionList{$Row[0]} = $Row[1];
    }

    return %ProcessTransitionList;
}

=head2 ProcessTransitionAllList()

returns a hash of all process Conditions

    my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionAllList(
        ProcessID     => 123,
        ProcessStepID => 123,
    );


=cut

sub ProcessTransitionAllList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID)) {
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

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, processstep_id FROM process_transition WHERE process_id = ? AND processstep_id = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, ],
    );

    # fetch the result
    my %ProcessTransitionList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessTransitionList{$Row[0]} = $Row[1];
    }

    return %ProcessTransitionList;
}

=head2 ProcessTransitionSumList()

returns a hash of all process Conditions

    my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionSumList(
        ProcessID     => 123,
    );


=cut

sub ProcessTransitionSumList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID)) {
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

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, processstep_id FROM process_transition WHERE process_id = ?',
        Bind => [ \$Param{ProcessID}, ],
    );

    # fetch the result
    my %ProcessTransitionList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessTransitionList{$Row[0]} = $Row[1];
    }

    return %ProcessTransitionList;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
