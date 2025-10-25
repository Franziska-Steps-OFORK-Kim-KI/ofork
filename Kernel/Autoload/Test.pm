# --
# Kernel/Autoload/Test.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Test.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use Kernel::System::Valid;

package Kernel::System::Valid;    ## no critic
use strict;
use warnings;

#
# This file demonstrates how to use the autoload mechanism of OFORK to change existing functionality,
#   adding a method to Kernel::System::Valid in this case.
#

#
# Please note that all autoload files have to be registered via SysConfig (see AutoloadPerlPackages###1000-Test).
#

sub AutoloadTest {
    return 1;
}

1;
