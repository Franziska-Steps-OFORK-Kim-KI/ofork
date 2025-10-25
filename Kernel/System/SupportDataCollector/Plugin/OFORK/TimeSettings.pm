# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/TimeSettings.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: TimeSettings.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::TimeSettings;

use strict;
use warnings;

use POSIX;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);
use Kernel::System::DateTime;

our @ObjectDependencies = (
    'Kernel::Config',
);

sub GetDisplayPath {
    return Translatable('OFORK') . '/' . Translatable('Time Settings');
}

sub Run {
    my $Self = shift;

    # Server time zone
    my $ServerTimeZone = POSIX::tzname();

    $Self->AddResultOk(
        Identifier => 'ServerTimeZone',
        Label      => Translatable('Server time zone'),
        Value      => $ServerTimeZone,
    );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # OFORK time zone
    my $OFORKTimeZone = $ConfigObject->Get('OFORKTimeZone');
    if ( defined $OFORKTimeZone ) {
        $Self->AddResultOk(
            Identifier => 'OFORKTimeZone',
            Label      => Translatable('OFORK time zone'),
            Value      => $OFORKTimeZone,
        );
    }
    else {
        $Self->AddResultProblem(
            Identifier => 'OFORKTimeZone',
            Label      => Translatable('OFORK time zone'),
            Value      => '',
            Message    => Translatable('OFORK time zone is not set.'),
        );
    }

    # User default time zone
    my $UserDefaultTimeZone = $ConfigObject->Get('UserDefaultTimeZone');
    if ( defined $UserDefaultTimeZone ) {
        $Self->AddResultOk(
            Identifier => 'UserDefaultTimeZone',
            Label      => Translatable('User default time zone'),
            Value      => $UserDefaultTimeZone,
        );
    }
    else {
        $Self->AddResultProblem(
            Identifier => 'UserDefaultTimeZone',
            Label      => Translatable('User default time zone'),
            Value      => '',
            Message    => Translatable('User default time zone is not set.'),
        );
    }

    # Calendar time zones
    for my $Counter ( 1 .. 9 ) {
        my $CalendarTimeZone = $ConfigObject->Get( 'TimeZone::Calendar' . $Counter );

        if ( defined $CalendarTimeZone ) {
            $Self->AddResultOk(
                Identifier => "OFORKTimeZone::Calendar$Counter",
                Label      => Translatable('OFORK time zone setting for calendar') . " $Counter",
                Value      => $CalendarTimeZone,
            );
        }
        else {
            $Self->AddResultInformation(
                Identifier => "OFORKTimeZone::Calendar$Counter",
                Label      => Translatable('OFORK time zone setting for calendar') . " $Counter",
                Value      => '',
                Message    => Translatable('Calendar time zone is not set.'),
            );
        }
    }

    return $Self->GetResults();
}

1;
