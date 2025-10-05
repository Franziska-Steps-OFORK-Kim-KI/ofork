# --
# Kernel/Modules/SelfService.pm - to handle customer messages
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: SelfService.pm,v 1.21 2016/11/20 19:35:56 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::SelfService;

use strict;
use warnings;

use MIME::Base64;

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

    my $ParamObject                 = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                 = $Kernel::OM->Get('Kernel::System::Valid');
    my $CustomerUserObject          = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $LinkObject                  = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $TicketObject                = $Kernel::OM->Get('Kernel::System::Ticket');
    my $SelfServiceObject           = $Kernel::OM->Get('Kernel::System::SelfService');
    my $SelfServiceCategoriesObject = $Kernel::OM->Get('Kernel::System::SelfServiceCategories');

    # get params
    my %GetParam;
    for my $Key (qw( CategoryID SelfServiceID )) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    if ( !$Self->{Subaction} ) {

        # print form ...
        my $Output .= $LayoutObject->CustomerHeader();
        $Output    .= $LayoutObject->CustomerNavigationBar();
        $Output    .= $Self->_MaskNew(
            %GetParam,
        );
        $Output .= $LayoutObject->CustomerFooter();
        return $Output;
    }
    elsif  ( $Self->{Subaction} eq "More" ) {

        # print form ...
        my $Output .= $LayoutObject->CustomerHeader();
        $Output    .= $LayoutObject->CustomerNavigationBar();
        $Output    .= $Self->_MaskMore(
            %GetParam,
        );
        $Output .= $LayoutObject->CustomerFooter();
        return $Output;

    }

}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $ParamObject                     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                     = $Kernel::OM->Get('Kernel::System::Valid');
    my $CustomerUserObject              = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $LinkObject                      = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $TicketObject                    = $Kernel::OM->Get('Kernel::System::Ticket');
    my $SelfServiceObject               = $Kernel::OM->Get('Kernel::System::SelfService');
    my $SelfServiceCategoriesObject     = $Kernel::OM->Get('Kernel::System::SelfServiceCategories');
    my $SelfServiceCategoriesIconObject = $Kernel::OM->Get('Kernel::System::SelfServiceCategoriesIcon');

    $Param{FormID} = $Self->{FormID};

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $LayoutObject->Block(
        Name => 'SelfServiceOverview',
        Data => { %Param, },
    );

    my %SelfServiceCategoriesList = $SelfServiceCategoriesObject->SelfServiceCategoriesList(
        Valid  => 1,
        UserID => $Self->{UserID},
    );

    my $LineNum = 0;
    for my $CategoryID ( sort { $SelfServiceCategoriesList{$a} cmp $SelfServiceCategoriesList{$b} } %SelfServiceCategoriesList ) {

        if ( $SelfServiceCategoriesList{$CategoryID} ) {

            my %SelfServiceCategoriesData = $SelfServiceCategoriesObject->SelfServiceCategoriesGet(
                Name    => $SelfServiceCategoriesList{$CategoryID},
                UserID  => 1,
            );

            my %SelfServiceList = $SelfServiceObject->SelfServiceCatList(
                Valid      => 1,
                CategoryID => $SelfServiceCategoriesData{SelfServiceCategoriesID},
                UserID     => 1,
            );

            if ( %SelfServiceList ) {

                my %Data = $SelfServiceCategoriesIconObject->SelfServiceCategoriesIconGet(
                    ID => $SelfServiceCategoriesData{ImageID},
                );

                $SelfServiceCategoriesData{Content} = encode_base64($Data{Content});

                $SelfServiceCategoriesData{Content} =~ s/ //g;
                $SelfServiceCategoriesData{Content} =~ s/\n//g;
                $SelfServiceCategoriesData{Content} =~ s/\r//g;

                $LayoutObject->Block(
                    Name => 'SelfServiceCat',
                    Data => { %Param, %SelfServiceCategoriesData, },
                );

            }

            for my $SelfServiceID ( sort { $SelfServiceList{$a} cmp $SelfServiceList{$b} } keys %SelfServiceList ) {

                $LineNum ++;

                if ( $LineNum <= 3 ) {

                    $Param{CategoryID} = $CategoryID;

                    my %SelfService = $SelfServiceObject->SelfServiceGet(
                        SelfServiceID => $SelfServiceID,
                    );

                    $LayoutObject->Block(
                        Name => 'SelfServiceHead',
                        Data => { %Param, %SelfService, },
                    );

                }
            }

            if ( $LineNum > 3 ) {

                $Param{CategoryID} = $CategoryID;

                $LayoutObject->Block(
                    Name => 'SelfServiceHeadMoreID',
                    Data => { %Param, },
                );

            }
            else {

                $LayoutObject->Block(
                    Name => 'SelfServiceHeadNull',
                    Data => { %Param, },
                );

            }
        }
        $LineNum = 0;
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'SelfService',
        Data         => \%Param,
    );
}

sub _MaskMore {
    my ( $Self, %Param ) = @_;

    my $ParamObject                 = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                 = $Kernel::OM->Get('Kernel::System::Valid');
    my $CustomerUserObject          = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $LinkObject                  = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $TicketObject                = $Kernel::OM->Get('Kernel::System::Ticket');
    my $SelfServiceObject           = $Kernel::OM->Get('Kernel::System::SelfService');
    my $SelfServiceCategoriesObject = $Kernel::OM->Get('Kernel::System::SelfServiceCategories');

    $Param{FormID} = $Self->{FormID};

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $LayoutObject->Block(
        Name => 'SelfServiceOverviewMore',
        Data => { %Param, },
    );

    my %SelfServiceCategoriesData = $SelfServiceCategoriesObject->SelfServiceCategoriesGet(
        SelfServiceCategoriesID  => $Param{CategoryID},
        UserID                   => 1,
    );

    $LayoutObject->Block(
        Name => 'SelfServiceCatMore',
        Data => { %Param, %SelfServiceCategoriesData, },
    );

    my %SelfServiceList = $SelfServiceObject->SelfServiceCatList(
        Valid      => 1,
        CategoryID => $Param{CategoryID},
        UserID     => 1,
    );

    my $LineNum = 0;
    for my $SelfServiceID ( sort { $SelfServiceList{$a} cmp $SelfServiceList{$b} } keys %SelfServiceList ) {

        $LineNum ++;

        my %SelfService = $SelfServiceObject->SelfServiceGet(
            SelfServiceID => $SelfServiceID,
        );

        $SelfService{LineNum} = $LineNum;

        if ( $SelfService{SelfServiceID} eq $Param{SelfServiceID} ) {

            $SelfService{PlusStaus}  = 'display:none';
            $SelfService{MinusStaus} = 'display:show';
            $SelfService{ServiceTextStaus} = 'display:show';
        }
        else {

            $SelfService{PlusStaus}  = 'display:show';
            $SelfService{MinusStaus} = 'display:none';
            $SelfService{ServiceTextStaus} = 'display:none';
        }

        $LayoutObject->Block(
            Name => 'SelfServiceHeadMore',
            Data => { %Param, %SelfService, },
        );

    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'SelfService',
        Data         => \%Param,
    );
}

1;
