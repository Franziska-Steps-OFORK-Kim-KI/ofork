# --
# scripts/DBUpdateTo11/CacheCleanup.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: CacheCleanup.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --

package scripts::DBUpdateTo11::CacheCleanup;

use strict;
use warnings;

use parent qw(scripts::DBUpdateTo11::Base);

our @ObjectDependencies = ();

=head1 NAME

scripts::DBUpdateTo11::CacheCleanup - Cleanup the system cache.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return $Self->CacheCleanup();
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
