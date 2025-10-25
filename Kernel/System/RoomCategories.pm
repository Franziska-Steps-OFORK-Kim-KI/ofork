# --
# Kernel/System/RoomCategories.pm - all service function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: RoomCategories.pm,v 1.4 2016/11/20 19:30:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RoomCategories;

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

Kernel::System::RoomCategories - RoomCategories lib

=head1 SYNOPSIS

All RoomCategories functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $RoomCategoriesObject = $Kernel::OM->Get('Kernel::System::RoomCategories');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item RoomCategoriesList()

return a hash list of RoomCategories

    my %RoomCategoriesList = $RoomCategoriesObject->RoomCategoriesList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub RoomCategoriesList {
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

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # ask database
    $DBObject->Prepare(
        SQL => 'SELECT id, name, valid_id FROM roomcategories',
    );

    # fetch the result
    my %RoomCategoriesList;
    my %RoomCategoriesValidList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomCategoriesList{ $Row[0] }      = $Row[1];
        $RoomCategoriesValidList{ $Row[0] } = $Row[2];
    }

    return %RoomCategoriesList if !$Param{Valid};

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # duplicate RoomCategories list
    my %RoomCategoriesListTmp = %RoomCategoriesList;

    # add suffix for correct sorting
    for my $RoomCategoriesID ( keys %RoomCategoriesListTmp ) {
        $RoomCategoriesListTmp{$RoomCategoriesID} .= '::';
    }

    my %RoomCategoriesInvalidList;
    CHANGECATEGORIESID:
    for my $RoomCategoriesID (
        sort { $RoomCategoriesListTmp{$a} cmp $RoomCategoriesListTmp{$b} }
        keys %RoomCategoriesListTmp
        )
    {

        my $Valid = scalar grep { $_ eq $RoomCategoriesValidList{$RoomCategoriesID} } @ValidIDs;

        next CHANGECATEGORIESID if $Valid;

        $RoomCategoriesInvalidList{ $RoomCategoriesList{$RoomCategoriesID} } = 1;
        delete $RoomCategoriesList{$RoomCategoriesID};
    }

    # delete invalid RoomCategories and childs
    for my $RoomCategoriesID ( keys %RoomCategoriesList ) {

        INVALIDNAME:
        for my $InvalidName ( keys %RoomCategoriesInvalidList ) {

            if ( $RoomCategoriesList{$RoomCategoriesID} =~ m{ \A \Q$InvalidName\E :: }xms ) {
                delete $RoomCategoriesList{$RoomCategoriesID};
                last INVALIDNAME;
            }
        }
    }

    return %RoomCategoriesList;
}

=item RoomCategoriesGet()

return a RoomCategories as hash

Return
    $RoomCategoriesData{RoomCategoriesID}
    $RoomCategoriesData{ParentID}
    $RoomCategoriesData{Name}
    $RoomCategoriesData{NameShort}
    $RoomCategoriesData{ValidID}
    $RoomCategoriesData{Comment}
    $RoomCategoriesData{CreateTime}
    $RoomCategoriesData{CreateBy}
    $RoomCategoriesData{ChangeTime}
    $RoomCategoriesData{ChangeBy}

    my %RoomCategoriesData = $RoomCategoriesObject->RoomCategoriesGet(
        RoomCategoriesID => 123,
        UserID           => 1,
    );

    my %RoomCategoriesData = $RoomCategoriesObject->RoomCategoriesGet(
        Name    => 'RoomCategories::SubRoomCategories',
        UserID  => 1,
    );

=cut

