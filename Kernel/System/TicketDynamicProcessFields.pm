# --
# Kernel/System/TicketDynamicProcessFields.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: TicketDynamicProcessFields.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketDynamicProcessFields;

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

Kernel::System::TicketDynamicProcessFields - TicketDynamicProcessFields lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add TicketDynamicProcessFields.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketDynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::TicketDynamicProcessFields');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 DynamicProcessFieldAdd()

to add a Dynamic Process fieöd

    my $ID = $TicketDynamicProcessFieldsObject->TicketDynamicProcessFieldAdd(
        ProcessID      => 123,
        ProcessStepID  => 123,
        DynamicFieldID => 123,
        Required       => 2,
        UserID         => 123,
        TicketID       => 123,
    );

=cut

sub DynamicProcessFieldAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID DynamicFieldID UserID TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !$Param{Required} ) {
        $Param{Required} = 1;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new Equipment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO t_dynamicprocess_fields (process_id, processstep_id, dynamicfield_id, required,'
            . ' create_time, create_by, change_time, change_by, ticket_id)'
            . ' VALUES (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?)',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{DynamicFieldID}, \$Param{Required}, \$Param{UserID}, \$Param{UserID}, \$Param{TicketID},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM t_dynamicprocess_fields WHERE process_id = ? AND processstep_id = ? AND dynamicfield_id = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{DynamicFieldID}, ],
    );

    my $ProcessFieldID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessFieldID = $Row[0];
    }

    return $ProcessFieldID;
}

=head2 DynamicProcessFieldGet()

get a dynamic process field

    my %List = $DynamicProcessFieldsObject->DynamicProcessFieldGet(
        ProcessFieldID => 123,
    );

=cut

sub DynamicProcessFieldGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ProcessFieldID)) {
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
        SQL => 'SELECT id, process_id, processstep_id, dynamicfield_id, required, create_time, create_by, change_time, change_by, ticket_id '
            . 'FROM t_dynamicprocess_fields WHERE id = ?',
        Bind  => [ \$Param{ProcessFieldID} ],
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}             = $Row[0];
        $Data{ProcessID}      = $Row[1];
        $Data{ProcessStepID}  = $Row[2];
        $Data{DynamicFieldID} = $Row[3];
        $Data{Required}       = $Row[4];
        $Data{CreateTime}     = $Row[5];
        $Data{CreateBy}       = $Row[6];
        $Data{ChangeTime}     = $Row[7];
        $Data{ChangeBy}       = $Row[8];
        $Data{TicketID}       = $Row[9];
    }
    return %Data;
}

=head2 DynamicProcessFieldList()

returns a hash of all process fields

    my %DynamicProcessFieldList = $DynamicProcessFieldsObject->DynamicProcessFieldList(
        ProcessID     => 123,
        ProcessStepID => 123,
    );


=cut

sub DynamicProcessFieldList {
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
        SQL => 'SELECT id, dynamicfield_id FROM t_dynamicprocess_fields WHERE process_id = ? AND processstep_id = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, ],
    );

    # fetch the result
    my %ProcessFieldList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessFieldList{$Row[0]} = $Row[1];
    }

    return %ProcessFieldList;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
