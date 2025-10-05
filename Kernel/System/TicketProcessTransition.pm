# --
# Kernel/System/TicketProcessTransition.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: TicketProcessTransition.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketProcessTransition;

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

Kernel::System::TicketProcessTransition - TicketProcessTransition lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add TicketProcessTransition.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketProcessTransitionObject = $Kernel::OM->Get('Kernel::System::TicketProcessTransition');

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

    my $Success = $TicketProcessTransitionObject->ProcessTransitionAdd(
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
        TicketID      => 123,
    );

=cut

sub ProcessTransitionAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID ProcessStepNo UserID TicketID)) {
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
        SQL => 'INSERT INTO t_process_transition (process_id, processstep_id, processstep_no, step_no, type_id, state_id, queue_id, service_id, sla_id,'
            . ' create_time, create_by, change_time, change_by, ticket_id)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?)',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{ProcessStepNo}, \$Param{StepNo}, \$Param{TypeID}, \$Param{StateID}, \$Param{QueueID},
            \$Param{ServiceID}, \$Param{SLAID}, \$Param{UserID}, \$Param{UserID}, \$Param{TicketID},
        ],
    );


    return 1;
}

=head2 ProcessTransitionGet()

get a process Transition

    my %Transition = $TicketProcessTransitionObject->ProcessTransitionGet(
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
        SQL => 'SELECT id, process_id, processstep_id, processstep_no, step_no, type_id, state_id, queue_id, service_id, sla_id, create_time, create_by, change_time, change_by, ticket_id '
            . 'FROM t_process_transition WHERE id = ?',
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
        $Data{TicketID}      = $Row[14];
    }
    return %Data;
}

=head2 ProcessTransitionList()

returns a hash of all process Conditions

    my %ProcessTransitionList = $TicketProcessTransitionObject->ProcessTransitionList(
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
        SQL => 'SELECT id, processstep_id, FROM t_process_transition WHERE process_id = ? AND processstep_id = ? AND processstep_no = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{ProcessStepNo}, ],
    );

    # fetch the result
    my %ProcessTransitionList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessTransitionList{$Row[0]} = $Row[1];
    }

    return %ProcessTransitionList;
}

=head2 ProcessTicketTransitionGet()

get a process Transition

    my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
        ProcessStepID => 123,
        TicketID      => 123,
    );

=cut

sub ProcessTicketTransitionGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ProcessStepID TicketID)) {
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
        SQL => 'SELECT id, process_id, processstep_id, processstep_no, step_no, type_id, state_id, queue_id, service_id, sla_id, create_time, create_by, change_time, change_by, ticket_id '
            . 'FROM t_process_transition WHERE processstep_id = ? AND ticket_id = ?',
        Bind  => [ \$Param{ProcessStepID}, \$Param{TicketID}, ],
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
        $Data{TicketID}      = $Row[14];
    }
    return %Data;
}

=head2 SearchNextParallel()

returns a hash of all Equipment data

    my $ProcessStepIDNext = $TicketProcessTransitionObject->SearchNextParallel(
        ProcessStepID => 123,
        TicketID      => 123,
    );

=cut

sub SearchNextParallel {
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
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT processstep_id FROM t_process_transition WHERE ticket_id = ? AND processstep_id > ?',
        Bind => [
            \$Param{TicketID}, \$Param{ProcessStepID},
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

=head2 ProcessTransitionSumList()

returns a hash of all process Conditions

    my %ProcessTransitionList = $TicketProcessTransitionObject->ProcessTransitionSumList(
        ProcessID => 123,
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
        SQL  => 'SELECT id, processstep_id FROM t_process_transition WHERE process_id = ?',
        Bind => [ \$Param{ProcessID}, ],
    );

    # fetch the result
    my %ProcessTransitionList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessTransitionList{ $Row[0] } = $Row[1];
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
