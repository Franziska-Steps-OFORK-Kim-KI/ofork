# --
# Kernel/Modules/AgentTicketPrint.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: AgentTicketPrint.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketPrint;

use strict;
use warnings;

use Kernel::System::DateTime;
use Kernel::System::VariableCheck qw(IsHashRefWithData);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Check needed stuff.
    if ( !$Self->{TicketID} ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Need TicketID!'),
        );
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # Check permissions.
    my $Access = $TicketObject->TicketPermission(
        Type     => 'ro',
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    # No permission, do not show ticket.
    return $LayoutObject->NoPermission( WithHeader => 'yes' ) if !$Access;

    # Get ACL restrictions.
    my %PossibleActions = (
        1 => $Self->{Action},
    );

    my $ACL = $TicketObject->TicketAcl(
        Data          => \%PossibleActions,
        Action        => $Self->{Action},
        TicketID      => $Self->{TicketID},
        ReturnType    => 'Action',
        ReturnSubType => '-',
        UserID        => $Self->{UserID},
    );
    my %AclAction = $TicketObject->TicketAclActionData();

    # Check if ACL restrictions exist.
    if ( $ACL || IsHashRefWithData( \%AclAction ) ) {

        my %AclActionLookup = reverse %AclAction;

        # Show error screen if ACL prohibits this action.
        if ( !$AclActionLookup{ $Self->{Action} } ) {
            return $LayoutObject->NoPermission( WithHeader => 'yes' );
        }
    }

    # Get content.
    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    # Assemble file name.
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    if ( $Self->{UserTimeZone} ) {
        $DateTimeObject->ToTimeZone( TimeZone => $Self->{UserTimeZone} );
    }
    my $Filename = 'Ticket_' . $Ticket{TicketNumber} . '_';
    $Filename .= $DateTimeObject->Format( Format => '%Y-%m-%d_%H:%M' );
    $Filename .= '.pdf';

    # Return the PDF document.
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $PDFString   = $Kernel::OM->Get('Kernel::Output::PDF::Ticket')->GeneratePDF(
        TicketID      => $Self->{TicketID},
        UserID        => $Self->{UserID},
        ArticleID     => $ParamObject->GetParam( Param => 'ArticleID' ),
        ArticleNumber => $ParamObject->GetParam( Param => 'ArticleNumber' ),
        Interface     => 'Agent',
    );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ShowImagePrint = $ConfigObject->Get('PDF::ImagePrint');

    if ( $ShowImagePrint && $ShowImagePrint >= 1 ) {

        # Get appropriate interface flag.
        my %Interface;
        $Interface{Agent} = 1;

        # Get article list.
        my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my @MetaArticles  = $ArticleObject->ArticleList(
            TicketID => $Ticket{TicketID},
            UserID   => $Self->{UserID},
            %{ $Interface{IsVisibleForCustomer} },
        );

        # Check if only one article should be printed in agent interface.
        if ( $ParamObject->GetParam( Param => 'ArticleID' ) ) {
            @MetaArticles = grep { $_->{ArticleID} == $ParamObject->GetParam( Param => 'ArticleID' ) }
                @MetaArticles;
        }

        # Get article content.
        my @ArticleBox;
        for my $MetaArticle (@MetaArticles) {
            my $ArticleBackendObject = $ArticleObject->BackendForArticle( %{$MetaArticle} );
            my %Article              = $ArticleBackendObject->ArticleGet(
                %{$MetaArticle},
                DynamicFields => 0,
            );
            my %Attachments = $ArticleBackendObject->ArticleAttachmentIndex(
                %{$MetaArticle},
                ExcludePlainText => 1,
                ExcludeHTMLBody  => 1,
                ExcludeInline    => 0,
            );
            $Article{Atms} = \%Attachments;
            push @ArticleBox, \%Article;
        }

        my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

        my @ArticleData = @ArticleBox;
        for my $ArticleTmp (@ArticleData) {

            my %Article = %{$ArticleTmp};

            # Get attachment string.
            my %AtmIndex = ();
            if ( $Article{Atms} ) {
                %AtmIndex = %{ $Article{Atms} };
            }
            for my $FileID ( sort keys %AtmIndex ) {
                my %File = %{ $AtmIndex{$FileID} };

                my @FilenameSplit = split( /\./, $File{Filename} );
                if ( $FilenameSplit[1] eq "jpeg" ) {
                    $File{Filename} = $FilenameSplit[0] . '.jpg';
                }

                if ( $File{Filename} && $File{Filename} ne '' ) {

                    my $GetFileLocation = $ConfigObject->Get('Home') . '/var/tmp/' . $File{Filename};

                    my $Success = $MainObject->FileDelete(
                        Location => $GetFileLocation,
                    );
                }
            }
        }
    }

    return $LayoutObject->Attachment(
        Filename    => $Filename,
        ContentType => "application/pdf",
        Content     => $PDFString,
        Type        => 'inline',
    );
}

1;