sub RoomCategoriesGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # either RoomCategoriesID or Name must be passed
    if ( !$Param{RoomCategoriesID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need RoomCategoriesID or Name!',
        );
        return;
    }

    # check that not both RoomCategoriesID and Name are given
    if ( $Param{RoomCategoriesID} && $Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need either RoomCategoriesID OR Name - not both!',
        );
        return;
    }

    # lookup the RoomCategoriesID
    if ( $Param{Name} ) {
        $Param{RoomCategoriesID} = $Self->RoomCategoriesLookup(
            Name => $Param{Name},
        );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get RoomCategories from db
    $DBObject->Prepare(
        SQL =>
            'SELECT id, name, valid_id, comments, create_time, create_by, change_time, change_by '
            . 'FROM roomcategories WHERE id = ?',
        Bind  => [ \$Param{RoomCategoriesID} ],
        Limit => 1,
    );

    # fetch the result
    my %RoomCategoriesData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomCategoriesData{RoomCategoriesID} = $Row[0];
        $RoomCategoriesData{Name}             = $Row[1];
        $RoomCategoriesData{ValidID}          = $Row[2];
        $RoomCategoriesData{Comment}          = $Row[3] || '';
        $RoomCategoriesData{CreateTime}       = $Row[4];
        $RoomCategoriesData{CreateBy}         = $Row[5];
        $RoomCategoriesData{ChangeTime}       = $Row[6];
        $RoomCategoriesData{ChangeBy}         = $Row[7];
    }

    # check RoomCategories
    if ( !$RoomCategoriesData{RoomCategoriesID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No such RoomCategoriesID ($Param{RoomCategoriesID})!",
        );
        return;
    }

    # create short name and parentid
    $RoomCategoriesData{NameShort} = $RoomCategoriesData{Name};
    if ( $RoomCategoriesData{Name} =~ m{ \A (.*) :: (.+?) \z }xms ) {
        $RoomCategoriesData{NameShort} = $2;

        # lookup parent
        my $RoomCategoriesID = $Self->RoomCategoriesLookup(
            Name => $1,
        );
        $RoomCategoriesData{ParentID} = $RoomCategoriesID;
    }

    return %RoomCategoriesData;
}

=item RoomCategoriesLookup()

return a RoomCategories name and id

    my $RoomCategoriesName = $RoomCategoriesObject->RoomCategoriesLookup(
        RoomCategoriesID => 123,
    );

    or

    my $RoomCategoriesID = $RoomCategoriesObject->RoomCategoriesLookup(
        Name => 'RoomCategories::SubRoomCategories',
    );

=cut

sub RoomCategoriesLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RoomCategoriesID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need RoomCategoriesID or Name!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{RoomCategoriesID} ) {

        # check cache
        my $CacheKey = 'Cache::RoomCategoriesLookup::ID::' . $Param{RoomCategoriesID};
        if ( defined $Self->{$CacheKey} ) {
            return $Self->{$CacheKey};
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT name FROM roomcategories WHERE id = ?',
            Bind  => [ \$Param{RoomCategoriesID} ],
            Limit => 1,
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->{$CacheKey} = $Row[0];
        }

        return $Self->{$CacheKey};
    }
    else {

        # check cache
        my $CacheKey = 'Cache::RoomCategoriesLookup::Name::' . $Param{Name};
        if ( defined $Self->{$CacheKey} ) {
            return $Self->{$CacheKey};
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT id FROM roomcategories WHERE name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->{$CacheKey} = $Row[0];
        }

        return $Self->{$CacheKey};
    }
}

=item RoomCategoriesAdd()

add a RoomCategories

    my $RoomCategoriesID = $RoomCategoriesObject->RoomCategoriesAdd(
        Name     => 'RoomCategories Name',
        ParentID => 1,           # (optional)
        ValidID  => 1,
        Comment  => 'Comment',    # (optional)
        UserID   => 1,
    );

=cut

sub RoomCategoriesAdd {
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

    # set comment
    $Param{Comment} ||= '';

    # get object
    my $DBObject        = $Kernel::OM->Get('Kernel::System::DB');
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    # cleanup given params
    for my $Argument (qw(Name Comment)) {
        $CheckItemObject->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }

    # check RoomCategories name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't add RoomCategories! Invalid RoomCategories name '$Param{Name}'!",
        );
        return;
    }

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {
        my $ParentName
            = $Self->RoomCategoriesLookup( RoomCategoriesID => $Param{ParentID}, );
        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }
    }

    # find existing RoomCategories
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM roomcategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( $DBObject->FetchrowArray() ) {
        $Exists = 1;
    }

    # add RoomCategories to database
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                'Can\'t add RoomCategories! RoomCategories with same name and parent already exists.'
        );
        return;
    }

    return if !$DBObject->Do(
        SQL => 'INSERT INTO roomcategories '
            . '(name, valid_id, comments, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{Comment},
            \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get RoomCategories id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM roomcategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $RoomCategoriesID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RoomCategoriesID = $Row[0];
    }

    return $RoomCategoriesID;
}

