#!/usr/bin/perl
# --
# scripts/DBUpdate-to-12.pl
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: index.pl,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';

use Kernel::System::ObjectManager;

use Getopt::Long;

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OFORK-DBUpdate-to-12.pl',
    },
);

# get options
my %Options = (
    Help           => 0,
    NonInteractive => 0,
    Timing         => 0,
    Verbose        => 0,
);
Getopt::Long::GetOptions(
    'help',                      \$Options{Help},
    'non-interactive',           \$Options{NonInteractive},
    'cleanup-orphaned-articles', \$Options{CleanupOrphanedArticles},
    'timing',                    \$Options{Timing},
    'verbose',                   \$Options{Verbose},
);

{
    if ( $Options{Help} ) {
        print <<"EOF";

DBUpdate-to-12.pl - Upgrade script for OTRS 6 to OFORK 12 migration.
Copyright (C) 2010-2025 OFORK, https://o-fork.de

Usage: $0
    Options are as follows:
        --help                          display this help
        --non-interactive               skip interactive input and display steps to execute after script has been executed
        --cleanup-orphaned-articles     delete orphaned article data if no corresponding ticket exists anymore (can only be used with non-interactive)
        --timing                        shows how much time is consumed on each task execution in the script
        --verbose                       shows details on some migration steps, not just failing.

EOF
        exit 1;
    }

    # UID check
    if ( $> == 0 ) {    # $EFFECTIVE_USER_ID
        die "
Cannot run this program as root.
Please run it as the 'ofork' user or with the help of su:
    su -c \"$0\" -s /bin/bash ofork
";
    }

    # Allow cleanup-orphaned-articles only if also non-interactive is set.
    if ( $Options{CleanupOrphanedArticles} && !$Options{NonInteractive} ) {
        $Options{CleanupOrphanedArticles} = 0;
    }

    $Kernel::OM->Create('scripts::DBUpdateTo12')->Run(
        CommandlineOptions => \%Options,
    );

    exit 0;
}

1;
