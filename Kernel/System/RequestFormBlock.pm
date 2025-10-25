# --
# Kernel/System/RequestFormBlock.pm - all service function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: RequestFormBlock.pm,v 1.7 2016/11/20 19:30:24 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RequestFormBlock;

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

Kernel::System::RequestFormBlock - RequestFormBlock lib

=head1 SYNOPSIS

All Antrag functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $RequestFormBlockObject = $Kernel::OM->Get('Kernel::System::RequestFormBlock');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item RequestFormBlockList()

return a hash list of RequestForm

    my %RequestFormBlockList = $RequestFormBlockObject->RequestFormBlockList(
        RequestFormID      => 123,
        RequestFormValueID => 123,
        RequestID          => 123,
        Valid             => 0,   # (optional) default 1 (0|1)
        UserID            => 1,
    );

=cut

sub RequestFormBlockList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} || !$Param{RequestID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID and RequestID!',
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
            SQL =>
                "SELECT id, orders FROM request_form_block WHERE request_id = $Param{RequestID} AND request_form_value = '$Param{RequestFormValueID}' AND request_form_id = $Param{RequestFormID} ORDER BY orders",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, orders FROM request_form_block WHERE WHERE request_id = $Param{RequestID} AND request_form_value = '$Param{RequestFormValueID}' AND request_form_id = $Param{RequestFormID} valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} ) ORDER BY orders",
        );
    }

    # fetch the result
    my %RequestFormBlockList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFormBlockList{ $Row[0] } = $Row[1];
    }

    return %RequestFormBlockList;
}

=item RequestFormLastOrderBlock()

return last number "Order" of RequestForm

    my $LastOrder = $RequestFormBlockObject->RequestFormLastOrderBlock(
        RequestID          => 123,
        RequestFormValueID => 123,
    );

=cut

sub RequestFormLastOrderBlock {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{RequestID} && $Param{RequestFormValueID} ) {
        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, orders FROM request_form_block WHERE orders = (SELECT MAX(orders) from request_form_block WHERE request_id = $Param{RequestID} AND request_form_value = '$Param{RequestFormValueID}')",
        );
    }
    else {
        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, orders FROM request_form_block WHERE orders = (SELECT MAX(orders) from request_form_block)",
        );
    }

    # fetch the result
    my $LastOrder;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $LastOrder = $Row[1];
    }

    return $LastOrder;
}

=item AntragFeldBlockDelete()

delete

    my $Remove = $RequestFormBlockObject->AntragFeldBlockDelete(
        RequestFormBlockID => 123,
    );

=cut

sub AntragFeldBlockDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestFormBlockID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need RequestFormBlockID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL  => 'DELETE FROM request_form_block WHERE id = ? ',
        Bind => [ \$Param{RequestFormBlockID}, ],
    );

    return 1;
}

=item RequestFormBlockGet()

get RequestFormBlock attributes

    my %RequestForm = $RequestFormBlockObject->RequestFormBlockGet(
        RequestFormID => 123,
    );

=cut

sub RequestFormBlockGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestFormID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need RequestFormID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, request_form_id, request_form_value, request_id, feld_id, requiredfield, orders, move_over, headline, beschreibung, valid_id, create_time, create_by '
            . 'FROM request_form_block WHERE id = ?',
        Bind => [ \$Param{RequestFormID} ],
    );

    my %RequestForm;
    while ( my @Data = $DBObject->FetchrowArray() ) {

        %RequestForm = (
            ID               => $Data[0],
            RequestFormID    => $Data[1],
            RequestFormValue => $Data[2],
            RequestID        => $Data[3],
            FeldID           => $Data[4],
            RequiredField    => $Data[5],
            Order            => $Data[6],
            ToolTip          => $Data[7],
            Headline         => $Data[8],
            Description      => $Data[9],
            ValidID          => $Data[10],
            CreateTime       => $Data[11],
            CreateBy         => $Data[12],
        );
    }

    # return result
    return %RequestForm;
}

=item RequestFormBlockUpdate()

update a RequestFormBlock

    my $RequestFormID = $RequestFormBlockObject->RequestFormBlockUpdate(
        RequestFormBlockID => 123,
        RequestFormID      => 123,
        RequestFormValueID => 123,,
        RequestID          => 123,
        FeldID            => 123,
        RequiredField       => 1,
        Order       => 1,
        ToolTip           => 'ToolTip',
        ValidID           => 1,
        UserID            => 123,
    );

=cut

sub RequestFormBlockUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestFormBlockID RequestFormValueID RequestFormID RequestID FeldID Order ValidID UserID)
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

    # update RequestFormBlock
    return if !$DBObject->Do(
        SQL =>
            'UPDATE request_form_block SET request_form_id = ?, request_form_value = ?, request_id = ?, feld_id = ?,'
            . ' requiredfield = ?, orders = ?, move_over = ?,'
            . ' valid_id = ?, create_time = current_timestamp, create_by = ? WHERE id = ?',
        Bind => [
            \$Param{RequestFormID}, \$Param{RequestFormValueID}, \$Param{RequestID},
            \$Param{FeldID}, \$Param{RequiredField}, \$Param{Order}, \$Param{ToolTip},
            \$Param{ValidID}, \$Param{UserID}, \$Param{RequestFormBlockID},
        ],
    );

    return 1;
}

