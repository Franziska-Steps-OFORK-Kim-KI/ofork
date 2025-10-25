# --
# Kernel/Output/HTML/Notification/SystemConfigurationIsDirtyCheck.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: SystemConfigurationIsDirtyCheck.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# ---
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Notification::SystemConfigurationIsDirtyCheck;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Group',
    'Kernel::System::SysConfig',
);

sub Run {
    my ( $Self, %Param ) = @_;

    if ( $Param{Type} eq 'Admin' ) {
        my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

        my $Group = $Param{Config}->{Group} || 'admin';

        my $HasPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
            UserID    => $Self->{UserID},
            GroupName => $Group,
            Type      => 'rw',
        );

        return '' if !$HasPermission;

        my $Result = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigurationIsDirtyCheck(
            UserID => $Self->{UserID},
        );

        if ($Result) {

            return $LayoutObject->Notify(
                Priority => 'Notice',
                Link => $LayoutObject->{Baselink} . 'Action=AdminSystemConfigurationDeployment;Subaction=Deployment',
                Data => $LayoutObject->{LanguageObject}->Translate(
                    "You have undeployed settings, would you like to deploy them?"
                ),
            );
        }
    }

    return '';
}

1;
