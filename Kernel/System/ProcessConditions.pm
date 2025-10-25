# --
# Kernel/System/ProcessConditions.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: ProcessConditions.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessConditions;

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

Kernel::System::ProcessConditions - ProcessConditions lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add ProcessConditions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $ProcessConditionsObject = $Kernel::OM->Get('Kernel::System::ProcessConditions');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 ProcessConditionsAdd()

to add a Process Conditions

    my $Success = $ProcessConditionsObject->ProcessConditionsAdd(
        ProcessID     => 123,
        ProcessStepID => 123,
        ProcessStepNo => 123,
        Title         => 1,
        Type          => 1,
        Queue         => 1,
        State         => 1,
        Service       => 1,
        SLA           => 1,
        CustomerUser  => 1,
        Owner         => 1,
        UserID        => 123,
    );

=cut

sub ProcessConditionsAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessID ProcessStepID ProcessStepNo UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !$Param{Title} ) {
        $Param{Title} = '';
    }
    if ( !$Param{Type} ) {
        $Param{Type} = 0;
    }
    if ( !$Param{Queue} ) {
        $Param{Queue} = 0;
    }
    if ( !$Param{State} ) {
        $Param{State} = 0;
    }
    if ( !$Param{Service} ) {
        $Param{Service} = 0;
    }
    if ( !$Param{SLA} ) {
        $Param{SLA} = 0;
    }
    if ( !$Param{CustomerUser} ) {
        $Param{CustomerUser} = '';
    }
    if ( !$Param{Owner} ) {
        $Param{Owner} = '';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new Equipment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO process_conditions (process_id, processstep_id, processstep_no, title, type, queue, state, service, sla, customer_user, owner,'
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{ProcessStepNo}, \$Param{Title}, \$Param{Type}, \$Param{Queue},
            \$Param{State}, \$Param{Service}, \$Param{SLA}, \$Param{CustomerUser}, \$Param{Owner},\$Param{UserID}, \$Param{UserID},
        ],
    );


    return 1;
}

=head2 ProcessConditionsGet()

get a process Conditions

    my %List = $ProcessConditionsObject->ProcessConditionsGet(
        ProcessConditionsID => 123,
    );

=cut

sub ProcessConditionsGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ProcessConditionsID)) {
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
        SQL => 'SELECT id, process_id, processstep_id, processstep_no, title, type, queue, state, service, sla, customer_user, owner, create_time, create_by, change_time, change_by '
            . 'FROM process_conditions WHERE id = ?',
        Bind  => [ \$Param{ProcessConditionsID} ],
        Limit => 1,
    );


    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}            = $Row[0];
        $Data{ProcessID}     = $Row[1];
        $Data{ProcessStepID} = $Row[2];
        $Data{ProcessStepNo} = $Row[3];
        $Data{Title}         = $Row[4];
        $Data{Type}          = $Row[5];
        $Data{Queue}         = $Row[6];
        $Data{State}         = $Row[7];
        $Data{Service}       = $Row[8];
        $Data{SLA}           = $Row[9];
        $Data{CustomerUser}  = $Row[10];
        $Data{Owner}         = $Row[11];
        $Data{CreateTime}    = $Row[12];
        $Data{CreateBy}      = $Row[13];
        $Data{ChangeTime}    = $Row[14];
        $Data{ChangeBy}      = $Row[15];
    }
    return %Data;
}

=head2 ProcessConditionsDelete()

to delete a Process Conditions

    my $Sucess = $ProcessConditionsObject->ProcessConditionsDelete(
        ProcessConditionsID => 123,
    );

=cut

sub ProcessConditionsDelete{
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ProcessConditionsID)) {
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
        SQL  => 'DELETE FROM process_conditions WHERE id = ?',
        Bind => [ \$Param{ProcessConditionsID} ],
    );

    return 1;
}


=head2 ProcessConditionsList()

returns a hash of all process Conditions

    my %ProcessConditionsList = $ProcessConditionsObject->ProcessConditionsList(
        ProcessID     => 123,
        ProcessStepID => 123,
        ProcessStepNo => 123,
    );


=cut

sub ProcessConditionsList {
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
        SQL => 'SELECT id, processstep_id FROM process_conditions WHERE process_id = ? AND processstep_id = ? AND processstep_no = ?',
        Bind => [ \$Param{ProcessID}, \$Param{ProcessStepID}, \$Param{ProcessStepNo}, ],
    );

    # fetch the result
    my %ProcessConditionsList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ProcessConditionsList{$Row[0]} = $Row[1];
    }

    return %ProcessConditionsList;
}

=head2 ProcessConditionsAllList()

returns a hash of all process Conditions

    my %ProcessConditionsList = $ProcessConditionsObject->ProcessConditionsAllList(
        ProcessID     => 123,
        ProcessStepID => 123,
    );


=cut

sub ProcessConditionsAllList {
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
        SQL => 'SELECT id, processstep_id FROM process_conditions WHERE process_id = ? AND processstep_id = ?',
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
