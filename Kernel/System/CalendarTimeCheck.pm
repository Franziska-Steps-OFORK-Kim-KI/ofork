# --
# Kernel/System/CalendarTimeCheck.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: CalendarTimeCheck.pm,v 1.22 2016/11/20 19:31:10 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::CalendarTimeCheck;

use strict;
use warnings;

use base qw(Kernel::System::EventHandler);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SysConfig',
    'Kernel::System::Time',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::CalendarTimeCheck - CalendarTimeCheck lib

=head1 SYNOPSIS

All Request functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $CalendarTimeCheckObject = $Kernel::OM->Get('Kernel::System::CalendarTimeCheck');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}


=item CalendarTimeCheck()

return TimeCheck list

    my %TimeCheckList = $CalendarTimeCheckObject->CalendarTimeCheck(
        FromSystemTime => 123456789,
        ToSystemTime   => 123456789,
        AgentID        => 123,
        CalID          => 123,
    );

=cut

sub CalendarTimeCheck {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(AgentID FromSystemTime ToSystemTime)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{CalID} ) {

        # sql
        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, calendar_id FROM calendar_appointment WHERE ((? between start_time AND end_time) OR (? between start_time AND end_time)) AND id != ? AND (resource_id LIKE '%," . $Param{AgentID} . ",%' OR resource_id LIKE '" . $Param{AgentID} . ",%' OR resource_id LIKE '%," . $Param{AgentID} . "' OR resource_id = '" . $Param{AgentID} . "' )",
            Bind => [ \$Param{FromSystemTime}, \$Param{ToSystemTime}, \$Param{CalID}, ],
        );
    }
    else {

        # sql
        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, calendar_id FROM calendar_appointment WHERE ((? between start_time AND end_time) OR (? between start_time AND end_time)) AND (resource_id LIKE '%," . $Param{AgentID} . ",%' OR resource_id LIKE '" . $Param{AgentID} . ",%' OR resource_id LIKE '%," . $Param{AgentID} . "' OR resource_id = '" . $Param{AgentID} . "' )",
            Bind => [ \$Param{FromSystemTime}, \$Param{ToSystemTime}, ],
        );
    }

    # fetch the result
    my %TimeCheckList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $TimeCheckList{ $Row[0] } = $Row[1];
    }

    return %TimeCheckList;
}


1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
