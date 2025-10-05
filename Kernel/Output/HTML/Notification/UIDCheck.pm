# --
# Kernel/Output/HTML/Notification/UIDCheck.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: UIDCheck.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# ---
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Notification::UIDCheck;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
);

sub Run {
    my ( $Self, %Param ) = @_;

    # return if it's not root@localhost
    return '' if $Self->{UserID} != 1;

    # get the product name
    my $ProductName = $Kernel::OM->Get('Kernel::Config')->Get('ProductName') || 'OFORK';

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # show error notfy, don't work with user id 1
    return $LayoutObject->Notify(
        Priority => 'Error',
        Link     => $LayoutObject->{Baselink} . 'Action=AdminUser',
        Info     => $LayoutObject->{LanguageObject}->Translate(
            'Don\'t use the Superuser account to work with %s! Create new Agents and work with these accounts instead.',
            $ProductName
        ),
    );
}

1;
