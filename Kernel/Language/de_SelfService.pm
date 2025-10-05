# --
# Kernel/Language/de_SelfService.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: de_SelfService.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_SelfService;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Create and manage SelfService categories.'} = 'SelfService Kategorien erstellen und bearbeiten.';
    $Self->{Translation}->{'SelfService categories'} = 'SelfService Kategorien';
    $Self->{Translation}->{'SelfService management'} = 'SelfService Administration';
    $Self->{Translation}->{'Create and manage SelfService.'} = 'SelfService erstellen und bearbeiten';

}

1;
