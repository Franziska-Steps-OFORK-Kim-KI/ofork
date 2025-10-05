# --
# Kernel/System/SysConfig/ValueType/Entity/Queue.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Queue.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SysConfig::ValueType::Entity::Queue;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::SysConfig::ValueType::Entity);

our @ObjectDependencies = (
    'Kernel::System::Queue',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::System::SysConfig::ValueType::Entity::Queue - System configuration queue entity type backend.

=head1 PUBLIC INTERFACE

=head2 new()

Create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $EntityTypeObject = $Kernel::OM->Get('Kernel::System::SysConfig::ValueType::Entity::Queue');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub EntityValueList {
    my ( $Self, %Param ) = @_;

    my %Queues = $Kernel::OM->Get('Kernel::System::Queue')->QueueList(
        Valid => 1,
    );

    my @Result;

    for my $ID ( sort keys %Queues ) {
        push @Result, $Queues{$ID};
    }

    return @Result;
}

sub EntityLookupFromWebRequest {
    my ( $Self, %Param ) = @_;

    my $QueueID = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'QueueID' ) // '';

    return if !$QueueID;

    return $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( QueueID => $QueueID );
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