=item RequestFormOrderUpdate()

update a RequestForm

    my $Success = $RequestFormBlockObject->RequestFormOrderUpdate(
        RequestFormID => 123,
        Order         => 1,
        UserID        => 123,
    );

=cut

sub RequestFormOrderUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestFormID Order UserID)
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
        SQL  => 'UPDATE request_form_block SET orders = ? WHERE id = ?',
        Bind => [
            \$Param{Order}, \$Param{RequestFormID},
        ],
    );

    return 1;
}

=item RequestFormHeadlineBlockUpdate()

update a RequestFormHeadlineBlock

    my $RequestFormID = $RequestFormBlockObject->RequestFormHeadlineBlockUpdate(
        RequestFormBlockID => 123,
        RequestFormValueID => 123,
        RequestFormID      => 123,
        RequestID          => 123,
        Headline          => 'Headline',
        Description      => 'Description',
        Order       => 1,
        UserID            => 123,
    );

=cut

sub RequestFormHeadlineBlockUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestFormBlockID RequestFormValueID RequestFormID RequestID Headline Order UserID)
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

    my $LDAPGruppe = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update RequestForm
    return if !$DBObject->Do(
        SQL =>
            'UPDATE request_form_block SET request_form_id = ?, request_form_value = ?, request_id = ?, headline = ?, orders = ?, beschreibung = ?,'
            . ' create_time = current_timestamp, create_by = ? WHERE id = ?',
        Bind => [
            \$Param{RequestFormID}, \$Param{RequestFormValueID}, \$Param{RequestID},
            \$Param{Headline},     \$Param{Order},       \$Param{Description},
            \$Param{UserID}, \$Param{RequestFormBlockID},
        ],
    );

    return 1;
}

=item RequestFormBlockAdd()

add a RequestFormBlock

    my $RequestFormBlockID = $RequestFormBlockObject->RequestFormBlockAdd(
        RequestFormID      => 123,
        RequestFormValueID => 123,
        RequestID          => 123,
        FeldID            => 123,
        RequiredField       => 1,
        Order       => 1,
        ToolTip           => 'ToolTip',
        ValidID           => 1,
        UserID            => 123,
    );

=cut

sub RequestFormBlockAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestFormID RequestFormValueID RequestID FeldID RequiredField Order ValidID UserID)
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

    my $LDAPGruppe = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO request_form_block '
            . '(request_form_id, request_form_value, request_id, feld_id, requiredfield, '
            . 'orders, move_over, valid_id, create_time, create_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Param{RequestFormID}, \$Param{RequestFormValueID}, \$Param{RequestID},
            \$Param{FeldID}, \$Param{RequiredField}, \$Param{Order}, \$Param{ToolTip}, \$Param{ValidID},
            \$Param{UserID},
        ],
    );

    # get id
    $DBObject->Prepare(
        SQL =>
            'SELECT id FROM request_form_block WHERE request_form_id = ? AND request_form_value = ? AND request_id = ? AND feld_id = ? AND orders = ?',
        Bind => [
            \$Param{RequestFormID}, \$Param{RequestFormValueID}, \$Param{RequestID},
            \$Param{FeldID}, \$Param{Order}
        ],
        Limit => 1,
    );
    my $RequestFormBlockID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFormBlockID = $Row[0];
    }

    return $RequestFormBlockID;
}

=item RequestFormHeadlineBlockAdd()

add a RequestFormHeadlineBlock

    my $RequestFormID = $RequestFormBlockObject->RequestFormHeadlineBlockAdd(
        RequestFormValueID => 123,
        RequestFormID      => 123,
        RequestID          => 123,
        Headline           => 'Headline',
        Description        => 'Description',
        Order              => 1,
        UserID             => 123,
    );

=cut

sub RequestFormHeadlineBlockAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestFormValueID RequestFormID RequestID Headline Order UserID)
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

    my $LDAPGruppe = 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO request_form_block '
            . '(request_form_id, request_form_value, request_id, headline, orders, beschreibung, create_time, create_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Param{RequestFormID}, \$Param{RequestFormValueID}, \$Param{RequestID}, \$Param{Headline},
            \$Param{Order}, \$Param{Description}, \$Param{UserID},
        ],
    );

    # get id
    $DBObject->Prepare(
        SQL =>
            'SELECT id FROM request_form_block WHERE request_form_id = ? AND request_form_value = ? AND request_id = ? AND headline = ? AND orders = ?',
        Bind => [
            \$Param{RequestFormID}, \$Param{RequestFormValueID}, \$Param{RequestID},
            \$Param{Headline}, \$Param{Order}
        ],
        Limit => 1,
    );
    my $RequestFormID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFormID = $Row[0];
    }

    return $RequestFormID;
}

=item RequestFieldBlockDelete()

delete

    my $Remove = $RequestFormBlockObject->RequestFieldBlockDelete(
        RequestFormBlockID => 123,
    );

=cut

sub RequestFieldBlockDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestFormBlockID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need AntragFormBlockID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL  => 'DELETE FROM request_form_block WHERE id = ? ',
        Bind => [ \$Param{RequestFormBlockID}, ],
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
