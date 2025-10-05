# --
# Kernel/Modules/AgentAppointmentResourceOverview.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: AgentAppointmentResourceOverview.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentAppointmentResourceOverview;

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{OverviewScreen} = 'ResourceOverview';

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Get user's permissions to associated modules which are displayed as links.
    for my $Module (
        qw(AdminAppointmentCalendarManage AgentAppointmentTeam AgentAppointmentTeamUser)
        )
    {
        my $ModuleGroups = $ConfigObject->Get('Frontend::Module')->{$Module}->{Group} // [];

        if ( IsArrayRefWithData($ModuleGroups) ) {
            MODULE_GROUP:
            for my $ModuleGroup ( @{$ModuleGroups} ) {
                my $HasPermission = $GroupObject->PermissionCheck(
                    UserID    => $Self->{UserID},
                    GroupName => $ModuleGroup,
                    Type      => 'rw',
                );
                if ($HasPermission) {
                    $Param{ModulePermissions}->{$Module} = 1;
                    last MODULE_GROUP;
                }
            }
        }

        # Always allow links if no groups are specified.
        else {
            $Param{ModulePermissions}->{$Module} = 1;
        }
    }

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # Get names of all parameters.
    my @ParamNames = $ParamObject->GetParamNames();

    # Get params.
    my %GetParam;
    PARAMNAME:
    for my $Key (@ParamNames) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    # Get all user's valid calendars.
    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );

    my $CalendarObject = $Kernel::OM->Get('Kernel::System::Calendar');

    my @Calendars = $CalendarObject->CalendarList(
        UserID  => $Self->{UserID},
        ValidID => $ValidID,
    );

    # Check if we found some.
    if (@Calendars) {

        my $TeamObject = $Kernel::OM->Get('Kernel::System::Calendar::Team');

        my %TeamList = $TeamObject->AllowedTeamList(
            UserID => $Self->{UserID},
        );

        if ( scalar keys %TeamList > 0 ) {

            my $UserObject = $Kernel::OM->Get('Kernel::System::User');

            # Get if it's needed to save a new team selection or get a previously selected team
            if ( $GetParam{Team} && $TeamList{ $GetParam{Team} } ) {

                # save the recently selected team
                $UserObject->SetPreferences(
                    Key    => 'LastAppointmentCalendarTeam',
                    Value  => $GetParam{Team},
                    UserID => $Self->{UserID},
                );
            }
            else {

                # Get the team selection for the current user.
                my %UserPreferences = $UserObject->GetPreferences(
                    UserID => $Self->{UserID},
                );

                if (
                    IsHashRefWithData( \%UserPreferences )
                    && $UserPreferences{LastAppointmentCalendarTeam}
                    && $TeamList{ $UserPreferences{LastAppointmentCalendarTeam} }
                    )
                {
                    $GetParam{Team} = $UserPreferences{LastAppointmentCalendarTeam};
                }
            }

            my @TeamIDs = sort keys %TeamList;
            $Param{Team} = $GetParam{Team} // $TeamIDs[0];

            $Param{TeamStrg} = $LayoutObject->BuildSelection(
                Data         => \%TeamList,
                Name         => 'Team',
                ID           => 'Team',
                Class        => 'Modernize',
                SelectedID   => $Param{Team},
                PossibleNone => 0,
            );

            $LayoutObject->Block(
                Name => 'TeamList',
                Data => { %Param, },
            );

            my %TeamUserIDs = $TeamObject->TeamUserList(
                TeamID => $Param{Team},
                UserID => $Self->{UserID},
            );

            if ( scalar keys %TeamUserIDs > 0 ) {

                # New appointment dialog.
                if ( $Self->{Subaction} eq 'AppointmentCreate' ) {
                    $LayoutObject->AddJSData(
                        Key   => 'AppointmentCreate',
                        Value => {
                            Start     => $ParamObject->GetParam( Param => 'Start' )     // undef,
                            End       => $ParamObject->GetParam( Param => 'End' )       // undef,
                            PluginKey => $ParamObject->GetParam( Param => 'PluginKey' ) // undef,
                            Search    => $ParamObject->GetParam( Param => 'Search' )    // undef,
                            ObjectID  => $ParamObject->GetParam( Param => 'ObjectID' )  // undef,
                        },
                    );
                }

                # Edit appointment dialog.
                else {
                    $LayoutObject->AddJSData(
                        Key   => 'AppointmentID',
                        Value => $ParamObject->GetParam( Param => 'AppointmentID' ) // undef,
                    );
                }

                # Trigger regular date picker initialization, used by AgentAppointmentEdit screen.
                #   This screen is initialized via AJAX, and then it's too late to output this
                #   configuration.
                $LayoutObject->{HasDatepicker} = 1;

                $LayoutObject->Block(
                    Name => 'AppointmentCreateButton',
                );

                $LayoutObject->Block(
                    Name => 'CalendarDiv',
                    Data => {
                        %Param,
                        CalendarWidth => 100,
                    },
                );

                $LayoutObject->Block(
                    Name => 'CalendarWidget',
                );

                # Get user preferences.
                my %Preferences = $UserObject->GetPreferences(
                    UserID => $Self->{UserID},
                );

                # Get resource names.
                my @TeamUserList;
                for my $UserID ( sort keys %TeamUserIDs ) {
                    my %User = $UserObject->GetUserData(
                        UserID => $UserID,
                    );
                    push @TeamUserList, {
                        UserID       => $User{UserID},
                        Name         => $User{UserFullname},
                        UserLastname => $User{UserLastname},
                    };
                }

                # Sort the list by last name.
                @TeamUserList = sort { $a->{UserLastname} cmp $b->{UserLastname} } @TeamUserList;
                my @TeamUserIDs = map { $_->{UserID} } @TeamUserList;

                # Resource name lookup table.
                my %TeamUserList = map { $_->{UserID} => $_->{Name} } @TeamUserList;

                for my $Key ( sort keys %TeamUserList ) {
                    $LayoutObject->AddJSData(
                        Key   => "Column$Key",
                        Value => $TeamUserList{$Key},
                    );
                }

                # User preference key.
                my $ShownResourcesPrefKey = 'User'
                    . $Self->{OverviewScreen}
                    . 'ShownResources-'
                    . $Param{Team};

                my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

                # Read preference if it exists.
                my @ShownResources;
                if ( $Preferences{$ShownResourcesPrefKey} ) {
                    my $ShownResourcesPrefVal = $JSONObject->Decode(
                        Data => $Preferences{$ShownResourcesPrefKey},
                    );

                    # Add only valid and unique users.
                    for my $UserID ( @{ $ShownResourcesPrefVal || [] } ) {
                        if ( grep { $_ eq $UserID } @TeamUserIDs ) {

                            if ( !grep { $_ eq $UserID } @ShownResources ) {
                                push @ShownResources, $UserID;
                            }
                        }
                    }

                    # Activate restore settings button.
                    $LayoutObject->AddJSData(
                        Key   => 'RestoreDefaultSettings',
                        Value => 1,
                    );
                }

                # Set default if empty.
                if ( !scalar @ShownResources ) {
                    @ShownResources = @TeamUserIDs;
                }

                # Calculate difference.
                my @AvailableResources;
                for my $ColumnName (@TeamUserIDs) {
                    if ( !grep { $_ eq $ColumnName } @ShownResources ) {
                        push @AvailableResources, $ColumnName;
                    }
                }

                # Variables for allocation list.
                $LayoutObject->AddJSData(
                    Key   => 'ShownResourceSettings',
                    Value => {
                        ColumnsEnabled   => $JSONObject->Encode( Data => \@ShownResources ),
                        ColumnsAvailable => $JSONObject->Encode( Data => \@AvailableResources ),
                        %Param,
                    },
                );

                my $CalendarLimit = int $ConfigObject->Get('AppointmentCalendar::CalendarLimitOverview') || 10;
                $LayoutObject->AddJSData(
                    Key   => 'CalendarLimit',
                    Value => $CalendarLimit,
                );

                my $CalendarSelection = $JSONObject->Decode(
                    Data => $Preferences{ 'User' . $Self->{OverviewScreen} . 'CalendarSelection' } || '[]',
                );

                my $CurrentCalendar = 1;
                my @CalendarConfig;
                for my $Calendar (@Calendars) {

                    # Check the calendar if stored in preferences.
                    if ( scalar @{$CalendarSelection} ) {
                        if (
                            grep { $_ == $Calendar->{CalendarID} }
                            @{$CalendarSelection}
                            )
                        {

                            if ( $CurrentCalendar <= $CalendarLimit ) {
                                $Calendar->{Checked} = 'checked="checked" ';
                            }
                        }
                    }

                    # Check calendar by default if limit is not yet reached.
                    else {
                        if ( $CurrentCalendar <= $CalendarLimit ) {
                            $Calendar->{Checked} = 'checked="checked" ';
                        }
                    }

                    # Get access tokens.
                    $Calendar->{AccessToken} = $CalendarObject->GetAccessToken(
                        CalendarID => $Calendar->{CalendarID},
                        UserLogin  => $Self->{UserLogin},
                    );

                    # Calendar check-box in the widget.
                    $LayoutObject->Block(
                        Name => 'CalendarSwitch',
                        Data => { %{$Calendar}, %Param, },
                    );

                    # Calculate best text color.
                    $Calendar->{TextColor} = $CalendarObject->GetTextColor(
                        Background => $Calendar->{Color}
                    ) || '#FFFFFF';

                    # Define calendar configuration.
                    push @CalendarConfig, $Calendar;

                    $CurrentCalendar++;
                }
                $LayoutObject->AddJSData(
                    Key   => 'CalendarConfig',
                    Value => \@CalendarConfig,
                );

                $LayoutObject->AddJSData(
                    Key   => 'TeamID',
                    Value => $Param{Team},
                );

                # Set initial view.
                $LayoutObject->AddJSData(
                    Key   => 'DefaultView',
                    Value => $Preferences{ 'User' . $Self->{OverviewScreen} . 'DefaultView' } || 'timelineWeek',
                );

                $LayoutObject->AddJSData(
                    Key   => 'TooltipTemplateResource',
                    Value => 1,
                );

                # Get plugin list.
                $Param{PluginList} = $Kernel::OM->Get('Kernel::System::Calendar::Plugin')->PluginList();

                $LayoutObject->AddJSData(
                    Key   => 'PluginList',
                    Value => $Param{PluginList},
                );

                # Get registered ticket appointment types.
                my %TicketAppointmentTypes = $CalendarObject->TicketAppointmentTypesGet();

                # Output configured ticket appointment type mark and draggability.
                my %TicketAppointmentConfig;
                for my $Type ( sort keys %TicketAppointmentTypes ) {
                    my $NoDrag = 0;

                    # prevent dragging of ticket escalation appointments
                    if (
                        $Type eq 'FirstResponseTime'
                        || $Type eq 'UpdateTime'
                        || $Type eq 'SolutionTime'
                        )
                    {
                        $NoDrag = 1;
                    }

                    $TicketAppointmentConfig{$Type} = {
                        Mark => lc substr(
                            $TicketAppointmentTypes{$Type}->{Mark}, 0, 1
                        ),
                        NoDrag => $NoDrag,
                    };
                }

                $LayoutObject->AddJSData(
                    Key   => 'TicketAppointmentConfig',
                    Value => \%TicketAppointmentConfig,
                );

                # Get working hour appointments.
                my @WorkingHours = $Self->_GetWorkingHours();
                my @WorkingHoursConfig;
                for my $Appointment (@WorkingHours) {

                    # Sort days of the week.
                    my @DoW = sort @{ $Appointment->{DoW} };

                    push @WorkingHoursConfig, {
                        id        => 'workingHours',
                        start     => $Appointment->{StartTime},
                        end       => $Appointment->{EndTime},
                        color     => '#D7D7D7',
                        rendering => 'inverse-background',
                        editable  => '',
                        dow       => \@DoW,
                    };
                }
                $LayoutObject->AddJSData(
                    Key   => 'WorkingHoursConfig',
                    Value => \@WorkingHoursConfig,
                );
            }

            # Show empty team message.
            else {
                $LayoutObject->Block(
                    Name => 'EmptyTeam',
                    Data => \%Param,
                );
            }
        }

        # Show no team found message.
        else {
            $LayoutObject->Block(
                Name => 'NoTeam',
                Data => \%Param,
            );
        }
    }

    # Show no calendar found message.
    else {
        $LayoutObject->Block(
            Name => 'NoCalendar',
        );
    }

    $LayoutObject->AddJSData(
        Key   => 'OverviewScreen',
        Value => $Self->{OverviewScreen},
    );

    # Get text direction from language object.
    my $TextDirection = $LayoutObject->{LanguageObject}->{TextDirection} || '';
    $LayoutObject->AddJSData(
        Key   => 'IsRTLLanguage',
        Value => ( $TextDirection eq 'rtl' ) ? '1' : '',
    );

    $LayoutObject->AddJSData(
        Key   => 'CalendarWeekDayStart',
        Value => $Kernel::OM->Get('Kernel::Config')->Get('CalendarWeekDayStart') || 0,
    );

    # Output page.
    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentAppointmentResourceOverview',
        Data         => { %Param, },
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

