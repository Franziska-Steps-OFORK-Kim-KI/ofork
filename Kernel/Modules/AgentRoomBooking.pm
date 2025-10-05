# --
# Kernel/Modules/AgentRoomBooking.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AgentRoomBooking.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentRoomBooking;

use strict;
use warnings;

use MIME::Base64;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    for my $NeededData (qw( UserID Subaction AccessRo SessionID ))
    {
        if ( !$Param{$NeededData} ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Parameter %s is missing.', $NeededData ),
            );
        }
        $Self->{$NeededData} = $Param{$NeededData};
    }

    # AccessRw controls the adding/editing of statistics.
    for my $Param (qw( AccessRw RequestedURL )) {
        if ( $Param{$Param} ) {
            $Self->{$Param} = $Param{$Param};
        }
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    my $SortBy         = $ParamObject->GetParam( Param => 'SortBy' )  || 'FromSystemTime';
    my $OrderByCurrent = $ParamObject->GetParam( Param => 'OrderBy' ) || 'Down';
    my $CustomerUserID = $ParamObject->GetParam( Param => 'CustomerUserID' ) || '';

    $Param{CustomerUserID} = $CustomerUserID;

    # get data
    my %CustomerList = $CustomerUserObject->CustomerSearch(
        Search => '*',
        Valid  => 1,
        Limit  => 1000,
    );
    $CustomerList{all} = $LayoutObject->{LanguageObject}->Translate( 'All');

    $Param{CustomerStrg} = $LayoutObject->BuildSelection(
        Data         => \%CustomerList,
        Name         => 'CustomerUserID',
        PossibleNone => 1,
        Sort         => 'AlphanumericKey',
        Translation  => 0,
        Class        => "Modernize",
    );

    my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
        SystemTime => $TimeObject->SystemTime(),
    );
    my $StartMonthGet = "$StartYear-$StartMonth-$StartDay 00:00:00";

    # filter definition
    my %Filters = (
        AllRooms => {
            All => {
                Name   => 'All',
                Prio   => 1000,
                Search => {
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    CustomerUserID => $CustomerUserID,
                },
            },
            Open => {
                Name   => 'Open',
                Prio   => 1100,
                Search => {
                    Type           => 'Open',
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    StartMonth     => $StartMonthGet,
                    CustomerUserID => $CustomerUserID,
                },
            },
            Closed => {
                Name   => 'Closed',
                Prio   => 1200,
                Search => {
                    Type           => 'Closed',
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    StartMonth     => $StartMonthGet,
                    CustomerUserID => $CustomerUserID,
                },
            },

        },
    );

    my $FilterCurrent = $ParamObject->GetParam( Param => 'Filter' ) || 'Open';

    # check if filter is valid
    if ( !$Filters{ $Self->{Subaction} }->{$FilterCurrent} ) {
        my $Output = $LayoutObject->Header(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->Error(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Invalid Filter: %s!', $FilterCurrent ),
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    my %NavBarFilter;
    my $Counter       = 0;
    my $AllRooms      = 0;
    my $AllRoomsTotal = 0;
    my $RoomBookingObject = $Kernel::OM->Get('Kernel::System::RoomBooking');

    for my $Filter ( sort keys %{ $Filters{ $Self->{Subaction} } } ) {
        $Counter++;

        my $Count = $RoomBookingObject->RoomBookingSearchAgent(
            %{ $Filters{ $Self->{Subaction} }->{$Filter}->{Search} },
            Result => 'COUNT',
        ) || 0;

        my $ClassA = '';
        if ( $Filter eq $FilterCurrent ) {
            $ClassA   = 'Active';
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
            CustomerUserID => $CustomerUserID,
        };
    }

    my $StartHit = int( $ParamObject->GetParam( Param => 'StartHit' ) || 1 );
    my $PageShown = 15;

    if ( !$AllRoomsTotal ) {
        $LayoutObject->Block(
            Name => 'Empty',
        );

        $LayoutObject->Block(
            Name => 'EmptyDefault',
        );

    }
    else {

        # create & return output
        my $Link = 'SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
            . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderByCurrent )
            . ';Filter=' . $LayoutObject->Ascii2Html( Text => $FilterCurrent )
            . ';Subaction=' . $LayoutObject->Ascii2Html( Text => $Self->{Subaction} )
            . ';CustomerUserID=' . $LayoutObject->Ascii2Html( Text => $CustomerUserID )
            . ';';
        my %PageNav = $LayoutObject->PageNavBar(
            Limit     => 10000,
            StartHit  => $StartHit,
            PageShown => $PageShown,
            AllHits   => $AllRooms,
            CustomerUserID => $CustomerUserID,
            Action    => 'Action=AgentRoomBooking',
            Link      => $Link,
            IDPrefix  => 'AgentRoomBooking',
        );

        my $OrderBy = 'Down';
        if ( $OrderByCurrent eq 'Down' ) {
            $OrderBy = 'Up';
        }
        my $Sort               = '';
        my $SubjectSort        = '';
        my $RoomIDSort         = '';
        my $ParticipantSort    = '';
        my $FromSystemTimeSort = '';
        my $ToSystemTimeSort   = '';
        my $CustomerSort       = '';

        # this sets the opposite to the $OrderBy
        if ( $OrderBy eq 'Down' ) {
            $Sort = 'SortAscendingLarge';
        }
        if ( $OrderBy eq 'Up' ) {
            $Sort = 'SortDescendingLarge';
        }

        if ( $SortBy eq 'Subject' ) {
            $SubjectSort = $Sort;
        }
        elsif ( $SortBy eq 'RoomID' ) {
            $RoomIDSort = $Sort;
        }
        elsif ( $SortBy eq 'Participant' ) {
            $ParticipantSort = $Sort;
        }
        elsif ( $SortBy eq 'FromSystemTime' ) {
            $FromSystemTimeSort = $Sort;
        }
        elsif ( $SortBy eq 'ToSystemTime' ) {
            $ToSystemTimeSort = $Sort;
        }
        elsif ( $SortBy eq 'Customer' ) {
            $CustomerSort = $Sort;
        }

        $LayoutObject->Block(
            Name => 'Filled',
            Data => {
                %Param,
                %PageNav,
                OrderBy            => $OrderBy,
                SubjectSort        => $SubjectSort,
                RoomIDSort         => $RoomIDSort,
                ParticipantSort    => $ParticipantSort,
                FromSystemTimeSort => $FromSystemTimeSort,
                ToSystemTimeSort   => $ToSystemTimeSort,
                CustomerSort       => $CustomerSort,
                Filter             => $FilterCurrent,
                CustomerUserID => $CustomerUserID,
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

        my @ViewableRooms = $RoomBookingObject->RoomBookingSearchAgent(
            %{ $Filters{ $Self->{Subaction} }->{$FilterCurrent}->{Search} },
            Result => 'ARRAY',
        );

        # show tickets
        $Counter = 0;
        for my $RoomBookingID (@ViewableRooms) {

            $Counter++;
            if (
                $Counter >= $StartHit
                && $Counter < ( $PageShown + $StartHit )
                )
            {
                $Self->ShowRoomStatus( RoomBookingID => $RoomBookingID );
            }
        }
    }

    # create & return output
    my $Title = $Self->{Subaction};

    my $Output = $LayoutObject->Header(
        Title   => $Title,
    );

    # build NavigationBar
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentRoomBooking',
        Data         => \%Param,
    );

    # get page footer
    $Output .= $LayoutObject->Footer();

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
    my $RoomBookingObject        = $Kernel::OM->Get('Kernel::System::RoomBooking');
    my $TimeObject               = $Kernel::OM->Get('Kernel::System::Time');
    my $CustomerUserObject       = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $CustomerCompanyObject    = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    my $RoomBookingID            = $Param{RoomBookingID} || return;
    
    my %RoomBooking = $RoomBookingObject->RoomBookingGet(
        RoomBookingID => $RoomBookingID,
    );

    my %Room = $BookingSystemRoomsObject->RoomGet(
        RoomID => $RoomBooking{RoomID},
    );

    $RoomBooking{FromSystemTimeCal} = $RoomBooking{FromSystemTime};
    my ($year, $mon, $day, $hour, $min, $sec) = split(/[-: ]/, $RoomBooking{FromSystemTime});
    $RoomBooking{FromSystemTime} = $day . '.' . $mon . '.' . $year . ' ' . $hour . ':' . $min;

    $RoomBooking{ToSystemTimeCal} = $RoomBooking{ToSystemTime};
    my ($Toyear, $Tomon, $Today, $Tohour, $Tomin, $Tosec) = split(/[-: ]/, $RoomBooking{ToSystemTime});
    $RoomBooking{ToSystemTime} = $Today . '.' . $Tomon . '.' . $Toyear . ' ' . $Tohour . ':' . $Tomin;

    if ( $Room{RoomCategoriesID} ) {

        my %RoomCategoriesData = $RoomCategoriesObject->RoomCategoriesGet(
            RoomCategoriesID => $Room{RoomCategoriesID},
            UserID           => 1,
        );
        $Room{CategoryName} = $RoomCategoriesData{Name};
        $Room{Category} = $Room{RoomCategoriesID};
    }


    my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
        User => $RoomBooking{CreateBy},
    );
    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $CustomerUser{UserCustomerID},
    );
    $RoomBooking{Customer} = $CustomerUser{UserFirstname} . ' ' . $CustomerUser{UserLastname} . ' - ' . $CustomerCompany{CustomerCompanyName};

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
            %RoomBooking,
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
                Data => { %Param, %Room, %RoomBooking, Image => $Room{Image}, },
            );
        }
        else {

            $LayoutObject->Block(
                Name => 'NoRoomIcon',
                Data => { %Param, %Room, %RoomBooking, },
            );
        }
    }
    else {

        $LayoutObject->Block(
            Name => 'NoRoomIcon',
            Data => { %Param, %Room, %RoomBooking, },
        );
    }

    my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
        SystemTime => $TimeObject->SystemTime(),
    );
    my $StartMonthGet = "$StartYear-$StartMonth-01 00:00:00";

    $Room{CalendarEvents} .= "{ id: '" . $RoomBookingID . "', resourceId: '" . $RoomBooking{RoomID} . "', start: '" . $RoomBooking{FromSystemTimeCal} . "', end: '" . $RoomBooking{ToSystemTimeCal} . "', title: '" . $RoomBooking{Subject} . "' },";

    my %RoomCal = $BookingSystemRoomsObject->RoomGet(
        RoomID => $RoomBooking{RoomID},
    );

    if ( $RoomCal{RoomColor} ) {
        $Room{CalendarResources} .= "{ id: '" . $RoomBooking{RoomID} . "', title: '" . $RoomCal{Room} . "', eventColor: '$RoomCal{RoomColor}' },";
    }
    else {
        $Room{CalendarResources} .= "{ id: '" . $RoomBooking{RoomID} . "', title: '" . $RoomCal{Room} . "', eventColor: '#02a543' },";
    }

    $LayoutObject->Block(
        Name => 'CalendarResources',
        Data => { %Param, %Room, },
    );

    $LayoutObject->Block(
        Name => 'CalendarEvents',
        Data => { %Param, %Room, },
    );

    return;
}

1;
