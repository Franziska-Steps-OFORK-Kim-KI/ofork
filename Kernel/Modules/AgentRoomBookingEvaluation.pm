# --
# Kernel/Modules/AgentRoomBookingEvaluation.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AgentRoomBookingEvaluation.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentRoomBookingEvaluation;

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

    # get form id
    $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'FormID' );

    # create form id
    if ( !$Self->{FormID} ) {
        $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCreate();
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject              = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TimeObject               = $Kernel::OM->Get('Kernel::System::Time');
    my $RoomBookingObject        = $Kernel::OM->Get('Kernel::System::RoomBooking');
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');
    my $CustomerUserObject       = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $CustomerCompanyObject    = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    my $RoomEquipmentObject      = $Kernel::OM->Get('Kernel::System::RoomEquipment');
    my $DateTimeObject           = $Kernel::OM->Create('Kernel::System::DateTime');

    # get params
    my %GetParam;

    for my $Key (
        qw(RoomID CustomerUserID FromDateDay FromDateMonth FromDateYear ToDateDay ToDateMonth ToDateYear ResultForm)
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }


    if ( !$Self->{Subaction} ) {

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        $Output .= $Self->_MaskEvaluationNew(
            %GetParam,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'NewStats' ) {

        my $Start = "$GetParam{FromDateYear}-$GetParam{FromDateMonth}-$GetParam{FromDateDay} 00:00:00";
        my $End = "$GetParam{ToDateYear}-$GetParam{ToDateMonth}-$GetParam{ToDateDay} 23:59:59";

        my $HeaderStart = "$GetParam{FromDateDay}.$GetParam{FromDateMonth}.$GetParam{FromDateYear}";
        my $HeaderEnd = "$GetParam{ToDateDay}.$GetParam{ToDateMonth}.$GetParam{ToDateYear}";

        my @RoomBookingSearch = $RoomBookingObject->RoomBookingAgentStats(
            CustomerUserID => $GetParam{CustomerUserID},
            RoomID         => $GetParam{RoomID},
            Start          => $Start,
            End            => $End,
        );

        my @Data;
        my $Customer            = '';
        my $CustomerOld         = '';
        my $WokingTimeClear     = 0;
        my $WorkingTime         = 0;
        my $WokingTimeClearName = '';
        my $PriceAll            = 0;
        my $CheckNum            = 0;
        my $PriceAllClear       = '';
        my $PriceFor            = '';
        my $EquipmentName       = '';
        my $EquipmentValue      = 0;
        my $EquipmentPrice      = 0;
        my $EquipmentPriceValue = 0;
        my $EquipmentPriceAll   = 0;
        my $EquipmentPriceFor   = '';
        my $EquipmentText       = '';

        for my $RoomBookingID ( @RoomBookingSearch ) {

            my %RoomBooking = $RoomBookingObject->RoomBookingGet(
                RoomBookingID => $RoomBookingID,
            );

            $CheckNum ++;
            $Customer = $RoomBooking{CreateBy};
            if ( $CheckNum == 1 ) {
                $CustomerOld = $RoomBooking{CreateBy};
            }

            my %Room = $BookingSystemRoomsObject->RoomGet(
                RoomID => $RoomBooking{RoomID},
            );

            my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                User => $RoomBooking{CreateBy},
            );
            my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
                CustomerID => $CustomerUser{UserCustomerID},
            );
            $RoomBooking{Customer} = $CustomerUser{UserFirstname} . ' ' . $CustomerUser{UserLastname} . ' - ' . $CustomerCompany{CustomerCompanyName};

            my ($Fromyear, $Frommon, $Fromday, $Fromhour, $Frommin, $Fromsec) = split(/[-: ]/, $RoomBooking{FromSystemTime});
            $RoomBooking{FromSystemTimeClear} = $Fromday . '.' . $Frommon . '.' . $Fromyear . ' ' . $Fromhour . ':' . $Frommin;

            my ($Toyear, $Tomon, $Today, $Tohour, $Tomin, $sec) = split(/[-: ]/, $RoomBooking{ToSystemTime});
            $RoomBooking{ToSystemTimeClear} = $Today . '.' . $Tomon . '.' . $Toyear . ' ' . $Tohour . ':' . $Tomin;

            if ( $Room{PriceFor} == 2 ) {
 
                my $StartTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $RoomBooking{FromSystemTime},
                    },
                );
                my $EndTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $RoomBooking{ToSystemTime},
                    },
                );
                my $Delta = $StartTimeObject->Delta(
                    DateTimeObject => $EndTimeObject,
                    ForWorkingTime => 1,
                    Calendar       => $Room{Calendar},
                );

                if ( $Delta->{Minutes} >= 1 ) {
                    $Delta->{Hours} = $Delta->{Hours} + 1;
                }
                if ( $Delta->{Hours} >= 1 ) {
                    $Delta->{Days} = $Delta->{Days} + 1;
                }
                $WokingTimeClear = $Delta->{Days};

                $Room{Price} =~ s/\,/\./g;                
                $PriceFor = "1 day - $Room{Price} $Room{Currency}";
                $Room{Price}         = $Room{Price} * $WokingTimeClear;
                $WokingTimeClearName = "$WokingTimeClear day";
 
                $RoomBooking{RoomPriceClear} = $Room{Price};
                $RoomBooking{RoomPriceClear} = sprintf ("%.2f", $RoomBooking{RoomPriceClear});
                $RoomBooking{RoomPriceClear} = "$RoomBooking{RoomPriceClear} $Room{Currency}";
             }
            else {

                my $StartTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $RoomBooking{FromSystemTime},
                    },
                );
                my $EndTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $RoomBooking{ToSystemTime},
                    },
                );
                my $Delta = $StartTimeObject->Delta(
                    DateTimeObject => $EndTimeObject,
                    ForWorkingTime => 1,
                    Calendar       => $Room{Calendar},
                );

                if ( $Delta->{Minutes} >= 1 ) {
                    $Delta->{Hours} = $Delta->{Hours} + 1;
                }
                if ( $Delta->{Days} >= 1 ) {
                    $Delta->{Hours} = $Delta->{Hours} + ($Delta->{Days} * 24);
                }
                $WokingTimeClear = $Delta->{Hours};

                $Room{Price} =~ s/\,/\./g;                
                $PriceFor = "1 hour - $Room{Price} $Room{Currency}";
                $Room{Price}         = $Room{Price} * $WokingTimeClear;
                $WokingTimeClearName = "$WokingTimeClear hour";

                $RoomBooking{RoomPriceClear} = $Room{Price};
                $RoomBooking{RoomPriceClear} = int(100 * $RoomBooking{RoomPriceClear} + 0.5) / 100;
                $RoomBooking{RoomPriceClear} = sprintf ("%.2f", $RoomBooking{RoomPriceClear});
                $RoomBooking{RoomPriceClear} = "$RoomBooking{RoomPriceClear} $Room{Currency}";

            }

            my @EquipmentOrderSplit = split(/\,/, $RoomBooking{EquipmentOrder});
            for my $EquipmentOrder ( @EquipmentOrderSplit ) {
                my @EquipmentSplit = split(/\-/, $EquipmentOrder);

                my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
                    ID => $EquipmentSplit[0],
                );
                $EquipmentName     = $EquipmentData{Name};
                $EquipmentValue    = $EquipmentSplit[1];
                $EquipmentPrice    = $EquipmentData{Price};
                $EquipmentPriceFor = $EquipmentData{PriceFor};


                if ( $EquipmentPriceFor == 1 ) {

                    my $StartTimeObject = $Kernel::OM->Create(
                        'Kernel::System::DateTime',
                        ObjectParams => {
                            String => $RoomBooking{FromSystemTime},
                        },
                    );
                    my $EndTimeObject = $Kernel::OM->Create(
                        'Kernel::System::DateTime',
                        ObjectParams => {
                            String => $RoomBooking{ToSystemTime},
                        },
                    );
                    my $Delta = $StartTimeObject->Delta(
                        DateTimeObject => $EndTimeObject,
                        ForWorkingTime => 1,
                        Calendar       => $Room{Calendar},
                    );

                    if ( $Delta->{Minutes} >= 1 ) {
                        $Delta->{Hours} = $Delta->{Hours} + 1;
                    }
                    if ( $Delta->{Days} >= 1 ) {
                        $Delta->{Hours} = $Delta->{Hours} + ($Delta->{Days} * 24);
                    }

                    $EquipmentData{Price} =~ s/\,/\./g;                
                    $EquipmentPriceValue = ($EquipmentData{Price} * $Delta->{Hours}) * $EquipmentValue;
                    $EquipmentPriceValue = int(100 * $EquipmentPriceValue + 0.5) / 100;
                    $EquipmentPriceValue = sprintf ("%.2f", $EquipmentPriceValue);

                    if ( $EquipmentValue >= 1 ) {
                        $EquipmentText .= "$EquipmentValue $EquipmentName - $EquipmentPriceValue $Room{Currency}\n";
                        $EquipmentPriceAll = $EquipmentPriceAll + $EquipmentPriceValue;
                    }

                }
                elsif ( $EquipmentPriceFor == 2 ) {

                    my $StartTimeObject = $Kernel::OM->Create(
                        'Kernel::System::DateTime',
                        ObjectParams => {
                            String => $RoomBooking{FromSystemTime},
                        },
                    );
                    my $EndTimeObject = $Kernel::OM->Create(
                        'Kernel::System::DateTime',
                        ObjectParams => {
                            String => $RoomBooking{ToSystemTime},
                        },
                    );
                    my $Delta = $StartTimeObject->Delta(
                        DateTimeObject => $EndTimeObject,
                        ForWorkingTime => 1,
                        Calendar       => $Room{Calendar},
                    );

                    if ( $Delta->{Minutes} >= 1 ) {
                        $Delta->{Hours} = $Delta->{Hours} + 1;
                    }
                    if ( $Delta->{Hours} >= 1 ) {
                        $Delta->{Days} = $Delta->{Days} + 1;
                    }

                    $EquipmentData{Price} =~ s/\,/\./g;                
                    $EquipmentPriceValue = ($EquipmentData{Price} * $Delta->{Days}) * $EquipmentValue;
                    $EquipmentPriceValue = int(100 * $EquipmentPriceValue + 0.5) / 100;
                    $EquipmentPriceValue = sprintf ("%.2f", $EquipmentPriceValue);

                    if ( $EquipmentValue >= 1 ) {
                        $EquipmentText .= "$EquipmentValue $EquipmentName - $EquipmentPriceValue $Room{Currency}\n";
                        $EquipmentPriceAll = $EquipmentPriceAll + $EquipmentPriceValue;
                    }
                }
                elsif ( $EquipmentPriceFor == 3 ) {

                    $EquipmentData{Price} =~ s/\,/\./g;                
                    $EquipmentPriceValue = $EquipmentData{Price} * $EquipmentValue;
                    $EquipmentPriceValue = int(100 * $EquipmentPriceValue + 0.5) / 100;
                    $EquipmentPriceValue = sprintf ("%.2f", $EquipmentPriceValue);

                    if ( $EquipmentValue >= 1 ) {
                        $EquipmentText .= "$EquipmentValue $EquipmentName - $EquipmentPriceValue $Room{Currency}\n";
                        $EquipmentPriceAll = $EquipmentPriceAll + $EquipmentPriceValue;
                    }
                }
            }

            $PriceAll = $PriceAll + $EquipmentPriceAll;

            if ( $CustomerOld eq "$RoomBooking{CreateBy}" ) {

                $PriceAll = $PriceAll + $Room{Price};
                $PriceAll = sprintf ("%.2f", $PriceAll);
            }
            else {

                $CustomerOld = $Customer;
                $PriceAll    = 0;
                $PriceAll    = $Room{Price};
                $PriceAll    = sprintf ("%.2f", $PriceAll);
            }

            $PriceAll =~ s/\./\,/g;                
            $PriceAllClear = "$PriceAll $Room{Currency}";
            $RoomBooking{RoomPriceClear} =~ s/\./\,/g;                
            $PriceFor =~ s/\./\,/g;                
            $PriceAllClear =~ s/\./\,/g;                
            $EquipmentText =~ s/\./\,/g;                

            # build table row
            push @Data, [
                $RoomBooking{Customer},
                $Room{Room},
                $RoomBooking{FromSystemTimeClear},
                $RoomBooking{ToSystemTimeClear},
                $PriceFor,
                $WokingTimeClearName,
                $RoomBooking{RoomPriceClear},
                $EquipmentText,
                $PriceAllClear
            ];

            $WokingTimeClear             = 0;
            $WorkingTime                 = 0;
            $WokingTimeClearName         = '';
            $RoomBooking{RoomPriceClear} = 0;
            $EquipmentPriceValue         = 0;
            $EquipmentValue              = 0;
            $EquipmentText               = '';
            $EquipmentPriceAll           = 0;

        }

        # table headlines
        my @HeadData = (
            'Kunde',
            'Raum',
            'von',
            'bis',
            'Preis pro',
            'Dauer',
            'Raum Kosten',
            'Raum Ausstattung',
            'Kosten Kunde gesamt'
        );

        my $Title         = "Statistik Raumbuchungen vom $HeaderStart bis $HeaderEnd";
        my @StatArray     = ([$Title], [@HeadData], @Data);
        my $Stat->{Title} = $Title;
        my $OFORKTimeZone = $DateTimeObject->OFORKTimeZoneGet();

        return $Kernel::OM->Get('Kernel::Output::HTML::Statistics::View')->StatsResultRender(
            StatArray => \@StatArray,
            Stat      => $Stat,
            TimeZone  => 'Europe/Berlin',
            UserID    => 1,
            Format    => $GetParam{ResultForm},
            %GetParam
        );


        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        $Output .= $Self->_MaskEvaluationNew(
            %GetParam,
        );

        $Output .= $LayoutObject->Footer();
        return $Output;


    }

}

