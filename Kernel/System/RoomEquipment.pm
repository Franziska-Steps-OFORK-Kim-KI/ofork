# --
# Kernel/System/RoomEquipment.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: RoomEquipment.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RoomEquipment;

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

Kernel::System::RoomEquipment - Equipment lib

=head1 DESCRIPTION

All Equipment functions. E. g. to add Equipments.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $RoomEquipmentObject = $Kernel::OM->Get('Kernel::System::RoomEquipment');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 EquipmentLookup()

get id or name for Equipment

    my $Equipment = $RoomEquipmentObject->EquipmentLookup(
        EquipmentID => $EquipmentID,
    );

    my $EquipmentID = $RoomEquipmentObject->EquipmentLookup(
        Equipment => $Equipment,
    );

=cut

sub EquipmentLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Equipment} && !$Param{EquipmentID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Equipment or EquipmentID!',
        );
        return;
    }

    # get Equipment list
    my %EquipmentList = $Self->EquipmentList(
        Valid => 0,
    );

    return $EquipmentList{ $Param{EquipmentID} } if $Param{EquipmentID};

    # create reverse list
    my %EquipmentListReverse = reverse %EquipmentList;

    return $EquipmentListReverse{ $Param{Equipment} };
}

=head2 EquipmentAdd()

to add a Equipment

    my $ID = $RoomEquipmentObject->EquipmentAdd(
        Name          => 'example-Equipment',
        Quantity      => 'Quantity',   # optional
        EquipmentType => 'EquipmentType',   # optional
        Price         => 'Price',   # optional
        PriceFor      => 'PriceFor',   # optional
        Currency      => 'Currency'  # optional
        Model         => 'Model',   # optional
        Bookable      => 1,
        Comment       => 'comment describing the Equipment',   # optional
        ValidID       => 1,
        UserID        => 123,
    );

=cut

sub EquipmentAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %ExistingEquipments = reverse $Self->EquipmentList( Valid => 0 );
    if ( defined $ExistingEquipments{ $Param{Name} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A Equipment with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new Equipment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO room_equipments (name, quantity, equipment_type, price, price_for, currency, model, bookable, comments, valid_id, '
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{Quantity}, \$Param{EquipmentType}, \$Param{Price}, \$Param{PriceFor}, \$Param{Currency}, \$Param{Model}, \$Param{Bookable},
            \$Param{Comment}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new Equipment id
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM room_equipments WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    my $EquipmentID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $EquipmentID = $Row[0];
    }

    return $EquipmentID;
}

=head2 EquipmentGet()

returns a hash with Equipment data

    my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
        ID => 2,
    );

This returns something like:

    %EquipmentData = (
        'Name'       => 'admin',
        'ID'         => 2,
        'ValidID'    => '1',
        'CreateTime' => '2010-04-07 15:41:15',
        'ChangeTime' => '2010-04-07 15:41:15',
        'Comment'    => 'Equipment of all administrators.',
    );

=cut

sub EquipmentGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # get Equipment list
    my %EquipmentList = $Self->EquipmentDataList(
        Valid => 0,
    );

    # extract Equipment data
    my %Equipment;
    if ( $EquipmentList{ $Param{ID} } && ref $EquipmentList{ $Param{ID} } eq 'HASH' ) {
        %Equipment = %{ $EquipmentList{ $Param{ID} } };
    }

    return %Equipment;
}

=head2 EquipmentUpdate()

update of a Equipment

    my $Success = $RoomEquipmentObject->EquipmentUpdate(
        ID            => 123,
        Name          => 'example-Equipment',
        Quantity      => 'Quantity',   # optional
        EquipmentType => 'EquipmentType',   # optional
        Price         => 'Price',   # optional
        PriceFor      => 'PriceFor',   # optional
        Model         => 'Model',   # optional
        Bookable      => 1,   # optional
        Comment       => 'comment describing the Equipment',   # optional
        ValidID       => 1,
        UserID        => 123,
    );

=cut

