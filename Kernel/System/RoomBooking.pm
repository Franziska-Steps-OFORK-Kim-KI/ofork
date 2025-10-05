# --
# Kernel/System/RoomBooking.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: RoomBooking.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RoomBooking;

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

Kernel::System::RoomBooking - RoomBooking lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $RoomBookingObject = $Kernel::OM->Get('Kernel::System::RoomBooking');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item RoomBookingList()

return a hash list of Request

    my %RoomBookingList = $RoomBookingObject->RoomBookingList(
        UserID => 1,
    );

=cut

sub RoomBookingList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "SELECT id, subject FROM room_booking",
    );

    # fetch the result
    my %RoomList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomList{ $Row[0] } = $Row[1];
    }

    return %RoomList;
}

=item RoomBookingFutureList()

return a hash list of Request

    my %RoomBookingList = $RoomBookingObject->RoomBookingFutureList(
        RoomID     => 1,
        StartMonth => '2019-05-01 00:00:00',
    );

=cut

sub RoomBookingFutureList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RoomID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need RoomID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "SELECT id, room_id FROM room_booking WHERE from_time > ? AND room_id = ?",
        Bind => [ \$Param{StartMonth}, \$Param{RoomID}, ],
    );


    # fetch the result
    my %RoomList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomList{ $Row[0] } = $Row[1];
    }

    return %RoomList;
}

=item RoomBookingFutureUserList()

return a hash list of Request

    my %RoomBookingList = $RoomBookingObject->RoomBookingFutureUserList(
        UserID     => 'user_id,
        StartMonth => '2019-05-01 00:00:00',
    );

=cut

sub RoomBookingFutureUserList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "SELECT id, room_id FROM room_booking WHERE from_time > ? AND create_by = ?",
        Bind => [ \$Param{StartMonth}, \$Param{UserID}, ],
    );


    # fetch the result
    my %RoomList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomList{ $Row[0] } = $Row[1];
    }

    return %RoomList;
}

=item RoomBookingGet()

get Request attributes

    my %RoomBooking = $RoomBookingObject->RoomBookingGet(
        RoomBookingID => 123,
    );

=cut

sub RoomBookingGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RoomBookingID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need RoomBookingID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, room_id, participant, subject, body, from_time, to_time, toend_time, email_list, equipment_order, '
            . 'cal_uid, sequence, qb_tid, qd_tid, qc_tid, create_time, create_by, change_time, change_by '
            . 'FROM room_booking WHERE id = ?',
        Bind => [ \$Param{RoomBookingID} ],
    );
    my %Room;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Room = (
            BookingID             => $Data[0],
            RoomID                => $Data[1],
            Participant           => $Data[2],
            Subject               => $Data[3],
            Body                  => $Data[4],
            FromSystemTime        => $Data[5],
            ToSystemTime          => $Data[6],
            ToEndSystemTime       => $Data[7],
            EmailList             => $Data[8],
            EquipmentOrder        => $Data[9],
            CalUID                => $Data[10],
            Sequence              => $Data[11],
            QueueBookingTicketID  => $Data[12],
            QueueDeviceTicketID   => $Data[13],
            QueueCateringTicketID => $Data[14],
            CreateTime            => $Data[15],
            CreateBy              => $Data[16],
            ChangeTime            => $Data[17],
            ChangeBy              => $Data[18],
        );
    }

    # return result
    return %Room;
}

=item RoomBookingUpdate()

update a RoomBooking

    my $RoomBookingID = $RoomBookingObject->RoomBookingUpdate(
        RoomBookingID   => 123,
        RoomID          => 123,
        Participant     => 22,
        Subject         => 'Subject',
        Body            => 'Message',
        FromSystemTime  => 123456789,
        ToSystemTime    => 123456789,
        ToEndSystemTime => 123456789,
        EmailList       => 'email',
        EquipmentOrder  => '1-12,2-10',
        Sequence        => 0,
        UserID          => 123,
    );

=cut

sub RoomBookingUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(RoomBookingID RoomID UserID)) {
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
            'UPDATE room_booking SET participant = ?, subject = ?, body = ?, from_time = ?, to_time = ?, toend_time = ?, email_list = ?, equipment_order = ?, '
            . 'sequence = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Participant}, \$Param{Subject}, \$Param{Body}, \$Param{FromSystemTime}, \$Param{ToSystemTime}, \$Param{ToEndSystemTime},
            \$Param{EmailList}, \$Param{EquipmentOrder}, \$Param{Sequence}, \$Param{UserID}, \$Param{RoomBookingID},
        ],
    );

    return 1;
}

=item RoomBookingAdd()

