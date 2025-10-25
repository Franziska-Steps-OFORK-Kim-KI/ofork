# --
# Kernel/System/SupportDataCollector/Plugin/OFORK/FileSystemWritable.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: FileSystemWritable.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OFORK::FileSystemWritable;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub GetDisplayPath {
    return Translatable('OFORK');
}

sub Run {
    my $Self = shift;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

    my @TestDirectories = qw(
        /bin/
        /Kernel/
        /Kernel/System/
        /Kernel/Output/
        /Kernel/Output/HTML/
        /Kernel/Modules/
    );

    my @ReadonlyDirectories;

    for my $TestDirectory (@TestDirectories) {
        my $File = $Home . $TestDirectory . "check_permissions.$$";
        if ( open( my $FH, '>', "$File" ) ) {
            print $FH "test";
            close($FH);
            unlink $File;
        }
        else {
            push @ReadonlyDirectories, $TestDirectory;
        }
    }

    if (@ReadonlyDirectories) {
        $Self->AddResultProblem(
            Label   => Translatable('File System Writable'),
            Value   => join( ', ', @ReadonlyDirectories ),
            Message => Translatable('The file system on your OFORK partition is not writable.'),
        );
    }
    else {
        $Self->AddResultOk(
            Label => Translatable('File System Writable'),
            Value => '',
        );
    }

    return $Self->GetResults();
}

1;
