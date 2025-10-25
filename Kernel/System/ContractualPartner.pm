# --
# Kernel/System/ContractualPartner.pm - all service function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: ContractualPartner.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ContractualPartner;

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

Kernel::System::ContractualPartner - ContractualPartner lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ContractualPartnerObject = $Kernel::OM->Get('Kernel::System::ConContractualPartnertract');

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

    my %ContractualPartnerList = $ContractualPartnerObject->ContractualPartnerList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub ContractualPartnerList {
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
            SQL => "SELECT id, company FROM contractualpartner",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, company  FROM contractualpartner WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )",
        );
    }

    # fetch the result
    my %ContractualPartnerList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractualPartnerList{ $Row[0] } = $Row[1];
    }

    return %ContractualPartnerList;
}

=item ContractualPartnerGet()

get ContractualPartner attributes

    my %ContractualPartner = $ContractualPartnerObject->ContractualPartnerGet(
        ContractualPartnerID => 123,
    );

=cut

sub ContractualPartnerGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ContractualPartnerID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need ContractualPartnerID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, company, street, postcode, city, country, phone, contactperson, e_mail, description, valid_id, create_time, create_by, change_time, change_by '
            . 'FROM contractualpartner WHERE id = ?',
        Bind => [ \$Param{ContractualPartnerID} ],
    );
    my %Room;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Room = (
            ContractualPartnerID => $Data[0],
            Company              => $Data[1],
            Street               => $Data[2],
            PostCode             => $Data[3],
            City                 => $Data[4],
            Country              => $Data[5],
            Phone                => $Data[6],
            ContactPerson        => $Data[7],
            eMail                => $Data[8],
            Description          => $Data[9],
            ValidID              => $Data[10],
            CreateTime           => $Data[11],
            CreateBy             => $Data[12],
            ChangeTime           => $Data[13],
            ChangeBy             => $Data[14],
        );
    }

    # return result
    return %Room;
}

=item ContractualPartnerUpdate()

update a ContractualPartner

    my $ContractualPartnerID = $ContractualPartnerObject->ContractualPartnerUpdate(
        ContractualPartnerID => 123,
        Company              => 123,
        Street               => 'Street',
        PostCode             => 'PostCode',
        City                 => 'City',
        Country              => 'Country',
        Phone                => '123456',
        ContactPerson        => 'ContactPerson',
        eMail                => 'e@mail.de',
        Description          => 'Description',
        ValidID              => 1,
        UserID               => 123,
    );

=cut

sub ContractualPartnerUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ContractualPartnerID Company ValidID UserID)) {
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
            'UPDATE contractualpartner SET company = ?, street = ?, postcode = ?, city = ?, country = ?, phone = ?, contactperson = ?, e_mail = ?, description = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Company}, \$Param{Street}, \$Param{PostCode}, \$Param{City}, \$Param{Country}, \$Param{Phone}, \$Param{ContactPerson}, \$Param{eMail},
            \$Param{Description}, \$Param{ValidID}, \$Param{UserID}, \$Param{ContractualPartnerID},
        ],
    );

    return 1;
}

=item ContractualPartnerAdd()

add a ContractualPartner

    my $ContractualPartnerID = $ContractualPartnerObject->ContractualPartnerAdd(
        Company       => 123,
        Street        => 'Street',
        PostCode      => 'PostCode',
        City          => 'City',
        Country        => 'Country',
        Phone         => '123456',
        ContactPerson => 'ContactPerson',
        eMail         => 'e@mail.de',
        Description   => 'Description',
        ValidID       => 1,
        UserID        => 123,
    );

=cut

sub ContractualPartnerAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Company ValidID UserID)) {
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
        SQL   => 'SELECT id FROM contractualpartner WHERE company = ?',
        Bind  => [ \$Param{Company} ],
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
        SQL => 'INSERT INTO contractualpartner '
            . '(company, street, postcode, city, country, phone, contactperson, e_mail, description, valid_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Company}, \$Param{Street}, \$Param{PostCode}, \$Param{City}, \$Param{Country}, \$Param{Phone}, \$Param{ContactPerson}, \$Param{eMail},
            \$Param{Description}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Request id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM contractualpartner WHERE company = ?',
        Bind  => [ \$Param{Company} ],
        Limit => 1,
    );
    my $ContractualPartnerID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractualPartnerID = $Row[0];
    }

    return $ContractualPartnerID;
}

=item ContractualPartnerSearch()

return a hash list of ContractualPartner

    my %ContractualPartnerSearch = $ContractualPartnerObject->ContractualPartnerSearch(
        Valid  => 0,   # (optional) default 1 (0|1)
    );

=cut

sub ContractualPartnerSearch {
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

    if ( $Param{SortBy} eq "Company" ) {
        $Param{SortBy} = 'company';
    }
    if ( $Param{SortBy} eq "City" ) {
        $Param{SortBy} = 'city';
    }
    if ( $Param{SortBy} eq "PostCode" ) {
        $Param{SortBy} = 'postcode';
    }

    if ( $Param{SortBy} ) {
         $SQLSearch = 'ORDER BY ' . $Param{SortBy} . ' ' . $SQLSort;
    }

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( !$Param{Valid} ) {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, company FROM contractualpartner $SQLSearch",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, company  FROM contractualpartner WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} ) $SQLSearch",
        );
    }

    # fetch the result
    my %ContractualPartnerList;
    my @ContractualPartnerList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractualPartnerList{ $Row[0] } = $Row[1];
        push @ContractualPartnerList, $Row[0];
    }

    my $Count = @ContractualPartnerList;

    if ( $Result eq 'COUNT' ) {
        return $Count;
    }
    else {
        return @ContractualPartnerList;
    }

    return %ContractualPartnerList;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