add a Room

    my $Success = $RoomBookingObject->RoomBookingAdd(
        RoomID                => 123,
        Participant           => 22,
        Subject               => 'Subject',
        Body                  => 'Message',
        FromSystemTime        => 123456789,
        ToSystemTime          => 123456789,
        ToEndSystemTime       => 123456789,
        EmailList             => 'email',
        EquipmentOrder        => '1-12,2-10',
        CalUID                => 123456789,
        Sequence              => 0,
        QueueBookingTicketID  => 123,
        QueueDeviceTicketID   => 123,
        QueueCateringTicketID => 123,
        UserID                => 123,
    );

=cut

sub RoomBookingAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(RoomID Subject Participant FromSystemTime ToSystemTime ToEndSystemTime UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    if ( !$Param{QueueBookingTicketID} ) {
        $Param{QueueBookingTicketID} = 0;
    }
    if ( !$Param{QueueDeviceTicketID} ) {
        $Param{QueueDeviceTicketID} = 0;
    }
    if ( !$Param{QueueCateringTicketID} ) {
        $Param{QueueCateringTicketID} = 0;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO room_booking '
            . '(room_id, participant, subject, body, from_time, to_time, toend_time, email_list, equipment_order, '
            . 'cal_uid, sequence, qb_tid, qd_tid, qc_tid, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{RoomID}, \$Param{Participant}, \$Param{Subject}, \$Param{Body}, \$Param{FromSystemTime}, \$Param{ToSystemTime}, \$Param{ToEndSystemTime},
            \$Param{EmailList}, \$Param{EquipmentOrder}, \$Param{CalUID}, \$Param{Sequence}, \$Param{QueueBookingTicketID}, \$Param{QueueDeviceTicketID},
            \$Param{QueueCateringTicketID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Request id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM room_booking WHERE from_time = ?',
        Bind  => [ \$Param{FromSystemTime} ],
        Limit => 1,
    );
    my $BookingID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $BookingID = $Row[0];
    }

    return $BookingID;

}

=item RoomBookingTimeCheck()

return room list

    my %RoomList = $RoomBookingObject->RoomBookingTimeCheck(
        RoomID         => 123,
        FromSystemTime => 123456789,
        ToSystemTime   => 123456789,
        RoomBookingID  => 123, #optional
    );

=cut

sub RoomBookingTimeCheck {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(RoomID FromSystemTime ToSystemTime)) {
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

    if ( $Param{RoomBookingID} ) {

        # sql
        return if !$DBObject->Prepare(
            SQL =>
                'SELECT id, room_id FROM room_booking WHERE ((? between from_time AND toend_time) OR (? between from_time AND toend_time)) AND room_id = ? AND id != ?',
            Bind => [ \$Param{FromSystemTime}, \$Param{ToSystemTime}, \$Param{RoomID}, \$Param{RoomBookingID}, ],
        );
    }
    else {

        # sql
        return if !$DBObject->Prepare(
            SQL =>
                'SELECT id, room_id FROM room_booking WHERE ((? between from_time AND toend_time) OR (? between from_time AND toend_time)) AND room_id = ?',
            Bind => [ \$Param{FromSystemTime}, \$Param{ToSystemTime}, \$Param{RoomID}, ],
        );
    }

    # fetch the result
    my %RoomList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomList{ $Row[0] } = $Row[1];
    }

    return %RoomList;
}

=item RoomBookingSearch()

return a hash list of Request

    my %RoomBookingSearch = $RoomBookingObject->RoomBookingSearch(
        UserID = 'UserID',
    );

=cut

sub RoomBookingSearch {
    my ( $Self, %Param ) = @_;

    my $Result  = $Param{Result}  || 'HASH';

    my $SQLSearch = '';
    my $SQLSort   = 'ASC';

    if ( $Param{OrderBy} eq "Down" ) {
        $SQLSort   = 'DESC';
    }
    if ( $Param{OrderBy} eq "Up" ) {
        $SQLSort   = 'ASC';
    }

    if ( $Param{SortBy} eq "RoomID" ) {
        $Param{SortBy} = 'room_id';
    }
    if ( $Param{SortBy} eq "Participant" ) {
        $Param{SortBy} = 'participant';
    }
    if ( $Param{SortBy} eq "Subject" ) {
        $Param{SortBy} = 'subject';
    }
    if ( $Param{SortBy} eq "FromSystemTime" ) {
        $Param{SortBy} = 'from_time';
    }
    if ( $Param{SortBy} eq "ToSystemTime" ) {
        $Param{SortBy} = 'to_time';
    }

    if ( $Param{SortBy} ) {
        if ( $Param{SortBy} eq "participant" ) {
             $SQLSearch = 'ORDER BY CONVERT(' . $Param{SortBy} . ', DECIMAL) ' . $SQLSort;
        }
        else {
             $SQLSearch = 'ORDER BY ' . $Param{SortBy} . ' ' . $SQLSort;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "SELECT id, room_id FROM room_booking WHERE create_by = ? $SQLSearch",
        Bind => [ \$Param{UserID} ],
    );


    # fetch the result
    my %RoomList;
    my @RoomList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomList{ $Row[0] } = $Row[1];
        push @RoomList, $Row[0];
    }

    my $Count = @RoomList;

    if ( $Result eq 'COUNT' ) {
        return $Count;
    }
    else {
        return @RoomList;
    }

    return %RoomList;
}

