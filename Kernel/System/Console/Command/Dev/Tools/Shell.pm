# --
# Kernel/System/Console/Command/Dev/Tools/Shell.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Shell.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Dev::Tools::Shell;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Main',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('An interactive REPL shell for the OFORK API.');

    $Self->AddOption(
        Name        => 'eval',
        Description => 'Perl code that should be evaluated in the OFORK context.',
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    my @Dependencies = ( 'Devel::REPL', 'Data::Printer' );

    DEPENDENCY:
    for my $Dependency (@Dependencies) {
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require( $Dependency, Silent => 1 ) ) {
            die
                "Required Perl module '$Dependency' not found. Please make sure the following dependencies are installed: "
                . join( ' ', @Dependencies );
        }
    }

    return 1;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Repl = Devel::REPL->new();

    for my $Plugin (qw(History LexEnv MultiLine::PPI FancyPrompt OFORK)) {
        $Repl->load_plugin($Plugin);
    }

    # fancy things are made with love <3
    $Repl->fancy_prompt(
        sub {
            my $Self = shift;
            return sprintf 'OFORK: %03d%s> ',
                $Self->lines_read(),
                $Self->can('line_depth') ? ':' . $Self->line_depth() : '';
        }
    );

    $Repl->ColoredOutput( $Self->{ANSI} );

    my $Code = $Self->GetOption('eval');
    if ($Code) {
        my @Result = $Repl->formatted_eval($Code);
        $Self->Print("@Result") if !$Repl->exit_repl();
    }
    else {
        $Repl->run();
    }

    return $Self->ExitCodeOk();
}

1;
