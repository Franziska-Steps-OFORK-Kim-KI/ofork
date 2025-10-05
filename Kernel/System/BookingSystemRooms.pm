# --
# Kernel/System/BookingSystemRooms.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: BookingSystemRooms.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::BookingSystemRooms;

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

Kernel::System::BookingSystemRooms - BookingSystemRooms lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item RoomList()

return a hash list of Request

    my %RoomList = $BookingSystemRoomsObject->RoomList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub RoomList {
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
            SQL => "SELECT id, room FROM rooms",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, room  FROM rooms WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )",
        );
    }

    # fetch the result
    my %RoomList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomList{ $Row[0] } = $Row[1];
    }

    return %RoomList;
}

=item RoomGet()

get Request attributes

    my %Room = $BookingSystemRoomsObject->RoomGet(
        RoomID => 123,
    );

=cut

sub RoomGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RoomID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need RoomID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, categories_id, categories, room, building, floor, street, post_code, city, calendar, room_color, '
            .'setup_time, persons, price, price_for, currency, equipment_bookable, equipment, description, queue_booking, ' 
            . 'queue_device, queue_catering, valid_id, comment, image_id, create_time, create_by, change_time, change_by '
            . 'FROM rooms WHERE id = ?',
        Bind => [ \$Param{RoomID} ],
    );
    my %Room;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Room = (
            RoomID            => $Data[0],
            RoomCategoriesID  => $Data[1],
            RoomCategories    => $Data[2],
            Room              => $Data[3],
            Building          => $Data[4],
            Floor             => $Data[5],
            Street            => $Data[6],
            PostCode          => $Data[7],
            City              => $Data[8],
            Calendar          => $Data[9],
            RoomColor         => $Data[10],
            SetupTime         => $Data[11],
            Persons           => $Data[12],
            Price             => $Data[13],
            PriceFor          => $Data[14],
            Currency          => $Data[15],
            EquipmentBookable => $Data[16],
            Equipment         => $Data[17],
            Description       => $Data[18],
            QueueBooking      => $Data[19],
            QueueDevice       => $Data[20],
            QueueCatering     => $Data[21],
            ValidID           => $Data[22],
            Comment           => $Data[23],
            ImageID           => $Data[24],
            CreateTime        => $Data[25],
            CreateBy          => $Data[26],
            ChangeTime        => $Data[27],
            ChangeBy          => $Data[28],
        );
    }

    # return result
    return %Room;
}

=item RoomUpdate()

update a Room

    my $RoomID = $BookingSystemRoomsObject->RoomUpdate(
        RoomID            => 123,
        RoomCategoriesID  => 123,
        RoomCategories    => 'RoomCategories',
        Room              => 'Room',
        Building          => 'Building',
        Floor             => 'Floor',
        Street            => 'Street',
        PostCode          => 'PostCode',
        City              => 'City',
        Calendar          => 'Calendar',
        RoomColor         => '123456',
        SetupTime         => '2',
        Persons           => '20',
        Price             => '1,50',
        PriceFor          => 1,
        Currency          => 'Euro',
        EquipmentBookable => 'EquipmentBookable',
        Equipment         => 'Equipment',
        Description       => 'Description',
        QueueBooking      => 123,
        QueueDevice       => 123,
        QueueCatering     => 123,
        ValidID           => 1,
        Comment           => 'Comment',
        ImageID           => 12,
        UserID            => 123,
    );

=cut

sub RoomUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(RoomID Room ValidID UserID)) {
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
            'UPDATE rooms SET categories_id = ?, categories = ?, room = ?, building = ?, floor = ?, street = ?, post_code = ?, '
            . 'city = ?, calendar = ?, room_color = ?, setup_time = ?, persons = ?, price = ?, price_for = ?, currency = ?, equipment_bookable = ?, equipment = ?, '
            . 'description = ?, queue_booking = ?, queue_device = ?, queue_catering = ?, valid_id = ?, comment = ?, image_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{RoomCategoriesID}, \$Param{RoomCategories}, \$Param{Room}, \$Param{Building}, \$Param{Floor}, \$Param{Street},
            \$Param{PostCode}, \$Param{City}, \$Param{Calendar}, \$Param{RoomColor}, \$Param{SetupTime}, \$Param{Persons}, \$Param{Price}, \$Param{PriceFor},
            \$Param{Currency}, \$Param{EquipmentBookable}, \$Param{Equipment}, \$Param{Description}, \$Param{QueueBooking}, \$Param{QueueDevice},
            \$Param{QueueCatering}, \$Param{ValidID}, \$Param{Comment}, \$Param{ImageID}, \$Param{UserID}, \$Param{RoomID},
        ],
    );

    return 1;
}

