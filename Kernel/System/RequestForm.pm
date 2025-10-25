# --
# Kernel/System/RequestForm.pm - all service function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: RequestForm.pm,v 1.31 2016/11/20 19:30:40 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RequestForm;

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

Kernel::System::RequestForm - RequestForm lib

=head1 SYNOPSIS

All Antrag functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $RequestFormObject = $Kernel::OM->Get('Kernel::System::RequestForm');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item RequestFormList()

return a hash list of RequestForm

    my %RequestFormList = $RequestFormObject->RequestFormList(
        RequestID => 123,
        Valid    => 0,   # (optional) default 1 (0|1)
        UserID   => 1,
    );

=cut

sub RequestFormList {
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
                "SELECT id, orders FROM request_form WHERE request_id = $Param{RequestID} ORDER BY orders",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, orders FROM request_form WHERE WHERE request_id = $Param{RequestID} valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} ) ORDER BY orders",
        );
    }

    # fetch the result
    my %RequestFormList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFormList{ $Row[0] } = $Row[1];
    }

    return %RequestFormList;
}

=item RequestFormLastOrder()

return last number "Order" of RequestForm

    my $LastOrder = $RequestFormObject->RequestFormLastOrder(
        RequestID = 123, 'optional
    );

=cut

sub RequestFormLastOrder {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{RequestID} ) {
        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, orders FROM request_form WHERE orders = (SELECT MAX(orders) from request_form WHERE request_id = $Param{RequestID})",
        );
    }
    else {
        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, orders FROM request_form WHERE orders = (SELECT MAX(orders) from request_form)",
        );
    }

    # fetch the result
    my $LastOrder;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $LastOrder = $Row[1];
    }

    return $LastOrder;
}

=item RequestFieldDelete()

delete

    my $Remove = $RequestFormObject->RequestFieldDelete(
        RequestFormID => 123,
    );

=cut

sub RequestFieldDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestFormID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need RequestFormID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL  => 'DELETE FROM request_form WHERE id = ? ',
        Bind => [ \$Param{RequestFormID}, ],
    );

    return 1;
}

=item RequestFormGet()

get RequestForm attributes

    my %RequestForm = $RequestFormObject->RequestFormGet(
        RequestFormID => 123,
    );

=cut

sub RequestFormGet {
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
            'SELECT id, request_id, feld_id, requiredfield, orders, move_over, tool_tip, headline, beschreibung, valid_id, create_time, create_by '
            . 'FROM request_form WHERE id = ?',
        Bind => [ \$Param{RequestFormID} ],
    );

    my %RequestForm;
    while ( my @Data = $DBObject->FetchrowArray() ) {

        %RequestForm = (
            ID            => $Data[0],
            RequestID     => $Data[1],
            FeldID        => $Data[2],
            RequiredField => $Data[3],
            Order         => $Data[4],
            ToolTip       => $Data[5],
            ToolTipUnder  => $Data[6],
            Headline      => $Data[7],
            Description   => $Data[8],
            ValidID       => $Data[9],
            CreateTime    => $Data[10],
            CreateBy      => $Data[11],
        );
    }

    # return result
    return %RequestForm;
}

=item RequestFormUpdate()

update a RequestForm

    my $RequestFormID = $RequestFormObject->RequestFormUpdate(
        RequestFormID    => 123,
        RequestID        => 123,
        FeldID          => 123,
        RequiredField     => 1,
        Order     => 1,
        ToolTip         => 'ToolTip',
        ToolTipUnder  => 1,
        ValidID         => 1,
        UserID          => 123,
    );

=cut

sub RequestFormUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestFormID RequestID FeldID RequiredField Order ValidID UserID)
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

    if ( !$Param{ToolTipUnder} ) {
        $Param{ToolTipUnder} = 0;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update RequestForm
    return if !$DBObject->Do(
        SQL => 'UPDATE request_form SET request_id = ?, feld_id = ?,'
            . ' requiredfield = ?, orders = ?, move_over = ?, tool_tip = ?,'
            . ' valid_id = ?, create_time = current_timestamp, create_by = ? WHERE id = ?',
        Bind => [
            \$Param{RequestID}, \$Param{FeldID},
            \$Param{RequiredField}, \$Param{Order}, \$Param{ToolTip},  \$Param{ToolTipUnder}, \$Param{ValidID},
            \$Param{UserID}, \$Param{RequestFormID},
        ],
    );

    return 1;
}

