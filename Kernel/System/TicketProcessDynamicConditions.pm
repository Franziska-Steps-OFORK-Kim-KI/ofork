# --
# Kernel/System/TicketProcessDynamicConditions.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: TicketProcessDynamicConditions.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketProcessDynamicConditions;

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

Kernel::System::TicketProcessDynamicConditions - TicketProcessDynamicConditions lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add TicketProcessDynamicConditions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketProcessDynamicConditionsObject = $Kernel::OM->Get('Kernel::System::TicketProcessDynamicConditions');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessDynamicConditionsAdd()

to add a Process Conditions

    my $Success = $TicketProcessDynamicConditionsObject->ProcessDynamicConditionsAdd(
        ProcessID      => 123,
        ProcessStepID  => 123,
        DynamicFieldID => 123,
        DynamicValue   => 1,
        TicketID       => 123,
        UserID         => 123,
    );

=cut

sub ProcessDynamicConditionsAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID DynamicFieldID DynamicValue TicketID UserID)) {
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
        SQL => 'INSERT INTO t_process_d_conditions (process_id, processstep_id, dynamicfield_id, dynamicfield_value, ticket_id,'
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{DynamicFieldID}, \$Param{DynamicValue}, \$Param{TicketID}, \$Param{UserID}, \$Param{UserID},
        ],
    );


    return 1;
}

=head2 ProcessDynamicConditionsGet()

get a process Conditions

    my %DynamicConditions = $TicketProcessDynamicConditionsObject->ProcessDynamicConditionsGet(
        DynamicConditionsID => 123,
    );

=cut

sub ProcessDynamicConditionsGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(DynamicConditionsID)) {
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
        SQL => 'SELECT id, process_id, processstep_id, dynamicfield_id, dynamicfield_value, ticket_id, create_time, create_by, change_time, change_by '
            . 'FROM t_process_d_conditions WHERE id = ?',
        Bind  => [ \$Param{DynamicConditionsID} ],
        Limit => 1,
    );


    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}             = $Row[0];
        $Data{ProcessID}      = $Row[1];
        $Data{ProcessStepID}  = $Row[2];
        $Data{DynamicFieldID} = $Row[3];
        $Data{DynamicValue}   = $Row[4];
        $Data{TicketID}       = $Row[5];
        $Data{CreateTime}     = $Row[6];
        $Data{CreateBy}       = $Row[7];
        $Data{ChangeTime}     = $Row[8];
        $Data{ChangeBy}       = $Row[9];
    }
    return %Data;
}

=head2 ProcessDynamicConditionsList()

returns a hash of all process Conditions

    my %ProcessConditionsList = $TicketProcessDynamicConditionsObject->ProcessDynamicConditionsList(
        ProcessID     => 123,
        ProcessStepID => 123,
    );


=cut

sub ProcessDynamicConditionsList {
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
        SQL => 'SELECT id, dynamicfield_id FROM t_process_d_conditions WHERE process_id = ? AND processstep_id = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, ],
    );

    # fetch the result
    my %ProcessConditionsList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessConditionsList{$Row[0]} = $Row[1];
    }

    return %ProcessConditionsList;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