sub EquipmentUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Name ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %ExistingEquipments = reverse $Self->EquipmentList( Valid => 0 );
    if ( defined $ExistingEquipments{ $Param{Name} } && $ExistingEquipments{ $Param{Name} } != $Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A Equipment with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # set default value
    $Param{Comment} ||= '';

    # get current Equipment data
    my %EquipmentData = $Self->EquipmentGet(
        ID => $Param{ID},
    );

    # check if update is required
    my $ChangeRequired;
    KEY:
    for my $Key (qw(Name Quantity EquipmentType Price PriceFor Currency Model Bookable Comment ValidID)) {

        next KEY if defined $EquipmentData{$Key} && $EquipmentData{$Key} eq $Param{$Key};

        $ChangeRequired = 1;

        last KEY;
    }

    return 1 if !$ChangeRequired;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update Equipment in database
    return if !$DBObject->Do(
        SQL => 'UPDATE room_equipments SET name = ?, quantity = ?, equipment_type = ?, price = ?, price_for = ?, currency = ?, model = ?, bookable = ?, comments = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Quantity}, \$Param{EquipmentType}, \$Param{Price}, \$Param{PriceFor}, \$Param{Currency}, \$Param{Model}, \$Param{Bookable},
            \$Param{Comment}, \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    return 1 if $EquipmentData{ValidID} eq $Param{ValidID};

    return 1;
}

=head2 EquipmentList()

returns a hash of all Equipments

    my %Equipments = $RoomEquipmentObject->EquipmentList(
        Valid    => 1,   # (optional) default 0
        Bookable => 1,    # (optional) default 0
    );

the result looks like

    %Equipments = (
        '1' => 'users',
        '2' => 'admin',
        '3' => 'stats',
        '4' => 'secret',
    );

=cut

sub EquipmentList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} ? 1 : 0;

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # get Equipment data list
    my %EquipmentDataList = $Self->EquipmentDataList();

    my %EquipmentListValid;
    my %EquipmentListAll;
    KEY:
    for my $Key ( sort keys %EquipmentDataList ) {

        next KEY if !$Key;

        # add Equipment to the list of all Equipments
        $EquipmentListAll{$Key} = $EquipmentDataList{$Key}->{Name};

        my $Match;
        VALIDID:
        for my $ValidID (@ValidIDs) {

            next VALIDID if $ValidID ne $EquipmentDataList{$Key}->{ValidID};

            $Match = 1;

            last VALIDID;
        }

        next KEY if !$Match;

        # add Equipment to the list of valid Equipments
        $EquipmentListValid{$Key} = $EquipmentDataList{$Key}->{Name};
    }

    return %EquipmentListValid if $Valid;
    return %EquipmentListAll;
}

=head2 EquipmentListForm()

returns a hash of all Equipments

    my %Equipments = $RoomEquipmentObject->EquipmentListForm(
        Valid    => 1,   # (optional) default 0
        Bookable => 1,    # (optional) default 0
    );

the result looks like

    %Equipments = (
        '1' => 'users',
        '2' => 'admin',
        '3' => 'stats',
        '4' => 'secret',
    );

=cut

sub EquipmentListForm {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} ? 1 : 0;

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # get Equipment data list
    my %EquipmentDataList = $Self->EquipmentDataListForm(
        Bookable => $Param{Bookable},
    );

    my %EquipmentListValid;
    my %EquipmentListAll;
    KEY:
    for my $Key ( sort keys %EquipmentDataList ) {

        next KEY if !$Key;

        # add Equipment to the list of all Equipments
        $EquipmentListAll{$Key} = $EquipmentDataList{$Key}->{Name};

        my $Match;
        VALIDID:
        for my $ValidID (@ValidIDs) {

            next VALIDID if $ValidID ne $EquipmentDataList{$Key}->{ValidID};

            $Match = 1;

            last VALIDID;
        }

        next KEY if !$Match;

        # add Equipment to the list of valid Equipments
        $EquipmentListValid{$Key} = $EquipmentDataList{$Key}->{Name};
    }

    return %EquipmentListValid if $Valid;
    return %EquipmentListAll;
}


=head2 EquipmentDataList()

