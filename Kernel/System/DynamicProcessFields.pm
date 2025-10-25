# --
# Kernel/System/DynamicProcessFields.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: DynamicProcessFields.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicProcessFields;

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

Kernel::System::DynamicProcessFields - DynamicProcessFields lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add DynamicProcessFields.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');

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

    my $ID = $DynamicProcessFieldsObject->DynamicProcessFieldAdd(
        ProcessID      => 123,
        ProcessStepID  => 123,
        DynamicFieldID => 123,
        Required       => 2,
        UserID         => 123,
    );

=cut

sub DynamicProcessFieldAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID DynamicFieldID UserID)) {
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
        SQL => 'INSERT INTO dynamicprocess_fields (process_id, processstep_id, dynamicfield_id, required,'
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{DynamicFieldID}, \$Param{Required}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM dynamicprocess_fields WHERE process_id = ? AND processstep_id = ? AND dynamicfield_id = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{DynamicFieldID}, ],
    );

    my $ProcessFieldID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessFieldID = $Row[0];
    }

    return $ProcessFieldID;
}

=head2 DynamicProcessFieldDelete()

to delete a Process fieöd

    my $Sucess = $DynamicProcessFieldsObject->DynamicProcessFieldDelete(
        DynamicFieldID => 123,
    );

=cut

sub DynamicProcessFieldDelete{
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(DynamicFieldID)) {
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
        SQL  => 'DELETE FROM dynamicprocess_fields WHERE id = ?',
        Bind => [ \$Param{DynamicFieldID} ],
    );

    return 1;
}

=head2 DynamicProcessFieldGet()

get a dynamic process field

    my %Data = $DynamicProcessFieldsObject->DynamicProcessFieldGet(
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
        SQL => 'SELECT id, process_id, processstep_id, dynamicfield_id, required, create_time, create_by, change_time, change_by '
            . 'FROM dynamicprocess_fields WHERE id = ?',
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
        SQL => 'SELECT id, dynamicfield_id FROM dynamicprocess_fields WHERE process_id = ? AND processstep_id = ?',
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
