# --
# scripts/DBUpdateTo11/UpdateNotificationTables.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: UpdateNotificationTables.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --

package scripts::DBUpdateTo11::UpdateNotificationTables;

use strict;
use warnings;
use utf8;

use parent qw(scripts::DBUpdateTo11::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

=head1 NAME

scripts::DBUpdateTo11::UpdateNotificationTables - perform updates for notification tables

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $Verbose = $Param{CommandlineOptions}->{Verbose} || 0;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    $DBObject->Prepare(
        SQL   => "SELECT id, subject FROM notification_event_message",
        Limit => 10000,
    );

    my %OldInserts;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $OldInserts{$Row[0]} = $Row[1];
    }

    my $NewSubject = '';
    for my $InsertsID ( keys %OldInserts ) {

        $NewSubject = $OldInserts{$InsertsID};
        $NewSubject =~ s/OTRS_/OFORK_/g;

        return if !$DBObject->Do(
            SQL => 'UPDATE notification_event_message SET subject = ? WHERE id = ?',
            Bind => [ \$NewSubject, \$InsertsID, ],
        );

    }

    $DBObject->Prepare(
        SQL   => "SELECT id, text FROM notification_event_message",
        Limit => 10000,
    );

    my %OldInsertsText;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $OldInsertsText{$Row[0]} = $Row[1];
    }

    my $NewText = '';
    for my $InsertsTextID ( keys %OldInsertsText ) {

        $NewText = $OldInsertsText{$InsertsTextID};
        $NewText =~ s/OTRS_/OFORK_/g;

        return if !$DBObject->Do(
            SQL => 'UPDATE notification_event_message SET text = ? WHERE id = ?',
            Bind => [ \$NewText, \$InsertsTextID, ],
        );

    }

    $DBObject->Prepare(
        SQL   => "SELECT id, text FROM salutation",
        Limit => 10000,
    );

    my %OldSalutationText;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $OldSalutationText{$Row[0]} = $Row[1];
    }

    my $NewSalutationText = '';
    for my $InsertsSalutationTextID ( keys %OldSalutationText ) {

        $NewSalutationText = $OldSalutationText{$InsertsSalutationTextID};
        $NewSalutationText =~ s/OTRS_/OFORK_/g;

        return if !$DBObject->Do(
            SQL => 'UPDATE salutation SET text = ? WHERE id = ?',
            Bind => [ \$NewSalutationText, \$InsertsSalutationTextID, ],
        );

    }

    $DBObject->Prepare(
        SQL   => "SELECT id, text FROM signature",
        Limit => 10000,
    );

    my %OldSignatureText;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $OldSignatureText{$Row[0]} = $Row[1];
    }

    my $NewSignatureText = '';
    for my $InsertsSignatureTextID ( keys %OldSignatureText ) {

        $NewSignatureText = $OldSignatureText{$InsertsSignatureTextID};
        $NewSignatureText =~ s/OTRS_/OFORK_/g;

        return if !$DBObject->Do(
            SQL => 'UPDATE signature SET text = ? WHERE id = ?',
            Bind => [ \$NewSignatureText, \$InsertsSignatureTextID, ],
        );

    }

    $DBObject->Prepare(
        SQL   => "SELECT id, text FROM standard_template",
        Limit => 10000,
    );

    my %OldTemplateText;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $OldTemplateText{$Row[0]} = $Row[1];
    }

    my $NewTemplateText = '';
    for my $InsertsTemplateTextID ( keys %OldTemplateText ) {

        $NewTemplateText = $OldTemplateText{$InsertsTemplateTextID};
        $NewTemplateText =~ s/OTRS_/OFORK_/g;

        return if !$DBObject->Do(
            SQL => 'UPDATE standard_template SET text = ? WHERE id = ?',
            Bind => [ \$NewTemplateText, \$InsertsTemplateTextID, ],
        );

    }

    $DBObject->Prepare(
        SQL   => "SELECT id, text0 FROM auto_response",
        Limit => 10000,
    );

    my %OldResponseInserts;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $OldResponseInserts{$Row[0]} = $Row[1];
    }

    my $NewResponseSubject = '';
    for my $InsertsResponseID ( keys %OldResponseInserts ) {

        $NewResponseSubject = $OldResponseInserts{$InsertsResponseID};
        $NewResponseSubject =~ s/OTRS_/OFORK_/g;

        return if !$DBObject->Do(
            SQL => 'UPDATE auto_response SET text0 = ? WHERE id = ?',
            Bind => [ \$NewResponseSubject, \$InsertsResponseID, ],
        );

    }

    $DBObject->Prepare(
        SQL   => "SELECT id, text1 FROM auto_response",
        Limit => 10000,
    );

    my %OldResponseInsertsText;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $OldResponseInsertsText{$Row[0]} = $Row[1];
    }

    my $NewResponseText = '';
    for my $InsertsResponseTextID ( keys %OldResponseInsertsText ) {

        $NewResponseText = $OldResponseInsertsText{$InsertsResponseTextID};
        $NewResponseText =~ s/OTRS_/OFORK_/g;

        return if !$DBObject->Do(
            SQL => 'UPDATE auto_response SET text1 = ? WHERE id = ?',
            Bind => [ \$NewResponseText, \$InsertsResponseTextID, ],
        );

    }

    my $TypeName    = 'RoomBooking';
    my $TypeValidID = '1';
    my $TypeUserID  = '1';
    $DBObject->Prepare(
        SQL   => "SELECT id FROM ticket_type WHERE name LIKE '%" . $TypeName . "%'",
        Limit => 1,
    );
    my $IfTicketTypeID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $IfTicketTypeID = $Row[0];
    }
    if ( $IfTicketTypeID == 0 ) {
        return if !$DBObject->Do(
            SQL => 'INSERT INTO ticket_type (name, valid_id, '
                . ' create_time, create_by, change_time, change_by)'
                . ' VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [ \$TypeName, \$TypeValidID, \$TypeUserID, \$TypeUserID ],
        );
    }

    my $GroupName    = 'RoomBooking';
    my $GroupValidID = '1';
    my $GroupUserID  = '1';
    my $GroupComment = 'Group for room booking access.';
    $DBObject->Prepare(
        SQL => "SELECT id FROM groups WHERE name LIKE '%" . $GroupName . "%'",
        Limit => 1,
    );
    my $IfGroupID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $IfGroupID = $Row[0];
    }
    if ( $IfGroupID == 0 ) {
        return if !$DBObject->Do(
            SQL => 'INSERT INTO groups (name, comments, valid_id, '
                . ' create_time, create_by, change_time, change_by)'
                . ' VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$GroupName, \$GroupComment, \$GroupValidID, \$GroupUserID, \$GroupUserID,
            ],
        );
    }

    my $TimeTrackingGroupName    = 'TimeTracking';
    my $TimeTrackingGroupValidID = '1';
    my $TimeTrackingGroupUserID  = '1';
    my $TimeTrackingGroupComment = 'Group for room TimeTracking access.';
    $DBObject->Prepare(
        SQL => "SELECT id FROM groups WHERE name LIKE '%" . $TimeTrackingGroupName . "%'",
        Limit => 1,
    );
    my $IfTimeTrackingGroupID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $IfTimeTrackingGroupID = $Row[0];
    }
    if ( $IfTimeTrackingGroupID == 0 ) {
        return if !$DBObject->Do(
            SQL => 'INSERT INTO groups (name, comments, valid_id, '
                . ' create_time, create_by, change_time, change_by)'
                . ' VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$TimeTrackingGroupName, \$TimeTrackingGroupComment, \$TimeTrackingGroupValidID, \$TimeTrackingGroupUserID, \$TimeTrackingGroupUserID,
            ],
        );
    }

    my $TimeTrackingEvaluationGroupName    = 'TimeTrackingEvaluation';
    my $TimeTrackingEvaluationGroupValidID = '1';
    my $TimeTrackingEvaluationGroupUserID  = '1';
    my $TimeTrackingEvaluationGroupComment = 'Group for room TimeTrackingEvaluation access.';
    $DBObject->Prepare(
        SQL => "SELECT id FROM groups WHERE name LIKE '%" . $TimeTrackingEvaluationGroupName . "%'",
        Limit => 1,
    );
    my $IfTimeTrackingEvaluationGroupID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $IfTimeTrackingEvaluationGroupID = $Row[0];
    }
    if ( $IfTimeTrackingEvaluationGroupID == 0 ) {
        return if !$DBObject->Do(
            SQL => 'INSERT INTO groups (name, comments, valid_id, '
                . ' create_time, create_by, change_time, change_by)'
                . ' VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$TimeTrackingEvaluationGroupName, \$TimeTrackingEvaluationGroupComment, \$TimeTrackingEvaluationGroupValidID, \$TimeTrackingEvaluationGroupUserID, \$TimeTrackingEvaluationGroupUserID,
            ],
        );
    }

    my $ProcessManagerGroupName    = 'ProcessManager';
    my $ProcessManagerGroupValidID = '1';
    my $ProcessManagerGroupUserID  = '1';
    my $ProcessManagerGroupComment = 'Group for room ProcessManager access.';
    $DBObject->Prepare(
        SQL => "SELECT id FROM groups WHERE name LIKE '%" . $ProcessManagerGroupName . "%'",
        Limit => 1,
    );
    my $IfProcessManagerGroupID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $IfProcessManagerGroupID = $Row[0];
    }
    if ( $IfProcessManagerGroupID == 0 ) {
        return if !$DBObject->Do(
            SQL => 'INSERT INTO groups (name, comments, valid_id, '
                . ' create_time, create_by, change_time, change_by)'
                . ' VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$ProcessManagerGroupName, \$ProcessManagerGroupComment, \$ProcessManagerGroupValidID, \$ProcessManagerGroupUserID, \$ProcessManagerGroupUserID,
            ],
        );
    }

    my $ContractManagerGroupName    = 'ContractManager';
    my $ContractManagerGroupValidID = '1';
    my $ContractManagerGroupUserID  = '1';
    my $ContractManagerGroupComment = 'Group for contract manager access.';
    $DBObject->Prepare(
        SQL => "SELECT id FROM groups WHERE name LIKE '%" . $ContractManagerGroupName . "%'",
        Limit => 1,
    );
    my $IfContractManagerGroupID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $IfContractManagerGroupID = $Row[0];
    }
    if ( $IfContractManagerGroupID == 0 ) {
        return if !$DBObject->Do(
            SQL => 'INSERT INTO groups (name, comments, valid_id, '
                . ' create_time, create_by, change_time, change_by)'
                . ' VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$ContractManagerGroupName, \$ContractManagerGroupComment, \$ContractManagerGroupValidID, \$ContractManagerGroupUserID, \$ContractManagerGroupUserID,
            ],
        );
    }

    my $StatsName   = 'Stats';
    my $ContentName = 'otrs_';
    return if !$DBObject->Do(
        SQL  => "DELETE FROM xml_storage WHERE xml_type LIKE '%" . $StatsName . "%' AND xml_content_key LIKE '%" . $ContentName . "%'",
    );

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
