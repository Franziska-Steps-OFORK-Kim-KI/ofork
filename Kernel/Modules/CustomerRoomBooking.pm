# --
# Kernel/Modules/CustomerRoomBooking.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: CustomerRoomBooking.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::CustomerRoomBooking;

use strict;
use warnings;

use MIME::Base64;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

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
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    # check needed CustomerID
    if ( !$Self->{UserCustomerID} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => Translatable('Need CustomerID!'),
        );
        $Output .= $LayoutObject->CustomerFooter();
        return $Output;
    }

    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenOverview',
        Value     => $Self->{RequestedURL},
    );

    my $SortBy         = $ParamObject->GetParam( Param => 'SortBy' )  || 'City';
    my $OrderByCurrent = $ParamObject->GetParam( Param => 'OrderBy' ) || 'Down';

    # filter definition
    my %Filters = (
        MyRooms => {
            All => {
                Name   => 'All',
                Prio   => 1000,
                Search => {
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    CustomerUserID => $Self->{UserID},
                },
            },
        },
    );

    my $UserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    my $FilterCurrent = $ParamObject->GetParam( Param => 'Filter' ) || 'All';

    # check if filter is valid
    if ( !$Filters{ $Self->{Subaction} }->{$FilterCurrent} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Invalid Filter: %s!', $FilterCurrent ),
        );
        $Output .= $LayoutObject->CustomerFooter();
        return $Output;
    }

    my %NavBarFilter;
    my $Counter       = 0;
    my $AllRooms      = 0;
    my $AllRoomsTotal = 0;
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');

    for my $Filter ( sort keys %{ $Filters{ $Self->{Subaction} } } ) {
        $Counter++;

        my $Count = $BookingSystemRoomsObject->RoomSearch(
            %{ $Filters{ $Self->{Subaction} }->{$Filter}->{Search} },
            Result => 'COUNT',
        ) || 0;

        my $ClassA = '';
        if ( $Filter eq $FilterCurrent ) {
            $ClassA     = 'Selected';
            $AllRooms = $Count;
        }
        if ( $Filter eq 'All' ) {
            $AllRoomsTotal = $Count;
        }
        $NavBarFilter{ $Filters{ $Self->{Subaction} }->{$Filter}->{Prio} } = {
            %{ $Filters{ $Self->{Subaction} }->{$Filter} },
            Count  => $Count,
            Filter => $Filter,
            ClassA => $ClassA,
        };
    }

    my $StartHit = int( $ParamObject->GetParam( Param => 'StartHit' ) || 1 );
    my $PageShown = $Self->{UserShowTickets} || 1;

    if ( !$AllRoomsTotal ) {
        $LayoutObject->Block(
            Name => 'Empty',
        );

        $LayoutObject->Block(
            Name => 'EmptyDefault',
        );

        # only show button, if frontend module for NewTicket is registered
        if (
            ref $ConfigObject->Get('CustomerFrontend::Module')->{CustomerTicketMessage}
            eq 'HASH'
            )
        {
            $LayoutObject->Block(
                Name => 'EmptyDefaultButton',
            );
        }
    }
    else {

        # create & return output
        my $Link = 'SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
            . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderByCurrent )
            . ';Filter=' . $LayoutObject->Ascii2Html( Text => $FilterCurrent )
            . ';Subaction=' . $LayoutObject->Ascii2Html( Text => $Self->{Subaction} )
            . ';';
        my %PageNav = $LayoutObject->PageNavBar(
            Limit     => 10000,
            StartHit  => $StartHit,
            PageShown => $PageShown,
            AllHits   => $AllRooms,
            Action    => 'Action=CustomerRoomBooking',
            Link      => $Link,
            IDPrefix  => 'CustomerRoomBooking',
        );

        my $OrderBy = 'Down';
        if ( $OrderByCurrent eq 'Down' ) {
            $OrderBy = 'Up';
        }
        my $Sort          = '';
        my $RoomSort      = '';
        my $CategorySort = '';
        my $CitySort      = '';
        my $PostCodeSort  = '';
        my $PersonsSort   = '';

        # this sets the opposite to the $OrderBy
        if ( $OrderBy eq 'Down' ) {
            $Sort = 'SortAscending';
        }
        if ( $OrderBy eq 'Up' ) {
            $Sort = 'SortDescending';
        }

        if ( $SortBy eq 'Room' ) {
            $RoomSort = $Sort;
        }
        elsif ( $SortBy eq 'Category' ) {
            $CategorySort = $Sort;
        }
        elsif ( $SortBy eq 'City' ) {
            $CitySort = $Sort;
        }
        elsif ( $SortBy eq 'PostCode' ) {
            $PostCodeSort = $Sort;
        }
        elsif ( $SortBy eq 'Persons' ) {
            $PersonsSort = $Sort;
        }
        $LayoutObject->Block(
            Name => 'Filled',
            Data => {
                %Param,
                %PageNav,
                OrderBy      => $OrderBy,
                RoomSort     => $RoomSort,
                CategorySort => $CategorySort,
                CitySort     => $CitySort,
                PostCodeSort => $PostCodeSort,
                PersonsSort  => $PersonsSort,
                Filter       => $FilterCurrent,
            },
        );

        # show header filter
        for my $Key ( sort keys %NavBarFilter ) {
            $LayoutObject->Block(
                Name => 'FilterHeader',
                Data => {
                    %Param,
                    %{ $NavBarFilter{$Key} },
                },
            );
        }

        # show footer filter - show only if more the one page is available
        if ( $AllRooms > $PageShown ) {
            $LayoutObject->Block(
                Name => 'FilterFooter',
                Data => {
                    %Param,
                    %PageNav,
                },
            );
        }
        for my $Key ( sort keys %NavBarFilter ) {
            if ( $AllRooms > $PageShown ) {
                $LayoutObject->Block(
                    Name => 'FilterFooterItem',
                    Data => {
                        %{ $NavBarFilter{$Key} },
                    },
                );
            }
        }

        my @ViewableRooms = $BookingSystemRoomsObject->RoomSearch(
            %{ $Filters{ $Self->{Subaction} }->{$FilterCurrent}->{Search} },
            Result => 'ARRAY',
        );

        # show tickets
        $Counter = 0;
        for my $RoomID (@ViewableRooms) {
            $Counter++;
            if (
                $Counter >= $StartHit
                && $Counter < ( $PageShown + $StartHit )
                )
            {
                $Self->ShowRoomStatus( RoomID => $RoomID );
            }
        }
    }

    # create & return output
    my $Title = $Self->{Subaction};

    my $Output = $LayoutObject->CustomerHeader(
        Title   => $Title,
    );

    # build NavigationBar
    $Output .= $LayoutObject->CustomerNavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'CustomerRoomBooking',
        Data         => \%Param,
    );

    # get page footer
    $Output .= $LayoutObject->CustomerFooter();

    # return page
    return $Output;
}

