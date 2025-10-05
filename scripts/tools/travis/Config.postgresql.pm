# --
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Config;

use strict;
use warnings;
use utf8;

use File::Basename;

sub Load {
    my $Self = shift;

    $Self->{DatabaseHost}     = '127.0.0.1';
    $Self->{Database}         = 'ofork';
    $Self->{DatabaseUser}     = 'ofork';
    $Self->{DatabasePw}       = 'ofork';
    $Self->{DatabaseDSN}      = "DBI:Pg:dbname=$Self->{Database};host=$Self->{DatabaseHost}";
    $Self->{Home}             = dirname dirname __FILE__;
    $Self->{TestHTTPHostname} = 'localhost:5000';
    $Self->{TestDatabase}     = {
        DatabaseDSN  => "DBI:Pg:dbname=oforktest;host=$Self->{DatabaseHost}",
        DatabaseUser => 'oforktest',
        DatabasePw   => 'oforktest',
    };
    return;
}

use parent qw(Kernel::Config::Defaults);

1;
