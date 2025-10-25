# --
# Kernel/System/Request.pm - all service function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: Request.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Request;

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

Kernel::System::Request - Request lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $RequestObject = $Kernel::OM->Get('Kernel::System::Request');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item RequestList()

return a hash list of Request

    my %RequestList = $RequestObject->RequestList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub RequestList {
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
            SQL => "SELECT id, name FROM request",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, name FROM request WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )",
        );
    }

    # fetch the result
    my %RequestList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestList{ $Row[0] } = $Row[1];
    }

    return %RequestList;
}

=item RequestGet()

get Request attributes

    my %Request = $RequestObject->RequestGet(
        RequestID => 123,
    );

=cut

sub RequestGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need RequestID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, name, subject, subject_changeable, comment, queue_id, ticket_owner, ticket_responsible, valid_id, image_id, show_configitem, show_configitems, create_time, create_by, change_time, change_by, type_id, show_attachment, request_group, process_id '
            . 'FROM request WHERE id = ?',
        Bind => [ \$Param{RequestID} ],
    );
    my %Request;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Request = (
            RequestID         => $Data[0],
            Name              => $Data[1],
            Subject           => $Data[2],
            SubjectChangeable => $Data[3],
            Comment           => $Data[4],
            Queue             => $Data[5],
            OwnerID           => $Data[6],
            ResponsibleID     => $Data[7],
            ValidID           => $Data[8],
            ImageID           => $Data[9],
            ShowConfigItem    => $Data[10],
            ShowConfigItems   => $Data[11],
            CreateTime        => $Data[12],
            CreateBy          => $Data[13],
            ChangeTime        => $Data[14],
            ChangeBy          => $Data[15],
            Type              => $Data[16],
            ShowAttachment    => $Data[17],
            RequestGroup      => $Data[18],
            ProcessID         => $Data[19],
        );
    }

    # return result
    return %Request;
}

=item RequestUpdate()

update a Request

    my $RequestID = $RequestObject->RequestUpdate(
        RequestID         => 123,
        Name              => 'Request',
        Subject           => 'Subject'
        SubjectChangeable => 1,
        Queue             => 1,
        Type              => 1,
        OwnerID           => 1,
        ResponsibleID     => 1,
        ValidID           => 1,
        ProcessID         => 1,
        Comment           => Request,
        ImageID           => 1,
        ShowConfigItem    => 2,
        ShowConfigItems   => 2,3,4
        Comment           => Request,
        ShowAttachment    => 1,
        RequestGroup      => 1,
        UserID            => 123,
    );

=cut

sub RequestUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(RequestID Name Subject ValidID UserID)) {
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
            'UPDATE request SET name = ?, subject = ?, subject_changeable = ?, comment = ?, '
            . 'ticket_owner = ?, ticket_responsible = ?,  show_attachment = ?, queue_id = ?, type_id = ?, image_id = ?, show_configitem = ?, request_group = ?, '
            . 'show_configitems = ?, valid_id = ?, process_id = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Subject}, \$Param{SubjectChangeable}, \$Param{Comment},
            \$Param{OwnerID}, \$Param{ResponsibleID}, \$Param{ShowAttachment}, \$Param{Queue}, \$Param{Type},
            \$Param{ImageID}, \$Param{ShowConfigItem}, \$Param{RequestGroup}, \$Param{ShowConfigItems},
            \$Param{ValidID}, \$Param{ProcessID}, \$Param{UserID}, \$Param{RequestID},
        ],
    );

    return 1;
}

=item RequestAdd()

add a Request

    my $RequestID = $RequestObject->RequestAdd(
        Name              => 'Request',
        Subject           => 'Subject'
        SubjectChangeable => 1,
        Queue             => 1,
        Type              => 1,
        OwnerID           => 1,
        ResponsibleID     => 1,
        ValidID           => 1,
        ProcessID         => 1,
        Comment           => Request,
        ImageID           => 1,
        ShowConfigItem    => 2,
        ShowConfigItems   => 2,3,4
        ShowAttachment    => 1,
        RequestGroup      => 1,
        UserID            => 123,
    );

=cut

sub RequestAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name Subject ValidID UserID)) {
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
        SQL   => 'SELECT id FROM request WHERE name = ?',
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
        SQL => 'INSERT INTO request '
            . '(name, subject, subject_changeable, comment, queue_id, type_id, image_id, show_attachment, show_configitem, request_group, show_configitems, ticket_owner, ticket_responsible, '
            . 'valid_id, process_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{Subject}, \$Param{SubjectChangeable}, \$Param{Comment}, \$Param{Queue},
            \$Param{Type}, \$Param{ImageID}, \$Param{ShowAttachment}, \$Param{ShowConfigItem}, \$Param{RequestGroup}, \$Param{ShowConfigItems},
            \$Param{OwnerID}, \$Param{ResponsibleID}, \$Param{ValidID}, \$Param{ProcessID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Request id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM request WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );
    my $RequestID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestID = $Row[0];
    }

    return $RequestID;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
