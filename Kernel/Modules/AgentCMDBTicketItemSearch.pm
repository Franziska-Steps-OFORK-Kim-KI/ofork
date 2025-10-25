# --
# Kernel/Modules/AgentCMDBTicketItemSearch.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AgentCMDBTicketItemSearch.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCMDBTicketItemSearch;

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

    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $EncodeObject         = $Kernel::OM->Get('Kernel::System::Encode');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    # get param
    my $CustomerUserID = $ParamObject->GetParam( Param => 'CustomerUserID' )     || '';

    my $ClassList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
        Valid => 1,
    );

    my $VersionID;
    my $CheckItem   = 0;
    my %ConfigItems = ();
    my $Output = '';

    for my $Class ( %{$ClassList} ) {
        if ( $Class =~ /^\d+$/ ) {

                if ( $Class ) {

                    # start search
                    my $SearchResultList = $ConfigItemObject->ConfigItemSearchExtended(
                        ClassIDs => [$Class],
                        What     => [
                            {
                                "[%]{'Version'}[%]{'Besitzer'}[%]{'Content'}" => $CustomerUserID,
                                "[%]{'Version'}[%]{'Owner'}[%]{'Content'}" => $CustomerUserID,
                            },
                        ],
                    );

                    $Param{Class} = ${$ClassList}{$Class};

                    for my $ConfigItemID ( @{$SearchResultList} ) {

                        my $VersionRef = $ConfigItemObject->VersionGet(
                            ConfigItemID => $ConfigItemID,
                        );
                        if ( $VersionRef->{Name} ) {
                            $CheckItem++;
                            $ConfigItems{ $VersionRef->{ConfigItemID} } = $VersionRef->{Name};
                        }
                    }

                    #generate output
                    $Param{ConfigItemStrg} = $LayoutObject->BuildSelection(
                        Data         => \%ConfigItems,
                        Name         => 'ConfigItemID' . $Class,
                        PossibleNone => 1,
                        Multiple     => 1,
                        Size         => 5,
                        Class        => 'Modernize',
                        Translation  => 0,
                        Max          => 200,
                    );

                    if ( $CheckItem >= 1 ) {
                        $LayoutObject->Block(
                            Name => 'ConfigItemClass',
                            Data => {
                                %Param,
                            },
                        );
                    }
                }
        }

        $CheckItem   = 0;
        %ConfigItems = ();
    }

    $Output = $LayoutObject->Output(
        TemplateFile => 'AgentCMDBTicketItemSearch',
        Data         => {%Param},
    );

    # get output back
    return $LayoutObject->Attachment(
        ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
        Content     => $Output,
        Type        => 'inline',
        NoCache     => '1',
    );

}

1;
