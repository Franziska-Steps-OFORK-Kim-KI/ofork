# --
# Kernel/System/SupportDataCollector/Plugin/Database/OutdatedTables.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: OutdatedTables.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::Database::OutdatedTables;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Package',
);

sub GetDisplayPath {
    return Translatable('Database');
}

sub Run {
    my $Self = shift;

    my %ExistingTables = map { lc($_) => 1 } $Kernel::OM->Get('Kernel::System::DB')->ListTables();

    my @OutdatedTables;

    if ( $ExistingTables{gi_object_lock_state} ) {
        my $SolManConnectorInstalled;

        for my $Package ( $Kernel::OM->Get('Kernel::System::Package')->RepositoryList() ) {
            if ( $Package->{Name}->{Content} eq 'OFORKGenericInterfaceConnectorSAPSolMan' ) {
                $SolManConnectorInstalled = 1;
            }
        }

        push @OutdatedTables, 'gi_object_lock_state' if !$SolManConnectorInstalled;
    }

    if ( !@OutdatedTables ) {
        $Self->AddResultOk(
            Label => Translatable('Outdated Tables'),
            Value => '',
        );
    }
    else {
        $Self->AddResultWarning(
            Label   => Translatable('Outdated Tables'),
            Value   => join( ', ', @OutdatedTables ),
            Message => Translatable("Outdated tables were found in the database. These can be removed if empty."),
        );
    }

    return $Self->GetResults();
}

1;
