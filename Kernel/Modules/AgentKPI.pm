# --
# Kernel/Modules/AgentKPI.pm
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AgentKPI.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentKPI;

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

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

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');
    my $GroupObject        = $Kernel::OM->Get('Kernel::System::Group');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
    my $StateObject        = $Kernel::OM->Get('Kernel::System::State');
    my $QueueObject        = $Kernel::OM->Get('Kernel::System::Queue');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime'
    );

    # get params
    my %GetParam;

    for my $Key (
        qw(FromDateDay FromDateMonth FromDateYear ToDateDay ToDateMonth ToDateYear FromDateErstYear OhneDatum)
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    if ( $GetParam{OhneDatum} ) {
    	$GetParam{FromDateDay} = '';
    	$GetParam{FromDateMonth} = '';
    	$GetParam{FromDateYear} = '';
    	$GetParam{ToDateDay} = '';
    	$GetParam{ToDateMonth} = '';
    	$GetParam{ToDateYear} = '';
    }

    my @StateIDs = $ParamObject->GetArray( Param => 'StateID' );
    my @QueueIDs = $ParamObject->GetArray( Param => 'QueueID' );

    $Param{FormID} = $Self->{FormID};

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
        YearPeriodPast       => 20,
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
        YearPeriodPast       => 20,
        YearPeriodFuture     => 1,
        DiffTime             => 3600,
        Class                => $Param{Errors}->{ToDateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 0,
    );

    $Param{FromDateErstString} = $LayoutObject->BuildDateSelection(
        Prefix               => 'FromDateErst',
        FromDateErstYear     => $StartYear,
        FromDateErstMonth    => 01,
        FromDateErstDay      => 01,
        Format               => 'DateInputFormat',
        YearPeriodPast       => 20,
        YearPeriodFuture     => 0,
        Validate             => 1,
        ValidateDateInFuture => 0,
    );

    my $openTickets  = '';
    my $closeTickets = '';

    if ( $GetParam{FromDateYear} ) {
        $openTickets = $TicketObject->TicketSearch(
            Result    => 'COUNT',
            TicketCreateTimeNewerDate => "$GetParam{FromDateYear}-$GetParam{FromDateMonth}-$GetParam{FromDateDay} 00:00:00",
            TicketCreateTimeOlderDate => "$GetParam{ToDateYear}-$GetParam{ToDateMonth}-$GetParam{ToDateDay} 00:00:00",
            StateType => ['open','new'],
            UserID    => 1,
        );
    }else{
        $openTickets = $TicketObject->TicketSearch(
            Result    => 'COUNT',
            StateType => ['open','new'],
            UserID    => 1,
        );
    }

    if ( $GetParam{FromDateYear} ) {

        $closeTickets = $TicketObject->TicketSearch(
            Result    => 'COUNT',
            TicketCreateTimeNewerDate => "$GetParam{FromDateYear}-$GetParam{FromDateMonth}-$GetParam{FromDateDay} 00:00:00",
            TicketCreateTimeOlderDate => "$GetParam{ToDateYear}-$GetParam{ToDateMonth}-$GetParam{ToDateDay} 00:00:00",
            StateType => ['closed'],
            UserID    => 1,
        );
    }else{
        $closeTickets = $TicketObject->TicketSearch(
            Result    => 'COUNT',
            StateType => ['closed'],
            UserID    => 1,
        );
    }

    $Param{'openTickets'} = $openTickets;
    $Param{'closeTickets'} = $closeTickets;

    my %StateList = $StateObject->StateList(
        UserID => 1,
        Valid  => 1,
    );

    $Param{StateStrg} = $LayoutObject->BuildSelection(
        Data         => \%StateList,
        Name         => 'StateID',
        Multiple     => 1,
        Size         => 10,
        PossibleNone => 0,
        Sort         => 'AlphanumericKey',
        SelectedIDs   => @StateIDs,
        Translation  => 1,
        Class        => "Modernize",
    );

    my $openTicketState = 0;
    if ( @StateIDs ) {

        for my $StateID ( @StateIDs ) {

            $openTicketState = $TicketObject->TicketSearch(
                Result   => 'COUNT',
                StateIDs => [$StateID],
                UserID   => 1,
            );

            my $State = $StateObject->StateLookup(
                StateID => $StateID,
            );

            if ( $openTicketState >= 1 ) {
                $State = $LayoutObject->{LanguageObject}->Translate($State);
                $Param{'States'} .= '{y: ' . $openTicketState . ', label: "' . $State . '", name: "' . $State . '"},';
            }
            $openTicketState = 0;
        }
    }
    else {

        for my $StateID ( sort keys %StateList ) {

            $openTicketState = $TicketObject->TicketSearch(
                Result => 'COUNT',
                States => [$StateList{$StateID}],
                UserID => 1,
            );
            if ( $openTicketState >= 1 ) {
                $StateList{$StateID} = $LayoutObject->{LanguageObject}->Translate($StateList{$StateID});
                $Param{'States'} .= '{y: ' . $openTicketState . ', label: "' . $StateList{$StateID} . '", name: "' . $StateList{$StateID} . '"},';
            }
            $openTicketState = 0;
        }
    }

    my %Queues = $QueueObject->QueueList( Valid => 1 );

    $Param{QueueStrg} = $LayoutObject->BuildSelection(
        Data         => \%Queues,
        Name         => 'QueueID',
        Multiple     => 1,
        Size         => 10,
        PossibleNone => 0,
        Sort         => 'AlphanumericKey',
        SelectedIDs   => @QueueIDs,
        Translation  => 1,
        Class        => "Modernize",
    );

    my $openTicketQueue = 0;
    if ( @QueueIDs ) {
 
        for my $QueueID ( @QueueIDs ) {

            $openTicketQueue = $TicketObject->TicketSearch(
                Result => 'COUNT',
                QueueIDs => [$QueueID],
                StateType => ['open','new'],
                UserID => 1,
            );

            my $Queue = $QueueObject->QueueLookup( QueueID => $QueueID );

            if ( $openTicketQueue >= 1 ) {
                $Queue = $LayoutObject->{LanguageObject}->Translate($Queue);
                $Param{'Queues'} .= '{y: ' . $openTicketQueue . ', label: "' . $Queue . '", name: "' . $Queue . '"},';
            }
            $openTicketQueue = 0;
        }
    }
    else {
 
        for my $QueueID ( sort keys %Queues ) {

            $openTicketQueue = $TicketObject->TicketSearch(
                Result => 'COUNT',
                Queues => [$Queues{$QueueID}],
                StateType => ['open','new'],
                UserID => 1,
            );

            if ( $openTicketQueue >= 1 ) {
                $Queues{$QueueID} = $LayoutObject->{LanguageObject}->Translate($Queues{$QueueID});
                $Param{'Queues'} .= '{y: ' . $openTicketQueue . ', label: "' . $Queues{$QueueID} . '", name: "' . $Queues{$QueueID} . '"},';
            }
            $openTicketQueue = 0;
        }
    }

    my $StartDate = "";
    my $EndDate   = "";
    if ( !$Param{StartMonth} ) {
        my ($Sec, $Min, $Hour, $Day, $Month, $Year, $WeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $TimeObject->SystemTime(),
        );
    	$StartDate = "$Year-01-01 00:00:00";
    }else {
    	$StartDate = "$Param{StartYear}-$Param{StartMonth}-$Param{StartDay} 00:00:00";
    }

    if ( !$Param{EndMonth} ) {
    	$EndDate = $TimeObject->CurrentTimestamp();
    }else {
    	$EndDate = "$Param{EndYear}-$Param{EndMonth}-$Param{EndDay} 23:59:59";
    }

    my @closeTickets = $TicketObject->TicketSearch(
        Result                   => 'ARRAY',
        StateType                => ['closed'],
        TicketCloseTimeNewerDate => $StartDate,
        TicketCloseTimeOlderDate => $EndDate,
        UserID                   => 1,
    );

    my $CloseTime8H  = 0;
    my $CloseTime1T  = 0;
    my $CloseTime3T  = 0;
    my $CloseTime5T  = 0;
    my $CloseTime10T = 0;
    my $CloseTime30T = 0;
    my $CloseTime88  = 0;

    for my $TicketID ( @closeTickets ) {

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 0,
            UserID        => 1,
            Silent        => 0,
        );

        my $StartTime = $TimeObject->TimeStamp2SystemTime(
            String => $Ticket{Created},
        );
        my $EndTime = $TimeObject->TimeStamp2SystemTime(
            String => $Ticket{Changed},
        );

        my $Worktime = $EndTime - $StartTime;

        if ( $Worktime >= 1 && $Worktime <= 28800 ) {
        	$CloseTime8H ++;
        }
        if ( $Worktime >= 28801 && $Worktime <= 86400 ) {
        	$CloseTime1T ++;
        }        
        if ( $Worktime >= 86401 && $Worktime <= 259200 ) {
        	$CloseTime3T ++;
        }        
        if ( $Worktime >= 259201 && $Worktime <= 432000 ) {
        	$CloseTime5T ++;
        }
        if ( $Worktime >= 432001 && $Worktime <= 864000 ) {
        	$CloseTime10T ++;
        }
        if ( $Worktime >= 864001 && $Worktime <= 2592000 ) {
        	$CloseTime30T ++;
        }
        if ( $Worktime >= 2592001 ) {
        	$CloseTime88 ++;
        }
    }

    $Param{'CloseTime'} .= '{y: ' . $CloseTime8H . ', label: "< 8 Stunden"},';
    $Param{'CloseTime'} .= '{y: ' . $CloseTime1T . ', label: "< 24 Stunden"},';
    $Param{'CloseTime'} .= '{y: ' . $CloseTime3T . ', label: "< 3 Tage"},';
    $Param{'CloseTime'} .= '{y: ' . $CloseTime5T . ', label: "< 5 Tage"},';
    $Param{'CloseTime'} .= '{y: ' . $CloseTime10T . ', label: "< 10 Tage"},';
    $Param{'CloseTime'} .= '{y: ' . $CloseTime30T . ', label: "< 30 Tage"},';
    $Param{'CloseTime'} .= '{y: ' . $CloseTime88 . ', label: "> 30 Tage"},';


    my $AnswerTime2H  = 0;
    my $AnswerTime8H  = 0;
    my $AnswerTime1T  = 0;
    my $AnswerTime3T  = 0;
    my $AnswerTime5T  = 0;
    my $AnswerTime10T = 0;
    my $AnswerTime30T = 0;
    my $AnswerTime88  = 0;

    my @openTickets = $TicketObject->TicketSearch(
        Result    => 'ARRAY',
        StateType => ['open','new'],
        UserID    => 1,
    );

    for my $TicketID ( @openTickets ) {

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 0,
            UserID        => 1,
            Silent        => 0,
        );

        my @HistoryLines = $TicketObject->HistoryGet(
            TicketID => $TicketID,
            UserID   => 1,
        );

        my $StartTime = $TimeObject->TimeStamp2SystemTime(
            String => $Ticket{Created},
        );

        for my $HistoryDataTmp ( @HistoryLines ) {

            my %HistoryData = %{$HistoryDataTmp};
            if ( $HistoryData{HistoryType} eq "SendAnswer" ) {

                my $EndTime = $TimeObject->TimeStamp2SystemTime(
                    String => $HistoryData{CreateTime},
                );

                my $Worktime = $EndTime - $StartTime;

                if ( $Worktime >= 1 && $Worktime <= 7200 ) {
        	        $AnswerTime2H ++;
                }
                if ( $Worktime >= 7201 && $Worktime <= 28800 ) {
        	        $AnswerTime8H ++;
                }
                if ( $Worktime >= 28801 && $Worktime <= 86400 ) {
        	        $AnswerTime1T ++;
                }        
                if ( $Worktime >= 86401 && $Worktime <= 259200 ) {
        	        $AnswerTime3T ++;
                }        
                if ( $Worktime >= 259201 && $Worktime <= 432000 ) {
        	        $AnswerTime5T ++;
                }
                if ( $Worktime >= 432001 && $Worktime <= 864000 ) {
        	        $AnswerTime10T ++;
                }
                if ( $Worktime >= 864001 && $Worktime <= 2592000 ) {
        	        $AnswerTime30T ++;
                }
                if ( $Worktime >= 2592001 ) {
        	        $AnswerTime88 ++;
                }
            }
        }
    }

    $Param{'AnswerTime'} .= '{y: ' . $AnswerTime2H . ', label: "< 2 Stunden"},';
    $Param{'AnswerTime'} .= '{y: ' . $AnswerTime8H . ', label: "< 8 Stunden"},';
    $Param{'AnswerTime'} .= '{y: ' . $AnswerTime1T . ', label: "< 24 Stunden"},';
    $Param{'AnswerTime'} .= '{y: ' . $AnswerTime3T . ', label: "< 3 Tage"},';
    $Param{'AnswerTime'} .= '{y: ' . $AnswerTime5T . ', label: "< 5 Tage"},';
    $Param{'AnswerTime'} .= '{y: ' . $AnswerTime10T . ', label: "< 10 Tage"},';
    $Param{'AnswerTime'} .= '{y: ' . $AnswerTime30T . ', label: "< 30 Tage"},';
    $Param{'AnswerTime'} .= '{y: ' . $AnswerTime88 . ', label: "> 30 Tage"},';

    my $StartYearSearch = '';
    my $EndYearSearch   = '';

    if ( $GetParam{FromDateErstYear} ) {
        $StartYearSearch = "$GetParam{FromDateErstYear}-01-01 00:00:00";
        $EndYearSearch   = "$GetParam{FromDateErstYear}-12-31 00:00:00";
    }
    else {
        $StartYearSearch = "$StartYear-01-01 00:00:00";
        $EndYearSearch   = "$StartYear-12-31 00:00:00";
    }

    my $openTicketsJan  = 0;
    my $openTicketsFeb  = 0;
    my $openTicketsMar  = 0;
    my $openTicketsApr  = 0;
    my $openTicketsMai  = 0;
    my $openTicketsJun  = 0;
    my $openTicketsJul  = 0;
    my $openTicketsAug  = 0;
    my $openTicketsSept = 0;
    my $openTicketsOkt  = 0;
    my $openTicketsNov  = 0;
    my $openTicketsDez  = 0;

    my @openTicketsSearch = $TicketObject->TicketSearch(
        Result                    => 'ARRAY',
        TicketCreateTimeNewerDate => $StartYearSearch,
        TicketCreateTimeOlderDate => $EndYearSearch,
        UserID                    => 1,
    );

    for my $TicketID ( @openTicketsSearch ) {

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 0,
            UserID        => 1,
            Silent        => 0,
        );

        my @CreateSplit = split('-', $Ticket{Created});

        if ( $CreateSplit[1] eq "01" ) {
        	$openTicketsJan ++;
        }
        if ( $CreateSplit[1] eq "02" ) {
        	$openTicketsFeb ++;
        }
        if ( $CreateSplit[1] eq "03" ) {
        	$openTicketsMar ++;
        }
        if ( $CreateSplit[1] eq "04" ) {
        	$openTicketsApr ++;
        }
        if ( $CreateSplit[1] eq "05" ) {
        	$openTicketsMai ++;
        }
        if ( $CreateSplit[1] eq "06" ) {
        	$openTicketsJun ++;
        }
        if ( $CreateSplit[1] eq "07" ) {
        	$openTicketsJul ++;
        }
        if ( $CreateSplit[1] eq "08" ) {
        	$openTicketsAug ++;
        }
        if ( $CreateSplit[1] eq "09" ) {
        	$openTicketsSept ++;
        }
        if ( $CreateSplit[1] eq "10" ) {
        	$openTicketsOkt ++;
        }
        if ( $CreateSplit[1] eq "11" ) {
        	$openTicketsNov ++;
        }
        if ( $CreateSplit[1] eq "12" ) {
        	$openTicketsDez ++;
        }
    }

    $Param{'OpenTicketsYear'} .= '{label: "Jan", y: ' . $openTicketsJan . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Feb", y: ' . $openTicketsFeb . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Mar", y: ' . $openTicketsMar . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Apr", y: ' . $openTicketsApr . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Mai", y: ' . $openTicketsMai . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Jun", y: ' . $openTicketsJun . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Jul", y: ' . $openTicketsJul . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Aug", y: ' . $openTicketsAug . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Sept", y: ' . $openTicketsSept . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Okt", y: ' . $openTicketsOkt . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Nov", y: ' . $openTicketsNov . ',},';
    $Param{'OpenTicketsYear'} .= '{label: "Dez", y: ' . $openTicketsDez . '}';


    my $closeTicketsJan = 0;
    my $closeTicketsFeb = 0;
    my $closeTicketsMar = 0;
    my $closeTicketsApr = 0;
    my $closeTicketsMai = 0;
    my $closeTicketsJun = 0;
    my $closeTicketsJul = 0;
    my $closeTicketsAug = 0;
    my $closeTicketsSept = 0;
    my $closeTicketsOkt = 0;
    my $closeTicketsNov = 0;
    my $closeTicketsDez = 0;

    my @closeTicketsSearch = $TicketObject->TicketSearch(
        Result                   => 'ARRAY',
        TicketCloseTimeNewerDate => $StartYearSearch,
        TicketCloseTimeOlderDate => $EndYearSearch,
        UserID                   => 1,
    );

    for my $TicketID ( @closeTicketsSearch ) {

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 0,
            UserID        => 1,
            Silent        => 0,
        );

        my @CreateSplit = split('-', $Ticket{Changed});

        if ( $CreateSplit[1] eq "01" ) {
        	$closeTicketsJan ++;
        }
        if ( $CreateSplit[1] eq "02" ) {
        	$closeTicketsFeb ++;
        }
        if ( $CreateSplit[1] eq "03" ) {
        	$closeTicketsMar ++;
        }
        if ( $CreateSplit[1] eq "04" ) {
        	$closeTicketsApr ++;
        }
        if ( $CreateSplit[1] eq "05" ) {
        	$closeTicketsMai ++;
        }
        if ( $CreateSplit[1] eq "06" ) {
        	$closeTicketsJun ++;
        }
        if ( $CreateSplit[1] eq "07" ) {
        	$closeTicketsJul ++;
        }
        if ( $CreateSplit[1] eq "08" ) {
        	$closeTicketsAug ++;
        }
        if ( $CreateSplit[1] eq "09" ) {
        	$closeTicketsSept ++;
        }
        if ( $CreateSplit[1] eq "10" ) {
        	$closeTicketsOkt ++;
        }
        if ( $CreateSplit[1] eq "11" ) {
        	$closeTicketsNov ++;
        }
        if ( $CreateSplit[1] eq "12" ) {
        	$closeTicketsDez ++;
        }
    }

    $Param{'CloseTicketsYear'} .= '{label: "Jan", y: ' . $closeTicketsJan . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Feb", y: ' . $closeTicketsFeb . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Mar", y: ' . $closeTicketsMar . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Apr", y: ' . $closeTicketsApr . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Mai", y: ' . $closeTicketsMai . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Jun", y: ' . $closeTicketsJun . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Jul", y: ' . $closeTicketsJul . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Aug", y: ' . $closeTicketsAug . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Sept", y: ' . $closeTicketsSept . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Okt", y: ' . $closeTicketsOkt . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Nov", y: ' . $closeTicketsNov . ',},';
    $Param{'CloseTicketsYear'} .= '{label: "Dez", y: ' . $closeTicketsDez . '}';


    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => $Self->{Action},
        Data         => \%Param
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

1;
