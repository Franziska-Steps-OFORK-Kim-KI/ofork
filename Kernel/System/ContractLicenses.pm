# --
# Kernel/System/ContractLicenses.pm - all service function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: ContractLicenses.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ContractLicenses;

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

Kernel::System::ContractLicenses - ContractLicenses lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ContractLicensesObject = $Kernel::OM->Get('Kernel::System::ContractLicenses');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item HandoverList()

return a hash list

    my %HandoverList = $ContractLicensesObject->HandoverList(
        ContractID => 1
        UserID     => 1,
    );

=cut

sub HandoverList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ContractID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ContractID!',
        );
        return;
    }


    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "SELECT id, handover FROM handover where contract_id = $Param{ContractID}",
    );

    # fetch the result
    my %HandoverList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $HandoverList{ $Row[0] } = $Row[1];
    }

    return %HandoverList;
}

=item HandoverAdd()

add a Handover

    my $HandoverID = $ContractLicensesObject->HandoverAdd(
        ContractID   => 123,
        Handover     => 'Name',
        HandoverDate => '30',
        UserID       => 123,
    );

=cut

sub HandoverAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ContractID Handover HandoverDate UserID)) {
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

    return if !$DBObject->Do(
        SQL => 'INSERT INTO handover '
            . '(contract_id, handover, handoverdate, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ContractID}, \$Param{Handover}, \$Param{HandoverDate}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Request id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM handover WHERE handover = ?',
        Bind  => [ \$Param{handover} ],
        Limit => 1,
    );
    my $HandoverID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $HandoverID = $Row[0];
    }

    return $HandoverID;
}

=item HandoverGet()

get attributes

    my %Handover = $ContractLicensesObject->HandoverGet(
        HandoverID => 123,
    );

=cut

sub HandoverGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{HandoverID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need ContractID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, contract_id, handover, handoverdate, create_time, create_by, change_time, change_by '
            . 'FROM handover WHERE id = ?',
        Bind => [ \$Param{HandoverID} ],
    );
    my %Handover;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Handover = (
            HandoverID   => $Data[0],
            ContractID   => $Data[1],
            Handover     => $Data[2],
            HandoverDate => $Data[3],
            CreateTime   => $Data[4],
            CreateBy     => $Data[5],
            ChangeTime   => $Data[6],
            ChangeBy     => $Data[7],
        );
    }

    # return result
    return %Handover;
}

=item ContractDeviceList()

return a hash list

    my %ContractDeviceList = $ContractLicensesObject->ContractDeviceList(
        UserID => 1,
    );

=cut

sub ContractDeviceList {
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
        SQL => "SELECT id, contract_id FROM contractdevice",
    );

    # fetch the result
    my %ContractDeviceList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractDeviceList{ $Row[0] } = $Row[1];
    }

    return %ContractDeviceList;
}

=item ContractDeviceGet()

get attributes

    my %Device = $ContractLicensesObject->ContractDeviceGet(
        ContractID => 123,
    );

=cut

sub ContractDeviceGet {
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
            'SELECT id, contract_id, device_name, device_number, ticket_create, queue_id, notification, create_time, create_by, change_time, change_by '
            . 'FROM contractdevice WHERE contract_id = ?',
        Bind => [ \$Param{ContractID} ],
    );
    my %Device;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Device = (
            DeviceID         => $Data[0],
            ContractID       => $Data[1],
            DeviceName       => $Data[2],
            DeviceNumber     => $Data[3],
            TicketCreateBy   => $Data[4],
            QueueID          => $Data[5],
            NotificationTime => $Data[6],
            CreateTime       => $Data[7],
            CreateBy         => $Data[8],
            ChangeTime       => $Data[9],
            ChangeBy         => $Data[10],
        );
    }

    # return result
    return %Device;
}

=item ContractDeviceUpdate()

update a Device

    my $DeviceID = $ContractLicensesObject->ContractDeviceUpdate(
        DeviceID       => 123,
        ContractID     => 123,
        DeviceName     => 'Name',
        DeviceNumber   => '30',
        TicketCreateBy => '20',
        QueueID        => 1,
        UserID         => 123,
    );

=cut

sub ContractDeviceUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ContractID DeviceName UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    if ( !$Param{DeviceNumber} ) {
        $Param{DeviceNumber} = '0';
    }

    if ( !$Param{TicketCreateBy} ) {
        $Param{TicketCreateBy} = '0';
    }
    
    if ( !$Param{QueueID} ) {
        $Param{QueueID} = '0';
    }

    if ( !$Param{NotificationTime} ) {
        $Param{NotificationTime} = '0000-00-00 00:00:00';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update ChangeCategories
    return if !$DBObject->Do(
        SQL =>
            'UPDATE contractdevice SET device_name = ?, device_number = ?,  ticket_create = ?, queue_id = ?, notification = ?, change_time = current_timestamp, change_by = ? WHERE contract_id = ?',
        Bind => [
            \$Param{DeviceName}, \$Param{DeviceNumber}, \$Param{TicketCreateBy}, \$Param{QueueID}, \$Param{NotificationTime}, \$Param{UserID}, \$Param{ContractID},
        ],
    );

    return 1;
}

=item NotificationUpdate()

update a contract

    my $ContractID = $ContractLicensesObject->NotificationUpdate(
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
            'UPDATE contractdevice SET notification = ?, change_time = current_timestamp, change_by = ? WHERE contract_id = ?',
        Bind => [
            \$Param{NotificationTime}, \$Param{UserID}, \$Param{ContractID},
        ],
    );

    return 1;
}

=item ContractDeviceAdd()

add a cntract

    my $DeviceID = $ContractLicensesObject->ContractDeviceAdd(
        ContractID     => 123,
        DeviceName     => 'Name',
        DeviceNumber   => '30',
        TicketCreateBy => '20',
        QueueID        => 1,
        UserID         => 123,
    );

=cut

sub ContractDeviceAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ContractID DeviceName UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    if ( !$Param{DeviceNumber} ) {
        $Param{DeviceNumber} = '0';
    }

    if ( !$Param{TicketCreateBy} ) {
        $Param{TicketCreateBy} = '0';
    }
    
    if ( !$Param{QueueID} ) {
        $Param{QueueID} = '0';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO contractdevice '
            . '(contract_id, device_name, device_number, ticket_create, queue_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ContractID}, \$Param{DeviceName}, \$Param{DeviceNumber}, \$Param{TicketCreateBy}, \$Param{QueueID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Request id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM contractdevice WHERE device_name = ?',
        Bind  => [ \$Param{DeviceName} ],
        Limit => 1,
    );
    my $DeviceID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $DeviceID = $Row[0];
    }

    return $DeviceID;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
