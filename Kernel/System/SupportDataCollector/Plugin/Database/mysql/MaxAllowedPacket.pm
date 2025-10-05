# --
# Kernel/System/SupportDataCollector/Plugin/Database/mysql/MaxAllowedPacket.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: MaxAllowedPacket.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::Database::mysql::MaxAllowedPacket;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

sub GetDisplayPath {
    return Translatable('Database');
}

sub Run {
    my $Self = shift;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $DBObject->GetDatabaseFunction('Type') ne 'mysql' ) {
        return $Self->GetResults();
    }

    $DBObject->Prepare( SQL => "show variables like 'max_allowed_packet'" );
    while ( my @Row = $DBObject->FetchrowArray() ) {

        if (
            !$Row[1]
            || $Row[1] < 1024 * 1024 * 64
            )
        {
            $Self->AddResultProblem(
                Label => Translatable('Maximum Query Size'),
                Value => $Row[1] / 1024 / 1024 . ' MB',
                Message =>
                    Translatable("The setting 'max_allowed_packet' must be higher than 64 MB."),
            );
        }
        else {
            $Self->AddResultOk(
                Label => Translatable('Maximum Query Size'),
                Value => $Row[1] / 1024 / 1024 . ' MB',
            );
        }
    }

    return $Self->GetResults();
}

1;
