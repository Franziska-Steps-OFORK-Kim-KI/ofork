# --
# Kernel/System/SelfService.pm - all SelfService function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: SelfService.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SelfService;

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

Kernel::System::SelfService - SelfService lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $SelfServiceObject = $Kernel::OM->Get('Kernel::System::SelfService');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item SelfServiceList()

return a hash list of SelfService

    my %SelfServiceList = $SelfServiceObject->SelfServiceList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub SelfServiceList {
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
            SQL => "SELECT id, headline FROM selfservice",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, headline FROM selfservice WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )",
        );
    }

    # fetch the result
    my %SelfServiceList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceList{ $Row[0] } = $Row[1];
    }

    return %SelfServiceList;
}

=item SelfServiceGet()

get SelfService attributes

    my %SelfService = $SelfServiceObject->SelfServiceGet(
        SelfServiceID => 123,
    );

=cut

sub SelfServiceGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{SelfServiceID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need SelfServiceID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, selfservice_categories_id, categories, headline, schlagwoerter, service_text, color, valid_id, create_time, create_by, change_time, change_by '
            . 'FROM selfservice WHERE id = ?',
        Bind => [ \$Param{SelfServiceID} ],
    );
    my %SelfService;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %SelfService = (
            SelfServiceID           => $Data[0],
            SelfServiceCategoriesID => $Data[1],
            SelfServiceCategories   => $Data[2],
            Headline                => $Data[3],
            Schlagwoerter           => $Data[4],
            SelfServiceText         => $Data[5],
            SelfServiceColor        => $Data[6],
            ValidID                 => $Data[7],
            CreateTime              => $Data[8],
            CreateBy                => $Data[9],
            ChangeTime              => $Data[10],
            ChangeBy                => $Data[11],
        );
    }

    # return result
    return %SelfService;
}

=item SelfServiceUpdate()

update a SelfService

    my $SelfServiceID = $SelfServiceObject->SelfServiceUpdate(
        SelfServiceID           => 123,
        SelfServiceCategoriesID => 123,
        SelfServiceCategories   => 'SelfServiceCategories',
        Headline                => 'Headline',
        Schlagwoerter           => 'Schlagwoerter',
        SelfServiceText         => 'SelfServiceText',
        SelfServiceColor        => '#000000',
        ValidID                 => 1,
        UserID                  => 123,
    );

=cut

sub SelfServiceUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(SelfServiceID Headline SelfServiceText ValidID UserID)) {
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
            'UPDATE selfservice SET selfservice_categories_id = ?, categories = ?, headline = ?, schlagwoerter = ?, service_text = ?, color = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{SelfServiceCategoriesID}, \$Param{SelfServiceCategories}, \$Param{Headline}, \$Param{Schlagwoerter}, \$Param{SelfServiceText},
            \$Param{SelfServiceColor}, \$Param{ValidID}, \$Param{UserID}, \$Param{SelfServiceID},
        ],
    );

    return 1;
}

=item SelfServiceAdd()

add a SelfService

    my $SelfServiceID = $SelfServiceObject->SelfServiceAdd(
        SelfServiceCategoriesID => 123,
        SelfServiceCategories   => 'SelfServiceCategories',
        Headline                => 'Headline',
        Schlagwoerter           => 'Schlagwoerter',
        SelfServiceText         => 'SelfServiceText',
        SelfServiceColor        => '#000000',
        ValidID                 => 1,
        UserID                  => 123,
    );

=cut

sub SelfServiceAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Headline ValidID UserID)) {
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
        SQL   => 'SELECT id FROM selfservice WHERE headline = ?',
        Bind  => [ \$Param{Headline} ],
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
        SQL => 'INSERT INTO selfservice '
            . '(selfservice_categories_id, categories, headline, schlagwoerter, service_text, color, valid_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{SelfServiceCategoriesID}, \$Param{SelfServiceCategories}, \$Param{Headline}, \$Param{Schlagwoerter}, \$Param{SelfServiceText},
            \$Param{SelfServiceColor}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get SelfService id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM selfservice WHERE headline = ?',
        Bind  => [ \$Param{Headline} ],
        Limit => 1,
    );
    my $SelfServiceID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceID = $Row[0];
    }

    return $SelfServiceID;
}

=item SelfServiceSearch()

return a hash list of SelfService

    my %SelfServiceSearch = $SelfServiceObject->SelfServiceSearch(
        Schlagwoerter => 'Schlagwoerter',
        Valid         => 0,   # (optional) default 1 (0|1)
    );

=cut

sub SelfServiceSearch {
    my ( $Self, %Param ) = @_;

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "SELECT id, headline FROM selfservice WHERE valid_id = 1 AND schlagwoerter like '" . $Param{Schlagwoerter} . "' ORDER BY headline ASC",
    );

    # fetch the result
    my %SelfServiceList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceList{ $Row[0] } = $Row[1];
    }

    return %SelfServiceList;
}

=item SelfServiceCatList()

return a hash list of SelfService

    my %SelfServiceList = $SelfServiceObject->SelfServiceCatList(
        Valid      => 0,   # (optional) default 1 (0|1)
        CategoryID => 1,
        UserID     => 1,
    );

=cut

sub SelfServiceCatList {
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
            SQL => "SELECT id, headline FROM selfservice WHERE selfservice_categories_id = $Param{CategoryID}",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, headline FROM selfservice WHERE selfservice_categories_id = $Param{CategoryID} AND valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )",
        );
    }

    # fetch the result
    my %SelfServiceList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceList{ $Row[0] } = $Row[1];
    }

    return %SelfServiceList;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
