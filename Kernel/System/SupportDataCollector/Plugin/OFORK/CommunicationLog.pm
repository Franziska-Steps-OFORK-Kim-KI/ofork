# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/CommunicationLog.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: CommunicationLog.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::CommunicationLog;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CommunicationLog',
    'Kernel::System::CommunicationLog::DB',
);

sub GetDisplayPath {
    return Translatable('OFORK') . '/' . Translatable('Communication Log');
}

sub Run {
    my $Self = shift;

    my $CommunicationLogDBObj = $Kernel::OM->Get('Kernel::System::CommunicationLog::DB');
    my @CommunicationList = @{ $CommunicationLogDBObj->CommunicationList() || [] };

    my %CommunicationData = (
        All        => 0,
        Successful => 0,
        Processing => 0,
        Failed     => 0,
        Incoming   => 0,
        Outgoing   => 0,
    );
    for my $Communication (@CommunicationList) {
        $CommunicationData{All}++;
        $CommunicationData{ $Communication->{Status} }++;
        $CommunicationData{ $Communication->{Direction} }++;
    }

    my $CommunicationAverageSeconds = $CommunicationLogDBObj->CommunicationList( Result => 'AVERAGE' );

    $Self->AddResultInformation(
        Identifier => 'Incoming',
        Label      => Translatable('Incoming communications'),
        Value      => $CommunicationData{Incoming},
    );
    $Self->AddResultInformation(
        Identifier => 'Outgoing',
        Label      => Translatable('Outgoing communications'),
        Value      => $CommunicationData{Outgoing},
    );
    $Self->AddResultInformation(
        Identifier => 'Failed',
        Label      => Translatable('Failed communications'),
        Value      => $CommunicationData{Failed}
    );

    my $Mask = "%.0f";
    if ( $CommunicationAverageSeconds < 10 ) {
        $Mask = "%.1f";
    }
    $Self->AddResultInformation(
        Identifier => 'AverageProcessingTime',
        Label      => Translatable('Average processing time of communications (s)'),
        Value      => sprintf( $Mask, $CommunicationAverageSeconds ),
    );

    return $Self->GetResults();
}

1;
