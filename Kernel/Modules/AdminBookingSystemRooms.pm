# --
# Kernel/Modules/AdminBookingSystemRooms.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminBookingSystemRooms.pm,v 1.37 2016/09/20 12:33:43 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminBookingSystemRooms;

use strict;
use warnings;

use MIME::Base64;

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

    my %Error = ();

    my $ParamObject              = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject              = $Kernel::OM->Get('Kernel::System::Valid');
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');
    my $RoomCategoriesObject     = $Kernel::OM->Get('Kernel::System::RoomCategories');


    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'RoomEdit' ) {

        # get params
        my %GetParam;

        my @EquipmentBookables = $ParamObject->GetArray( Param => 'EquipmentBookable' );
        $GetParam{EquipmentBookable} = '';
        for my $EquipmentBookables (@EquipmentBookables) {
            $GetParam{EquipmentBookable} .= "$EquipmentBookables,";
        }

        my @Equipments = $ParamObject->GetArray( Param => 'Equipment' );
        $GetParam{Equipment} = '';
        for my $Equipments (@Equipments) {
            $GetParam{Equipment} .= "$Equipments,";
        }

        for my $Param (
            qw(RoomID RoomCategoriesID Room Building Floor Street PostCode City Calendar RoomColor SetupTime Persons Price PriceFor Currency Description QueueBooking QueueDevice QueueCatering ValidID Comment ImageID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            RoomID           => $GetParam{RoomID},
            RoomCategoriesID => $GetParam{RoomCategoriesID},
            %Param,
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    #  save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'RoomSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;

        my @EquipmentBookables = $ParamObject->GetArray( Param => 'EquipmentBookable' );
        $GetParam{EquipmentBookable} = '';
        for my $EquipmentBookables (@EquipmentBookables) {
            $GetParam{EquipmentBookable} .= "$EquipmentBookables,";
        }

        my @Equipments = $ParamObject->GetArray( Param => 'Equipment' );
        $GetParam{Equipment} = '';
        for my $Equipments (@Equipments) {
            $GetParam{Equipment} .= "$Equipments,";
        }

        for my $Param (

            qw(RoomID RoomCategoriesID Room Building Floor Street PostCode City Calendar RoomColor SetupTime Persons Price PriceFor Currency Description QueueBooking QueueDevice QueueCatering ValidID Comment ImageID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed stuff
        %Error = ();
        if ( !$GetParam{Room} ) {
            $Error{'RoomInvalid'} = 'ServerError';
        }

        if ( !$GetParam{RoomCategoriesID} ) {
            $Error{'RoomCategoriesIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Error ) {

            if ( !$GetParam{ImageID} ) {
                $GetParam{ImageID} = 0;
            }

            if ( !$GetParam{PriceFor} ) {
                $GetParam{PriceFor} = 0;
            }

            if ( !$GetParam{EquipmentBookable} ) {
                $GetParam{EquipmentBookable} = 0;
            }

            if ( !$GetParam{Equipment} ) {
                $GetParam{Equipment} = 0;
            }

            if ( !$GetParam{QueueBooking} ) {
                $GetParam{QueueBooking} = 0;
            }

            if ( !$GetParam{QueueDevice} ) {
                $GetParam{QueueDevice} = 0;
            }

            if ( !$GetParam{QueueCatering} ) {
                $GetParam{QueueCatering} = 0;
            }

            my %RoomCategoriesData = $RoomCategoriesObject->RoomCategoriesGet(
                RoomCategoriesID => $GetParam{RoomCategoriesID},
                UserID           => 1,
            );

            if ( $GetParam{RoomID} ) {

                my $RequestID = $BookingSystemRoomsObject->RoomUpdate(
                    RoomID            => $GetParam{RoomID},
                    RoomCategoriesID  => $GetParam{RoomCategoriesID},
                    RoomCategories    => $RoomCategoriesData{Name},
                    Room              => $GetParam{Room},
                    Building          => $GetParam{Building},
                    Floor             => $GetParam{Floor},
                    Street            => $GetParam{Street},
                    PostCode          => $GetParam{PostCode},
                    City              => $GetParam{City},
                    Calendar          => $GetParam{Calendar},
                    RoomColor         => $GetParam{RoomColor},
                    SetupTime         => $GetParam{SetupTime},
                    Persons           => $GetParam{Persons},
                    Price             => $GetParam{Price},
                    PriceFor          => $GetParam{PriceFor},
                    Currency          => $GetParam{Currency},
                    EquipmentBookable => $GetParam{EquipmentBookable},
                    Equipment         => $GetParam{Equipment},
                    Description       => $GetParam{Description},
                    QueueBooking      => $GetParam{QueueBooking},
                    QueueDevice       => $GetParam{QueueDevice},
                    QueueCatering     => $GetParam{QueueCatering},
                    ValidID           => $GetParam{ValidID},
                    Comment           => $GetParam{Comment},
                    ImageID           => $GetParam{ImageID},
                    UserID            => $Self->{UserID},
                );
            }
            else {

                my $RoomID = $BookingSystemRoomsObject->RoomAdd(
                    RoomCategoriesID  => $GetParam{RoomCategoriesID},
                    RoomCategories    => $RoomCategoriesData{Name},
                    Room              => $GetParam{Room},
                    Building          => $GetParam{Building},
                    Floor             => $GetParam{Floor},
                    Street            => $GetParam{Street},
                    PostCode          => $GetParam{PostCode},
                    City              => $GetParam{City},
                    Calendar          => $GetParam{Calendar},
                    RoomColor         => $GetParam{RoomColor},
                    SetupTime         => $GetParam{SetupTime},
                    Persons           => $GetParam{Persons},
                    Price             => $GetParam{Price},
                    PriceFor          => $GetParam{PriceFor},
                    Currency          => $GetParam{Currency},
                    EquipmentBookable => $GetParam{EquipmentBookable},
                    Equipment         => $GetParam{Equipment},
                    Description       => $GetParam{Description},
                    QueueBooking      => $GetParam{QueueBooking},
                    QueueDevice       => $GetParam{QueueDevice},
                    QueueCatering     => $GetParam{QueueCatering},
                    ValidID           => $GetParam{ValidID},
                    Comment           => $GetParam{Comment},
                    ImageID           => $GetParam{ImageID},
                    UserID            => $Self->{UserID},
                );
                $GetParam{RoomID} = $RoomID;
            }
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .=
            $Error{Message}
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Error{Message},
            )
            : '';

        # html output
        $Output .= $Self->_MaskNew(
            RoomID  => $GetParam{RoomID},
            IDError => $GetParam{IDError},
            %Param,
            %GetParam,
            %Error,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => { %Param, },
        );

        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionAdd' );

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewList',
            Data => { %Param, },
        );

        # get  list
        my %RoomList = $BookingSystemRoomsObject->RoomList(
            Valid  => 0,
            UserID => $Self->{UserID},
        );

        # get valid list
        my %ValidList = $ValidObject->ValidList();

        if (%RoomList) {
            for my $RoomID ( sort { lc $RoomList{$a} cmp lc $RoomList{$b} } keys %RoomList ) {

                # get the sla data
                my %RoomData = $BookingSystemRoomsObject->RoomGet(
                    RoomID => $RoomID,
                    UserID => $Self->{UserID},
                );

                # output overview list row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => { %RoomData, Valid => $ValidList{ $RoomData{ValidID} }, },
                );
            }
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminBookingSystemRooms',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskNew {

    my ( $Self, %Param ) = @_;

    my $ParamObject              = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject              = $Kernel::OM->Get('Kernel::System::Valid');
    my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
    my $UserObject               = $Kernel::OM->Get('Kernel::System::User');
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');
    my $RoomCategoriesObject     = $Kernel::OM->Get('Kernel::System::RoomCategories');
    my $RoomIconObject           = $Kernel::OM->Get('Kernel::System::RoomIcon');
    my $RoomEquipmentObject      = $Kernel::OM->Get('Kernel::System::RoomEquipment');
    my $QueueObject              = $Kernel::OM->Get('Kernel::System::Queue');

    # get params
    my %RoomData;
    $RoomData{RoomID} = $Param{RoomID} || '';
    $RoomData{IDError}  = $Param{IDError}  || '';

    if ( $RoomData{RoomID} ) {

        # get the sla data
        %RoomData = $BookingSystemRoomsObject->RoomGet(
            RoomID => $RoomData{RoomID},
            UserID   => $Self->{UserID},
        );
    }

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    my %PriceFor = ( '1' => '1 hour', '2' => '1 day' );
    $Param{PriceForStrg} = $LayoutObject->BuildSelection(
        Name         => 'PriceFor',
        Data         => \%PriceFor,
        SelectedID   => $RoomData{PriceFor},
        Class        => "Modernize",
        Translation  => 1,
        PossibleNone => 1,
    );

    my %QueueList = $QueueObject->QueueList( Valid => 1 );
    $RoomData{QueueBookingStrg} = $LayoutObject->BuildSelection(
        Data         => \%QueueList,
        PossibleNone => 1,
        Name         => 'QueueBooking',
        Class        => "Modernize",
        SelectedID   => $RoomData{QueueBooking},
    );
    $RoomData{QueueDeviceStrg} = $LayoutObject->BuildSelection(
        Data         => \%QueueList,
        PossibleNone => 1,
        Name         => 'QueueDevice',
        Class        => "Modernize",
        SelectedID   => $RoomData{QueueDevice},
    );
    $RoomData{QueueCateringStrg} = $LayoutObject->BuildSelection(
        Data         => \%QueueList,
        PossibleNone => 1,
        Name         => 'QueueCatering',
        Class        => "Modernize",
        SelectedID   => $RoomData{QueueCatering},
    );

    $RoomData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $RoomData{ValidID} || $ValidListReverse{valid},
    );

    my %Calendar = ( '' => '-' );
    my $Maximum = $ConfigObject->Get("MaximumCalendarNumber") || 50;
    for my $CalendarNumber ( '', 1 .. $Maximum ) {
        if ( $ConfigObject->Get("TimeVacationDays::Calendar$CalendarNumber") ) {
            $Calendar{$CalendarNumber} = "Calendar $CalendarNumber - "
                . $ConfigObject->Get( "TimeZone::Calendar" . $CalendarNumber . "Name" );
        }
    }
    $RoomData{CalendarStrg} = $LayoutObject->BuildSelection(
        Data        => \%Calendar,
        Translation => 0,
        Name        => 'Calendar',
        SelectedID  => $RoomData{Calendar},
        Class       => 'Modernize',
    );

    my %EquipmentBookable = $RoomEquipmentObject->EquipmentListForm(
        Bookable => 2,
        Valid    => 1,
    );

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%RoomData,
        );
    }

    my @EquipmentsBookable = split( /,/, $RoomData{EquipmentBookable} );
    $RoomData{EquipmentBookableStrg} = $LayoutObject->BuildSelection(
        Data         => \%EquipmentBookable,
        Name         => 'EquipmentBookable',
        Multiple     => 1,
        Size         => 10,
        Class        => "",
        PossibleNone => 0,
        SelectedID   => \@EquipmentsBookable,
    );

    my %Equipment = $RoomEquipmentObject->EquipmentListForm(
        Bookable => 1,
        Valid    => 1,
    );

    my @Equipments = split( /,/, $RoomData{Equipment} );
    $RoomData{EquipmentStrg} = $LayoutObject->BuildSelection(
        Data         => \%Equipment,
        Name         => 'Equipment',
        Multiple     => 1,
        Size         => 10,
        Class        => "",
        PossibleNone => 0,
        SelectedID   => \@Equipments,
    );

    # build RequestCategories dropdown
    my %RoomCategoriesList = $RoomCategoriesObject->RoomCategoriesList(
        Valid  => 1,
        UserID => $Self->{UserID},
    );

    $RoomData{RoomCategoriesStrg} = $LayoutObject->BuildSelection(
        Name         => 'RoomCategoriesID',
        Data         => \%RoomCategoriesList,
        SelectedID   => $RoomData{RoomCategoriesID},
        Class        => "Modernize",
        PossibleNone => 1,
    );

    # output edit
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, %RoomData, },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    $LayoutObject->Block(
        Name => 'RoomEdit',
        Data => { %Param, %RoomData, },
    );

    # shows header
    if ( $RoomData{RoomID} ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    my %List = $RoomIconObject->RoomIconList(
        UserID => 1,
        Valid  => 1,
    );

    # if there are any results, they are shown
    if (%List) {

        # get valid list
        for my $ID ( sort { $List{$a} cmp $List{$b} } keys %List ) {
            my %Data = $RoomIconObject->RoomIconGet(
                ID => $ID,
            );

            $Data{Content} = encode_base64($Data{Content});
            if ( $ID == $RoomData{ImageID} ) {
                $Data{CheckedImageID} = 'checked="checked"';
                $Data{ColorImageID} = 'green 2px solid';
            }
            else {
                $Data{ColorImageID} = '#c1e6f5 2px solid';
            }

            $LayoutObject->Block(
                Name => 'RoomIcons',
                Data => { %Param, %Data, },
            );
        }
    }

    # get output back
    return $LayoutObject->Output( TemplateFile => 'AdminBookingSystemRooms', Data => \%Param );
}

1;
