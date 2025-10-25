# --
# Kernel/System/TicketRequest.pm - all service function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: TicketRequest.pm,v 1.7 2016/09/13 19:17:01 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketRequest;

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

Kernel::System::TicketRequest - TicketRequest lib

=head1 SYNOPSIS

All Antrag functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketRequestObject = $Kernel::OM->Get('Kernel::System::TicketRequest');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item TicketRequestList()

return a hash list of Antrag

    my @TicketRequestList = $TicketRequestObject->TicketRequestList(
        TicketID  => 123,
        RequestID  => 123,
        UserID => 1,
    );

=cut

sub TicketRequestList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TicketID RequestID UserID)) {
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

    my @TicketRequestList;

    return if !$DBObject->Prepare(
        SQL =>
            "SELECT feld_key, feld_value, feld_beschriftung FROM ticket_request WHERE ticket_id = $Param{TicketID} AND antrag_id = $Param{RequestID}",
    );

    # fetch the result
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %TicketRequest;
        $TicketRequest{FeldKey}          = $Row[0];
        $TicketRequest{FeldValue}        = $Row[1];
        $TicketRequest{FeldLabeling} = $Row[2];
        push @TicketRequestList, \%TicketRequest;
    }

    # return result
    return @TicketRequestList;
}

=item TicketRequestOverview()

return a hash list of Antrag

    my %TicketRequestList = $TicketRequestObject->TicketRequestOverview(
        TicketID => 123,
        UserID   => 1,
    );

=cut

sub TicketRequestOverview {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TicketID UserID)) {
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

    my @TicketRequestList;

    return if !$DBObject->Prepare(
        SQL =>
            "SELECT feld_key, feld_value FROM ticket_request WHERE ticket_id = $Param{TicketID}",
    );

    # fetch the result
        my %TicketRequest;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $TicketRequest{$Row[0]}   = $Row[1];
    }

    # return result
    return %TicketRequest;
}

=item TicketRequestGet()

return RequestID

    my $RequestID = $TicketRequestObject->TicketRequestGet(
        TicketID  => 123,
        UserID => 1,
    );

=cut

sub TicketRequestGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TicketID UserID)) {
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

    return if !$DBObject->Prepare(
        SQL =>
            "SELECT antrag_id FROM ticket_request WHERE ticket_id = $Param{TicketID}",
        Limit => 1,
    );

    my $RequestID;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $RequestID = $Data[0];
    }

    # return result
    return $RequestID;
}

=item TicketRequestAdd()

add a TicketRequest

    my $Success = $TicketRequestObject->TicketRequestAdd(
        TicketID         => 123,
        RequestID         => 123,
        FeldKey          => 'FeldName',
        FeldValue        => 'FeldInhalt',
        FeldLabeling => 'Feld-Beschriftung',
        UserID           => 123,
    );

=cut

sub TicketRequestAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TicketID RequestID FeldKey FeldLabeling UserID)) {
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
        SQL => 'INSERT INTO ticket_request '
            . '(ticket_id, antrag_id, feld_key, feld_value, feld_beschriftung, create_time, '
            . 'create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TicketID},         \$Param{RequestID},   \$Param{FeldKey},  \$Param{FeldValue},
            \$Param{FeldLabeling}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    return 1;
}

=item TicketIDRequestAdd()

add a TicketIDRequest

    my $Success = $TicketRequestObject->TicketIDRequestAdd(
        TicketID  => 123,
        RequestID => 123,
        UserID    => 123,
    );

=cut

sub TicketIDRequestAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TicketID RequestID UserID)) {
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
        SQL => 'INSERT INTO ticket_id_request '
            . '(ticket_id, request_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TicketID}, \$Param{RequestID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    return 1;
}

=item TicketIDRequestList()

return a hash list of Antrag

    my %TicketIDRequestList = $TicketRequestObject->TicketIDRequestList(
        TicketID  => 123,
        UserID => 1,
    );

=cut

sub TicketIDRequestList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TicketID UserID)) {
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

    return if !$DBObject->Prepare(
        SQL =>
            "SELECT ticket_id, request_id, FROM ticket_id_request WHERE ticket_id = $Param{TicketID}",
    );

    my %TicketIDRequestList;

    # fetch the result
    while ( my @Row = $DBObject->FetchrowArray() ) {
        TicketIDRequestList{$Row[0]} = $Row[1];
    }

    # return result
    return %TicketIDRequestList;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
