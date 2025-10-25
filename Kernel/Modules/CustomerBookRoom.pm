# --
# Kernel/Modules/CustomerBookRoom.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: CustomerBookRoom.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::CustomerBookRoom;

use strict;
use warnings;

use MIME::Base64;
use Data::ICal;
use Data::ICal::Entry::Event;
use Data::ICal::Entry::Todo;
use Date::ICal;

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

    my $Config                   = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");
    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');
    my $RoomIconObject           = $Kernel::OM->Get('Kernel::System::RoomIcon');
    my $RoomCategoriesObject     = $Kernel::OM->Get('Kernel::System::RoomCategories');
    my $RoomEquipmentObject      = $Kernel::OM->Get('Kernel::System::RoomEquipment');
    my $TimeObject               = $Kernel::OM->Get('Kernel::System::Time');
    my $RoomBookingObject        = $Kernel::OM->Get('Kernel::System::RoomBooking');

    # get params
    my %GetParam;
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    for my $Key (qw( ChangeID RoomID Subject Body Participant EmailList FromDateYear FromDateMonth FromDateDay FromDateHour FromDateMinute ToDateYear ToDateMonth ToDateDay ToDateHour ToDateMinute )) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    $GetParam{Store} = 'StoreNew';

    if ( $GetParam{ChangeID} ) {

        my %RoomBooking = $RoomBookingObject->RoomBookingGet(
            RoomBookingID => $GetParam{ChangeID},
        );

        $GetParam{RoomID} = $RoomBooking{RoomID};
        $GetParam{Store} = 'StoreChange';
    }

    my %Room = $BookingSystemRoomsObject->RoomGet(
        RoomID => $GetParam{RoomID},
    );

    my @Equipments = split( /,/, $Room{EquipmentBookable} );
    if ( @Equipments ) {
        for my $EquipmentID ( @Equipments ) {
    
            if ( $EquipmentID ) {
                my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
                    ID => $EquipmentID,
                );
                my $GetKey = 'BookableValue_' . $EquipmentData{ID};
                $GetParam{$GetKey} = $ParamObject->GetParam( Param => $GetKey );
            }
        }
    }

    if ( !$Self->{Subaction} ) {

        # print form ...
        my $Output = $LayoutObject->CustomerHeader();
        $Output .= $LayoutObject->CustomerNavigationBar();
        $Output .= $Self->_MaskNew(
            %GetParam,
        );
        $Output .= $LayoutObject->CustomerFooter();
        return $Output;
    }

    elsif ( $Self->{Subaction} eq 'Change' ) {

        my %RoomBooking = $RoomBookingObject->RoomBookingGet(
            RoomBookingID => $GetParam{ChangeID},
        );

        my @EquipmentOrderSplit = split(/\,/, $RoomBooking{EquipmentOrder});
        for my $EquipmentOrder ( @EquipmentOrderSplit ) {
             my @EquipmentSplit = split(/\-/, $EquipmentOrder);
             my $GetKey = 'BookableValue_' . $EquipmentSplit[0];
             $GetParam{$GetKey} = $EquipmentSplit[1];
        }

        my ($Fromyear, $Frommon, $Fromday, $Fromhour, $Frommin, $Fromsec) = split(/[-: ]/, $RoomBooking{FromSystemTime});
        my ($Toyear, $Tomon, $Today, $Tohour, $Tomin, $Tosec) = split(/[-: ]/, $RoomBooking{ToSystemTime});

        $GetParam{Subject}        = $RoomBooking{Subject};
        $GetParam{Body}           = $RoomBooking{Body};
        $GetParam{Participant}    = $RoomBooking{Participant};
        $GetParam{EmailList}      = $RoomBooking{EmailList};
        $GetParam{FromDateYear}   = $Fromyear;
        $GetParam{FromDateMonth}  = $Frommon;
        $GetParam{FromDateDay}    = $Fromday;
        $GetParam{FromDateHour}   = $Fromhour;
        $GetParam{FromDateMinute} = $Frommin;
        $GetParam{ToDateYear}     = $Toyear;
        $GetParam{ToDateMonth}    = $Tomon;
        $GetParam{ToDateDay}      = $Today;
        $GetParam{ToDateHour}     = $Tohour;
        $GetParam{ToDateMinute}   = $Tomin;
        $GetParam{Anker}          = 'RoomBooking';
        $GetParam{ChangeTheBook}  = 1;

        # print form ...
        my $Output = $LayoutObject->CustomerHeader();
        $Output .= $LayoutObject->CustomerNavigationBar();
        $Output .= $Self->_MaskNew(
            %GetParam,
        );
        $Output .= $LayoutObject->CustomerFooter();
        return $Output;

    }

    elsif ( $Self->{Subaction} eq 'Cancel' ) {

        my %RoomBooking = $RoomBookingObject->RoomBookingGet(
            RoomBookingID => $GetParam{ChangeID},
        );

        my $ChangeSequence = $RoomBooking{Sequence} + 1;

        my $Success = $RoomBookingObject->RoomBookingDelete(
            RoomBookingID   => $GetParam{ChangeID},
            UserID          => $Self->{UserID},
        );

        my $ICalLocation = "$Room{Street}, $Room{PostCode} $Room{City}, $Room{Building}, $Room{Floor}, $Room{Room}";
        my $ICalPlainBody = $LayoutObject->RichText2Ascii( String => $RoomBooking{Body} );

        my ($ActSec, $ActMin, $ActHour, $ActDay, $ActMonth, $ActYear, $ActWeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $TimeObject->SystemTime(),
        );

        my ($FromDateYear, $FromDateMonth, $FromDateDay, $FromDateHour, $FromDateMinute, $FromDateSec) = split(/[-: ]/, $RoomBooking{FromSystemTime});
        my ($ToDateYear, $ToDateMonth, $ToDateDay, $ToDateHour, $ToDateMinute, $ToDateSec) = split(/[-: ]/, $RoomBooking{ToSystemTime});


        my $calendar = Data::ICal->new();

        $calendar->add_properties(
            method => 'CANCEL',
        );

        my $vtodo = Data::ICal::Entry::Event->new();
        $vtodo->add_properties(
          class       => 'PUBLIC',
          uid         => $RoomBooking{CalUID},
          dtstamp     => Date::ICal->new(
              day   => $ActDay, 
              month => $ActMonth, 
              year  => $ActYear,
              hour  => $ActHour,
              min   => $ActMin,
              sec   => 00
          )->ical,
          summary     => $RoomBooking{Subject},
          location    => $ICalLocation,
          priority    => 5,
          sequence    => $ChangeSequence,
          transp      => 'OPAQUE',
          organizer   => "mailto:$Self->{UserEmail}", 
          dtstart     => Date::ICal->new (
              day   => $FromDateDay, 
              month => $FromDateMonth, 
              year  => $FromDateYear,
              hour  => $FromDateHour,
              min   => $FromDateMinute,
              sec   => 00
          )->ical,
          dtend      => Date::ICal->new(
              day   => $ToDateDay, 
              month => $ToDateMonth, 
              year  => $ToDateYear,
              hour  => $ToDateHour,
              min   => $ToDateMinute,
              sec   => 00
          )->ical,
          description => $ICalPlainBody,
        );

        if ( $RoomBooking{EmailList} ) {

            my $ICalEmailList = $RoomBooking{EmailList};
            $ICalEmailList =~ s/ //g;
            my @Participants = split(/\;/, $ICalEmailList);
            for my $ICalParticipant ( @Participants ) {
    
                $vtodo->add_properties(
                    attendee => [ "mailto:$ICalParticipant",
                        { 'ROLE'     => 'REQ-PARTICIPANT',
                          'PARTSTAT' => 'NEEDS-ACTION',
                          'RSVP'     => 'TRUE',
                          'CN'       => $ICalParticipant
                        },
                    ],
                );
            }
        }

        $calendar->add_entry($vtodo);
        my $SendIcal = $calendar->as_string;
        $SendIcal =~ s/\r//g;

        my $EmailObject = $Kernel::OM->Get('Kernel::System::Email');
        $EmailObject->Send(
            From       => $Self->{UserEmail},
            To         => "$Self->{UserEmail}; $RoomBooking{EmailList}",
            Subject    => $RoomBooking{Subject},
            MimeType   => 'text/plain',
            Charset    => $LayoutObject->{UserCharset},
            Body       => $ICalPlainBody,
            Loop       => 1,
            Attachment => [
                {
                    Filename    => "invite.ics",
                    Content     => $SendIcal,
                    ContentType => "text/calendar",
                }
            ],
        );

        my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
        my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );
        my $QueueObject          = $Kernel::OM->Get('Kernel::System::Queue');

        if ( $Room{QueueBooking} ) {

            my $ChangeRoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Cancel room booking");
            my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

            my $QueueBookingBody = "<b>$ChangeRoomBookingHeader:</b><br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $RoomBooking{Participant}<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $FromDateDay.$FromDateMonth.$FromDateYear $FromDateHour:$FromDateMinute<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $ToDateDay.$ToDateMonth.$ToDateYear $ToDateHour:$ToDateMinute<br>";

            $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
            $QueueBookingBody = $QueueBookingBody . $RoomBooking{Body};

            my $MimeType = 'text/plain';
            if ( $LayoutObject->{BrowserRichText} ) {
                $MimeType = 'text/html';

                # verify html document
                $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                    String => $QueueBookingBody,
                );
            }

            my $PlainBody = $QueueBookingBody;

            if ( $LayoutObject->{BrowserRichText} ) {
                $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
            }

            # create article
            my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                UserLogin => $Self->{UserLogin},
            );
            my $From = "\"$FullName\" <$Self->{UserEmail}>";

            my $ArticleID = $ArticleBackendObject->ArticleCreate(
                TicketID             => $RoomBooking{QueueBookingTicketID},
                IsVisibleForCustomer => 1,
                SenderType           => 'customer',
                From                 => $From,
                To                   => 'System',
                Subject              => $RoomBooking{Subject},
                Body                 => $QueueBookingBody,
                MimeType             => $MimeType,
                Charset              => $LayoutObject->{UserCharset},
                UserID               => 1,
                HistoryType          => 'FollowUp',
                HistoryComment       => 'Cancel room booking',
                AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                ? 'auto reply'
                : '',
                OrigHeader => {
                    From    => $From,
                    To      => $Self->{UserLogin},
                    Subject => $RoomBooking{Subject},
                    Body    => $PlainBody,
                },
                Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueBooking} ),
            );

            if ( !$ArticleID ) {
                my $Output = $LayoutObject->CustomerHeader(
                    Title => Translatable('Error'),
                );
                $Output .= $LayoutObject->CustomerError();
                $Output .= $LayoutObject->CustomerFooter();
                return $Output;
            }
        }

        if ( $Room{QueueDevice} ) {

            my $ChangeRoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Cancel room booking");
            my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

            my $QueueBookingBody = "<b>$ChangeRoomBookingHeader:</b><br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $RoomBooking{Participant}<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $FromDateDay.$FromDateMonth.$FromDateYear $FromDateHour:$FromDateMinute<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $ToDateDay.$ToDateMonth.$ToDateYear $ToDateHour:$ToDateMinute<br>";

            $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
            $QueueBookingBody = $QueueBookingBody . $RoomBooking{Body};

            my $MimeType = 'text/plain';
            if ( $LayoutObject->{BrowserRichText} ) {
                $MimeType = 'text/html';

                # verify html document
                $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                    String => $QueueBookingBody,
                );
            }

            my $PlainBody = $QueueBookingBody;

            if ( $LayoutObject->{BrowserRichText} ) {
                $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
            }

            # create article
            my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                UserLogin => $Self->{UserLogin},
            );
            my $From = "\"$FullName\" <$Self->{UserEmail}>";

            my $ArticleID = $ArticleBackendObject->ArticleCreate(
                TicketID             => $RoomBooking{QueueDeviceTicketID},
                IsVisibleForCustomer => 1,
                SenderType           => 'customer',
                From                 => $From,
                To                   => 'System',
                Subject              => $RoomBooking{Subject},
                Body                 => $QueueBookingBody,
                MimeType             => $MimeType,
                Charset              => $LayoutObject->{UserCharset},
                UserID               => 1,
                HistoryType          => 'FollowUp',
                HistoryComment       => 'Cancel room booking',
                AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                ? 'auto reply'
                : '',
                OrigHeader => {
                    From    => $From,
                    To      => $Self->{UserLogin},
                    Subject => $RoomBooking{Subject},
                    Body    => $PlainBody,
                },
                Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueBooking} ),
            );

            if ( !$ArticleID ) {
                my $Output = $LayoutObject->CustomerHeader(
                    Title => Translatable('Error'),
                );
                $Output .= $LayoutObject->CustomerError();
                $Output .= $LayoutObject->CustomerFooter();
                return $Output;
            }
        }

        if ( $Room{QueueCatering} ) {

            my $ChangeRoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Cancel room booking");
            my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

            my $QueueBookingBody = "<b>$ChangeRoomBookingHeader:</b><br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $RoomBooking{Participant}<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $FromDateDay.$FromDateMonth.$FromDateYear $FromDateHour:$FromDateMinute<br>";
            $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $ToDateDay.$ToDateMonth.$ToDateYear $ToDateHour:$ToDateMinute<br>";

            $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
            $QueueBookingBody = $QueueBookingBody . $RoomBooking{Body};

            my $MimeType = 'text/plain';
            if ( $LayoutObject->{BrowserRichText} ) {
                $MimeType = 'text/html';

                # verify html document
                $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                    String => $QueueBookingBody,
                );
            }

            my $PlainBody = $QueueBookingBody;

            if ( $LayoutObject->{BrowserRichText} ) {
                $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
            }

            # create article
            my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                UserLogin => $Self->{UserLogin},
            );
            my $From = "\"$FullName\" <$Self->{UserEmail}>";

            my $ArticleID = $ArticleBackendObject->ArticleCreate(
                TicketID             => $RoomBooking{QueueCateringTicketID},
                IsVisibleForCustomer => 1,
                SenderType           => 'customer',
                From                 => $From,
                To                   => 'System',
                Subject              => $RoomBooking{Subject},
                Body                 => $QueueBookingBody,
                MimeType             => $MimeType,
                Charset              => $LayoutObject->{UserCharset},
                UserID               => 1,
                HistoryType          => 'FollowUp',
                HistoryComment       => 'Cancel room booking',
                AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                ? 'auto reply'
                : '',
                OrigHeader => {
                    From    => $From,
                    To      => $Self->{UserLogin},
                    Subject => $RoomBooking{Subject},
                    Body    => $PlainBody,
                },
                Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueBooking} ),
            );

            if ( !$ArticleID ) {
                my $Output = $LayoutObject->CustomerHeader(
                    Title => Translatable('Error'),
                );
                $Output .= $LayoutObject->CustomerError();
                $Output .= $LayoutObject->CustomerFooter();
                return $Output;
            }
        }

        # redirect
        return $LayoutObject->Redirect(
            OP => "Action=CustomerBookingOverview;Subaction=MyRooms;SortBy=FromSystemTime;OrderBy=Down;Filter=All",
        );

    }

    elsif ( $Self->{Subaction} eq 'StoreChange' ) {

        my %RoomBooking = $RoomBookingObject->RoomBookingGet(
            RoomBookingID => $GetParam{ChangeID},
        );

        my @Equipments = split( /,/, $Room{EquipmentBookable} );
        for my $EquipmentID ( @Equipments ) {

            if ( $EquipmentID ) {
                my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
                    ID => $EquipmentID,
                );
                my $GetKey = 'BookableValue_' . $EquipmentData{ID};
                $GetParam{$GetKey} = $ParamObject->GetParam( Param => $GetKey );
            }
        }

        my %Error;

        if ( !$GetParam{Subject} ) {
             $Error{'SubjectInvalid'} = ' ServerError';
        }
        if ( !$GetParam{Participant} ) {
             $Error{'ParticipantInvalid'} = ' ServerError';
        }
        if ( !$GetParam{RoomID} ) {
             $Error{'RoomIDInvalid'} = ' ServerError';
        }

        if ( !$GetParam{FromDateYear} ) {
             $Error{'FromDateYearInvalid'} = ' ServerError';
        }
        if ( !$GetParam{FromDateMonth} ) {
             $Error{'FromDateMonthInvalid'} = ' ServerError';
        }
        if ( !$GetParam{FromDateDay} ) {
             $Error{'FromDateDayInvalid'} = ' ServerError';
        }
        if ( $GetParam{Participant} !~ /^\d+$/ ) {
             $Error{'ParticipantInvalid'} = ' ServerError';
        }
        if ( $Room{Persons} && $Room{Persons} < $GetParam{Participant} ) {
             $Error{'ParticipantInvalid'} = ' ServerError';
        }

        if (%Error) {

            # html output
            my $Output = $LayoutObject->CustomerHeader();
            $Output .= $LayoutObject->CustomerNavigationBar();
            $Output .= $Self->_MaskNew(
                %GetParam,
                Errors           => \%Error,
            );
            $Output .= $LayoutObject->CustomerFooter();
            return $Output;
        }

        my $FromSystemTime = "$GetParam{FromDateYear}-$GetParam{FromDateMonth}-$GetParam{FromDateDay} $GetParam{FromDateHour}:$GetParam{FromDateMinute}:00";
        my $ToSystemTime = "$GetParam{ToDateYear}-$GetParam{ToDateMonth}-$GetParam{ToDateDay} $GetParam{ToDateHour}:$GetParam{ToDateMinute}:00";

        my $FromStartSetSystemTime = $TimeObject->Date2SystemTime(
            Year   => $GetParam{FromDateYear},
            Month  => $GetParam{FromDateMonth},
            Day    => $GetParam{FromDateDay},
            Hour   => $GetParam{FromDateHour},
            Minute => $GetParam{FromDateMinute},
            Second => 0,
        );

        my $ToEndSetSystemTime = $TimeObject->Date2SystemTime(
            Year   => $GetParam{ToDateYear},
            Month  => $GetParam{ToDateMonth},
            Day    => $GetParam{ToDateDay},
            Hour   => $GetParam{ToDateHour},
            Minute => $GetParam{ToDateMinute},
            Second => 0,
        );

        my ($CheckToStartSec, $CheckToStartMin, $CheckToStartHour, $CheckToStartDay, $CheckToStartMonth, $CheckToStartYear, $CheckToStartWeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $FromStartSetSystemTime,
        );
        my ($CheckToEndSec, $CheckToEndMin, $CheckToEndHour, $CheckToEndDay, $CheckToEndMonth, $CheckToEndYear, $CheckToEndWeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $ToEndSetSystemTime,
        );

        my $ToEndSetSystemTimeMail = $ToEndSetSystemTime;

        $ToEndSetSystemTime = $ToEndSetSystemTime + ($Room{SetupTime} * 60 * 60);
        my ($ToEndSec, $ToEndMin, $ToEndHour, $ToEndDay, $ToEndMonth, $ToEndYear, $ToEndWeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $ToEndSetSystemTime,
        );
        my $ToEndSystemTime = "$ToEndYear-$ToEndMonth-$ToEndDay $ToEndHour:$ToEndMin:00";

        my $EquipmentOrder = '';
        my $EquipmentOrderTicket = '';
        for my $EquipmentID ( @Equipments ) {

            if ( $EquipmentID ) {
                my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
                    ID => $EquipmentID,
                );
                my $GetKey = 'BookableValue_' . $EquipmentData{ID};
                $GetParam{$GetKey} = $ParamObject->GetParam( Param => $GetKey );
                $EquipmentOrder .= $EquipmentID . '-' . $GetParam{$GetKey} . ',';
                if ( $GetParam{$GetKey} ) {
                    $EquipmentOrderTicket .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">$EquipmentData{Name}:</label> $GetParam{$GetKey}<br>";
                }
            }
        }
        $GetParam{EquipmentOrder} = $EquipmentOrder;

        my %CheckRoomList = $RoomBookingObject->RoomBookingTimeCheck(
            RoomID          => $GetParam{RoomID},
            FromSystemTime  => $FromSystemTime,
            ToSystemTime    => $ToSystemTime,
            RoomBookingID   => $GetParam{ChangeID},
        );

        my $CheckPossible = 0;
        for my $CheckID ( keys %CheckRoomList ) {
            $CheckPossible = 1;
        }

        my $CheckToStartWeekDayName = '';
        if ( $CheckToStartWeekDay == 1 ) {
             $CheckToStartWeekDayName = 'Mon';
        }
        if ( $CheckToStartWeekDay == 2 ) {
             $CheckToStartWeekDayName = 'Tue';
        }
        if ( $CheckToStartWeekDay == 3 ) {
             $CheckToStartWeekDayName = 'Wed';
        }
        if ( $CheckToStartWeekDay == 4 ) {
             $CheckToStartWeekDayName = 'Thu';
        }
        if ( $CheckToStartWeekDay == 5 ) {
             $CheckToStartWeekDayName = 'Fri';
        }
        if ( $CheckToStartWeekDay == 6 ) {
             $CheckToStartWeekDayName = 'Sat';
        }
        if ( $CheckToStartWeekDay == 0 ) {
             $CheckToStartWeekDayName = 'Sun';
        }

        my $CheckToEndWeekDayName = '';
        if ( $CheckToEndWeekDay == 1 ) {
             $CheckToEndWeekDayName = 'Mon';
        }
        if ( $CheckToEndWeekDay == 2 ) {
             $CheckToEndWeekDayName = 'Tue';
        }
        if ( $CheckToEndWeekDay == 3 ) {
             $CheckToEndWeekDayName = 'Wed';
        }
        if ( $CheckToEndWeekDay == 4 ) {
             $CheckToEndWeekDayName = 'Thu';
        }
        if ( $CheckToEndWeekDay == 5 ) {
             $CheckToEndWeekDayName = 'Fri';
        }
        if ( $CheckToEndWeekDay == 6 ) {
             $CheckToEndWeekDayName = 'Sat';
        }
        if ( $CheckToEndWeekDay == 0 ) {
             $CheckToEndWeekDayName = 'Sun';
        }

        # Get working and vacation times, use calendar if given
        my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');
        my $TimeWorkingHours        = $ConfigObject->Get('TimeWorkingHours');

        # Convert $TimeWorkingHours into Hash
        my %TimeWorkingHours;
        for my $DayName ( sort keys %{$TimeWorkingHours} ) {
            $TimeWorkingHours{$DayName} = { map { $_ => 1 } @{ $TimeWorkingHours->{$DayName} } };
        }

        my $StartDayCheck = 0;
        for my $CheckIfInTime ( keys %{$TimeWorkingHours{$CheckToStartWeekDayName}} ) {
            if ( $CheckIfInTime == $CheckToStartHour ) {
                $StartDayCheck = 1;
            }
        }
        my $EndDayCheck = 0;
        for my $CheckIfInTime ( keys %{$TimeWorkingHours{$CheckToEndWeekDayName}} ) {
            if ( $CheckIfInTime == $CheckToEndHour ) {
                $EndDayCheck = 1;
            }
        }

        if ( ( $StartDayCheck >= 1 ) && ( $EndDayCheck >= 1 ) && $CheckPossible < 1 ) {
             $CheckPossible = 0;
        }
        else {
             $CheckPossible = 2;
        }

        if ( $CheckPossible >= 1 ) {

            # print form ...
            my $Output = $LayoutObject->CustomerHeader();
            $Output .= $LayoutObject->CustomerNavigationBar();
            $Output .= $Self->_MaskNew(
                %GetParam,
                CheckPossible => $CheckPossible,
            );
            $Output .= $LayoutObject->CustomerFooter();
            return $Output;
        }
        else {

            my $ChangeSequence = $RoomBooking{Sequence} + 1;

            my $Success = $RoomBookingObject->RoomBookingUpdate(
                RoomBookingID   => $GetParam{ChangeID},
                RoomID          => $GetParam{RoomID},
                Participant     => $GetParam{Participant},
                Subject         => $GetParam{Subject},
                Body            => $GetParam{Body},
                FromSystemTime  => $FromSystemTime,
                ToSystemTime    => $ToSystemTime,
                ToEndSystemTime => $ToEndSystemTime,
                EmailList       => $GetParam{EmailList},
                EquipmentOrder  => $GetParam{EquipmentOrder},
                Sequence        => $ChangeSequence,
                UserID          => $Self->{UserID},
            );

            my $ICalLocation = "";
            if ( $Room{Street} ) {
                 $ICalLocation = "$Room{Street}, ";
            }
            if ( $Room{PostCode} ) {
                 $ICalLocation .= "$Room{PostCode}, ";
            }
            if ( $Room{City} ) {
                 $ICalLocation .= "$Room{City}, ";
            }
            if ( $Room{Building} ) {
                 $ICalLocation .= "$Room{Building}, ";
            }
            if ( $Room{Floor} ) {
                 $ICalLocation .= "$Room{Floor}, ";
            }
            if ( $Room{Room} ) {
                 $ICalLocation .= "$Room{Room}";
            }

            my $ICalPlainBody = $LayoutObject->RichText2Ascii( String => $GetParam{Body} );

            my ($ActSec, $ActMin, $ActHour, $ActDay, $ActMonth, $ActYear, $ActWeekDay) = $TimeObject->SystemTime2Date(
                SystemTime => $TimeObject->SystemTime(),
            );

            my $calendar = Data::ICal->new();

            $calendar->add_properties(
                method => 'REQUEST',
            );

            my $vtodo = Data::ICal::Entry::Event->new();
            $vtodo->add_properties(
              class       => 'PUBLIC',
              uid         => $RoomBooking{CalUID},
              dtstamp     => Date::ICal->new(
                  day   => $ActDay, 
                  month => $ActMonth, 
                  year  => $ActYear,
                  hour  => $ActHour,
                  min   => $ActMin,
                  sec   => 00
              )->ical,
              summary     => $GetParam{Subject},
              location    => $ICalLocation,
              priority    => 5,
              sequence    => $ChangeSequence,
              transp      => 'OPAQUE',
              organizer   => "mailto:$Self->{UserEmail}", 
              dtstart     => Date::ICal->new (
                  day   => $GetParam{FromDateDay}, 
                  month => $GetParam{FromDateMonth}, 
                  year  => $GetParam{FromDateYear},
                  hour  => $GetParam{FromDateHour},
                  min   => $GetParam{FromDateMinute},
                  sec   => 00
              )->ical,
              dtend      => Date::ICal->new(
                  day   => $GetParam{ToDateDay}, 
                  month => $GetParam{ToDateMonth}, 
                  year  => $GetParam{ToDateYear},
                  hour  => $GetParam{ToDateHour},
                  min   => $GetParam{ToDateMinute},
                  sec   => 00
              )->ical,
              description => $ICalPlainBody,
            );

            if ( $GetParam{EmailList} ) {

                my $ICalEmailList = $GetParam{EmailList};
                $ICalEmailList =~ s/ //g;
                my @Participants = split(/\;/, $ICalEmailList);
                for my $ICalParticipant ( @Participants ) {
    
                    $vtodo->add_properties(
                        attendee => [ "mailto:$ICalParticipant",
                            { 'ROLE'     => 'REQ-PARTICIPANT',
                              'PARTSTAT' => 'NEEDS-ACTION',
                              'RSVP'     => 'TRUE',
                              'CN'       => $ICalParticipant
                            },
                        ],
                    );
                }
            }

            $calendar->add_entry($vtodo);
            my $SendIcal = $calendar->as_string;
            $SendIcal =~ s/\r//g;

            my $EmailObject = $Kernel::OM->Get('Kernel::System::Email');
            $EmailObject->Send(
                From       => $Self->{UserEmail},
                To         => "$Self->{UserEmail}; $GetParam{EmailList}",
                Subject    => $GetParam{Subject},
                MimeType   => 'text/plain',
                Charset    => $LayoutObject->{UserCharset},
                Body       => $ICalPlainBody,
                Loop       => 1,
                Attachment => [
                    {
                        Filename    => "invite.ics",
                        Content     => $SendIcal,
                        ContentType => "text/calendar",
                    }
                ],
            );

            my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
            my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
            my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );
            my $QueueObject          = $Kernel::OM->Get('Kernel::System::Queue');

            if ( $Room{QueueBooking} ) {

                my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $FromStartSetSystemTime,
                );
                my ($EndSec, $EndMin, $EndHour, $EndDay, $EndMonth, $EndYear, $EndWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $ToEndSetSystemTimeMail,
                );

                my $ChangeRoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Change room booking");
                my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

                my $QueueBookingBody = "<b>$ChangeRoomBookingHeader:</b><br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $GetParam{Participant}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $StartDay.$StartMonth.$StartYear $StartHour:$StartMin<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $EndDay.$EndMonth.$EndYear $EndHour:$EndMin<br>";

                $QueueBookingBody = $QueueBookingBody . $EquipmentOrderTicket;

                $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
                $QueueBookingBody = $QueueBookingBody . $GetParam{Body};

                my $MimeType = 'text/plain';
                if ( $LayoutObject->{BrowserRichText} ) {
                    $MimeType = 'text/html';

                    # verify html document
                    $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                        String => $QueueBookingBody,
                    );
                }

                my $PlainBody = $QueueBookingBody;

                if ( $LayoutObject->{BrowserRichText} ) {
                    $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
                }

                # create article
                my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                    UserLogin => $Self->{UserLogin},
                );
                my $From = "\"$FullName\" <$Self->{UserEmail}>";

                my $ArticleID = $ArticleBackendObject->ArticleCreate(
                    TicketID             => $RoomBooking{QueueBookingTicketID},
                    IsVisibleForCustomer => 1,
                    SenderType           => 'customer',
                    From                 => $From,
                    To                   => 'System',
                    Subject              => $GetParam{Subject},
                    Body                 => $QueueBookingBody,
                    MimeType             => $MimeType,
                    Charset              => $LayoutObject->{UserCharset},
                    UserID               => 1,
                    HistoryType          => 'FollowUp',
                    HistoryComment       => 'Change room booking',
                    AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                    ? 'auto reply'
                    : '',
                    OrigHeader => {
                        From    => $From,
                        To      => $Self->{UserLogin},
                        Subject => $GetParam{Subject},
                        Body    => $PlainBody,
                    },
                    Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueBooking} ),
                );

                if ( !$ArticleID ) {
                    my $Output = $LayoutObject->CustomerHeader(
                        Title => Translatable('Error'),
                    );
                    $Output .= $LayoutObject->CustomerError();
                    $Output .= $LayoutObject->CustomerFooter();
                    return $Output;
                }
            }

            if ( $Room{QueueDevice} ) {

                my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $FromStartSetSystemTime,
                );
                my ($EndSec, $EndMin, $EndHour, $EndDay, $EndMonth, $EndYear, $EndWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $ToEndSetSystemTimeMail,
                );

                my $ChangeRoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Change room booking");
                my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

                my $QueueBookingBody = "<b>$ChangeRoomBookingHeader:</b><br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $GetParam{Participant}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $StartDay.$StartMonth.$StartYear $StartHour:$StartMin<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $EndDay.$EndMonth.$EndYear $EndHour:$EndMin<br>";

                $QueueBookingBody = $QueueBookingBody . $EquipmentOrderTicket;

                $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
                $QueueBookingBody = $QueueBookingBody . $GetParam{Body};

                my $MimeType = 'text/plain';
                if ( $LayoutObject->{BrowserRichText} ) {
                    $MimeType = 'text/html';

                    # verify html document
                    $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                        String => $QueueBookingBody,
                    );
                }

                my $PlainBody = $QueueBookingBody;

                if ( $LayoutObject->{BrowserRichText} ) {
                    $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
                }

                # create article
                my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                    UserLogin => $Self->{UserLogin},
                );
                my $From = "\"$FullName\" <$Self->{UserEmail}>";

                my $ArticleID = $ArticleBackendObject->ArticleCreate(
                    TicketID             => $RoomBooking{QueueDeviceTicketID},
                    IsVisibleForCustomer => 1,
                    SenderType           => 'customer',
                    From                 => $From,
                    To                   => 'System',
                    Subject              => $GetParam{Subject},
                    Body                 => $QueueBookingBody,
                    MimeType             => $MimeType,
                    Charset              => $LayoutObject->{UserCharset},
                    UserID               => 1,
                    HistoryType          => 'FollowUp',
                    HistoryComment       => 'Change room booking',
                    AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                    ? 'auto reply'
                    : '',
                    OrigHeader => {
                        From    => $From,
                        To      => $Self->{UserLogin},
                        Subject => $GetParam{Subject},
                        Body    => $PlainBody,
                    },
                    Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueBooking} ),
                );

                if ( !$ArticleID ) {
                    my $Output = $LayoutObject->CustomerHeader(
                        Title => Translatable('Error'),
                    );
                    $Output .= $LayoutObject->CustomerError();
                    $Output .= $LayoutObject->CustomerFooter();
                    return $Output;
                }
            }

            if ( $Room{QueueCatering} ) {

                my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $FromStartSetSystemTime,
                );
                my ($EndSec, $EndMin, $EndHour, $EndDay, $EndMonth, $EndYear, $EndWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $ToEndSetSystemTimeMail,
                );

                my $ChangeRoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Change room booking");
                my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

                my $QueueBookingBody = "<b>$ChangeRoomBookingHeader:</b><br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $GetParam{Participant}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $StartDay.$StartMonth.$StartYear $StartHour:$StartMin<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $EndDay.$EndMonth.$EndYear $EndHour:$EndMin<br>";

                $QueueBookingBody = $QueueBookingBody . $EquipmentOrderTicket;

                $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
                $QueueBookingBody = $QueueBookingBody . $GetParam{Body};

                my $MimeType = 'text/plain';
                if ( $LayoutObject->{BrowserRichText} ) {
                    $MimeType = 'text/html';

                    # verify html document
                    $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                        String => $QueueBookingBody,
                    );
                }

                my $PlainBody = $QueueBookingBody;

                if ( $LayoutObject->{BrowserRichText} ) {
                    $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
                }

                # create article
                my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                    UserLogin => $Self->{UserLogin},
                );
                my $From = "\"$FullName\" <$Self->{UserEmail}>";

                my $ArticleID = $ArticleBackendObject->ArticleCreate(
                    TicketID             => $RoomBooking{QueueCateringTicketID},
                    IsVisibleForCustomer => 1,
                    SenderType           => 'customer',
                    From                 => $From,
                    To                   => 'System',
                    Subject              => $GetParam{Subject},
                    Body                 => $QueueBookingBody,
                    MimeType             => $MimeType,
                    Charset              => $LayoutObject->{UserCharset},
                    UserID               => 1,
                    HistoryType          => 'FollowUp',
                    HistoryComment       => 'Change room booking',
                    AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                    ? 'auto reply'
                    : '',
                    OrigHeader => {
                        From    => $From,
                        To      => $Self->{UserLogin},
                        Subject => $GetParam{Subject},
                        Body    => $PlainBody,
                    },
                    Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueBooking} ),
                );

                if ( !$ArticleID ) {
                    my $Output = $LayoutObject->CustomerHeader(
                        Title => Translatable('Error'),
                    );
                    $Output .= $LayoutObject->CustomerError();
                    $Output .= $LayoutObject->CustomerFooter();
                    return $Output;
                }
            }
        }

        # redirect
        return $LayoutObject->Redirect(
            OP => "Action=CustomerBookingOverview;Subaction=MyRooms;SortBy=FromSystemTime;OrderBy=Down;Filter=All",
        );
    }

    elsif ( $Self->{Subaction} eq 'StoreNew' ) {

        my @Equipments = split( /,/, $Room{EquipmentBookable} );
        for my $EquipmentID ( @Equipments ) {

            if ( $EquipmentID ) {
                my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
                    ID => $EquipmentID,
                );
                if ( %EquipmentData ) {
                    my $GetKey = 'BookableValue_' . $EquipmentData{ID};
                    $GetParam{$GetKey} = $ParamObject->GetParam( Param => $GetKey );
                }
            }
        }

        my %Error;

        if ( !$GetParam{Subject} ) {
             $Error{'SubjectInvalid'} = ' ServerError';
        }
        if ( !$GetParam{Participant} ) {
             $Error{'ParticipantInvalid'} = ' ServerError';
        }
        if ( !$GetParam{RoomID} ) {
             $Error{'RoomIDInvalid'} = ' ServerError';
        }
        if ( !$GetParam{FromDateYear} ) {
             $Error{'FromDateYearInvalid'} = ' ServerError';
        }
        if ( !$GetParam{FromDateMonth} ) {
             $Error{'FromDateMonthInvalid'} = ' ServerError';
        }
        if ( !$GetParam{FromDateDay} ) {
             $Error{'FromDateDayInvalid'} = ' ServerError';
        }
        if ( $GetParam{Participant} !~ /^\d+$/ ) {
             $Error{'ParticipantInvalid'} = ' ServerError';
        }
        if ( $Room{Persons} && $Room{Persons} < $GetParam{Participant} ) {
             $Error{'ParticipantInvalid'} = ' ServerError';
        }

        if (%Error) {

            # html output
            my $Output = $LayoutObject->CustomerHeader();
            $Output .= $LayoutObject->CustomerNavigationBar();
            $Output .= $Self->_MaskNew(
                %GetParam,
                Errors           => \%Error,
            );
            $Output .= $LayoutObject->CustomerFooter();
            return $Output;
        }

        my $FromSystemTime = "$GetParam{FromDateYear}-$GetParam{FromDateMonth}-$GetParam{FromDateDay} $GetParam{FromDateHour}:$GetParam{FromDateMinute}:00";
        my $ToSystemTime = "$GetParam{ToDateYear}-$GetParam{ToDateMonth}-$GetParam{ToDateDay} $GetParam{ToDateHour}:$GetParam{ToDateMinute}:00";

        my $FromStartSetSystemTime = $TimeObject->Date2SystemTime(
            Year   => $GetParam{FromDateYear},
            Month  => $GetParam{FromDateMonth},
            Day    => $GetParam{FromDateDay},
            Hour   => $GetParam{FromDateHour},
            Minute => $GetParam{FromDateMinute},
            Second => 0,
        );

        my $ToEndSetSystemTime = $TimeObject->Date2SystemTime(
            Year   => $GetParam{ToDateYear},
            Month  => $GetParam{ToDateMonth},
            Day    => $GetParam{ToDateDay},
            Hour   => $GetParam{ToDateHour},
            Minute => $GetParam{ToDateMinute},
            Second => 0,
        );

        my ($CheckToStartSec, $CheckToStartMin, $CheckToStartHour, $CheckToStartDay, $CheckToStartMonth, $CheckToStartYear, $CheckToStartWeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $FromStartSetSystemTime,
        );
        my ($CheckToEndSec, $CheckToEndMin, $CheckToEndHour, $CheckToEndDay, $CheckToEndMonth, $CheckToEndYear, $CheckToEndWeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $ToEndSetSystemTime,
        );

        my $ToEndSetSystemTimeMail = $ToEndSetSystemTime;

        if ( $Room{SetupTime} ) {
            $ToEndSetSystemTime = $ToEndSetSystemTime + ($Room{SetupTime} * 60 * 60);
        }

        my ($ToEndSec, $ToEndMin, $ToEndHour, $ToEndDay, $ToEndMonth, $ToEndYear, $ToEndWeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $ToEndSetSystemTime,
        );
        my $ToEndSystemTime = "$ToEndYear-$ToEndMonth-$ToEndDay $ToEndHour:$ToEndMin:00";

        my $EquipmentOrder = '';
        my $EquipmentOrderTicket = '';
        if ( @Equipments ) {
            for my $EquipmentID ( @Equipments ) {
    
                if ( $EquipmentID ) {
                    my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
                        ID => $EquipmentID,
                    );
                    my $GetKey = 'BookableValue_' . $EquipmentData{ID};
                    $GetParam{$GetKey} = $ParamObject->GetParam( Param => $GetKey );
                    $EquipmentOrder .= $EquipmentID . '-' . $GetParam{$GetKey} . ',';
                    if ( $GetParam{$GetKey} ) {
                        $EquipmentOrderTicket .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">$EquipmentData{Name}:</label> $GetParam{$GetKey}<br>";
                    }
                }
            }
        }
        $GetParam{EquipmentOrder} = $EquipmentOrder;

        my %CheckRoomList = $RoomBookingObject->RoomBookingTimeCheck(
            RoomID         => $GetParam{RoomID},
            FromSystemTime => $FromSystemTime,
            ToSystemTime   => $ToSystemTime,
        );

        my $CheckPossible    = 0;
        my $CheckPossibleOne = 0;
        for my $CheckID ( keys %CheckRoomList ) {
            $CheckPossible    = 1;
            $CheckPossibleOne = 1;
        }

        my $CheckToStartWeekDayName = '';
        if ( $CheckToStartWeekDay == 1 ) {
             $CheckToStartWeekDayName = 'Mon';
        }
        if ( $CheckToStartWeekDay == 2 ) {
             $CheckToStartWeekDayName = 'Tue';
        }
        if ( $CheckToStartWeekDay == 3 ) {
             $CheckToStartWeekDayName = 'Wed';
        }
        if ( $CheckToStartWeekDay == 4 ) {
             $CheckToStartWeekDayName = 'Thu';
        }
        if ( $CheckToStartWeekDay == 5 ) {
             $CheckToStartWeekDayName = 'Fri';
        }
        if ( $CheckToStartWeekDay == 6 ) {
             $CheckToStartWeekDayName = 'Sat';
        }
        if ( $CheckToStartWeekDay == 0 ) {
             $CheckToStartWeekDayName = 'Sun';
        }

        my $CheckToEndWeekDayName = '';
        if ( $CheckToEndWeekDay == 1 ) {
             $CheckToEndWeekDayName = 'Mon';
        }
        if ( $CheckToEndWeekDay == 2 ) {
             $CheckToEndWeekDayName = 'Tue';
        }
        if ( $CheckToEndWeekDay == 3 ) {
             $CheckToEndWeekDayName = 'Wed';
        }
        if ( $CheckToEndWeekDay == 4 ) {
             $CheckToEndWeekDayName = 'Thu';
        }
        if ( $CheckToEndWeekDay == 5 ) {
             $CheckToEndWeekDayName = 'Fri';
        }
        if ( $CheckToEndWeekDay == 6 ) {
             $CheckToEndWeekDayName = 'Sat';
        }
        if ( $CheckToEndWeekDay == 0 ) {
             $CheckToEndWeekDayName = 'Sun';
        }

        # Get working and vacation times, use calendar if given
        my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');
        my $TimeWorkingHours        = $ConfigObject->Get('TimeWorkingHours');

        # Convert $TimeWorkingHours into Hash
        my %TimeWorkingHours;
        for my $DayName ( sort keys %{$TimeWorkingHours} ) {
            $TimeWorkingHours{$DayName} = { map { $_ => 1 } @{ $TimeWorkingHours->{$DayName} } };
        }

        my $StartDayCheck = 0;
        for my $CheckIfInTime ( keys %{$TimeWorkingHours{$CheckToStartWeekDayName}} ) {
            if ( $CheckIfInTime == $CheckToStartHour ) {
                $StartDayCheck = 1;
            }
        }
        my $EndDayCheck = 0;
        for my $CheckIfInTime ( keys %{$TimeWorkingHours{$CheckToEndWeekDayName}} ) {
            if ( $CheckIfInTime == $CheckToEndHour ) {
                $EndDayCheck = 1;
            }
        }

        if ( ( $StartDayCheck >= 1 ) && ( $EndDayCheck >= 1 ) && $CheckPossibleOne < 1 ) {
             $CheckPossible = 0;
        }
        else {
             $CheckPossible = 2;
        }

        if ( $CheckPossible >= 1 ) {

            # print form ...
            my $Output = $LayoutObject->CustomerHeader();
            $Output .= $LayoutObject->CustomerNavigationBar();
            $Output .= $Self->_MaskNew(
                %GetParam,
                CheckPossible => $CheckPossible,
            );
            $Output .= $LayoutObject->CustomerFooter();
            return $Output;
        }
        else {

            my $ICalLocation = "";
            if ( $Room{Street} ) {
                 $ICalLocation = "$Room{Street}, ";
            }
            if ( $Room{PostCode} ) {
                 $ICalLocation .= "$Room{PostCode}, ";
            }
            if ( $Room{City} ) {
                 $ICalLocation .= "$Room{City}, ";
            }
            if ( $Room{Building} ) {
                 $ICalLocation .= "$Room{Building}, ";
            }
            if ( $Room{Floor} ) {
                 $ICalLocation .= "$Room{Floor}, ";
            }
            if ( $Room{Room} ) {
                 $ICalLocation .= "$Room{Room}";
            }

            my $ICalPlainBody = $LayoutObject->RichText2Ascii( String => $GetParam{Body} );

            my ($ActSec, $ActMin, $ActHour, $ActDay, $ActMonth, $ActYear, $ActWeekDay) = $TimeObject->SystemTime2Date(
                SystemTime => $TimeObject->SystemTime(),
            );

            my $ActSystemTime = $TimeObject->SystemTime();

            my $calendar = Data::ICal->new();

            $calendar->add_properties(
                method => 'REQUEST',
            );

            my $vtodo = Data::ICal::Entry::Event->new();
            $vtodo->add_properties(
              class       => 'PUBLIC',
              uid         => $ActSystemTime,
              dtstamp     => Date::ICal->new(
                  day   => $ActDay, 
                  month => $ActMonth, 
                  year  => $ActYear,
                  hour  => $ActHour,
                  min   => $ActMin,
                  sec   => 00
              )->ical,
              summary     => $GetParam{Subject},
              location    => $ICalLocation,
              priority    => 5,
              sequence    => 0,
              transp      => 'OPAQUE',
              organizer   => "mailto:$Self->{UserEmail}", 
              dtstart     => Date::ICal->new (
                  day   => $GetParam{FromDateDay}, 
                  month => $GetParam{FromDateMonth}, 
                  year  => $GetParam{FromDateYear},
                  hour  => $GetParam{FromDateHour},
                  min   => $GetParam{FromDateMinute},
                  sec   => 00
              )->ical,
              dtend      => Date::ICal->new(
                  day   => $GetParam{ToDateDay}, 
                  month => $GetParam{ToDateMonth}, 
                  year  => $GetParam{ToDateYear},
                  hour  => $GetParam{ToDateHour},
                  min   => $GetParam{ToDateMinute},
                  sec   => 00
              )->ical,
              description => $ICalPlainBody,
            );

            if ( $GetParam{EmailList} ) {

                my $ICalEmailList = $GetParam{EmailList};
                $ICalEmailList =~ s/ //g;
                my @Participants = split(/\;/, $ICalEmailList);
                for my $ICalParticipant ( @Participants ) {
    
                    $vtodo->add_properties(
                        attendee => [ "mailto:$ICalParticipant",
                            { 'ROLE'     => 'REQ-PARTICIPANT',
                              'PARTSTAT' => 'NEEDS-ACTION',
                              'RSVP'     => 'TRUE',
                              'CN'       => $ICalParticipant
                            },
                        ],
                    );
                }
            }

            $calendar->add_entry($vtodo);
            my $SendIcal = $calendar->as_string;
            $SendIcal =~ s/\r//g;

            my $EmailObject = $Kernel::OM->Get('Kernel::System::Email');
            $EmailObject->Send(
                From       => $Self->{UserEmail},
                To         => "$Self->{UserEmail}; $GetParam{EmailList}",
                Subject    => $GetParam{Subject},
                MimeType   => 'text/plain',
                Charset    => $LayoutObject->{UserCharset},
                Body       => $ICalPlainBody,
                Loop       => 1,
                Attachment => [
                    {
                        Filename    => "invite.ics",
                        Content     => $SendIcal,
                        ContentType => "text/calendar",
                    }
                ],
            );

            my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
            my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
            my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );
            my $QueueObject          = $Kernel::OM->Get('Kernel::System::Queue');
            my $QueueBookingTicketID  = '';
            my $QueueDeviceTicketID   = '';
            my $QueueCateringTicketID = '';

            if ( $Room{QueueBooking} ) {

                # create new ticket, do db insert
                $QueueBookingTicketID = $TicketObject->TicketCreate(
                    QueueID      => $Room{QueueBooking},
                    Title        => $GetParam{Subject},
                    Priority     => '3 normal',
                    Type         => 'RoomBooking',
                    Lock         => 'unlock',
                    State        => 'new',
                    CustomerID   => $Self->{UserCustomerID},
                    CustomerUser => $Self->{UserLogin},
                    OwnerID      => 1,
                    UserID       => 1,
                );

                my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $FromStartSetSystemTime,
                );
                my ($EndSec, $EndMin, $EndHour, $EndDay, $EndMonth, $EndYear, $EndWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $ToEndSetSystemTimeMail,
                );

                my $RoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Book a room");
                my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

                my $QueueBookingBody = "<b>$RoomBookingHeader:</b><br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $GetParam{Participant}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $StartDay.$StartMonth.$StartYear $StartHour:$StartMin<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $EndDay.$EndMonth.$EndYear $EndHour:$EndMin<br>";

                $QueueBookingBody = $QueueBookingBody . $EquipmentOrderTicket;

                $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
                $QueueBookingBody = $QueueBookingBody . $GetParam{Body};

                my $MimeType = 'text/plain';
                if ( $LayoutObject->{BrowserRichText} ) {
                    $MimeType = 'text/html';

                    # verify html document
                    $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                        String => $QueueBookingBody,
                    );
                }

                my $PlainBody = $QueueBookingBody;

                if ( $LayoutObject->{BrowserRichText} ) {
                    $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
                }

                # create article
                my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                    UserLogin => $Self->{UserLogin},
                );
                my $From = "\"$FullName\" <$Self->{UserEmail}>";

                my $ArticleID = $ArticleBackendObject->ArticleCreate(
                    TicketID             => $QueueBookingTicketID,
                    IsVisibleForCustomer => 1,
                    SenderType           => 'customer',
                    From                 => $From,
                    To                   => 'System',
                    Subject              => $GetParam{Subject},
                    Body                 => $QueueBookingBody,
                    MimeType             => $MimeType,
                    Charset              => $LayoutObject->{UserCharset},
                    UserID               => 1,
                    HistoryType          => 'NewTicket',
                    HistoryComment       => 'New room booking',
                    AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                    ? 'auto reply'
                    : '',
                    OrigHeader => {
                        From    => $From,
                        To      => $Self->{UserLogin},
                        Subject => $GetParam{Subject},
                        Body    => $PlainBody,
                    },
                    Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueBooking} ),
                );

                if ( !$ArticleID ) {
                    my $Output = $LayoutObject->CustomerHeader(
                        Title => Translatable('Error'),
                    );
                    $Output .= $LayoutObject->CustomerError();
                    $Output .= $LayoutObject->CustomerFooter();
                    return $Output;
                }
            }

            if ( $Room{QueueDevice} ) {

                # create new ticket, do db insert
                $QueueDeviceTicketID = $TicketObject->TicketCreate(
                    QueueID      => $Room{QueueDevice},
                    Title        => $GetParam{Subject},
                    Priority     => '3 normal',
                    Type         => 'RoomBooking',
                    Lock         => 'unlock',
                    State        => 'new',
                    CustomerID   => $Self->{UserCustomerID},
                    CustomerUser => $Self->{UserLogin},
                    OwnerID      => 1,
                    UserID       => 1,
                );

                my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $FromStartSetSystemTime,
                );
                my ($EndSec, $EndMin, $EndHour, $EndDay, $EndMonth, $EndYear, $EndWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $ToEndSetSystemTimeMail,
                );

                my $RoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Book a room");
                my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

                my $QueueBookingBody = "<b>$RoomBookingHeader:</b><br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $GetParam{Participant}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $StartDay.$StartMonth.$StartYear $StartHour:$StartMin<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $EndDay.$EndMonth.$EndYear $EndHour:$EndMin<br>";

                $QueueBookingBody = $QueueBookingBody . $EquipmentOrderTicket;

                $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
                $QueueBookingBody = $QueueBookingBody . $GetParam{Body};

                my $MimeType = 'text/plain';
                if ( $LayoutObject->{BrowserRichText} ) {
                    $MimeType = 'text/html';

                    # verify html document
                    $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                        String => $QueueBookingBody,
                    );
                }

                my $PlainBody = $QueueBookingBody;

                if ( $LayoutObject->{BrowserRichText} ) {
                    $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
                }

                # create article
                my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                    UserLogin => $Self->{UserLogin},
                );
                my $From = "\"$FullName\" <$Self->{UserEmail}>";

                my $ArticleID = $ArticleBackendObject->ArticleCreate(
                    TicketID             => $QueueDeviceTicketID,
                    IsVisibleForCustomer => 1,
                    SenderType           => 'customer',
                    From                 => $From,
                    To                   => 'System',
                    Subject              => $GetParam{Subject},
                    Body                 => $QueueBookingBody,
                    MimeType             => $MimeType,
                    Charset              => $LayoutObject->{UserCharset},
                    UserID               => 1,
                    HistoryType          => 'NewTicket',
                    HistoryComment       => 'New room booking',
                    AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                    ? 'auto reply'
                    : '',
                    OrigHeader => {
                        From    => $From,
                        To      => $Self->{UserLogin},
                        Subject => $GetParam{Subject},
                        Body    => $PlainBody,
                    },
                    Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueDevice} ),
                );

                if ( !$ArticleID ) {
                    my $Output = $LayoutObject->CustomerHeader(
                        Title => Translatable('Error'),
                    );
                    $Output .= $LayoutObject->CustomerError();
                    $Output .= $LayoutObject->CustomerFooter();
                    return $Output;
                }
            }

            if ( $Room{QueueCatering} ) {

                # create new ticket, do db insert
                $QueueCateringTicketID = $TicketObject->TicketCreate(
                    QueueID      => $Room{QueueCatering},
                    Title        => $GetParam{Subject},
                    Priority     => '3 normal',
                    Type         => 'RoomBooking',
                    Lock         => 'unlock',
                    State        => 'new',
                    CustomerID   => $Self->{UserCustomerID},
                    CustomerUser => $Self->{UserLogin},
                    OwnerID      => 1,
                    UserID       => 1,
                );

                my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $FromStartSetSystemTime,
                );
                my ($EndSec, $EndMin, $EndHour, $EndDay, $EndMonth, $EndYear, $EndWeekDay) = $TimeObject->SystemTime2Date(
                    SystemTime => $ToEndSetSystemTimeMail,
                );

                my $RoomBookingHeader = $LayoutObject->{LanguageObject}->Translate("Book a room");
                my $RemarksHeader = $LayoutObject->{LanguageObject}->Translate("Remarks");

                my $QueueBookingBody = "<b>$RoomBookingHeader:</b><br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Raum:</label> $Room{Room}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Personen:</label> $GetParam{Participant}<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Start:</label> $StartDay.$StartMonth.$StartYear $StartHour:$StartMin<br>";
                $QueueBookingBody .= "<label style=\"width:160px;display:inline-block;background-color: #d9f8ea;padding:3px;text-align:right;margin-bottom:4px;border-radius:3px;\">Ende:</label> $EndDay.$EndMonth.$EndYear $EndHour:$EndMin<br>";

                $QueueBookingBody = $QueueBookingBody . $EquipmentOrderTicket;

                $QueueBookingBody .= "<br><b>$RemarksHeader:</b><br>";
                $QueueBookingBody = $QueueBookingBody . $GetParam{Body};

                my $MimeType = 'text/plain';
                if ( $LayoutObject->{BrowserRichText} ) {
                    $MimeType = 'text/html';

                    # verify html document
                    $QueueBookingBody = $LayoutObject->RichTextDocumentComplete(
                        String => $QueueBookingBody,
                    );
                }

                my $PlainBody = $QueueBookingBody;

                if ( $LayoutObject->{BrowserRichText} ) {
                    $PlainBody = $LayoutObject->RichText2Ascii( String => $QueueBookingBody );
                }

                # create article
                my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                    UserLogin => $Self->{UserLogin},
                );
                my $From = "\"$FullName\" <$Self->{UserEmail}>";

                my $ArticleID = $ArticleBackendObject->ArticleCreate(
                    TicketID             => $QueueCateringTicketID,
                    IsVisibleForCustomer => 1,
                    SenderType           => 'customer',
                    From                 => $From,
                    To                   => 'System',
                    Subject              => $GetParam{Subject},
                    Body                 => $QueueBookingBody,
                    MimeType             => $MimeType,
                    Charset              => $LayoutObject->{UserCharset},
                    UserID               => 1,
                    HistoryType          => 'NewTicket',
                    HistoryComment       => 'New room booking',
                    AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
                    ? 'auto reply'
                    : '',
                    OrigHeader => {
                        From    => $From,
                        To      => $Self->{UserLogin},
                        Subject => $GetParam{Subject},
                        Body    => $PlainBody,
                    },
                    Queue => $QueueObject->QueueLookup( QueueID => $Room{QueueCatering} ),
                );

                if ( !$ArticleID ) {
                    my $Output = $LayoutObject->CustomerHeader(
                        Title => Translatable('Error'),
                    );
                    $Output .= $LayoutObject->CustomerError();
                    $Output .= $LayoutObject->CustomerFooter();
                    return $Output;
                }
            }

            my $BookingID = $RoomBookingObject->RoomBookingAdd(
                RoomID                => $GetParam{RoomID},
                Participant           => $GetParam{Participant},
                Subject               => $GetParam{Subject},
                Body                  => $GetParam{Body},
                FromSystemTime        => $FromSystemTime,
                ToSystemTime          => $ToSystemTime,
                ToEndSystemTime       => $ToEndSystemTime,
                EmailList             => $GetParam{EmailList},
                EquipmentOrder        => $GetParam{EquipmentOrder},
                CalUID                => $ActSystemTime,
                Sequence              => 0,
                QueueBookingTicketID  => $QueueBookingTicketID,
                QueueDeviceTicketID   => $QueueDeviceTicketID,
                QueueCateringTicketID => $QueueCateringTicketID,
                UserID                => $Self->{UserID},
            );
        }

        # redirect
        return $LayoutObject->Redirect(
            OP => "Action=CustomerBookingOverview;Subaction=MyRooms;SortBy=FromSystemTime;OrderBy=Down;Filter=All",
        );
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    $Param{FormID} = $Self->{FormID};

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $BookingSystemRoomsObject = $Kernel::OM->Get('Kernel::System::BookingSystemRooms');
    my $RoomIconObject           = $Kernel::OM->Get('Kernel::System::RoomIcon');
    my $RoomCategoriesObject     = $Kernel::OM->Get('Kernel::System::RoomCategories');
    my $RoomEquipmentObject      = $Kernel::OM->Get('Kernel::System::RoomEquipment');
    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Config                   = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");
    my $TimeObject               = $Kernel::OM->Get('Kernel::System::Time');
    my $RoomBookingObject        = $Kernel::OM->Get('Kernel::System::RoomBooking');
    my $SysConfigObject          = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $RoomID        = $Param{RoomID} || return;
    my $CheckPossible = $Param{CheckPossible} || 0;
    my $ChangeTheBook = $Param{ChangeTheBook} || '';


    my %Room = $BookingSystemRoomsObject->RoomGet(
        RoomID => $RoomID,
    );

    if ( $Room{Calendar} ) {

        my %Setting = $SysConfigObject->SettingGet(
            Name            => 'TimeWorkingHours::Calendar' . $Room{Calendar},
            OverriddenInXML => 1,
            UserID          => 1,
        );

        my %Result;

        # Send only useful setting attributes to reduce amount of data transfered in the AJAX call.
        for my $Key (qw(IsModified IsDirty IsLocked ExclusiveLockGUID IsValid UserModificationActive)) {
            $Result{Data}->{SettingData}->{$Key} = $Setting{$Key};
        }

        $Result{Data}->{HTMLStrg} = $SysConfigObject->SettingRender(
            Setting => \%Setting,
            RW      => 0,
            UserID  => 1,
        );
        $Room{WorkingTime} = $Result{Data}->{HTMLStrg};

        $LayoutObject->Block(
            Name => 'BookableTimes',
            Data => { %Param, %Room, },
        );
    }
    else {

        my %Setting = $SysConfigObject->SettingGet(
            Name            => 'TimeWorkingHours',
            OverriddenInXML => 1,
            UserID          => 1,
        );

        my %Result;

        # Send only useful setting attributes to reduce amount of data transfered in the AJAX call.
        for my $Key (qw(IsModified IsDirty IsLocked ExclusiveLockGUID IsValid UserModificationActive)) {
            $Result{Data}->{SettingData}->{$Key} = $Setting{$Key};
        }

        $Result{Data}->{HTMLStrg} = $SysConfigObject->SettingRender(
            Setting => \%Setting,
            RW      => 0,
            UserID  => 1,
        );
        $Room{WorkingTime} = $Result{Data}->{HTMLStrg};

        $LayoutObject->Block(
            Name => 'BookableTimes',
            Data => { %Param, %Room, },
        );

    }

    if ( $ChangeTheBook ) {

        $LayoutObject->Block(
            Name => 'CancelBooking',
            Data => { %Param, %Room, },
        );
    }
    else {

        $LayoutObject->Block(
            Name => 'CrateBooking',
            Data => { %Param, %Room, },
        );
    }

    if ( $CheckPossible == 1 ) {

        $LayoutObject->Block(
            Name => 'DateOccupied',
            Data => { %Param, %Room, },
        );
        $Room{Anker} = 'DateOccupied',
    }
    if ( $CheckPossible == 2 ) {

        $LayoutObject->Block(
            Name => 'DateOccupiedRange',
            Data => { %Param, %Room, },
        );
        $Room{Anker} = 'DateOccupiedRange',
    }

    # prepare errors
    if ( $Param{Errors} ) {
        for ( sort keys %{ $Param{Errors} } ) {
            $Param{$_} = $Param{Errors}->{$_};
        }
    }

    if ( $Room{PriceFor} == 1 ) {
        $LayoutObject->Block(
            Name => 'RoomPerHour',
            Data => { %Param, %Room, },
        );
    }
    if ( $Room{PriceFor} == 2 ) {
        $LayoutObject->Block(
            Name => 'RoomPerDay',
            Data => { %Param, %Room, },
        );
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

    if ( $Room{EquipmentBookable} ) {

        my @Equipments = split( /,/, $Room{EquipmentBookable} );
        for my $EquipmentID ( @Equipments ) {

            my %EquipmentData = $RoomEquipmentObject->EquipmentGet(
                ID => $EquipmentID,
            );
            $Room{EquipmentInventaryBookable} = $EquipmentData{Name};
            $Room{EquipmentBookablePrice} = $EquipmentData{Price};
            $Room{EquipmentBookableCurrency} = $EquipmentData{Currency};
            $Room{BookableID} = $EquipmentData{ID};
            my $SetValueName = 'BookableValue_' . $EquipmentData{ID};
            $Room{BookableValue} = $Param{"$SetValueName"};

            $LayoutObject->Block(
                Name => 'EquipmentInventaryBookable',
                Data => { %Param, %Room, },
            );
            $LayoutObject->Block(
                Name => 'InventaryBookable',
                Data => { %Param, %Room, },
            );

            if ( $EquipmentData{PriceFor} == 1 ) {
                $LayoutObject->Block(
                    Name => 'PerHour',
                    Data => { %Param, %Room, },
                );
                $LayoutObject->Block(
                    Name => 'BookablePerHour',
                    Data => { %Param, %Room, },
                );
            }
            if ( $EquipmentData{PriceFor} == 2 ) {
                $LayoutObject->Block(
                    Name => 'PerDay',
                    Data => { %Param, %Room, },
                );
                $LayoutObject->Block(
                    Name => 'BookablePerDay',
                    Data => { %Param, %Room, },
                );
            }
            if ( $EquipmentData{PriceFor} == 3 ) {
                $LayoutObject->Block(
                    Name => 'PerPiece',
                    Data => { %Param, %Room, },
                );
                $LayoutObject->Block(
                    Name => 'BookablePerPiece',
                    Data => { %Param, %Room, },
                );
            }
            if ( $EquipmentData{PriceFor} == 4 ) {
                $LayoutObject->Block(
                    Name => 'FlatRate',
                    Data => { %Param, %Room, },
                );
                $LayoutObject->Block(
                    Name => 'BookableFlatRate',
                    Data => { %Param, %Room, },
                );
            }
        }
    }

    my ($StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay) = $TimeObject->SystemTime2Date(
        SystemTime => $TimeObject->SystemTime(),
    );
    my $StartMonthGet = "$StartYear-$StartMonth-01 00:00:00";

    my %RoomBookingFutureList = $RoomBookingObject->RoomBookingFutureList(
        RoomID     => $RoomID,
        StartMonth => $StartMonthGet,
    );

    for my $CheckRoomID ( keys %RoomBookingFutureList ) {
        my %RoomBooking = $RoomBookingObject->RoomBookingGet(
            RoomBookingID => $CheckRoomID,
        );
        $Room{CalendarEvents} .= "{ id: '" . $CheckRoomID . "', resourceId: '" . $RoomID . "', start: '" . $RoomBooking{FromSystemTime} . "', end: '" . $RoomBooking{ToSystemTime} . "', title: '" . $RoomBooking{Subject} . "' },";
    }

    $Room{CalendarResources} = "{ id: '" . $RoomID . "', title: '" . $Room{Room} . "', eventColor: '#8a0303' },";

    $LayoutObject->Block(
        Name => 'CalendarResources',
        Data => { %Param, %Room, },
    );

    $LayoutObject->Block(
        Name => 'CalendarEvents',
        Data => { %Param, %Room, },
    );

    $Param{FromDateString} = $LayoutObject->BuildDateSelection(
        Prefix               => 'FromDate',
        FromDateYear         => $Param{FromDateYear},
        FromDateMonth        => $Param{FromDateMonth},
        FromDateDay          => $Param{FromDateDay},
        FromDateHour         => $Param{FromDateHour},
        FromDateMinute       => $Param{FromDateMinute},
        Format               => 'DateInputFormatLong',
        YearPeriodPast       => 0,
        YearPeriodFuture     => 1,
        DiffTime             => 0,
        Class                => $Param{Errors}->{FromDateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 1,
    );

    $Param{ToDateString} = $LayoutObject->BuildDateSelection(
        Prefix               => 'ToDate',
        ToDateYear           => $Param{ToDateYear},
        ToDateMonth          => $Param{ToDateMonth},
        ToDateDay            => $Param{ToDateDay},
        ToDateHour           => $Param{ToDateHour},
        ToDateMinute         => $Param{ToDateMinute},
        Format               => 'DateInputFormatLong',
        YearPeriodPast       => 0,
        YearPeriodFuture     => 1,
        DiffTime             => 3600,
        Class                => $Param{Errors}->{ToDateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 1,
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


    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

        # set up customer rich text editor
        $LayoutObject->CustomerSetRichTextParameters(
            Data => \%Param,
        );
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'CustomerBookRoom',
        Data => { %Param, %Room, },
    );
}

1;