=item RequestFormOrderUpdate()

update a RequestForm

    my $Success = $RequestFormObject->RequestFormOrderUpdate(
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
        SQL  => 'UPDATE request_form SET orders = ? WHERE id = ?',
        Bind => [
            \$Param{Order}, \$Param{RequestFormID},
        ],
    );

    return 1;
}

=item RequestFormHeadlineUpdate()

update a RequestFormHeadline

    my $RequestFormID = $RequestFormObject->RequestFormHeadlineUpdate(
        RequestFormID => 123,
        RequestID     => 123,
        Headline     => 'Headline',
        Description => 'Description',
        Order  => 1,
        UserID       => 123,
    );

=cut

sub RequestFormHeadlineUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestFormID RequestID Headline Order UserID)
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
            'UPDATE request_form SET request_id = ?, headline = ?, orders = ?, beschreibung = ?,'
            . ' create_time = current_timestamp, create_by = ? WHERE id = ?',
        Bind => [
            \$Param{RequestID}, \$Param{Headline}, \$Param{Order}, \$Param{Description},
            \$Param{UserID}, \$Param{RequestFormID},
        ],
    );

    return 1;
}



=item RequestFormAdd()

add a RequestForm

    my $RequestFormID = $RequestFormObject->RequestFormAdd(
        RequestID     => 123,
        FeldID        => 123,
        RequiredField => 1,
        Order         => 1,
        ToolTip       => 'ToolTip',
        ToolTipUnder  => 1,
        ValidID       => 1,
        UserID        => 123,
    );

=cut

sub RequestFormAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestID FeldID Order ValidID UserID)
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

    if ( !$Param{RequiredField} ) {
        $Param{RequiredField} = 0;
    }

    if ( !$Param{ToolTipUnder} ) {
        $Param{ToolTipUnder} = 0;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO request_form '
            . '(request_id, feld_id, requiredfield, '
            . 'orders, move_over, tool_tip, valid_id, create_time, create_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Param{RequestID}, \$Param{FeldID},
            \$Param{RequiredField}, \$Param{Order}, \$Param{ToolTip}, \$Param{ToolTipUnder}, \$Param{ValidID},
            \$Param{UserID},
        ],
    );

    # get id
    $DBObject->Prepare(
        SQL => 'SELECT id FROM request_form WHERE request_id = ? AND feld_id = ? AND orders = ?',
        Bind  => [ \$Param{RequestID}, \$Param{FeldID}, \$Param{Order} ],
        Limit => 1,
    );
    my $RequestFormID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFormID = $Row[0];
    }

    return $RequestFormID;
}

=item RequestFormHeadlineAdd()

add a RequestFormHeadline

    my $RequestFormID = $RequestFormObject->RequestFormHeadlineAdd(
        RequestID     => 123,
        Headline     => 'Headline',
        Description => 'Description',
        Order  => 1,
        UserID       => 123,
    );

=cut

sub RequestFormHeadlineAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (
        qw(RequestID Headline Order UserID)
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

    if ( !$Param{RequiredField} ) {
        $Param{RequiredField} = 0;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO request_form '
            . '(request_id, headline, orders, beschreibung, create_time, create_by) '
            . 'VALUES (?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Param{RequestID}, \$Param{Headline}, \$Param{Order}, \$Param{Description},
            \$Param{UserID},
        ],
    );

    # get id
    $DBObject->Prepare(
        SQL =>
            'SELECT id FROM request_form WHERE request_id = ? AND headline = ? AND orders = ?',
        Bind => [ \$Param{RequestID}, \$Param{Headline}, \$Param{Order} ],
        Limit => 1,
    );
    my $RequestFormID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFormID = $Row[0];
    }

    return $RequestFormID;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
