# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/ErrorLog.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: ErrorLog.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::ErrorLog;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::Log',
);

sub GetDisplayPath {
    return Translatable('OFORK');
}

sub Run {
    my $Self = shift;

    my @ErrorLines;

    for my $Line ( split( /\n/, $Kernel::OM->Get('Kernel::System::Log')->GetLog() ) ) {
        my @Row = split( /;;/, $Line );
        if ( $Row[3] && $Row[1] =~ /error/i ) {
            push @ErrorLines, $Row[3];
        }
    }

    if (@ErrorLines) {
        $Self->AddResultInformation(
            Label   => Translatable('Error Log'),
            Value   => join( "\n", @ErrorLines ),
            Message => Translatable('There are error reports in your system log.'),
        );
    }
    else {
        $Self->AddResultInformation(
            Label => Translatable('Error Log'),
            Value => '',
        );
    }

    return $Self->GetResults();
}

1;