=item RoomBookingSearchAgent()

return a hash list of Request

    my %RoomBookingSearch = $RoomBookingObject->RoomBookingSearchAgent();

=cut

sub RoomBookingSearchAgent {
    my ( $Self, %Param ) = @_;

    my $Result  = $Param{Result}  || 'HASH';

    my $SQLSearch = '';
    my $SQLSort   = 'ASC';

    if ( $Param{OrderBy} eq "Down" ) {
        $SQLSort   = 'DESC';
    }
    if ( $Param{OrderBy} eq "Up" ) {
        $SQLSort   = 'ASC';
    }

    if ( $Param{SortBy} eq "RoomID" ) {
        $Param{SortBy} = 'room_id';
    }
    if ( $Param{SortBy} eq "Participant" ) {
        $Param{SortBy} = 'participant';
    }
    if ( $Param{SortBy} eq "Subject" ) {
        $Param{SortBy} = 'subject';
    }
    if ( $Param{SortBy} eq "FromSystemTime" ) {
        $Param{SortBy} = 'from_time';
    }
    if ( $Param{SortBy} eq "ToSystemTime" ) {
        $Param{SortBy} = 'to_time';
    }
    if ( $Param{SortBy} eq "Customer" ) {
        $Param{SortBy} = 'create_by';
    }

    if ( $Param{SortBy} ) {
        if ( $Param{SortBy} eq "participant" ) {
             $SQLSearch = 'ORDER BY CONVERT(' . $Param{SortBy} . ', DECIMAL) ' . $SQLSort;
        }
        else {
             $SQLSearch = 'ORDER BY ' . $Param{SortBy} . ' ' . $SQLSort;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');


    if ( !$Param{CustomerUserID} || $Param{CustomerUserID} eq "all" ) {
        $Param{CustomerUserID} = '';
    }

    if ( $Param{Type} ) {

        if ( $Param{Type} eq "Open" ) {

            return if !$DBObject->Prepare(
                SQL => "SELECT id, room_id FROM room_booking WHERE from_time >= ? AND create_by LIKE '%" . $Param{CustomerUserID} . "%' $SQLSearch",
                Bind => [ \$Param{StartMonth}, ],
            );
        }
        else {

            return if !$DBObject->Prepare(
                SQL => "SELECT id, room_id FROM room_booking WHERE from_time < ? AND create_by LIKE '%" . $Param{CustomerUserID} . "%' $SQLSearch",
                Bind => [ \$Param{StartMonth}, ],
            );
        }

    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, room_id FROM room_booking WHERE create_by LIKE '%" . $Param{CustomerUserID} . "%' $SQLSearch",
        );
    }



    # fetch the result
    my %RoomList;
    my @RoomList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomList{ $Row[0] } = $Row[1];
        push @RoomList, $Row[0];
    }

    my $Count = @RoomList;

    if ( !$Count ) {
        $Count = 0;
    }

    if ( $Result eq 'COUNT' ) {
        return $Count;
    }
    else {
        return @RoomList;
    }

    return %RoomList;
}

=item RoomBookingAgentStats()

return a hash list of Request

    my %RoomBookingSearch = $RoomBookingObject->RoomBookingAgentStats(
        CustomerUserID => 'CustomerUserID',
        RoomID         => 123,
        Start          => 123456789,
        End            => 123456789,
    );

=cut

sub RoomBookingAgentStats {
    my ( $Self, %Param ) = @_;

    my $SQLSearch = "ORDER BY create_by ASC, from_time ASC";


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');


    if ( !$Param{CustomerUserID} || $Param{CustomerUserID} eq "all" ) {
        $Param{CustomerUserID} = '';
    }

    if ( !$Param{RoomID} || $Param{RoomID} eq "all" ) {
        $Param{RoomID} = '';
    }

    return if !$DBObject->Prepare(
        SQL => "SELECT id, room_id FROM room_booking WHERE from_time >= ? AND to_time <= ? AND create_by LIKE '%" . $Param{CustomerUserID} . "%' AND room_id LIKE '%" . $Param{RoomID} . "%' $SQLSearch",
        Bind => [ \$Param{Start}, \$Param{End}, ],
    );

    # fetch the result
    my %RoomList;
    my @RoomList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomList{ $Row[0] } = $Row[1];
        push @RoomList, $Row[0];
    }

    return @RoomList;
}

=head2 RoomBookingDelete()

delete a booking

    $RoomBookingObject->RoomBookingDelete(
        RoomBookingID => 123,
    );

=cut

sub RoomBookingDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(RoomBookingID)) {
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
        SQL  => 'DELETE FROM room_booking WHERE id = ?',
        Bind => [ \$Param{RoomBookingID} ],
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
