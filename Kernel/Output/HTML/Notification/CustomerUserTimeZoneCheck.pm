# --
# Kernel/Output/HTML/Notification/CustomerUserTimeZoneCheck.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: CustomerUserTimeZoneCheck.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# ---
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Notification::CustomerUserTimeZoneCheck;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::DateTime;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CustomerUser',
    'Kernel::Output::HTML::Layout',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $ShowUserTimeZoneSelectionNotification
        = $Kernel::OM->Get('Kernel::Config')->Get('ShowUserTimeZoneSelectionNotification');
    return '' if !$ShowUserTimeZoneSelectionNotification;

    my %CustomerUserPreferences = $Kernel::OM->Get('Kernel::System::CustomerUser')->GetPreferences(
        UserID => $Self->{UserID},
    );
    return '' if !%CustomerUserPreferences;

    # Ignore stored time zone if it's actually an old-style offset which is not valid anymore.
    #   Please see bug#13374 for more information.
    if (
        $CustomerUserPreferences{UserTimeZone}
        && !Kernel::System::DateTime->IsTimeZoneValid( TimeZone => $CustomerUserPreferences{UserTimeZone} )
        )
    {
        delete $CustomerUserPreferences{UserTimeZone};
    }

    # Do not show notification if user has already valid time zone in the preferences.
    return '' if $CustomerUserPreferences{UserTimeZone};

    # If OFORKTimeZone and UserDefaultTimeZone match and are not set to UTC, don't show a notification,
    # because in this case it almost certainly means that only this time zone is relevant.
    my $OFORKTimeZone        = Kernel::System::DateTime->OFORKTimeZoneGet();
    my $UserDefaultTimeZone = Kernel::System::DateTime->UserDefaultTimeZoneGet();
    return '' if $OFORKTimeZone eq $UserDefaultTimeZone && $OFORKTimeZone ne 'UTC';

    # show notification to set time zone
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    return $LayoutObject->Notify(
        Priority => 'Notice',

        # Link     => $LayoutObject->{Baselink} . 'Action=CustomerPreferences',
        Info =>
            Translatable('Please select a time zone in your preferences and confirm it by clicking the save button.'),
    );
}

1;
