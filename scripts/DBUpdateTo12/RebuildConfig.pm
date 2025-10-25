# --
# scripts/DBUpdateTo12/RebuildConfig.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: RebuildConfig.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --

package scripts::DBUpdateTo12::RebuildConfig;

use strict;
use warnings;

use parent qw(scripts::DBUpdateTo12::Base);

our @ObjectDependencies = ();

=head1 NAME

scripts::DBUpdateTo12::RebuildConfig - Rebuilds the system configuration.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return $Self->RebuildConfig();
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