returns a hash of all Equipment data

    my %EquipmentDataList = $RoomEquipmentObject->EquipmentDataList();

the result looks like

    %EquipmentDataList = (
        1 => {
            ID         => 1,
            Name       => 'Equipment 1',
            Comment    => 'The Comment of Equipment 1',
            ValidID    => 1,
            CreateTime => '2014-01-01 00:20:00',
            CreateBy   => 1,
            ChangeTime => '2014-01-02 00:10:00',
            ChangeBy   => 1,
        },
        2 => {
            ID         => 2,
            Name       => 'Equipment 2',
            Comment    => 'The Comment of Equipment 2',
            ValidID    => 1,
            CreateTime => '2014-11-01 10:00:00',
            CreateBy   => 1,
            ChangeTime => '2014-11-02 01:00:00',
            ChangeBy   => 1,
        },
    );

=cut

sub EquipmentDataList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all Equipment data from database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, quantity, equipment_type, price, price_for, currency, model, bookable, comments, valid_id, create_time, create_by, change_time, change_by FROM room_equipments',
    );

    # fetch the result
    my %EquipmentDataList;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        $EquipmentDataList{ $Row[0] } = {
            ID            => $Row[0],
            Name          => $Row[1],
            Quantity      => $Row[2] || '',
            EquipmentType => $Row[3] || '',
            Price         => $Row[4] || '',
            PriceFor      => $Row[5] || '',
            Currency      => $Row[6] || '',
            Model         => $Row[7] || '',
            Bookable      => $Row[8] || '',
            Comment       => $Row[9] || '',
            ValidID       => $Row[10],
            CreateTime    => $Row[11],
            CreateBy      => $Row[12],
            ChangeTime    => $Row[13],
            ChangeBy      => $Row[14],
        };
    }

    return %EquipmentDataList;
}

=head2 EquipmentDataListForm()

returns a hash of all Equipment data

    my %EquipmentDataList = $RoomEquipmentObject->EquipmentDataListForm();

the result looks like

    %EquipmentDataList = (
        1 => {
            ID         => 1,
            Name       => 'Equipment 1',
            Comment    => 'The Comment of Equipment 1',
            ValidID    => 1,
            CreateTime => '2014-01-01 00:20:00',
            CreateBy   => 1,
            ChangeTime => '2014-01-02 00:10:00',
            ChangeBy   => 1,
        },
        2 => {
            ID         => 2,
            Name       => 'Equipment 2',
            Comment    => 'The Comment of Equipment 2',
            ValidID    => 1,
            CreateTime => '2014-11-01 10:00:00',
            CreateBy   => 1,
            ChangeTime => '2014-11-02 01:00:00',
            ChangeBy   => 1,
        },
    );

=cut

sub EquipmentDataListForm {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{Bookable} == 1 ) {

        # get all Equipment data from database
        return if !$DBObject->Prepare(
            SQL => 'SELECT id, name, quantity, equipment_type, price, price_for, currency, model, bookable, comments, valid_id, create_time, create_by, change_time, change_by FROM room_equipments WHERE bookable = 1',
        );
    }
    else {

        # get all Equipment data from database
        return if !$DBObject->Prepare(
            SQL => 'SELECT id, name, quantity, equipment_type, price, price_for, currency, model, bookable, comments, valid_id, create_time, create_by, change_time, change_by FROM room_equipments WHERE bookable = 2',
        );
    }

    # fetch the result
    my %EquipmentDataList;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        $EquipmentDataList{ $Row[0] } = {
            ID            => $Row[0],
            Name          => $Row[1],
            Quantity      => $Row[2] || '',
            EquipmentType => $Row[3] || '',
            Price         => $Row[4] || '',
            PriceFor      => $Row[5] || '',
            Currency      => $Row[6] || '',
            Model         => $Row[7] || '',
            Bookable      => $Row[8] || '',
            Comment       => $Row[9] || '',
            ValidID       => $Row[10],
            CreateTime    => $Row[11],
            CreateBy      => $Row[12],
            ChangeTime    => $Row[13],
            ChangeBy      => $Row[14],
        };
    }

    return %EquipmentDataList;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
