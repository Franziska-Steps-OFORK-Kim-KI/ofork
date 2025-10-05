# --
# Kernel/System/TicketProcessesMerge.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: TicketProcessesMerge.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketProcessesMerge;

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

Kernel::System::TicketProcessesMerge - TicketProcessesMerge lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add TicketProcessesMerge.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketProcessesMergeObject = $Kernel::OM->Get('Kernel::System::TicketProcessesMerge');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessMergeAdd()

to add a Process

    my $Success = $TicketProcessesMergeObject->ProcessMergeAdd(
        OldID    => 123,
        NewID    => 123,
        TicketID => 123,
    );

=cut

sub ProcessMergeAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(OldID NewID TicketID)) {
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
        SQL => 'INSERT INTO t_process_merge (old_id, new_id, ticket_id)'
            . ' VALUES (?, ?, ?)',
        Bind => [
            \$Param{OldID}, \$Param{NewID}, \$Param{TicketID},
        ],
    );

    return 1;
}

=head2 ProcessMergeDelete()

to delete a Process Transition

    my $Sucess = $TicketProcessesMergeObject->ProcessMergeDelete(
        TicketID => 123,
    );

=cut

sub ProcessMergeDelete{
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID)) {
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
        SQL  => 'DELETE FROM t_process_merge WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    return 1;
}


=head2 ProcessMergeGet()

returns a hash with Equipment data

    my $NewID = $TicketProcessesMergeObject->ProcessMergeGet(
        OldID    => 123,
        TicketID => 123,
    );

=cut

sub ProcessMergeGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{OldID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need OldID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT new_id FROM t_process_merge WHERE old_id = ? AND ticket_id = ?',
        Bind => [
            \$Param{OldID}, \$Param{TicketID},
        ],
    );

    # fetch the result
    my $MewID = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $MewID = $Row[0];
    }

    return $MewID;

}

=head2 ProcessMergeStepNoFromUpdate()

update 

    my $Success = $TicketProcessesMergeObject->ProcessMergeStepNoFromUpdate(
        OldID         => 123,
        TicketID      => 123,
        ProcessStepID => 123,
    );

=cut

sub ProcessMergeStepNoFromUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(OldID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $NewID = $Self->ProcessMergeGet(
        OldID    => $Param{OldID},
        TicketID => $Param{TicketID},
    );

    # Update system address.
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE t_process_step SET step_no_from = ? WHERE id = ?',
        Bind => [
            \$NewID, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessMergeToIDFromOneUpdate()

update 

    my $Success = $TicketProcessesMergeObject->ProcessMergeToIDFromOneUpdate(
        OldID         => 123,
        TicketID      => 123,
        ProcessStepID => 123,
    );

=cut

sub ProcessMergeToIDFromOneUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(OldID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $NewID = $Self->ProcessMergeGet(
        OldID    => $Param{OldID},
        TicketID => $Param{TicketID},
    );

    # Update system address.
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE t_process_step SET to_id_from_one = ? WHERE id = ?',
        Bind => [
            \$NewID, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

=head2 ProcessMergeToIDFromTwoUpdate()

update 

    my $Success = $TicketProcessesMergeObject->ProcessMergeToIDFromTwoUpdate(
        OldID         => 123,
        TicketID      => 123,
        ProcessStepID => 123,
    );

=cut

sub ProcessMergeToIDFromTwoUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(OldID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $NewID = $Self->ProcessMergeGet(
        OldID    => $Param{OldID},
        TicketID => $Param{TicketID},
    );

    # Update system address.
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE t_process_step SET to_id_from_two = ? WHERE id = ?',
        Bind => [
            \$NewID, \$Param{ProcessStepID},
        ],
    );

    return 1;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