=item RoomAdd()

add a Room

    my $RoomID = $BookingSystemRoomsObject->RoomAdd(
        RoomCategoriesID  => 123,
        RoomCategories    => 'RoomCategories',
        Room              => 'Room',
        Building          => 'Building',
        Floor             => 'Floor',
        Street            => 'Street',
        PostCode          => 'PostCode',
        City              => 'City',
        Calendar          => 'Calendar',
        RoomColor         => '123456',
        SetupTime         => '2',
        Persons           => '20',
        Price             => '1,50',
        PriceFor          => 1,
        Currency          => 'Euro',
        EquipmentBookable => 'EquipmentBookable',
        Equipment         => 'Equipment',
        Description       => 'Description',
        QueueBooking      => 123,
        QueueDevice       => 123,
        QueueCatering     => 123,
        ValidID           => 1,
        Comment           => 'Comment',
        ImageID           => 12,
        UserID            => 123,
    );

=cut

sub RoomAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Room ValidID UserID)) {
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
        SQL   => 'SELECT id FROM rooms WHERE room = ?',
        Bind  => [ \$Param{Room} ],
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
        SQL => 'INSERT INTO rooms '
            . '(categories_id, categories, room, building, floor, street, post_code, city, calendar, room_color, '
            . 'setup_time, persons, price, price_for, currency, equipment_bookable, equipment, description, queue_booking, '
            . 'queue_device, queue_catering, valid_id, comment, image_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{RoomCategoriesID}, \$Param{RoomCategories}, \$Param{Room}, \$Param{Building}, \$Param{Floor}, \$Param{Street},
            \$Param{PostCode}, \$Param{City}, \$Param{Calendar}, \$Param{RoomColor}, \$Param{SetupTime}, \$Param{Persons}, \$Param{Price}, \$Param{PriceFor},
            \$Param{Currency}, \$Param{EquipmentBookable}, \$Param{Equipment}, \$Param{Description}, \$Param{QueueBooking}, \$Param{QueueDevice},
            \$Param{QueueCatering}, \$Param{ValidID}, \$Param{Comment}, \$Param{ImageID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Request id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM rooms WHERE room = ?',
        Bind  => [ \$Param{Room} ],
        Limit => 1,
    );
    my $RequestID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestID = $Row[0];
    }

    return $RequestID;
}

=item RoomSearch()

return a hash list of Request

    my %RoomSearch = $BookingSystemRoomsObject->RoomSearch(
        Valid  => 0,   # (optional) default 1 (0|1)
    );

=cut

sub RoomSearch {
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

    if ( $Param{SortBy} eq "Room" ) {
        $Param{SortBy} = 'room';
    }
    if ( $Param{SortBy} eq "City" ) {
        $Param{SortBy} = 'city';
    }
    if ( $Param{SortBy} eq "PostCode" ) {
        $Param{SortBy} = 'post_code';
    }
    if ( $Param{SortBy} eq "Persons" ) {
        $Param{SortBy} = 'persons';
    }
    if ( $Param{SortBy} eq "Category" ) {
        $Param{SortBy} = 'categories';
    }

    if ( $Param{SortBy} ) {
        if ( $Param{SortBy} eq "persons" ) {
             $SQLSearch = 'ORDER BY CONVERT(' . $Param{SortBy} . ', DECIMAL) ' . $SQLSort;
        }
        else {
             $SQLSearch = 'ORDER BY ' . $Param{SortBy} . ' ' . $SQLSort;
        }
    }

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( !$Param{Valid} ) {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, room FROM rooms $SQLSearch",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, room FROM rooms WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} ) $SQLSearch",
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

    if ( $Result eq 'COUNT' ) {
        return $Count;
    }
    else {
        return @RoomList;
    }

    return %RoomList;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
