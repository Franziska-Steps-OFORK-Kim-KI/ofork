# --
# Kernel/Modules/AgentTimeTrackingEvaluation.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de/
# --
# $Id: AgentTimeTrackingEvaluation.pm,v 1.6 2019/08/21 08:41:59 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTimeTrackingEvaluation;

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
    $Self->{FormID}
        = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'FormID' );

    # create form id
    if ( !$Self->{FormID} ) {
        $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCreate();
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject               = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TimeObject                 = $Kernel::OM->Get('Kernel::System::Time');
    my $TimeTrackingArticleObject  = $Kernel::OM->Get('Kernel::System::TimeTrackingArticle');
    my $TimeTrackingCategoryObject = $Kernel::OM->Get('Kernel::System::TimeTrackingCategory');
    my $CustomerCompanyObject      = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    my $TicketObject               = $Kernel::OM->Get('Kernel::System::Ticket');
    my $DateTimeObject             = $Kernel::OM->Create('Kernel::System::DateTime');
    my $UserObject                 = $Kernel::OM->Get('Kernel::System::User');

    # get params
    my %GetParam;

    for my $Key (
        qw(FromDateDay FromDateMonth FromDateYear ToDateDay ToDateMonth ToDateYear ResultForm)
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

        my $Start
            = "$GetParam{FromDateYear}-$GetParam{FromDateMonth}-$GetParam{FromDateDay} 00:00:00";
        my $End = "$GetParam{ToDateYear}-$GetParam{ToDateMonth}-$GetParam{ToDateDay} 23:59:59";

        my $HeaderStart = "$GetParam{FromDateDay}.$GetParam{FromDateMonth}.$GetParam{FromDateYear}";
        my $HeaderEnd   = "$GetParam{ToDateDay}.$GetParam{ToDateMonth}.$GetParam{ToDateYear}";

        my @CustomerIDs = $ParamObject->GetArray( Param => 'CustomerID' );
        my @HeadData = ();
        my @Data;

        if ( !@CustomerIDs ) {

            my @TimeTrackingSearch = $TimeTrackingArticleObject->TimeTrackingArticleStats(
                Start => $Start,
                End   => $End,
            );

            my $TimeUnitsTicket   = 0;
            my $TicketID          = 0;
            my $TimeUnitsCustomer = 0;

            TICKETID:
            for my $TimeTrackingID (@TimeTrackingSearch) {

                my %TimeTracking = $TimeTrackingArticleObject->TimeTrackingArticleGet(
                    ID => $TimeTrackingID,
                );

                if (%TimeTracking) {

                    $TimeTrackingArticleObject->TimeTrackingArticleUpdateSeen(
                        ID => $TimeTrackingID,
                    );
                }

                my %Ticket = $TicketObject->TicketGet(
                    TicketID      => $TimeTracking{TicketID},
                    DynamicFields => 0,
                );

                next TICKETID if !%Ticket;

                if ( $TicketID > 1 && $TicketID != $TimeTracking{TicketID} ) {
                    $TimeUnitsTicket = 0;
                }

                my %Category = $TimeTrackingCategoryObject->CategoryGet(
                    ID => $TimeTracking{TimeTrackingID},
                );

                $TicketID          = $TimeTracking{TicketID};
                $TimeUnitsTicket   = $TimeUnitsTicket + $TimeTracking{TimeTrackingTime};
                $TimeUnitsCustomer = $TimeUnitsCustomer + $TimeTracking{TimeTrackingTime};
                $TimeTracking{CreateBy}
                    = $UserObject->UserName( UserID => $TimeTracking{CreateBy} );

                # build table row
                push @Data, [
                    $Ticket{TicketNumber},
                    $Ticket{Title},
                    $Ticket{Queue},
                    $Ticket{State},
                    $TimeTracking{CustomerID},
                    $TimeTracking{CreateBy},
                    $TimeTracking{Subject},
                    $Category{Name},
                    $TimeTracking{CreateTime},
                    $TimeTracking{Seen},
                    $TimeTracking{TimeTrackingTime},
                    $TimeUnitsTicket,
                    $TimeUnitsCustomer,
                ];

                %TimeTracking = ();
                %Ticket       = ();
                %Category     = ();
            }

            # table headlines
            @HeadData = (
                'Ticketnumber',
                'Title',
                'Queue',
                'State',
                'Customer',
                'Agent',
                'Activity',
                'Category',
                'Date',
                'Seen',
                'Time units',
                'Time units ticket',
                'Time units customer',
            );

        }
        else {

            for my $CustomerID (@CustomerIDs) {

                my @TimeTrackingSearch = $TimeTrackingArticleObject->TimeTrackingArticleStats(
                    CustomerID => $CustomerID,
                    Start      => $Start,
                    End        => $End,
                );

                my $TimeUnitsTicket   = 0;
                my $TicketID          = 0;
                my $TimeUnitsCustomer = 0;

                TICKETID:
                for my $TimeTrackingID (@TimeTrackingSearch) {

                    my %TimeTracking = $TimeTrackingArticleObject->TimeTrackingArticleGet(
                        ID => $TimeTrackingID,
                    );

                    if (%TimeTracking) {

                        $TimeTrackingArticleObject->TimeTrackingArticleUpdateSeen(
                            ID => $TimeTrackingID,
                        );
                    }

                    my %Ticket = $TicketObject->TicketGet(
                        TicketID      => $TimeTracking{TicketID},
                        DynamicFields => 0,
                    );

                    next TICKETID if !%Ticket;

                    if ( $TicketID > 1 && $TicketID != $TimeTracking{TicketID} ) {
                        $TimeUnitsTicket = 0;
                    }

                    my %Category = $TimeTrackingCategoryObject->CategoryGet(
                        ID => $TimeTracking{TimeTrackingID},
                    );

                    $TicketID          = $TimeTracking{TicketID};
                    $TimeUnitsTicket   = $TimeUnitsTicket + $TimeTracking{TimeTrackingTime};
                    $TimeUnitsCustomer = $TimeUnitsCustomer + $TimeTracking{TimeTrackingTime};
                    $TimeTracking{CreateBy}
                        = $UserObject->UserName( UserID => $TimeTracking{CreateBy} );

                    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
                        CustomerID => $TimeTracking{CustomerID},
                    );
                    $TimeTracking{Customer} = $CustomerCompany{CustomerCompanyName};

                    # build table row
                    push @Data, [
                        $Ticket{TicketNumber},
                        $Ticket{Title},
                        $Ticket{Queue},
                        $Ticket{State},
                        $TimeTracking{Customer},
                        $TimeTracking{CreateBy},
                        $TimeTracking{Subject},
                        $Category{Name},
                        $TimeTracking{CreateTime},
                        $TimeTracking{Seen},
                        $TimeTracking{TimeTrackingTime},
                        $TimeUnitsTicket,
                        $TimeUnitsCustomer,
                    ];

                    %TimeTracking = ();
                    %Ticket       = ();
                    %Category     = ();
                }

                # table headlines
                @HeadData = (
                    'Ticketnumber',
                    'Title',
                    'Queue',
                    'State',
                    'Customer',
                    'Agent',
                    'Activity',
                    'Category',
                    'Date',
                    'Seen',
                    'Time units',
                    'Time units ticket',
                    'Time units customer',
                );
            }
        }

        my $Title         = "Evaluation time tracking from $HeaderStart to $HeaderEnd";
        my @StatArray     = ( [$Title], [@HeadData], @Data );
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
    my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject          = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    my $TimeObject            = $Kernel::OM->Get('Kernel::System::Time');

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime'
    );

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    my %CustomerList = $CustomerCompanyObject->CustomerCompanyList(
        Valid => 1,
        Limit => 0,
    );
    $Param{CustomerStrg} = $LayoutObject->BuildSelection(
        Data         => \%CustomerList,
        Name         => 'CustomerID',
        Multiple     => 1,
        Size         => 10,
        PossibleNone => 0,
        Sort         => 'AlphanumericKey',
        SelectedID   => $Param{CustomerID},
        Translation  => 0,
        Class        => "Modernize",
    );

    my ( $StartSec, $StartMin, $StartHour, $StartDay, $StartMonth, $StartYear, $StartWeekDay )
        = $TimeObject->SystemTime2Date(
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
        YearPeriodPast       => 1,
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
        YearPeriodPast       => 1,
        YearPeriodFuture     => 1,
        DiffTime             => 3600,
        Class                => $Param{Errors}->{ToDateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 0,
    );

    $Param{ResultFormStrg} = $LayoutObject->BuildSelection(
        Data => {
            Print => Translatable('Print'),
            CSV   => Translatable('CSV'),
            Excel => Translatable('Excel'),
        },
        Name       => 'ResultForm',
        SelectedID => $Param{ResultForm} || 'CSV',
        Class      => 'Modernize',
    );

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentTimeTrackingEvaluation',
        Data         => \%Param,
    );
}

1;
