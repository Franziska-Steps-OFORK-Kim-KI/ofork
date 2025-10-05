# --
# Kernel/System/ChecklistField.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: ChecklistField.pm,v 1.5 2016/11/20 19:30:55 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ChecklistField;

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

Kernel::System::ChecklistField - ChecklistField lib

=head1 SYNOPSIS

All Antrag functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ChecklistFieldObject = $Kernel::OM->Get('Kernel::System::ChecklistField');

    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item ChecklistFieldList()

return a hash list of Antrag

    my %ChecklistFieldList = $ChecklistFieldObject->ChecklistFieldList(
        ChecklistID => 123,
    );

=cut

sub ChecklistFieldList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ChecklistID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ChecklistID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, fieldorder FROM checklist_field WHERE checklist_id = ? ORDER BY fieldorder',
        Bind => [ \$Param{ChecklistID} ],
    );

    # fetch the result
    my %ChecklistFieldList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ChecklistFieldList{ $Row[0] } = $Row[1];
    }

    return %ChecklistFieldList;
}

=item ChecklistFieldGet()

get ChecklistField attributes

    my %ChecklistField = $ChecklistFieldObject->ChecklistFieldGet(
        ChecklistFieldID => 123,
    );

=cut

sub ChecklistFieldGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ChecklistFieldID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need ChecklistFieldID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, checklist_id, task, field_type, fieldorder, create_time, create_by, change_time, change_by '
            . 'FROM checklist_field WHERE id = ?',
        Bind => [ \$Param{ChecklistFieldID} ],
    );
    my %ChecklistField;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %ChecklistField = (
            ID          => $Data[0],
            ChecklistID => $Data[1],
            Task        => $Data[2],
            FieldType   => $Data[3],
            Order       => $Data[4],
            CreateTime  => $Data[5],
            CreateBy    => $Data[6],
            ChangeTime  => $Data[7],
            ChangeBy    => $Data[8],
        );
    }

    # return result
    return %ChecklistField;
}

=item ChecklistFieldUpdate()

update ChecklistField

    my $ChecklistFieldID = $ChecklistFieldObject->ChecklistFieldUpdate(
        ID          => 123,
        ChecklistID => 123,
        Task        => 'FieldName',
        FieldType   => 'Headline',
        Order       => 12,
        UserID      => 123,
    );

=cut

sub ChecklistFieldUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ID ChecklistID Task Order UserID)) {
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
            'UPDATE checklist_field SET checklist_id = ?, task = ?, field_type = ?, fieldorder = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{ChecklistID}, \$Param{Task}, \$Param{FieldType}, \$Param{Order},\$Param{UserID}, \$Param{ID},
        ],
    );

    return 1;
}

=item ChecklistFieldAdd()

add ChecklistField

    my $ChecklistFieldID = $ChecklistFieldObject->ChecklistFieldAdd(
        ChecklistID => 123,
        Task        => 'UserName',
        FieldType   => 'Headline',
        Order       => 12,
        UserID      => 123,
    );

=cut

sub ChecklistFieldAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ChecklistID Task Order FieldType UserID)) {
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

    # find existing service
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM checklist_field WHERE task = ?',
        Bind  => [ \$Param{Task} ],
        Limit => 1,
    );
    my $Exists;
    while ( $DBObject->FetchrowArray() ) {
        $Exists = 1;
    }

    # add service to database
    if ($Exists) {
        return 'Exists';
    }

    return if !$DBObject->Do(
        SQL => 'INSERT INTO checklist_field '
            . '(checklist_id, task, fieldorder, field_type, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ChecklistID}, \$Param{Task}, \$Param{Order}, \$Param{FieldType}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get ChecklistField id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM checklist_field WHERE task = ?',
        Bind  => [ \$Param{Task} ],
        Limit => 1,
    );
    my $ChecklistFieldID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ChecklistFieldID = $Row[0];
    }

    return $ChecklistFieldID;
}

=item ChecklistFieldDelete()

get Antrag attributes

    my $Success = $ChecklistFieldObject->ChecklistFieldDelete(
        ChecklistFieldID => 123,
    );

=cut

sub ChecklistFieldDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ChecklistFieldID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need ChecklistFieldID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL  => 'DELETE FROM checklist_field WHERE id = ? ',
        Bind => [ \$Param{ChecklistFieldID}, ],
    );

    return 1;
}

=item ChecklistFieldLastOrder()

return last number "Order"

    my $LastOrder = $RequestFormObject->ChecklistFieldLastOrder(
        ChecklistID = 123,
    );

=cut

sub ChecklistFieldLastOrder {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "SELECT id, fieldorder FROM checklist_field WHERE fieldorder = (SELECT MAX(fieldorder) from checklist_field WHERE checklist_id = $Param{ChecklistID})",
    );

    # fetch the result
    my $LastOrder;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $LastOrder = $Row[1];
    }

    return $LastOrder;
}

=item ChecklistOrderUpdate()

update a Checklist

    my $Success = $ChecklistFormObject->ChecklistOrderUpdate(
        ChecklistID => 123,
        Order         => 1,
        UserID        => 123,
    );

=cut

sub ChecklistOrderUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(ChecklistID Order UserID)
        )
    {
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

    # update RequestForm
    return if !$DBObject->Do(
        SQL  => 'UPDATE checklist_field SET fieldorder = ? WHERE id = ?',
        Bind => [
            \$Param{Order}, \$Param{ChecklistID},
        ],
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