# ShowRooms
sub ShowRoomStatus {
    my ( $Self, %Param ) = @_;

    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');
    my $RoomIconObject           = $Kernel::OM->Get('Kernel::System::RoomIcon');
    my $RoomCategoriesObject     = $Kernel::OM->Get('Kernel::System::RoomCategories');
    my $RoomEquipmentObject      = $Kernel::OM->Get('Kernel::System::RoomEquipment');
    my $RoomID                   = $Param{RoomID} || return;

    my %Room = $BookingSystemRoomsObject->RoomGet(
        RoomID => $RoomID,
    );

    if ( $Room{RoomCategoriesID} ) {

        my %RoomCategoriesData = $RoomCategoriesObject->RoomCategoriesGet(
            RoomCategoriesID => $Room{RoomCategoriesID},
            UserID           => 1,
        );
        $Room{CategoryName} = $RoomCategoriesData{Name};
        $Room{Category} = $Room{RoomCategoriesID};
    }

    if ( $Room{Equipment} ) {

        my @Equipments = split( /,/, $Room{Equipment} );
        for my $EquipmentID ( @Equipments ) {

            my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
                ID => $EquipmentID,
            );
            $Room{EquipmentInventary} .= '<i class="fa fa-circle" style="color:#80d2a1;margin-right: 5px;margin-bottom: 3px;font-size: 12px;"></i>' . $EquipmentData{Name} . '<br>';
        }
    }
    else {
        $Room{EquipmentInventary} = '-';
    }

    # add block
    $LayoutObject->Block(
        Name => 'Record',
        Data => {
            %Room,
            %Param,
        },
    );

    if ( $Room{ImageID} ) {

        my %ImageData = $RoomIconObject->RoomIconGet(
            ID => $Room{ImageID},
        );
        $Room{Image} = encode_base64($ImageData{Content});

        if ( $Room{Image} && $Room{Image} ne '' ) {
            $LayoutObject->Block(
                Name => 'RoomIcon',
                Data => { %Param, %Room, Image => $Room{Image}, },
            );
        }
        else {

            $LayoutObject->Block(
                Name => 'NoRoomIcon',
                Data => { %Param, %Room, },
            );
        }
    }
    else {

        $LayoutObject->Block(
            Name => 'NoRoomIcon',
            Data => { %Param, %Room, },
        );
    }

    return;
}

1;
