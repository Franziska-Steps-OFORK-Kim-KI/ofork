# --
# Kernel/System/TicketProcessStepValue.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: TicketProcessStepValue.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketProcessStepValue;

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

Kernel::System::TicketProcessStepValue - TicketProcessStepValue lib

=head1 DESCRIPTION

All functions. E. g. to add TicketProcessStepValue.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketProcessStepValueObject = $Kernel::OM->Get('Kernel::System::TicketProcessStepValue');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessFieldValueAdd()

to add a Process field value

    my $ID = $TicketProcessStepValueObject->ProcessFieldValueAdd(
        TicketID      => 123,
        ProcessID     => 123,
        ProcessStepID => 123,
        Report        => 'Report',
        Title         => 'Title',
        TypeID        => 123,
        QueueID       => 123,
        StateID       => 123,
        FromCustomer  => 'FromCustomer',
        User          => 123,
        Approval      => 1,
        UserID        => 123,
    );

=cut

sub ProcessFieldValueAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID ProcessID ProcessStepID UserID)) {
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
    if ( !$Param{QueueID} ) {
        $Param{QueueID} = 0;
    }
    if ( !$Param{StateID} ) {
        $Param{StateID} = 0;
    }
    if ( !$Param{User} ) {
        $Param{User} = 0;
    }
    if ( !$Param{Approval} ) {
        $Param{Approval} = 0;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new Equipment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO t_process_fields_value (ticket_id, process_id, process_step_id, report, title, type_id, queue_id, state_id,'
            . ' from_customer, user_id, approval, create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TicketID}, \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{Report}, \$Param{Title}, \$Param{TypeID}, \$Param{QueueID}, \$Param{StateID},
            \$Param{FromCustomer}, \$Param{User}, \$Param{Approval}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    $Param{Ready} = 1;

    # update process step in database
    return if !$DBObject->Do(
        SQL => 'UPDATE t_process_step SET ready = ? WHERE ticket_id = ? AND process_id = ? AND id = ?',
        Bind => [
            \$Param{Ready}, \$Param{TicketID}, \$Param{ProcessID}, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessDynamicFieldValueAdd()

to add a Process dynamic field value

    my $ID = $TicketProcessStepValueObject->ProcessDynamicFieldValueAdd(
        TicketID       => 123,
        ProcessID      => 123,
        ProcessStepID  => 123,
        DynamicfieldID => 123,
        FieldValue     => 'FieldValue',
        UserID         => 123,
    );

=cut

sub ProcessDynamicFieldValueAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID ProcessID ProcessStepID UserID)) {
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

    # insert new Equipment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO t_dynamicprocess_fields_value (ticket_id, process_id, process_step_id, dynamicfield_id, field_value,'
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TicketID}, \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{DynamicfieldID}, \$Param{FieldValue}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    return 1;
}

=head2 ProcessDynamicFieldValueGet()

get a process field value

    my %ProcessFieldValue = $TicketProcessStepValueObject->ProcessDynamicFieldValueGet(
        TicketID       => 123,
        ProcessID      => 123,
        ProcessStepID  => 123,
        DynamicfieldID => 123,
    );

=cut

sub ProcessDynamicFieldValueGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(TicketID ProcessID ProcessStepID DynamicfieldID)) {
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
        SQL => 'SELECT id, ticket_id, process_id, process_step_id, dynamicfield_id, field_value,'
            . ' create_time, create_by, change_time, change_by'
            . ' FROM t_dynamicprocess_fields_value WHERE ticket_id = ? AND process_id = ? AND process_step_id = ? AND dynamicfield_id = ?',
        Bind  => [ \$Param{TicketID}, \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{DynamicfieldID}, ],
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}             = $Row[0];
        $Data{TicketID}       = $Row[1];
        $Data{ProcessID}      = $Row[2];
        $Data{ProcessStepID}  = $Row[3];
        $Data{DynamicfieldID} = $Row[4];
        $Data{FieldValue}     = $Row[5];
        $Data{CreateTime}     = $Row[11];
        $Data{CreateBy}       = $Row[12];
        $Data{ChangeTime}     = $Row[13];
        $Data{ChangeBy}       = $Row[14];
    }
    return %Data;
}

=head2 ProcessFieldValueGet()

get a process field value

    my %ProcessFieldValue = $TicketProcessStepValueObject->ProcessFieldValueGet(
        TicketID      => 123,
        ProcessID     => 123,
        ProcessStepID => 123,
    );

=cut

sub ProcessFieldValueGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(TicketID ProcessID ProcessStepID)) {
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
        SQL => 'SELECT id, ticket_id, process_id, process_step_id, report, title, type_id, queue_id, state_id,'
            . ' from_customer, user_id, approval, create_time, create_by, change_time, change_by'
            . ' FROM t_process_fields_value WHERE ticket_id = ? AND process_id = ? AND process_step_id = ?',
        Bind  => [ \$Param{TicketID}, \$Param{ProcessID}, \$Param{ProcessStepID}, ],
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}            = $Row[0];
        $Data{TicketID}      = $Row[1];
        $Data{ProcessID}     = $Row[2];
        $Data{ProcessStepID} = $Row[3];
        $Data{Report}        = $Row[4];
        $Data{Title}         = $Row[5];
        $Data{TypeID}        = $Row[6];
        $Data{QueueID}       = $Row[7];
        $Data{StateID}       = $Row[8];
        $Data{FromCustomer}  = $Row[9];
        $Data{User}          = $Row[10];
        $Data{Approval}      = $Row[11];
        $Data{CreateTime}    = $Row[12];
        $Data{CreateBy}      = $Row[13];
        $Data{ChangeTime}    = $Row[14];
        $Data{ChangeBy}      = $Row[15];
    }
    return %Data;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
