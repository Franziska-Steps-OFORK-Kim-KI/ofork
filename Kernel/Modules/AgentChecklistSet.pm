# --
# Kernel/Modules/AgentChecklistSet.pm - to link objects
# Copyright (C) 2010-2025 OFORK, https://o-fork.de/
# --
# $Id: AgentChecklistSet.pm,v 1.1 2019/01/20 14:22:31 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentChecklistSet;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    # Checklist management
    my $ChecklistObject           = $Kernel::OM->Get('Kernel::System::Checklist');
    my $ChecklistFieldObject      = $Kernel::OM->Get('Kernel::System::ChecklistField');
    my $ChecklistFieldValueObject = $Kernel::OM->Get('Kernel::System::ChecklistFieldValue');

    # get params
    my %GetParam;
    for my $Param (
        qw(TicketID ChecklistFieldValueID IfSet SetArticle Task)
        )
    {
        $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
    }

    my $ChecklistFieldValueID = $ChecklistFieldValueObject->ChecklistFieldValueUpdate(
        ChecklistFieldValueID => $GetParam{ChecklistFieldValueID},
        IfSet                 => $GetParam{IfSet},
        UserID                => $Self->{UserID},
    );

    if ( $GetParam{SetArticle} == 1 ) {

        my $From    = "\"$Self->{UserFullname}\" <$Self->{UserEmail}>";
        my $Subject = "";

        my $SubjectA = $LayoutObject->{LanguageObject}->Translate( 'The task ');
        my $SubjectB = $LayoutObject->{LanguageObject}->Translate( ' has been completed.');
        my $SubjectC = $LayoutObject->{LanguageObject}->Translate( ' is not needed.');

        if ( $GetParam{IfSet} == 1 ) {
            $Subject = $SubjectA . '"' . $GetParam{Task} . '"' . $SubjectB;
        }else {
            $Subject = $SubjectA . '"' . $GetParam{Task} . '"' . $SubjectC;
        }

        my $ArticleID = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
            TicketID             => $GetParam{TicketID},
            SenderType           => 'agent',
            IsVisibleForCustomer => 0,
            From                 => $From,
            Subject              => $Subject,
            Body                 => $Subject,
            Charset              => '$LayoutObject->{UserCharset}',
            MimeType             => 'text/plain',
            HistoryType          => 'AddNote',
            HistoryComment       => '%%Note',
            UserID               => $Self->{UserID},
        );
    }

    return $LayoutObject->Redirect( OP => "Action=AgentTicketZoom;TicketID=$GetParam{TicketID};ChecklistWidget=Expanded" );
}

1;
