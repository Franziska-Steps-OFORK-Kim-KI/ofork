# --
# Kernel/System/ChecklistFieldValue.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: ChecklistFieldValue.pm,v 1.5 2016/11/20 19:30:55 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ChecklistFieldValue;

use strict;
use warnings;

use base qw(Kernel::System::EventHandler);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SysConfig',
    'Kernel::System::Time',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::ChecklistFieldValue - ChecklistFieldValue lib

=head1 SYNOPSIS

All Antrag functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ChecklistFieldValueObject = $Kernel::OM->Get('Kernel::System::ChecklistFieldValue');

    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item ChecklistFieldValueList()

return a hash list of Antrag

    my %ChecklistFieldValueList = $ChecklistFieldValueObject->ChecklistFieldValueList(
        ChecklistID => 123,
        TicketID    => 123,
    );

=cut

sub ChecklistFieldValueList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ChecklistID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ChecklistID!',
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

    # sql
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, fieldorder FROM checklist_field_value WHERE checklist_id = ? AND ticket_id = ? ORDER BY fieldorder',
        Bind => [ \$Param{ChecklistID}, \$Param{TicketID} ],
    );

    # fetch the result
    my %ChecklistFieldValueList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ChecklistFieldValueList{ $Row[0] } = $Row[1];
    }

    return %ChecklistFieldValueList;
}

=item ChecklistFieldValueGet()

get ChecklistFieldValue attributes

    my %ChecklistFieldValue = $ChecklistFieldValueObject->ChecklistFieldValueGet(
        ChecklistFieldValueID => 123,
    );

=cut

sub ChecklistFieldValueGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ChecklistFieldValueID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need ChecklistFieldValueID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, checklist_id, ticket_id, task, field_type, fieldorder, if_set, create_time, create_by, change_time, change_by '
            . 'FROM checklist_field_value WHERE id = ?',
        Bind => [ \$Param{ChecklistFieldValueID} ],
    );
    my %ChecklistFieldValue;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %ChecklistFieldValue = (
            ID          => $Data[0],
            ChecklistID => $Data[1],
            TicketID    => $Data[2],
            Task        => $Data[3],
            FieldType   => $Data[4],
            Order       => $Data[5],
            IfSet       => $Data[6],
            CreateTime  => $Data[7],
            CreateBy    => $Data[8],
            ChangeTime  => $Data[9],
            ChangeBy    => $Data[10],
        );
    }

    # return result
    return %ChecklistFieldValue;
}

=item ChecklistFieldValueUpdate()

update ChecklistFieldValue

    my $ChecklistFieldValueID = $ChecklistFieldValueObject->ChecklistFieldValueUpdate(
        ChecklistFieldValueID => 123,
        IfSet                 => 1,
        UserID                => 123,
    );

=cut

sub ChecklistFieldValueUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw( ChecklistFieldValueID IfSet UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update
    return if !$DBObject->Do(
        SQL =>
            'UPDATE checklist_field_value SET if_set = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{IfSet}, \$Param{UserID}, \$Param{ChecklistFieldValueID},
        ],
    );

    return 1;
}

=item ChecklistFieldValueAdd()

add ChecklistFieldValue

    my $ChecklistFieldValueID = $ChecklistFieldValueObject->ChecklistFieldValueAdd(
        ChecklistID => 123,
        TicketID    => 123,
        Task        => 'UserName',
        FieldType   => 'Headline',
        Order       => 12,
        UserID      => 123,
    );

=cut

sub ChecklistFieldValueAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ChecklistID Task Order UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO checklist_field_value '
            . '(checklist_id, ticket_id, task, field_type, fieldorder, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ChecklistID}, \$Param{TicketID}, \$Param{Task}, \$Param{FieldType}, \$Param{Order}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get ChecklistField id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM checklist_field_value WHERE task = ?',
        Bind  => [ \$Param{Task} ],
        Limit => 1,
    );
    my $ChecklistFieldID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ChecklistFieldID = $Row[0];
    }

    return $ChecklistFieldID;
}

=head2 ChecklistFieldValueDelete()

delete

    $ChecklistFieldValueObject->ChecklistFieldValueDelete(
        TicketID => 123,
    );

=cut

sub ChecklistFieldValueDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(TicketID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM checklist_field_value WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