=item RoomCategoriesUpdate()

update a existing RoomCategories

    my $True = $RoomCategoriesObject->RoomCategoriesUpdate(
        RoomCategoriesID => 123,
        ParentID  => 1,           # (optional)
        Name      => 'RoomCategories Name',
        ValidID   => 1,
        Comment   => 'Comment',    # (optional)
        UserID    => 1,
    );

=cut

sub RoomCategoriesUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(RoomCategoriesID Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get object
    my $DBObject        = $Kernel::OM->Get('Kernel::System::DB');
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    # set default comment
    $Param{Comment} ||= '';

    # cleanup given params
    for my $Argument (qw(Name Comment)) {
        $CheckItemObject->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }

    # check RoomCategories name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Can't update RoomCategories! Invalid RoomCategories name '$Param{Name}'!",
        );
        return;
    }

    # get old name of RoomCategories
    my $OldRoomCategoriesName
        = $Self->RoomCategoriesLookup( RoomCategoriesID => $Param{RoomCategoriesID}, );

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {

        # lookup RoomCategories
        my $ParentName = $Self->RoomCategoriesLookup(
            RoomCategoriesID => $Param{ParentID},
        );

        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }

        # check, if selected parent was a child of this RoomCategories
        if ( $Param{FullName} =~ m{ \A ( \Q$OldRoomCategoriesName\E ) :: }xms ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Can\'t update RoomCategories! Invalid parent was selected.'
            );
            return;
        }
    }

    # find exists RoomCategories
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM roomcategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{RoomCategoriesID} ne $Row[0] ) {
            $Exists = 1;
        }
    }

    # update RoomCategories
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                'Can\'t update RoomCategories! RoomCategories with same name and parent already exists.'
        );
        return;

    }

    # update RoomCategories
    return if !$DBObject->Do(
        SQL => 'UPDATE roomcategories SET name = ?, valid_id = ?, comments = ?,'
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{Comment},
            \$Param{UserID}, \$Param{RoomCategoriesID},
        ],
    );

    # find all childs
    $DBObject->Prepare(
        SQL => "SELECT id, name FROM roomcategories WHERE name LIKE '"
            . $DBObject->Quote( $OldRoomCategoriesName, 'Like' )
            . "::%'",
    );
    my @Childs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Child;
        $Child{RoomCategoriesID} = $Row[0];
        $Child{Name}               = $Row[1];
        push @Childs, \%Child;
    }

    # update childs
    for my $Child (@Childs) {
        $Child->{Name} =~ s{ \A ( \Q$OldRoomCategoriesName\E ) :: }{$Param{FullName}::}xms;
        $DBObject->Do(
            SQL => 'UPDATE roomcategories SET name = ? WHERE id = ?',
            Bind => [ \$Child->{Name}, \$Child->{RoomCategoriesID} ],
        );
    }
    return 1;
}

=item RoomCategoriesSearch()

return RoomCategories ids as an array

    my @RoomCategoriesList = $RoomCategoriesObject->RoomCategoriesSearch(
        Name   => 'RoomCategories Name', # (optional)
        Limit  => 122,            # (optional) default 1000
        UserID => 1,
    );

=cut

sub RoomCategoriesSearch {
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

    # set default limit
    $Param{Limit} ||= 1000;

    # create sql query
    my $SQL
        = "SELECT id FROM roomcategories WHERE valid_id IN ( ${\(join ', ', $Self->{ValidObject}->ValidIDsGet())} )";

    if ( $Param{Name} ) {

        # quote
        $Param{Name} = $DBObject->Quote( $Param{Name}, 'Like' );

        # replace * with % and clean the string
        $Param{Name} =~ s{ \*+ }{%}xmsg;
        $Param{Name} =~ s{ %+ }{%}xmsg;

        $SQL .= " AND name LIKE '$Param{Name}' ";
    }

    $SQL .= ' ORDER BY name';

    # search RoomCategories in db
    $DBObject->Prepare( SQL => $SQL );

    my @RoomCategoriesList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @RoomCategoriesList, $Row[0];
    }

    return @RoomCategoriesList;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
