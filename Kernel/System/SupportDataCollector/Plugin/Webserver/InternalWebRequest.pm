# --
# Kernel/System/SupportDataCollector/Plugin/Webserver/InternalWebRequest.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: InternalWebRequest.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::Webserver::InternalWebRequest;

use strict;
use warnings;

use Kernel::System::ObjectManager;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = ();

sub GetDisplayPath {
    return Translatable('Webserver');
}

sub Run {
    my $Self = shift;

    # Skip the plugin, if the support data collection is running in a web request.
    return $Self->GetResults() if $ENV{GATEWAY_INTERFACE};

    $Self->AddResultWarning(
        Label   => Translatable('Support Data Collection'),
        Value   => 0,
        Message => Translatable('Support data could not be collected from the web server.'),
    );

    return $Self->GetResults();
}

1;
