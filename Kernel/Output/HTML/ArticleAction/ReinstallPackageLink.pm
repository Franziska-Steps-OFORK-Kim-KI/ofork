# --
# Kernel/Output/HTML/ArticleAction/ReinstallPackageLink.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: ReinstallPackageLink.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# ---
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ArticleAction::ReinstallPackageLink;

use strict;
use warnings;
use utf8;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::System::CommunicationChannel',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Ticket::Article',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub CheckAccess {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Ticket Article ChannelName UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Check 'admin' group access.
    my $Permission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
        UserID    => $Param{UserID},
        GroupName => 'admin',
        Type      => 'rw',
    );
    return if !$Permission;

    return 1;
}

sub GetConfig {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Ticket Article UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle(
        TicketID  => $Param{Ticket}->{TicketID},
        ArticleID => $Param{Article}->{ArticleID},
    );

    my %Article = $ArticleBackendObject->ArticleGet(
        TicketID  => $Param{Ticket}->{TicketID},
        ArticleID => $Param{Article}->{ArticleID},
    );

    # Get communication channel data.
    my %CommunicationChannel = $Kernel::OM->Get('Kernel::System::CommunicationChannel')->ChannelGet(
        ChannelID => $Article{CommunicationChannelID},
    );

    return ( \%MenuItem );
}

1;
