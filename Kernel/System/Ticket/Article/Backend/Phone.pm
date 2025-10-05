# --
# Kernel/System/Ticket/Article/Backend/Phone.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Phone.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Article::Backend::Phone;

use strict;
use warnings;

use parent 'Kernel::System::Ticket::Article::Backend::MIMEBase';

our @ObjectDependencies = ();

=head1 NAME

Kernel::System::Ticket::Article::Backend::Phone - backend class for phone articles

=head1 DESCRIPTION

This class provides functions to manipulate phone articles in the database.

Inherits from L<Kernel::System::Ticket::Article::Backend::MIMEBase>, please have a look there for its API.

=cut

sub ChannelNameGet {
    return 'Phone';
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
