# --
# Kernel/System/SupportDataCollector/Plugin/OS/DiskPartitionOFORK.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: DiskPartitionOFORK.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OS::DiskPartitionOFORK;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub GetDisplayPath {
    return Translatable('Operating System');
}

sub Run {
    my $Self = shift;

    # Check if used OS is a linux system
    if ( $^O !~ /(linux|unix|netbsd|freebsd|darwin)/i ) {
        return $Self->GetResults();
    }

    # find OFORK partition
    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

    my $OFORKPartition = `df -P $Home | tail -1 | cut -d' ' -f 1`;
    chomp $OFORKPartition;

    $Self->AddResultInformation(
        Label => Translatable('OFORK Disk Partition'),
        Value => $OFORKPartition,
    );

    return $Self->GetResults();
}

1;
