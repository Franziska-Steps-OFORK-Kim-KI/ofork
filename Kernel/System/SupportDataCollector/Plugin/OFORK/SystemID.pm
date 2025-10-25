# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/SystemID.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: SystemID.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::SystemID;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub GetDisplayPath {
    return Translatable('OFORK');
}

sub Run {
    my $Self = shift;

    # Get the configured SystemID
    my $SystemID = $Kernel::OM->Get('Kernel::Config')->Get('SystemID');

    # Does the SystemID contain non-digits?
    if ( $SystemID !~ /^\d+$/ ) {
        $Self->AddResultProblem(
            Label   => Translatable('SystemID'),
            Value   => $SystemID,
            Message => Translatable('Your SystemID setting is invalid, it should only contain digits.'),
        );
    }
    else {
        $Self->AddResultOk(
            Label => Translatable('SystemID'),
            Value => $SystemID,
        );
    }

    return $Self->GetResults();
}

1;
