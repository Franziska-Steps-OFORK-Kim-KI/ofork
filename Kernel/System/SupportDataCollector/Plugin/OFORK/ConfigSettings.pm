# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/ConfigSettings.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: ConfigSettings.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::ConfigSettings;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub GetDisplayPath {
    return Translatable('OFORK') . '/' . Translatable('Config Settings');
}

sub Run {
    my $Self = shift;

    my @Settings = (
        'Home',
        'FQDN',
        'HttpType',
        'DefaultLanguage',
        'SystemID',
        'Version',
        'ProductName',
        'Organization',
        'OFORKTimeZone',
        'Ticket::IndexModule',
        'Ticket::SearchIndexModule',
        'Ticket::Article::Backend::MIMEBase::ArticleStorage',
        'SendmailModule',
        'Frontend::RichText',
        'Frontend::AvatarEngine',
        'Loader::Agent::DefaultSelectedSkin',
        'Loader::Customer::SelectedSkin',
    );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    for my $Setting (@Settings) {

        my $ConfigValue = $ConfigObject->Get($Setting);

        if ( $Setting =~ m{###} ) {
            my ( $Name, $SubKey ) = $Setting =~ m{(.*)###(.*)};
            $ConfigValue = $ConfigObject->Get($Name);
            $ConfigValue = $ConfigValue->{$SubKey} if ref $ConfigValue eq 'HASH';
        }

        if ( defined $ConfigValue ) {
            $Self->AddResultInformation(
                Identifier => $Setting,
                Label      => $Setting,
                Value      => $ConfigValue,
            );
        }
        else {
            $Self->AddResultProblem(
                Identifier => $Setting,
                Label      => $Setting,
                Value      => $ConfigValue,
                Message    => Translatable('Could not determine value.'),
            );
        }
    }

    return $Self->GetResults();
}

1;
