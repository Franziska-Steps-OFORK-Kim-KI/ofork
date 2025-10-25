# --
# Kernel/Modules/AgentAppointmentTeamList.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: AgentAppointmentTeamList.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentAppointmentTeamList;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Output;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # Get names of all parameters.
    my @ParamNames = $ParamObject->GetParamNames();

    # Get params.
    my %GetParam;

    KEY:
    for my $Key (@ParamNames) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $JSON = $LayoutObject->JSONEncode( Data => [] );

    $LayoutObject->ChallengeTokenCheck();

    # check request
    if ( $Self->{Subaction} eq 'ListResources' ) {

        if ( $GetParam{TeamID} ) {

            # Get list of agents for the team.
            my %TeamUserIDs = $Kernel::OM->Get('Kernel::System::Calendar::Team')->TeamUserList(
                TeamID => $GetParam{TeamID},
                UserID => $Self->{UserID},
            );

            if ( scalar keys %TeamUserIDs > 0 ) {

                my $UserObject = $Kernel::OM->Get('Kernel::System::User');

                # get user preferences
                my %Preferences = $UserObject->GetPreferences(
                    UserID => $Self->{UserID},
                );

                # get resource names
                my @TeamUserList;
                for my $UserID ( sort keys %TeamUserIDs ) {
                    my %User = $UserObject->GetUserData(
                        UserID => $UserID,
                    );
                    push @TeamUserList, {
                        id           => $User{UserID},
                        title        => $User{UserFullname},
                        TeamID       => $GetParam{TeamID},
                        UserLastname => $User{UserLastname},
                    };
                }

                # Sort the list by last name.
                @TeamUserList = sort { $a->{UserLastname} cmp $b->{UserLastname} } @TeamUserList;
                my @TeamUserIDs = map { $_->{id} } @TeamUserList;

                # Resource name lookup table.
                my %TeamUserList = map { $_->{id} => $_->{title} } @TeamUserList;

                # User preference key.
                my $ShownResourcesPrefKey = 'UserResourceOverviewShownResources-' . $GetParam{TeamID};

                # Read preference if it exists.
                my @ShownResources;
                if ( $Preferences{$ShownResourcesPrefKey} ) {
                    my $ShownResourcesPrefVal = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
                        Data => $Preferences{$ShownResourcesPrefKey},
                    );

                    # Add only valid and unique users.
                    for my $UserID ( @{ $ShownResourcesPrefVal || [] } ) {
                        if ( grep { $_ eq $UserID } @TeamUserIDs ) {
                            if ( !grep { $_->{id} eq $UserID } @ShownResources ) {
                                push @ShownResources, {
                                    id     => $UserID,
                                    title  => $TeamUserList{$UserID},
                                    TeamID => $GetParam{TeamID},
                                };
                            }
                        }
                    }
                }

                # Set default if empty.
                if ( !scalar @ShownResources ) {
                    @ShownResources = @TeamUserList;
                }

                push @ShownResources, {
                    id     => 0,
                    title  => $LayoutObject->{LanguageObject}->Translate('Unassigned'),
                    TeamID => $GetParam{TeamID},
                };

                # Build JSON output.
                $JSON = $LayoutObject->JSONEncode(
                    Data => (
                        \@ShownResources,
                    ),
                );
            }
        }
    }

    # Send JSON response.
    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

1;
