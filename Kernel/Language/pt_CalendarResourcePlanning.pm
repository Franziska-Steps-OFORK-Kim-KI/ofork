# --
# Kernel/Language/pt_CalendarResourcePlanning.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de
# --
# $Id: pt_CalendarResourcePlanning.pm,v 1.1.1.1 2018/08/18 15:31:33 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::pt_CalendarResourcePlanning;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Resource Overview'} = '';
    $Self->{Translation}->{'Manage Teams'} = '';
    $Self->{Translation}->{'Manage Team Agents'} = '';
    $Self->{Translation}->{'No teams found.'} = '.';
    $Self->{Translation}->{'Please add a team first by using Manage Teams page.'} = '';
    $Self->{Translation}->{'No team agents found.'} = '';
    $Self->{Translation}->{'Please assign agents to a team first by using Manage Team Agents page.'} = '';
    $Self->{Translation}->{'Add Team'} = '';
    $Self->{Translation}->{'Team Import'} = '';
    $Self->{Translation}->{'Here you can upload a configuration file to import a team to your system. The file needs to be in .yml format as exported by team management module.'} = '';
    $Self->{Translation}->{'Upload team configuration'} = '';
    $Self->{Translation}->{'Import team'} = '';
    $Self->{Translation}->{'Filter for teams'} = '';
    $Self->{Translation}->{'Export team'} = '';
    $Self->{Translation}->{'Edit Team'} = '';
    $Self->{Translation}->{'Team with same name already exists.'} = '';
    $Self->{Translation}->{'Filter for agents'} = '';
    $Self->{Translation}->{'Teams'} = '';
    $Self->{Translation}->{'Manage Team-Agent Relations'} = '';
    $Self->{Translation}->{'Change Agent Relations for Team'} = '';
    $Self->{Translation}->{'Change Team Relations for Agent'} = '';
    $Self->{Translation}->{'Shown resources'} = '';
    $Self->{Translation}->{'Available Resources'} = '';
    $Self->{Translation}->{'Filter available resources'} = '';
    $Self->{Translation}->{'Visible Resources (order by drag & drop)'} = '';
    $Self->{Translation}->{'Need TeamID!'} = '';
    $Self->{Translation}->{'Invalid GroupID!'} = '';
    $Self->{Translation}->{'Couldn\'t read team configuration file. Please make sure you file is valid.'} = '';
    $Self->{Translation}->{'Could not import the team!'} = '';
    $Self->{Translation}->{'Team imported!'} = '';
    $Self->{Translation}->{'Could not retrieve data for given TeamID %s!'} = '';
    $Self->{Translation}->{'Unassigned'} = 'Nicht zugewiesen';
    $Self->{Translation}->{'is occupied during this period.'} = '';
    $Self->{Translation}->{'Manage team agents.'} = '';
    $Self->{Translation}->{'Resource overview page.'} = '';
    $Self->{Translation}->{'Resource overview screen.'} = '';
    $Self->{Translation}->{'Resources list.'} = '';
    $Self->{Translation}->{'Team agents management screen.'} = '';
    $Self->{Translation}->{'Team list'} = '';
    $Self->{Translation}->{'Team management screen.'} = '';
    $Self->{Translation}->{'Team management.'} = '';

    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Available Resources',
    'Filter available resources',
    'Shown resources',
    'Visible Resources (order by drag & drop)',
    );
}

1;
