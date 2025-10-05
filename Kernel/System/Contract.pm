# --
# Kernel/System/Contract.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: Contract.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Contract;

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

Kernel::System::Contract - Contract lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ContractObject = $Kernel::OM->Get('Kernel::System::Contract');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item ContractList()

return a hash list

    my %ContractList = $ContractObject->ContractList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub ContractList {
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
            SQL => "SELECT id, contractnumber FROM contract",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, contractnumber FROM contract WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )",
        );
    }

    # fetch the result
    my %ContractList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractList{ $Row[0] } = $Row[1];
    }

    return %ContractList;
}

=item ContractGet()

get attributes

    my %Contract = $ContractObject->ContractGet(
        ContractID => 123,
    );

=cut

sub ContractGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ContractID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need ContractID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, cp_id, customer_id, customeruser_id, direction, contracttype_id, contractnumber, description, contractstart, contractend, service_id, sla_id, '
            .'price, paymentmethod, noticeperiod, ticket_create, memory, memory_time, notification, queue_id, valid_id, create_time, create_by, change_time, change_by '
            . 'FROM contract WHERE id = ?',
        Bind => [ \$Param{ContractID} ],
    );
    my %Contract;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Contract = (
            ContractID           => $Data[0],
            ContractualPartnerID => $Data[1],
            CustomerID           => $Data[2],
            CustomerUserID       => $Data[3],
            ContractDirection    => $Data[4],
            ContractTypeID       => $Data[5],
            ContractNumber       => $Data[6],
            Description          => $Data[7],
            ContractStart        => $Data[8],
            ContractEnd          => $Data[9],
            ServiceID            => $Data[10],
            SLAID                => $Data[11],
            Price                => $Data[12],
            PaymentMethod        => $Data[13],
            NoticePeriod         => $Data[14],
            TicketCreate         => $Data[15],
            Memory               => $Data[16],
            MemoryTime           => $Data[17],
            NotificationTime     => $Data[18],
            QueueID              => $Data[19],
            ValidID              => $Data[20],
            CreateTime           => $Data[21],
            CreateBy             => $Data[22],
            ChangeTime           => $Data[23],
            ChangeBy             => $Data[24],
        );
    }

    # return result
    return %Contract;
}

=item ContractUpdate()

update a contract

    my $ContractID = $ContractObject->ContractUpdate(
        ContractID           => 123,
        ContractualPartnerID => 123,
        CustomerID           => 123,
        CustomerUserID       => 'ud',
        ContractDirection    => 'eingehend',
        ContractTypeID       => 123,
        ContractNumber       => '123456',
        Description          => 'Description',
        ContractStart        => '01.01.2021',
        ContractEnd          => '31.12.2021',
        ServiceID            => 123,
        SLAID                => 123,
        Price                => '100,00',
        PaymentMethod        => 'monatlich',
        NoticePeriod         => '30',
        TicketCreate         => 'Yes',
        Memory               => 20,
        MemoryTime           => '31.12.2021',
        QueueID              => 1,
        ValidID              => 1,
        UserID               => 123,
    );

=cut

sub ContractUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ContractID ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    if ( !$Param{ContractualPartnerID} ) {
        $Param{ContractualPartnerID} = '0';
    }

    if ( !$Param{ServiceID} ) {
        $Param{ServiceID} = '0';
    }
    
    if ( !$Param{SLAID} ) {
        $Param{SLAID} = '0';
    }

    if ( !$Param{QueueID} ) {
        $Param{QueueID} = '0';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update ChangeCategories
    return if !$DBObject->Do(
        SQL =>
            'UPDATE contract SET cp_id = ?, customer_id = ?, customeruser_id = ?, direction = ?,contracttype_id = ?, contractnumber = ?, description = ?, contractstart = ?, '
            . 'contractend = ?, service_id = ?, sla_id = ?, price = ?, paymentmethod = ?, noticeperiod = ?,  ticket_create = ?,  memory = ?,  memory_time = ?, queue_id = ? ,valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{ContractualPartnerID}, \$Param{CustomerID}, \$Param{CustomerUserID}, \$Param{ContractDirection}, \$Param{ContractTypeID}, \$Param{ContractNumber}, \$Param{Description},
            \$Param{ContractStart}, \$Param{ContractEnd}, \$Param{ServiceID}, \$Param{SLAID}, \$Param{Price}, \$Param{PaymentMethod}, \$Param{NoticePeriod},
            \$Param{TicketCreate}, \$Param{Memory}, \$Param{MemoryTime}, \$Param{QueueID}, \$Param{ValidID}, \$Param{UserID}, \$Param{ContractID},
        ],
    );

    return 1;
}

