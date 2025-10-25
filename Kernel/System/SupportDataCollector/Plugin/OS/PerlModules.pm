# --
# Kernel/System/SupportDataCollector/Plugin/OS/PerlModules.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: PerlModules.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OS::PerlModules;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub GetDisplayPath {
    return Translatable('Operating System');
}

sub Run {
    my $Self = shift;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

    my $Output;
    open( my $FH, "-|", "perl $Home/bin/ofork.CheckModules.pl nocolors --all" );

    while (<$FH>) {
        $Output .= $_;
    }
    close($FH);

    if (
        $Output =~ m{Not \s installed! \s \(required}ismx
        || $Output =~ m{failed!}ismx
        )
    {
        $Self->AddResultProblem(
            Label   => Translatable('Perl Modules'),
            Value   => $Output,
            Message => Translatable('Not all required Perl modules are correctly installed.'),
        );
    }
    else {
        $Self->AddResultOk(
            Label => Translatable('Perl Modules'),
            Value => $Output,
        );
    }

    return $Self->GetResults();
}

1;
