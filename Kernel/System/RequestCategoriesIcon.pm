# --
# Kernel/System/RequestCategoriesIcon.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: RequestCategoriesIcon.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RequestCategoriesIcon;

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

Kernel::System::RequestCategoriesIcon - standard attachment lib

=head1 DESCRIPTION

All standard attachment functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $RequestCategoriesIconObject = $Kernel::OM->Get('Kernel::System::RequestCategoriesIcon');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'RequestCategoriesIcon';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 RequestCategoriesIconAdd()

create a new standard attachment

    my $ID = $RequestCategoriesIconObject->RequestCategoriesIconAdd(
        Name        => 'Some Name',
        ValidID     => 1,
        Content     => $Content,
        ContentType => 'text/xml',
        Filename    => 'SomeFile.xml',
        UserID      => 123,
    );

=cut

sub RequestCategoriesIconAdd {
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
        SQL => 'INSERT INTO request_categories_icon '
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
        SQL  => 'SELECT id FROM request_categories_icon WHERE name = ? AND content_type = ?',
        Bind => [ \$Param{Name}, \$Param{ContentType}, ],
    );

    # fetch the result
    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return $ID;
}

=head2 RequestCategoriesIconGet()

get a standard attachment

    my %Data = $RequestCategoriesIconObject->RequestCategoriesIconGet(
        ID => $ID,
    );

=cut

sub RequestCategoriesIconGet {
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
            . 'FROM request_categories_icon WHERE id = ?',
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

=head2 RequestCategoriesIconUpdate()

update a new standard attachment

    my $ID = $RequestCategoriesIconObject->RequestCategoriesIconUpdate(
        ID          => $ID,
        Name        => 'Some Name',
        ValidID     => 1,
        Content     => $Content,
        ContentType => 'text/xml',
        Filename    => 'SomeFile.xml',
        UserID      => 123,
    );

=cut

sub RequestCategoriesIconUpdate {
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
    my %Data = $Self->RequestCategoriesIconGet(
        ID => $Param{ID},
    );

    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RequestCategoriesIconLookupID::' . $Data{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RequestCategoriesIconLookupName::' . $Data{Name},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RequestCategoriesIconLookupID::' . $Param{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RequestCategoriesIconLookupName::' . $Param{Name},
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update attachment
    return if !$DBObject->Do(
        SQL => 'UPDATE request_categories_icon SET name = ?, comments = ?, valid_id = ?, '
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
            SQL => 'UPDATE request_categories_icon SET content = ?, content_type = ?, '
                . ' filename = ? WHERE id = ?',
            Bind => [
                \$Param{Content}, \$Param{ContentType}, \$Param{Filename}, \$Param{ID},
            ],
        );
    }

    return 1;
}

=head2 RequestCategoriesIconDelete()

delete a standard attachment

    $RequestCategoriesIconObject->RequestCategoriesIconDelete(
        ID => $ID,
    );

=cut

sub RequestCategoriesIconDelete {
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
    my %Data = $Self->RequestCategoriesIconGet(
        ID => $Param{ID},
    );

    $Param{NullID} = '0';

    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RequestCategoriesIconLookupID::' . $Param{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'RequestCategoriesIconLookupName::' . $Data{Name},
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update RequestCategories
    return if !$DBObject->Do(
        SQL => 'UPDATE requestcategories SET image_id = ? WHERE image_id = ?',
        Bind => [
            \$Param{NullID}, \$Param{ID},
        ],
    );

    # sql
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM request_categories_icon WHERE ID = ?',
        Bind => [ \$Param{ID} ],
    );

    return 1;
}

=head2 RequestCategoriesIconLookup()

lookup for a standard attachment

    my $ID = $RequestCategoriesIconObject->RequestCategoriesIconLookup(
        RequestCategoriesIcon => 'Some Name',
    );

    my $Name = $RequestCategoriesIconObject->RequestCategoriesIconLookup(
        RequestCategoriesIconID => $ID,
    );

=cut

sub RequestCategoriesIconLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestCategoriesIcon} && !$Param{RequestCategoriesIconID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Got no RequestCategoriesIcon or RequestCategoriesIconID!',
        );
        return;
    }

    # check if we ask the same request?
    my $CacheKey;
    my $Key;
    my $Value;
    if ( $Param{RequestCategoriesIconID} ) {
        $CacheKey = 'RequestCategoriesIconLookupID::' . $Param{RequestCategoriesIconID};
        $Key      = 'RequestCategoriesIconID';
        $Value    = $Param{RequestCategoriesIconID};
    }
    else {
        $CacheKey = 'RequestCategoriesIconLookupName::' . $Param{RequestCategoriesIcon};
        $Key      = 'RequestCategoriesIcon';
        $Value    = $Param{RequestCategoriesIcon};
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
    if ( $Param{RequestCategoriesIcon} ) {
        $SQL = 'SELECT id FROM request_categories_icon WHERE name = ?';
        push @Bind, \$Param{RequestCategoriesIcon};
    }
    else {
        $SQL = 'SELECT name FROM request_categories_icon WHERE id = ?';
        push @Bind, \$Param{RequestCategoriesIconID};
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

=head2 RequestCategoriesIconList()

get list of standard attachments - return a hash (ID => Name (Filename))

    my %List = $RequestCategoriesIconObject->RequestCategoriesIconList(
        Valid => 0,  # optional, defaults to 1
    );

returns:

        %List = (
          '1' => 'Some Name' ( Filname ),
          '2' => 'Some Name' ( Filname ),
          '3' => 'Some Name' ( Filname ),
    );

=cut

sub RequestCategoriesIconList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} // 1;

    # create the valid list
    my $ValidIDs = join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # build SQL
    my $SQL = 'SELECT id, name, filename FROM request_categories_icon';

    # add WHERE statement in case Valid param is set to '1', for valid RequestCategoriesIcon
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
    my %RequestCategoriesIconList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestCategoriesIconList{ $Row[0] } = "$Row[1] ( $Row[2] )";
    }

    return %RequestCategoriesIconList;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