=item NotificationUpdate()

update a contract

    my $ContractID = $ContractObject->NotificationUpdate(
        ContractID       => 123,
        NotificationTime => '31.12.2021',
        UserID           => 123,
    );

=cut

sub NotificationUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ContractID NotificationTime UserID)) {
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
            'UPDATE contract SET notification = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{NotificationTime}, \$Param{UserID}, \$Param{ContractID},
        ],
    );

    return 1;
}

=item ContractAdd()

add a cntract

    my $ContractID = $ContractObject->ContractAdd(
        ContractualPartnerID => 123,
        CustomerID           => 123,
        CustomerUserID       => 'ud',
        ContractDirection    => 'eingehend',
        ContractTypeID       => 123,
        ContractNumber       => '123456',
        Description          => 'Description',
        ContractStart        => '01.01.2021',
        ContractEnd          => '31.12.2021',
        ServiceID            => 123,
        SLAID                => 123,
        Price                => '100,00',
        PaymentMethod        => 'monatlich',
        NoticePeriod         => '30',
        TicketCreate         => 'Yes',
        Memory               => 20,
        MemoryTime           => '31.12.2021',
        QueueID              => 1,
        ValidID              => 1,
        UserID               => 123,
    );

=cut

sub ContractAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ContractNumber ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    if ( !$Param{ContractualPartnerID} ) {
        $Param{ContractualPartnerID} = '0';
    }

    if ( !$Param{ServiceID} ) {
        $Param{ServiceID} = '0';
    }
    
    if ( !$Param{SLAID} ) {
        $Param{SLAID} = '0';
    }

    if ( !$Param{QueueID} ) {
        $Param{QueueID} = '0';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO contract '
            . '(cp_id, customer_id, customeruser_id, direction, contracttype_id, contractnumber, description, contractstart, contractend, service_id, sla_id, '
            . 'price, paymentmethod, noticeperiod, ticket_create, memory, memory_time, queue_id, valid_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ContractualPartnerID}, \$Param{CustomerID}, \$Param{CustomerUserID}, \$Param{ContractDirection}, \$Param{ContractTypeID}, \$Param{ContractNumber}, \$Param{Description},
            \$Param{ContractStart}, \$Param{ContractEnd}, \$Param{ServiceID}, \$Param{SLAID}, \$Param{Price}, \$Param{PaymentMethod}, \$Param{NoticePeriod},
            \$Param{TicketCreate}, \$Param{Memory}, \$Param{MemoryTime}, \$Param{QueueID}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Request id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM contract WHERE contractnumber = ?',
        Bind  => [ \$Param{ContractNumber} ],
        Limit => 1,
    );
    my $ContractID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractID = $Row[0];
    }

    return $ContractID;
}

=item ContractEscalationSearch()

return a hash list of Request

    my @ContractEscalationSearch = $ContractObject->ContractEscalationSearch(
        UserID  => 1,
    );

=cut

sub ContractEscalationSearch {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

    my ($Sec, $Min, $Hour, $Day, $Month, $Year, $WeekDay) = $TimeObject->SystemTime2Date(
        SystemTime => $TimeObject->SystemTime(),
    );

   $Param{Search} = $Year . '-' . $Month . '-' . $Day . ' 23:59:59';

    return if !$DBObject->Prepare(
        SQL => "SELECT id FROM contract WHERE memory_time < ? AND ticket_create = 'Yes' ",
        Bind => [ \$Param{Search}, ],
    );

    # fetch the result
    my @ContractEscalationSearch;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ContractEscalationSearch, $Row[0];
    }

    return @ContractEscalationSearch;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