sub _MaskEvaluationNew {
    my ( $Self, %Param ) = @_;

    $Param{FormID} = $Self->{FormID};

    # get objects
    my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');
    my $CustomerUserObject       = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $TimeObject               = $Kernel::OM->Get('Kernel::System::Time');

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime'
    );

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    my %RoomList = $BookingSystemRoomsObject->RoomList(
        Valid  => 1,
        UserID => 1,
    );
    $RoomList{all} = 'All';

    $Param{RoomIDStrg} = $LayoutObject->BuildSelection(
        Class        => 'Validate_Required Modernize',
        Data         => \%RoomList,
        Name         => 'RoomID',
        SelectedID   => $Param{RoomID},
        PossibleNone => 1,
        Translation  => 1,
    );

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
        SelectedID   => $Param{CustomerUserID},
        Translation  => 0,
        Class        => "Modernize",
    );

    my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
        SystemTime => $TimeObject->SystemTime(),
    );
    my $LastDayOfMonth = $DateTimeObject->LastDayOfMonthGet();

    $Param{FromDateString} = $LayoutObject->BuildDateSelection(
        Prefix               => 'FromDate',
        FromDateYear         => $StartYear,
        FromDateMonth        => $StartMonth,
        FromDateDay          => 01,
        FromDateHour         => 00,
        FromDateMinute       => 01,
        Format               => 'DateInputFormat',
        YearPeriodPast       => 0,
        YearPeriodFuture     => 1,
        DiffTime             => 0,
        Class                => $Param{Errors}->{FromDateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 0,
    );

    $Param{ToDateString} = $LayoutObject->BuildDateSelection(
        Prefix               => 'ToDate',
        ToDateYear           => $StartYear,
        ToDateMonth          => $StartMonth,
        ToDateDay            => $LastDayOfMonth->{Day},
        ToDateHour           => 23,
        ToDateMinute         => 59,
        Format               => 'DateInputFormat',
        YearPeriodPast       => 0,
        YearPeriodFuture     => 1,
        DiffTime             => 3600,
        Class                => $Param{Errors}->{ToDateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 0,
    );

    $Param{ResultFormStrg} = $LayoutObject->BuildSelection(
        Data => {
            Print  => Translatable('Print'),
            CSV    => Translatable('CSV'),
            Excel  => Translatable('Excel'),
        },
        Name       => 'ResultForm',
        SelectedID => $Param{ResultForm} || 'CSV',
        Class      => 'Modernize',
    );

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentRoomBookingEvaluation',
        Data         => \%Param,
    );
}


1;
