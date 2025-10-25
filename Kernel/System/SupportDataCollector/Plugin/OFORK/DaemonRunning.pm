# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/DaemonRunning.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: DaemonRunning.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::DaemonRunning;

use strict;
use warnings;

use Kernel::System::ObjectManager;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
);

sub GetDisplayPath {
    return Translatable('OFORK');
}

sub Run {
    my $Self = shift;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get the NodeID from the SysConfig settings, this is used on High Availability systems.
    my $NodeID = $ConfigObject->Get('NodeID') || 1;

    # get running daemon cache
    my $Running = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => 'DaemonRunning',
        Key  => $NodeID,
    );

    if ($Running) {
        $Self->AddResultOk(
            Label   => Translatable('Daemon'),
            Value   => 1,
            Message => Translatable('Daemon is running.'),
        );
    }
    else {
        $Self->AddResultProblem(
            Label   => Translatable('Daemon'),
            Value   => 0,
            Message => Translatable('Daemon is not running.'),
        );
    }

    return $Self->GetResults();
}

1;
