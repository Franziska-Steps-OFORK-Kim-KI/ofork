# --
# Kernel/System/TimeTrackingCategory.pm - the time tracking lib
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de/
# --
# $Id: TimeTrackingCategory.pm,v 1.1 2018/12/02 08:07:54 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TimeTrackingCategory;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SysConfig',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::TimeTrackingCategory - TimeTrackingCategory lib

=head1 DESCRIPTION

All type functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $TimeTrackingCategoryObject = $Kernel::OM->Get('Kernel::System::TimeTrackingCategory');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 CategoryAdd()

add a new category

    my $ID = $TimeTrackingCategoryObject->CategoryAdd(
        Name    => 'New category',
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub CategoryAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Name ValidID UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # check if a type with this name already exists
    if ( $Self->NameExistsCheck( Name => $Param{Name} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A type with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO tracking_category (name, valid_id, '
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [ \$Param{Name}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID} ],
    );

    # get new type id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT id FROM tracking_category WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }
    return if !$ID;

    return $ID;
}

=head2 CategoryGet()

get types attributes

    my %Category = $TimeTrackingCategoryObject->CategoryGet(
        ID => 123,
    );

    my %Category = $TimeTrackingCategoryObject->CategoryGet(
        Name => 'default',
    );

Returns:

    Category = (
        ID                  => '123',
        Name                => 'Category',
        ValidID             => '1',
        CreateTime          => '2010-04-07 15:41:15',
        CreateBy            => '321',
        ChangeTime          => '2010-04-07 15:59:45',
        ChangeBy            => '223',
    );

=cut

sub CategoryGet {
    my ( $Self, %Param ) = @_;

    # either ID or Name must be passed
    if ( !$Param{ID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID or Name!',
        );
        return;
    }

    # check that not both ID and Name are given
    if ( $Param{ID} && $Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need either ID OR Name - not both!',
        );
        return;
    }

    # lookup the ID
    if ( $Param{Name} ) {
        $Param{ID} = $Self->CategoryLookup(
            Category => $Param{Name},
        );
        if ( !$Param{ID} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "CategoryID for Category '$Param{Name}' not found!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask the database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, valid_id, '
            . 'create_time, create_by, change_time, change_by '
            . 'FROM tracking_category WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # fetch the result
    my %Category;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Category{ID}         = $Data[0];
        $Category{Name}       = $Data[1];
        $Category{ValidID}    = $Data[2];
        $Category{CreateTime} = $Data[3];
        $Category{CreateBy}   = $Data[4];
        $Category{ChangeTime} = $Data[5];
        $Category{ChangeBy}   = $Data[6];
    }

    # no data found
    if ( !%Category ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Category '$Param{ID}' not found!",
        );
        return;
    }

    return %Category;
}

=head2 CategoryUpdate()

update category attributes

    $TimeTrackingCategoryObject->CategoryUpdate(
        ID      => 123,
        Name    => 'New Type',
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub CategoryUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ID Name ValidID UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # check if a type with this name already exists
    if (
        $Self->NameExistsCheck(
            Name => $Param{Name},
            ID   => $Param{ID}
        )
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A type with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE tracking_category SET name = ?, valid_id = ?, '
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    return 1;
}

=head2 CategoryList()

get category list

    my %List = $TimeTrackingCategoryObject->CategoryList();

or

    my %List = $TimeTrackingCategoryObject->CategoryList(
        Valid => 0,
    );

=cut

sub CategoryList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    my $Valid = 1;
    if ( !$Param{Valid} && defined $Param{Valid} ) {
        $Valid = 0;
    }


    # create the valid list
    my $ValidIDs = join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # build SQL
    my $SQL = 'SELECT id, name FROM tracking_category';

    # add WHERE statement
    if ($Valid) {
        $SQL .= ' WHERE valid_id IN (' . $ValidIDs . ')';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask database
    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    # fetch the result
    my %CategoryList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $CategoryList{ $Row[0] } = $Row[1];
    }

    return %CategoryList;
}

=head2 CategoryLookup()

get id or name for a ticket type

    my $Category = $TimeTrackingCategoryObject->CategoryLookup( CategoryID => $CategoryID );

    my $CategoryID = $TimeTrackingCategoryObject->CategoryLookup( Category => $Category );

=cut

sub CategoryLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Category} && !$Param{CategoryID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Got no Category or CategoryID!',
        );
        return;
    }

    # get (already cached) type list
    my %CategoryList = $Self->CategoryList(
        Valid => 0,
    );

    my $Key;
    my $Value;
    my $ReturnData;
    if ( $Param{CategoryID} ) {
        $Key        = 'CategoryID';
        $Value      = $Param{CategoryID};
        $ReturnData = $CategoryList{ $Param{CategoryID} };
    }
    else {
        $Key   = 'Category';
        $Value = $Param{Category};
        my %CategoryListReverse = reverse %CategoryList;
        $ReturnData = $CategoryListReverse{ $Param{Category} };
    }

    # check if data exists
    if ( !defined $ReturnData ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No $Key for $Value found!",
        );
        return;
    }

    return $ReturnData;
}

=head2 NameExistsCheck()

    return 1 if another type with this name already exits

        $Exist = $ServiceCodeObject->NameExistsCheck(
            Name => 'Some::Template',
            ID => 1, # optional
        );

=cut

sub NameExistsCheck {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM tracking_category WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    # fetch the result
    my $Flag;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( !$Param{ID} || $Param{ID} ne $Row[0] ) {
            $Flag = 1;
        }
    }
    if ($Flag) {
        return 1;
    }
    return 0;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
