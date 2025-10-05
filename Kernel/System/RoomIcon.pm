# --
# Kernel/System/RoomIcon.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: RoomIcon.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RoomIcon;

use strict;
use warnings;

use MIME::Base64;

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Encode',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::RoomIcon - standard attachment lib

=head1 DESCRIPTION

All standard attachment functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $RoomIconObject = $Kernel::OM->Get('Kernel::System::RoomIcon');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'RoomIcon';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 RoomIconAdd()

create a new standard attachment

    my $ID = $RoomIconObject->RoomIconAdd(
        Name        => 'Some Name',
        ValidID     => 1,
        Content     => $Content,
        ContentType => 'text/xml',
        Filename    => 'SomeFile.xml',
        UserID      => 123,
    );

=cut

sub RoomIconAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Name ValidID Content ContentType Filename UserID)) {
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

    # encode attachment if it's a postgresql backend!!!
    if ( !$DBObject->GetDatabaseFunction('DirectBlob') ) {
        $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput( \$Param{Content} );
        $Param{Content} = encode_base64( $Param{Content} );
    }

    # insert attachment
    return if !$DBObject->Do(
        SQL => 'INSERT INTO room_icon '
            . ' (name, content_type, content, filename, valid_id, comments, '
            . ' create_time, create_by, change_time, change_by) VALUES '
            . ' (?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name},    \$Param{ContentType}, \$Param{Content}, \$Param{Filename},
            \$Param{ValidID}, \$Param{Comment},     \$Param{UserID},  \$Param{UserID},
        ],
    );

    # get the id
    $DBObject->Prepare(
        SQL  => 'SELECT id FROM room_icon WHERE name = ? AND content_type = ?',
        Bind => [ \$Param{Name}, \$Param{ContentType}, ],
    );

    # fetch the result
    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return $ID;
}

=head2 RoomIconGet()

get a standard attachment

    my %Data = $RoomIconObject->RoomIconGet(
        ID => $ID,
    );

=cut

sub RoomIconGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL => 'SELECT name, content_type, content, filename, valid_id, comments, '
            . 'create_time, create_by, change_time, change_by '
            . 'FROM room_icon WHERE id = ?',
        Bind   => [ \$Param{ID} ],
        Encode => [ 1, 1, 0, 1, 1, 1 ],
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        # decode attachment if it's a postgresql backend!!!
        if ( !$DBObject->GetDatabaseFunction('DirectBlob') ) {
            $Row[2] = decode_base64( $Row[2] );
        }
        %Data = (
            ID          => $Param{ID},
            Name        => $Row[0],
            ContentType => $Row[1],
            Content     => $Row[2],
            Filename    => $Row[3],
            ValidID     => $Row[4],
            Comment     => $Row[5],
            CreateTime  => $Row[6],
            CreateBy    => $Row[7],
            ChangeTime  => $Row[8],
            ChangeBy    => $Row[9],
        );
    }

    return %Data;
}

=head2 RoomIconUpdate()

update a new standard attachment

    my $ID = $RoomIconObject->RoomIconUpdate(
        ID          => $ID,
        Name        => 'Some Name',
        ValidID     => 1,
        Content     => $Content,
        ContentType => 'text/xml',
        Filename    => 'SomeFile.xml',
        UserID      => 123,
    );

=cut

sub RoomIconUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ID Name ValidID UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    # reset cache
    my %Data = $Self->RoomIconGet(
        ID => $Param{ID},
    );

    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RoomIconLookupID::' . $Data{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RoomIconLookupName::' . $Data{Name},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RoomIconLookupID::' . $Param{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RoomIconLookupName::' . $Param{Name},
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update attachment
    return if !$DBObject->Do(
        SQL => 'UPDATE room_icon SET name = ?, comments = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    if ( $Param{Content} ) {

        # encode attachment if it's a postgresql backend!!!
        if ( !$DBObject->GetDatabaseFunction('DirectBlob') ) {
            $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput( \$Param{Content} );
            $Param{Content} = encode_base64( $Param{Content} );
        }

        return if !$DBObject->Do(
            SQL => 'UPDATE room_icon SET content = ?, content_type = ?, '
                . ' filename = ? WHERE id = ?',
            Bind => [
                \$Param{Content}, \$Param{ContentType}, \$Param{Filename}, \$Param{ID},
            ],
        );
    }

    return 1;
}

