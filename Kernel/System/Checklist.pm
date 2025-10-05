# --
# Kernel/System/Checklist.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: Checklist.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Checklist;

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

Kernel::System::Checklist - Checklist lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ChecklistObject = $Kernel::OM->Get('Kernel::System::Checklist');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item ChecklistList()

return a hash list of Request

    my %ChecklistList = $ChecklistObject->ChecklistList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub ChecklistList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 0;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( !$Param{Valid} ) {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, name FROM checklist",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, name FROM checklist WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )",
        );
    }

    # fetch the result
    my %ChecklistList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ChecklistList{ $Row[0] } = $Row[1];
    }

    return %ChecklistList;
}

=item ChecklistGet()

get Checklist attributes

    my %Checklist = $ChecklistObject->ChecklistGet(
        ChecklistID => 123,
    );

=cut

sub ChecklistGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ChecklistID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need ChecklistID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, name, queue_ids, type_ids, service_ids, set_article, valid_id, comment, create_time, create_by, change_time, change_by '
            . 'FROM checklist WHERE id = ?',
        Bind => [ \$Param{ChecklistID} ],
    );
    my %Checklist;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Checklist = (
            ChecklistID => $Data[0],
            Name        => $Data[1],
            QueueIDs    => $Data[2],
            TypeIDs     => $Data[3],
            ServiceIDs  => $Data[4],
            SetArticle  => $Data[5],
            ValidID     => $Data[6],
            Comment     => $Data[7],
            CreateTime  => $Data[8],
            CreateBy    => $Data[9],
            ChangeTime  => $Data[10],
            ChangeBy    => $Data[11],
        );
    }

    # return result
    return %Checklist;
}

=item ChecklistUpdate()

update a Checklist

    my $ChecklistID = $ChecklistObject->ChecklistUpdate(
        ChecklistID => 123,
        Name        => 'Checklist',
        QueueIDs    => 123,
        TypeIDs     => 123,
        ServiceIDs  => 123,
        SetArticle  => 1,
        ValidID     => 1,
        Comment     => 'Checklist',
        UserID      => 123,
    );

=cut

sub ChecklistUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ChecklistID Name ValidID UserID)) {
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

    # update ChangeCategories
    return if !$DBObject->Do(
        SQL =>
            'UPDATE checklist SET name = ?, queue_ids = ?, type_ids = ?, service_ids = ?, set_article = ?, '
            . 'valid_id = ?, comment = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{QueueIDs}, \$Param{TypeIDs}, \$Param{ServiceIDs}, \$Param{SetArticle},
            \$Param{ValidID}, \$Param{Comment}, \$Param{UserID}, \$Param{ChecklistID},
        ],
    );

    return 1;
}

=item ChecklistAdd()

add a Checklist

    my $ChecklistID = $ChecklistObject->ChecklistAdd(
        Name       => 'Checklist',
        QueueID    => 123,
        TypeID     => 123,
        ServiceID  => 123,
        QueueIDs   => 123,
        TypeIDs    => 123,
        ServiceIDs => 123,
        SetArticle => 1,
        ValidID    => 1,
        Comment    => 'Checklist',
        UserID     => 123,
    );

=cut

sub ChecklistAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name ValidID UserID)) {
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
        SQL   => 'SELECT id FROM checklist WHERE name = ?',
        Bind  => [ \$Param{Name} ],
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
        SQL => 'INSERT INTO checklist '
            . '(name, queue_id, type_id, service_id, queue_ids, type_ids, service_ids, set_article, valid_id, comment, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{QueueID}, \$Param{TypeID}, \$Param{ServiceID}, \$Param{QueueIDs}, \$Param{TypeIDs}, \$Param{ServiceIDs},
            \$Param{SetArticle}, \$Param{ValidID}, \$Param{Comment}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Request id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM checklist WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );
    my $ChecklistID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ChecklistID = $Row[0];
    }

    return $ChecklistID;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