sub _GetWorkingHours {
    my ( $Self, %Param ) = @_;

    # Get working hours from system configuration.
    my $WorkingHoursConfig = $Kernel::OM->Get('Kernel::Config')->Get('TimeWorkingHours');

    # Create working hour appointments for each day.
    my @WorkingHours;
    for my $DayName ( sort keys %{$WorkingHoursConfig} ) {

        # Day of the week.
        my $DoW = 0;    # Sun
        if ( $DayName eq 'Mon' ) {
            $DoW = 1;
        }
        elsif ( $DayName eq 'Tue' ) {
            $DoW = 2;
        }
        elsif ( $DayName eq 'Wed' ) {
            $DoW = 3;
        }
        elsif ( $DayName eq 'Thu' ) {
            $DoW = 4;
        }
        elsif ( $DayName eq 'Fri' ) {
            $DoW = 5;
        }
        elsif ( $DayName eq 'Sat' ) {
            $DoW = 6;
        }

        my $StartTime = 0;
        my $EndTime   = 0;

        START_TIME:
        for ( $StartTime = 0; $StartTime < 24; $StartTime++ ) {

            # Is this working hour?
            if ( grep { $_ eq $StartTime } @{ $WorkingHoursConfig->{$DayName} } ) {

                # Go to the end of the working hours.
                for ( my $EndHour = $StartTime; $EndHour < 24; $EndHour++ ) {
                    if ( !grep { $_ eq $EndHour } @{ $WorkingHoursConfig->{$DayName} } ) {
                        $EndTime = $EndHour;

                        # Add appointment
                        if ( $EndTime > $StartTime ) {
                            push @WorkingHours, {
                                StartTime => sprintf( '%02d:00:00', $StartTime ),
                                EndTime   => sprintf( '%02d:00:00', $EndTime ),
                                DoW       => [$DoW],
                            };
                        }

                        # Skip some hours.
                        $StartTime = $EndHour;

                        next START_TIME;
                    }
                }
            }
        }
    }

    # Collapse appointments with same start and end times.
    for my $AppointmentA (@WorkingHours) {
        for my $AppointmentB (@WorkingHours) {
            if (
                $AppointmentA->{StartTime}
                && $AppointmentB->{StartTime}
                && $AppointmentA->{StartTime} eq $AppointmentB->{StartTime}
                && $AppointmentA->{EndTime} eq $AppointmentB->{EndTime}
                && $AppointmentA->{DoW} ne $AppointmentB->{DoW}
                )
            {
                push @{ $AppointmentA->{DoW} }, @{ $AppointmentB->{DoW} };
                $AppointmentB = undef;
            }
        }
    }

    # Return only non-empty appointments.
    return grep { scalar keys %{$_} } @WorkingHours;
}

1;