=head2 RoomIconDelete()

delete a standard attachment

    $RoomIconObject->RoomIconDelete(
        ID => $ID,
    );

=cut

sub RoomIconDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    # reset cache
    my %Data = $Self->RoomIconGet(
        ID => $Param{ID},
    );

    $Param{NullID} = '0';

    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RoomIconLookupID::' . $Param{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RoomIconLookupName::' . $Data{Name},
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update Room
    return if !$DBObject->Do(
        SQL => 'UPDATE rooms SET image_id = ? WHERE image_id = ?',
        Bind => [
            \$Param{NullID}, \$Param{ID},
        ],
    );

    # sql
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM room_icon WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    return 1;
}

=head2 RoomIconLookup()

lookup for a standard attachment

    my $ID = $RoomIconObject->RoomIconLookup(
        RoomIcon => 'Some Name',
    );

    my $Name = $RoomIconObject->RoomIconLookup(
        RoomIconID => $ID,
    );

=cut

sub RoomIconLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RoomIcon} && !$Param{RoomIconID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Got no RoomIcon or RoomIconID!',
        );
        return;
    }

    # check if we ask the same request?
    my $CacheKey;
    my $Key;
    my $Value;
    if ( $Param{RoomIconID} ) {
        $CacheKey = 'RoomIconLookupID::' . $Param{RoomIconID};
        $Key      = 'RoomIconID';
        $Value    = $Param{RoomIconID};
    }
    else {
        $CacheKey = 'RoomIconLookupName::' . $Param{RoomIcon};
        $Key      = 'RoomIcon';
        $Value    = $Param{RoomIcon};
    }

    my $Cached = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type           => $Self->{CacheType},
        Key            => $CacheKey,
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    return $Cached if $Cached;

    # get data
    my $SQL;
    my @Bind;
    if ( $Param{RoomIcon} ) {
        $SQL = 'SELECT id FROM room_icon WHERE name = ?';
        push @Bind, \$Param{RoomIcon};
    }
    else {
        $SQL = 'SELECT name FROM room_icon WHERE id = ?';
        push @Bind, \$Param{RoomIconID};
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    my $DBValue;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $DBValue = $Row[0];
    }

    # check if data exists
    if ( !$DBValue ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Found no $Key found for $Value!",
        );
        return;
    }

    # cache result
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type           => $Self->{CacheType},
        TTL            => $Self->{CacheTTL},
        Key            => $CacheKey,
        Value          => $DBValue,
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    return $DBValue;
}

=head2 RoomIconList()

get list of standard attachments - return a hash (ID => Name (Filename))

    my %List = $RoomIconObject->RoomIconList(
        Valid => 0,  # optional, defaults to 1
    );

returns:

        %List = (
          '1' => 'Some Name' ( Filname ),
          '2' => 'Some Name' ( Filname ),
          '3' => 'Some Name' ( Filname ),
    );

=cut

sub RoomIconList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} // 1;

    # create the valid list
    my $ValidIDs = join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # build SQL
    my $SQL = 'SELECT id, name, filename FROM room_icon';

    # add WHERE statement in case Valid param is set to '1', for valid RoomIcon
    if ($Valid) {
        $SQL .= ' WHERE valid_id IN (' . $ValidIDs . ')';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get data from database
    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    # fetch the result
    my %RoomIconList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomIconList{ $Row[0] } = "$Row[1] ( $Row[2] )";
    }

    return %RoomIconList;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
