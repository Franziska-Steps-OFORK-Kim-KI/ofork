# --
# Kernel/System/ProcessFields.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: ProcessFields.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessFields;

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

Kernel::System::ProcessFields - ProcessFields lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add ProcessFields.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $ProcessFieldsObject = $Kernel::OM->Get('Kernel::System::ProcessFields');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessFieldAdd()

to add a Process fieöd

    my $ID = $ProcessFieldsObject->ProcessFieldAdd(
        ProcessID     => 123,
        ProcessStepID => 123,
        FieldID       => 1,
        Required      => 1,
        Sequence      => 1,
        UserID        => 123,
    );

=cut

sub ProcessFieldAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID Required FieldID UserID)) {
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

    my %ProcessFieldList = $Self->ProcessFieldList(
        ProcessID     => $Param{ProcessID},
        ProcessStepID => $Param{ProcessStepID},
    );

    if ( !%ProcessFieldList ) {
        $Param{Sequence} = 1;
    }
    else {

        my @SequenceNum;
        for my $ProcessListID ( keys %ProcessFieldList ) {

            my %ProcessList = $Self->ProcessFieldGet(
                ProcessFieldID => $ProcessListID,
            );
            push @SequenceNum, $ProcessList{Sequence};
        }

        @SequenceNum = sort @SequenceNum;
        my $SequenceZahl = (sort{$a <=> $b} @SequenceNum)[-1];
        $SequenceZahl = $SequenceZahl + 1;
        $Param{Sequence} = $SequenceZahl;
    }

    # insert new Equipment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO process_fields (process_id, processstep_id, field_id, required, sequence,'
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{FieldID}, \$Param{Required}, \$Param{Sequence}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM process_fields WHERE process_id = ? AND processstep_id = ? AND field_id = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{FieldID}, ],
    );

    my $ProcessFieldID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessFieldID = $Row[0];
    }

    return $ProcessFieldID;
}

=head2 ProcessFieldGet()

get a process field

    my %List = $ProcessFieldsObject->ProcessFieldGet(
        ProcessFieldID => 123,
    );

=cut

sub ProcessFieldGet {
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
        SQL => 'SELECT id, process_id, processstep_id, field_id, required, sequence, create_time, create_by, change_time, change_by '
            . 'FROM process_fields WHERE id = ?',
        Bind  => [ \$Param{ProcessFieldID} ],
        Limit => 1,
    );


    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}            = $Row[0];
        $Data{ProcessID}     = $Row[1];
        $Data{ProcessStepID} = $Row[2];
        $Data{FieldID}       = $Row[3];
        $Data{Required}      = $Row[4];
        $Data{Sequence}      = $Row[5];
        $Data{CreateTime}    = $Row[6];
        $Data{CreateBy}      = $Row[7];
        $Data{ChangeTime}    = $Row[8];
        $Data{ChangeBy}      = $Row[9];
    }
    return %Data;
}

=head2 ProcessFieldDelete()

to delete a Process fieöd

    my $Sucess = $ProcessFieldsObject->ProcessFieldDelete(
        ProcessFieldID => 123,
    );

=cut

sub ProcessFieldDelete{
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessFieldID)) {
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
        SQL  => 'DELETE FROM process_fields WHERE id = ?',
        Bind => [ \$Param{ProcessFieldID} ],
    );

    return 1;
}


=head2 ProcessFieldList()

returns a hash of all process fields

    my %ProcessFieldList = $ProcessFieldsObject->ProcessFieldList(
        ProcessID     => 123,
        ProcessStepID => 123,
    );


=cut

sub ProcessFieldList {
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
        SQL => 'SELECT id, field_id, sequence FROM process_fields WHERE process_id = ? AND processstep_id = ? order by sequence DESC',
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
