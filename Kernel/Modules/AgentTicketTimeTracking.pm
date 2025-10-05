# --
# Kernel/Modules/AgentTicketTimeTracking.pm - the OTRS::ITSM config item search module
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de/
# --
# $Id: AgentTicketTimeTracking.pm,v 1.2 2018/12/02 14:52:26 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketTimeTracking;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
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

    # get needed objects
    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject               = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject               = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TimeTrackingCategoryObject = $Kernel::OM->Get('Kernel::System::TimeTrackingCategory');
    my $TimeTrackingArticleObject  = $Kernel::OM->Get('Kernel::System::TimeTrackingArticle');

    # get params
    my %GetParam;
    for my $Key (
        qw(
        ID TicketID TimeTrackingID TimeTrackingTime Subject TimeTrackingArticleID Day Month Year Hour Minute Filename FileUpload
        )
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    $GetParam{CreateTime}
        = "$GetParam{Year}-$GetParam{Month}-$GetParam{Day} $GetParam{Hour}:$GetParam{Minute}:00";

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $GetParam{TicketID},
        DynamicFields => 0,
    );

    $GetParam{TimeTrackingTime} =~ s/\,/\./g;

    $GetParam{CustomerID} = $Ticket{CustomerID};

    if ( $Self->{Subaction} eq 'Store' ) {

        # store action
        my %Error;

        # check subject
        if ( !$GetParam{Subject} ) {
            $Error{'SubjectInvalid'} = 'ServerError';
        }

        # check ServiceCode
        if ( !$GetParam{TimeTrackingID} ) {
            $Error{'TimeTrackingIDInvalid'} = 'ServerError';
        }

        # check ServiceTime
        if ( !$GetParam{TimeTrackingTime} ) {
            $Error{'TimeTrackingTime'} = 'ServerError';
        }

        if ( $GetParam{TimeTrackingTime} !~ /^[\d|\.]+$/ ) {
            $Error{'TimeTrackingTimeErrorNumbers'} = 'Error';
        }

        # check errors
        if (%Error) {

            my $Output = $LayoutObject->Header(
                Type      => 'Small',
                Value     => $GetParam{TicketID},
                BodyClass => 'Popup',
            );
            $Output .= $Self->_Mask(
                %GetParam,
                %Error,
            );
            $Output .= $LayoutObject->Footer(
                Type => 'Small',
            );
            return $Output;
        }

        # add ServiceCodeArticle
        my $ServiceCodeArticle = $TimeTrackingArticleObject->TimeTrackingArticleAdd(
            %GetParam,
            UserID => $Self->{UserID}
        );

        my $From = "\"$Self->{UserFullname}\" <$Self->{UserEmail}>";

        my $Subject  = "";
        my $SubjectA = $LayoutObject->{LanguageObject}->Translate('Time tracking');
        $Subject = $SubjectA . ': ' . $GetParam{Subject} . ' - ' . $GetParam{TimeTrackingTime};

        my $ArticleID
            = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
            TicketID             => $GetParam{TicketID},
            SenderType           => 'agent',
            IsVisibleForCustomer => 0,
            From                 => $From,
            Subject              => $Subject,
            Body                 => $Subject,
            Charset              => '$LayoutObject->{UserCharset}',
            MimeType             => 'text/plain',
            HistoryType          => 'AddNote',
            HistoryComment       => '%%Note',
            UserID               => $Self->{UserID},
            );

        my $Output = $LayoutObject->Header(
            Type      => 'Small',
            Value     => $GetParam{TicketID},
            BodyClass => 'Popup',
        );
        $Output .= $Self->_Mask(
            TicketID => $GetParam{TicketID},
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;

    }
    elsif ( $Self->{Subaction} eq 'Change' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';

        my %TimeTrackingArticle = $TimeTrackingArticleObject->TimeTrackingArticleGet(
            ID => $ID,
        );
        my %Category = $TimeTrackingCategoryObject->CategoryGet(
            ID => $TimeTrackingArticle{TimeTrackingID},
        );
        $TimeTrackingArticle{TimeTracking} = $Category{Name};

        my $Output = $LayoutObject->Header(
            Type      => 'Small',
            Value     => $TimeTrackingArticle{TicketID},
            BodyClass => 'Popup',
        );
        $Output .= $Self->_Mask(
            ActionType => 'StoreChange',
            ID         => $ID,
            %TimeTrackingArticle,
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'StoreChange' ) {

        # store action
        my %Error;

        # check subject
        if ( !$GetParam{Subject} ) {
            $Error{'SubjectInvalid'} = 'ServerError';
        }

        # check TimeTracking
        if ( !$GetParam{ID} ) {
            $Error{'TimeTrackingIDInvalid'} = 'ServerError';
        }

        # check TimeTrackingTime
        if ( !$GetParam{TimeTrackingTime} ) {
            $Error{'TimeTrackingTimeInvalid'} = 'ServerError';
        }

        if ( $GetParam{TimeTrackingTime} !~ /^[\d|\.]+$/ ) {
            $Error{'TimeTrackingTimeErrorNumbers'} = 'Error';
        }

        # check errors
        if (%Error) {

            my $Output = $LayoutObject->Header(
                Type      => 'Small',
                Value     => $GetParam{TicketID},
                BodyClass => 'Popup',
            );
            $Output .= $Self->_Mask(
                %GetParam,
                %Error,
            );
            $Output .= $LayoutObject->Footer(
                Type => 'Small',
            );
            return $Output;
        }

        # add TimeTrackingArticle
        my $TimeTrackingArticle = $TimeTrackingArticleObject->TimeTrackingArticleUpdate(
            %GetParam,
            UserID => $Self->{UserID}
        );

        my $From = "\"$Self->{UserFullname}\" <$Self->{UserEmail}>";

        my $Subject  = "";
        my $SubjectA = $LayoutObject->{LanguageObject}->Translate('Change time tracking');
        $Subject = $SubjectA . ': ' . $GetParam{Subject} . ' - ' . $GetParam{TimeTrackingTime};

        my $ArticleID
            = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
            TicketID             => $GetParam{TicketID},
            SenderType           => 'agent',
            IsVisibleForCustomer => 0,
            From                 => $From,
            Subject              => $Subject,
            Body                 => $Subject,
            Charset              => '$LayoutObject->{UserCharset}',
            MimeType             => 'text/plain',
            HistoryType          => 'AddNote',
            HistoryComment       => '%%Note',
            UserID               => $Self->{UserID},
            );

        my $Output = $LayoutObject->Header(
            Type      => 'Small',
            Value     => $GetParam{TicketID},
            BodyClass => 'Popup',
        );
        $Output .= $Self->_Mask(
            TicketID => $GetParam{TicketID},
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;

    }
    elsif ( $Self->{Subaction} eq 'Unterschrift' ) {

        # print form ...
        my $Output = $LayoutObject->Header(
            Type      => 'Small',
            Value     => $Ticket{TicketNumber},
            BodyClass => 'Popup',
        );
        $Output .= $Self->_MaskUnterschrift(
            TicketID => $GetParam{TicketID},
            ID       => $GetParam{ID},
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;

    }
    elsif ( $Self->{Subaction} eq 'UnterschriftSave' ) {

        my %UploadStuff = ();

        $UploadStuff{Content} = $GetParam{FileUpload};
        $UploadStuff{ContentType} = 'image/png';
        $UploadStuff{Filename} = $GetParam{Filename} . 'png';

        # add unterschrift
        my $IconID = $TimeTrackingArticleObject->TimeTrackingArticleUnterschrift(
            %GetParam,
            %UploadStuff,
            UserID => 1,
        );

        # print form ...
        my $Output = $LayoutObject->Header(
            Type      => 'Small',
            Value     => $Ticket{TicketNumber},
            BodyClass => 'Popup',
        );
        $Output .= $Self->_Mask(
            TicketID => $GetParam{TicketID},
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;

    }
    elsif ( $Self->{Subaction} eq 'Delete' ) {

        my $Delete = $TimeTrackingArticleObject->TimeTrackingArticleUnterschriftDelete(
            ID       => $GetParam{ID},
            TicketID => $GetParam{TicketID},
        );

        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => ($Delete) ? $GetParam{TicketID} : 0,
            Type        => 'inline',
            NoCache     => 1,
        );

    }
    else {

        # print form ...
        my $Output = $LayoutObject->Header(
            Type      => 'Small',
            Value     => $Ticket{TicketNumber},
            BodyClass => 'Popup',
        );
        $Output .= $Self->_Mask(
            TicketID => $GetParam{TicketID},
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;

    }

}

sub _Mask {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject               = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TimeTrackingCategoryObject = $Kernel::OM->Get('Kernel::System::TimeTrackingCategory');
    my $TimeTrackingArticleObject  = $Kernel::OM->Get('Kernel::System::TimeTrackingArticle');
    my $UserObject                 = $Kernel::OM->Get('Kernel::System::User');

    if ( $Param{ActionType} ) {
        $Param{ActionType} = $Param{ActionType};
    }
    else {
        $Param{ActionType} = 'Store';
    }

    # prepare errors!
    if ( $Param{Error} ) {
        for my $KeyError ( sort keys %{ $Param{Error} } ) {
            $Param{$KeyError}
                = '* ' . $LayoutObject->Ascii2Html( Text => $Param{Error}->{$KeyError} );
        }
    }

    if ( $Param{TimeTrackingTimeErrorNumbers} ) {

        $LayoutObject->Block(
            Name => 'TimeTrackingTimeErrorNumbers',
            Data => \%Param,
        );
    }

    my %Ticket = $TicketObject->TicketGet( TicketID => $Param{TicketID} );

    my %Category = $TimeTrackingCategoryObject->CategoryList(
        UserID => $Self->{UserID},
        Valid  => 1,
    );
    $Param{TimeTrackingStrg} = $LayoutObject->BuildSelection(
        Class      => 'Validate_Required Modernize ' . ( $Param{Error}->{CategoryIDInvalid} || '' ),
        Data         => \%Category,
        Name         => 'TimeTrackingID',
        SelectedID   => $Param{TimeTrackingID},
        PossibleNone => 1,
        Sort         => 'AlphanumericValue',
        Translation  => 0,
    );

    my %TimeTrackingArticleSet = ();

    if ( $Param{ID} ) {
        %TimeTrackingArticleSet = $TimeTrackingArticleObject->TimeTrackingArticleGet(
            ID => $Param{ID},
        );
    }

    my @SetDateSplit     = split( / /, $TimeTrackingArticleSet{CreateTime} );
    my @SetDateSplitYear = split( /-/, $SetDateSplit[0] );
    my @SetDateSplitHour = split( /:/, $SetDateSplit[1] );

    $Param{DateString} = $LayoutObject->BuildDateSelection(
        %TimeTrackingArticleSet,
        Year                 => $SetDateSplitYear[0],
        Month                => $SetDateSplitYear[1],
        Day                  => $SetDateSplitYear[2],
        Hour                 => $SetDateSplitHour[0],
        Minute               => $SetDateSplitHour[1],
        Format               => 'DateInputFormatLong',
        YearPeriodPast       => 1,
        YearPeriodFuture     => 5,
        DiffTime             => 0,
        Class                => $Param{DateInvalid} || ' ',
        Validate             => 1,
        ValidateDateInFuture => 0,
    );

    my %TimeTrackingArticleList = $TimeTrackingArticleObject->TimeTrackingArticleList(
        TicketID => $Param{TicketID},
    );

    my $TimeTrackingValue     = 0;
    my $TimeTrackingTimeValue = 0;

    for my $TimeTrackingArticleID ( sort keys %TimeTrackingArticleList ) {

        $TimeTrackingValue ++;

        my %TimeTrackingArticle = $TimeTrackingArticleObject->TimeTrackingArticleGet(
            ID => $TimeTrackingArticleID,
        );

        $TimeTrackingTimeValue         = $TimeTrackingTimeValue + $TimeTrackingArticle{TimeTrackingTime};
        $TimeTrackingArticle{CreateBy}
            = $UserObject->UserName( UserID => $TimeTrackingArticle{CreateBy} );

        my %Category = $TimeTrackingCategoryObject->CategoryGet(
            ID => $TimeTrackingArticle{TimeTrackingID},
        );
        $TimeTrackingArticle{TimeTracking} = $Category{Name};


        $LayoutObject->Block(
            Name => 'OverviewResultRow',
            Data => {
                %TimeTrackingArticle,
            },
        );

        $TimeTrackingArticle{Signature} = '<a href="index.pl?Action=AgentTicketTimeTracking;ID=' . $TimeTrackingArticle{ID} . ';TicketID=' . $Param{TicketID} . ';Subaction=Unterschrift">Unterschrift erfassen</a>';

        if ( !$TimeTrackingArticle{Content} ) {
            $LayoutObject->Block(
                Name => 'OverviewResultRowSignature',
                Data => {
                    %TimeTrackingArticle,
                },
            );
        }
        else {

            $LayoutObject->Block(
                Name => 'OverviewResultRowImage',
                Data => {
                    %TimeTrackingArticle,
                },
            );
        }

    }

    $LayoutObject->Block(
        Name => 'OverviewResultRowAdded',
        Data => {
            TimeTrackingValue     => $TimeTrackingValue,
            TimeTrackingTimeValue => $TimeTrackingTimeValue,
        },
    );


    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentTicketTimeTracking',
        Data         => \%Param
    );

}

sub _MaskUnterschrift {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject               = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TimeTrackingCategoryObject = $Kernel::OM->Get('Kernel::System::TimeTrackingCategory');
    my $TimeTrackingArticleObject  = $Kernel::OM->Get('Kernel::System::TimeTrackingArticle');
    my $UserObject                 = $Kernel::OM->Get('Kernel::System::User');

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentTicketTimeTrackingUnterschrift',
        Data         => \%Param
    );

}

1;
