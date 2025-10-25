# --
# Kernel/Modules/AgentAppointmentDateCheck.pm - to handle customer messages
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AgentAppointmentDateCheck.pm,v 1.21 2016/12/13 14:37:23 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentAppointmentDateCheck;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject             = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TimeObject              = $Kernel::OM->Get('Kernel::System::Time');
    my $CalendarTimeCheckObject = $Kernel::OM->Get('Kernel::System::CalendarTimeCheck');
    my $UserObject              = $Kernel::OM->Get('Kernel::System::User');

    if ( $Self->{Subaction} eq "DateCheck" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(StartDay StartMonth StartYear StartHour StartMinute EndDay EndMonth EndYear EndHour EndMinute CalID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my @Agents = $ParamObject->GetArray( Param => 'Agents[]' );
        my $ResourceIDs = \@Agents;

    if (length($GetParam{StartMonth}) == 1) {
        $GetParam{StartMonth} = "0$GetParam{StartMonth}";
    }
    if (length($GetParam{StartDay}) == 1) {
        $GetParam{StartDay} = "0$GetParam{StartDay}";
    }
    if (length($GetParam{StartHour}) == 1) {
        $GetParam{StartHour} = "0$GetParam{StartHour}";
    }
    if (length($GetParam{StartMinute}) == 1) {
        $GetParam{StartMinute} = "0$GetParam{StartMinute}";
    }
    if (!$GetParam{StartHour}) {
        $GetParam{StartHour} = "00";
    }
    if (!$GetParam{StartMinute}) {
        $GetParam{StartMinute} = "00";
    }

    if (length($GetParam{EndMonth}) == 1) {
        $GetParam{EndMonth} = "0$GetParam{EndMonth}";
    }
    if (length($GetParam{EndDay}) == 1) {
        $GetParam{EndDay} = "0$GetParam{EndDay}";
    }
    if (length($GetParam{EndHour}) == 1) {
        $GetParam{EndHour} = "0$GetParam{EndHour}";
    }
    if (length($GetParam{EndMinute}) == 1) {
        $GetParam{EndMinute} = "0$GetParam{EndMinute}";
    }
    if (!$GetParam{EndHour}) {
        $GetParam{EndHour} = "00";
    }
    if (!$GetParam{EndMinute}) {
        $GetParam{EndMinute} = "00";
    }

        my $FromSystemTime = "$GetParam{StartYear}-$GetParam{StartMonth}-$GetParam{StartDay} $GetParam{StartHour}:$GetParam{StartMinute}:00";
        my $ToSystemTime = "$GetParam{EndYear}-$GetParam{EndMonth}-$GetParam{EndDay} $GetParam{EndHour}:$GetParam{EndMinute}:00";

        my %TimeCheckList = ();
        my $AgentIfBusy = '';
        my $AgentIfBusyText = $LayoutObject->{LanguageObject}->Translate( "is occupied during this period.");


        for my $AgentID ( @{$ResourceIDs} ) {

            %TimeCheckList = $CalendarTimeCheckObject->CalendarTimeCheck(
                FromSystemTime => $FromSystemTime,
                ToSystemTime   => $ToSystemTime,
                AgentID        => $AgentID,
                CalID          => $GetParam{CalID},
            );

            if ( %TimeCheckList ) {
                my $Name = $UserObject->UserName(
                    UserID => $AgentID,
                );
                $AgentIfBusy .= "Agent $Name $AgentIfBusyText<br>";
            }
        }

        my $Output = $AgentIfBusy;

        # get output back
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $Output,
            Type        => 'inline',
            NoCache     => '1',
        );
    }
}

1;
