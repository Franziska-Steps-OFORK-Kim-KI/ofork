# --
# Kernel/Modules/RequestCustomerTicketMessageBlock.pm - to handle customer messages
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: RequestCustomerTicketMessageBlock.pm,v 1.21 2016/12/13 14:37:23 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::RequestCustomerTicketMessageBlock;

use strict;
use warnings;

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

    my $TypeObject                 = $Kernel::OM->Get('Kernel::System::Type');
    my $RequestObject               = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFieldsObject         = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestFormObject           = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $TicketRequestObject        = $Kernel::OM->Get('Kernel::System::TicketRequest');
    my $TimeObject                 = $Kernel::OM->Get('Kernel::System::Time');
    my $LinkObject                 = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $GroupObject                = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject                 = $Kernel::OM->Get('Kernel::System::User');
    my $CustomerUserObject         = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $SendmailObject             = $Kernel::OM->Get('Kernel::System::Email');
    my $RequestFormBlockObject      = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $QueueObject                = $Kernel::OM->Get('Kernel::System::Queue');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $Self->{Subaction} eq "ShowBlock" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(RequestID RequestFormID RequestFormValueID RequestFormBlockIDs NewBlockValues)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my @NewValueSplit = split( /\#/, $GetParam{NewBlockValues} );

        for my $ValueSplit (@NewValueSplit) {
            my @SetValueSplit = split( /\=/, $ValueSplit );
            $GetParam{ $SetValueSplit[1] } = $SetValueSplit[2];
        }

        if ( $GetParam{RequestFormBlockIDs} ) {
            my @RequestFormIDArray = split( /,/, $GetParam{RequestFormBlockIDs} );
            for my $NewValues (@RequestFormIDArray) {
                my @FeldCheck = split( /-/, $NewValues );
                if (
                    $FeldCheck[1]
                    && ( $FeldCheck[1] !~ /[a-z]/ig && $FeldCheck[0] !~ /Beteiligt/ )
                    )
                {
                    my %RequestForm = $RequestFormBlockObject->RequestFormBlockGet(
                        RequestFormID => $FeldCheck[1],
                    );
                    my %RequestFields = $RequestFieldsObject->RequestFieldsGet(
                        RequestFieldsID => $RequestForm{FeldID},
                    );
                    if ( $RequestFields{Typ} eq "Multiselect" ) {
                        my @MultiArray;
                        for my $ParamNew (
                            qw($NewValues)
                            )
                        {
                            @MultiArray = $ParamObject->GetArray( Param => $NewValues );
                        }
                        for my $NewValue (@MultiArray) {
                            $GetParam{$NewValues} .= "$NewValue,";
                        }
                    }
                    else {
                        $GetParam{$NewValues} = $ParamObject->GetParam( Param => $NewValues );
                        if ( $RequestFields{Typ} eq "Checkbox" && !$GetParam{$NewValues} ) {
                            $GetParam{$NewValues} = "Nein";
                        }
                        if (
                            $RequestFields{Typ} eq "Checkbox"
                            && $GetParam{$NewValues}
                            && ( $GetParam{$NewValues} ne "Nein" )
                            )
                        {
                            $GetParam{$NewValues} = "Ja";
                        }
                        elsif ( !$GetParam{$NewValues} ) {
                            $GetParam{$NewValues} = "Nein";
                        }
                    }
                }
                else {
                    $GetParam{$NewValues} = $ParamObject->GetParam( Param => $NewValues );
                    if ( !$GetParam{$NewValues} ) {
                        $GetParam{$NewValues} = "-";
                    }
                }
            }
        }

        # html output
        my $Output = $Self->_MaskNew(
            RequestID          => $GetParam{RequestID},
            RequestFormID      => $GetParam{RequestFormID},
            RequestFormValueID => $GetParam{RequestFormValueID},
            %Param,
            %GetParam,
        );

        # get output back
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $Output,
            Type        => 'inline',
            NoCache     => '1',
        );
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $TypeObject                 = $Kernel::OM->Get('Kernel::System::Type');
    my $RequestObject               = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFieldsObject         = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestFormObject           = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $TicketRequestObject        = $Kernel::OM->Get('Kernel::System::TicketRequest');
    my $TimeObject                 = $Kernel::OM->Get('Kernel::System::Time');
    my $LinkObject                 = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $GroupObject                = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject                 = $Kernel::OM->Get('Kernel::System::User');
    my $CustomerUserObject         = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $SendmailObject             = $Kernel::OM->Get('Kernel::System::Email');
    my $RequestFormBlockObject      = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $QueueObject                = $Kernel::OM->Get('Kernel::System::Queue');
    my $ConfigObject               = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %Request = $RequestObject->RequestGet(
        RequestID => $Param{RequestID},
    );

    # output overview result
    $LayoutObject->Block(
        Name => 'OverviewFelderList',
        Data => {
            %Param,
        },
    );

    my %RequestFormList = $RequestFormBlockObject->RequestFormBlockList(
        RequestFormID      => $Param{RequestFormID},
        RequestFormValueID => $Param{RequestFormValueID},
        RequestID          => $Param{RequestID},
        UserID            => 1,
    );

    my $IfValue;
    my $CheckFields = 0;
    for my $RequestFormListID (
        sort { $RequestFormList{$a} <=> $RequestFormList{$b} }
        keys %RequestFormList
        )
    {

        #get RequestForm
        my %RequestForm = $RequestFormBlockObject->RequestFormBlockGet(
            RequestFormID => $RequestFormListID,
        );

        $LayoutObject->Block(
            Name => 'OverviewListFelderRow',
            Data => {
                %Param,
            },
        );

        $RequestForm{Kunden} = 1;

        $Param{ToolTip}       = $RequestForm{ToolTip};
        $Param{FeldAktuellID} = $RequestFormListID;

        if ( !$RequestForm{Headline} && !$RequestForm{Description} ) {


                #get RequestFeld
                my %RequestFields = $RequestFieldsObject->RequestFieldsGet(
                    RequestFieldsID => $RequestForm{FeldID},
                );

                #get RequestFieldsWerte
                my %RequestFieldsWerte = $RequestFieldsObject->RequestFieldsWerteGet(
                    ID => $RequestFields{ID},
                );

                #get list
                my %RequestFieldsListe = $RequestFieldsObject->RequestFieldsWerteList(
                    FeldID => $RequestForm{FeldID},
                );

                my %RequestWerteDropdown = ();
                if (%RequestFieldsListe) {
                    for my $RequestFieldsWerteID ( sort keys %RequestFieldsListe ) {

                        #get RequestFieldsWerte
                        my %RequestFieldsWerte = $RequestFieldsObject->RequestFieldsWerteGet(
                            ID => $RequestFieldsWerteID,
                        );
                        $RequestWerteDropdown{ $RequestFieldsWerte{Schluessel} }
                            = $RequestFieldsWerte{Inhalt};
                    }
                }

                $Param{FeldLabeling} = $RequestFields{Labeling};
                $Param{FeldName}         = $RequestFields{Name};

                if ( $RequestFields{Typ} eq "Multiselect" && $RequestForm{RequiredField} == 1 ) {

                    my @DefaultvalueValue;
                    if ( $RequestFields{Defaultvalue} ) {
                        @DefaultvalueValue = split( /,/, $RequestFields{Defaultvalue} );
                    }

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    $IfValue = $RequestFields{Name} . '-' . $RequestFormListID;
                    if ( $Param{$IfValue} ) {
                        @DefaultvalueValue = split( /,/, $Param{$IfValue} );
                    }
                    $Param{FeldName} = $RequestFields{Name} . '-' . $RequestFormListID;

                    if ( $RequestFields{LeerWert} && $RequestFields{LeerWert} == 2 ) {
                        $RequestFields{LeerWert} = '';
                    }

                    #generate output
                    $Param{FeldNameStrg} = $LayoutObject->BuildSelection(
                        Data         => \%RequestWerteDropdown,
                        Name         => $RequestFields{Name} . '-' . $RequestFormListID,
                        PossibleNone => $RequestFields{LeerWert},
                        Multiple     => 1,
                        Size         => 5,
                        Class        => 'Validate_Required',
                        SelectedID   => \@DefaultvalueValue,
                        Translation  => 1,
                        Max          => 200,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderMultiselectRequired',
                        Data => {
                            %Param,
                        },
                    );
                }
                if ( $RequestFields{Typ} eq "Multiselect" && $RequestForm{RequiredField} == 2 ) {

                    my @DefaultvalueValue;
                    if ( $RequestFields{Defaultvalue} ) {
                        @DefaultvalueValue = split( /,/, $RequestFields{Defaultvalue} );
                    }

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    $IfValue = $RequestFields{Name} . '-' . $RequestFormListID;
                    if ( $Param{$IfValue} ) {
                        @DefaultvalueValue = split( /,/, $Param{$IfValue} );
                    }
                    $Param{FeldName} = $RequestFields{Name} . '-' . $RequestFormListID;

                    if ( $RequestFields{LeerWert} && $RequestFields{LeerWert} == 2 ) {
                        $RequestFields{LeerWert} = '';
                    }

                    #generate output
                    $Param{FeldNameStrg} = $LayoutObject->BuildSelection(
                        Data         => \%RequestWerteDropdown,
                        Name         => $RequestFields{Name} . '-' . $RequestFormListID,
                        PossibleNone => $RequestFields{LeerWert},
                        Multiple     => 1,
                        Size         => 5,
                        Class        => 'W50pc',
                        SelectedID   => \@DefaultvalueValue,
                        Translation  => 1,
                        Max          => 200,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderMultiselect',
                        Data => {
                            %Param,
                        },
                    );
                }

                if ( $RequestFields{Typ} eq "Dropdown" && $RequestForm{RequiredField} == 1 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    $IfValue = $RequestFields{Name} . '-' . $RequestFormListID;
                    if ( $Param{$IfValue} ) {
                        $RequestFields{Defaultvalue} = $Param{$IfValue};
                    }
                    $Param{FeldName} = $RequestFields{Name} . '-' . $RequestFormListID;

                    if ( $RequestFields{LeerWert} && $RequestFields{LeerWert} == 2 ) {
                        $RequestFields{LeerWert} = '';
                    }

                    #generate output
                    $Param{FeldNameStrg} = $LayoutObject->BuildSelection(
                        Data         => \%RequestWerteDropdown,
                        Name         => $RequestFields{Name} . '-' . $RequestFormListID,
                        PossibleNone => $RequestFields{LeerWert},
                        Size         => 1,
                        Class        => 'Validate_Required',
                        SelectedID   => $RequestFields{Defaultvalue},
                        Translation  => 1,
                        Max          => 200,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderDropdownRequired',
                        Data => {
                            %Param,
                        },
                    );
                }
                if ( $RequestFields{Typ} eq "Dropdown" && $RequestForm{RequiredField} == 2 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    $IfValue = $RequestFields{Name} . '-' . $RequestFormListID;
                    if ( $Param{$IfValue} ) {
                        $RequestFields{Defaultvalue} = $Param{$IfValue};
                    }
                    $Param{FeldName} = $RequestFields{Name} . '-' . $RequestFormListID;

                    if ( $RequestFields{LeerWert} && $RequestFields{LeerWert} == 2 ) {
                        $RequestFields{LeerWert} = '';
                    }

                    #generate output
                    $Param{FeldNameStrg} = $LayoutObject->BuildSelection(
                        Data         => \%RequestWerteDropdown,
                        Name         => $RequestFields{Name} . '-' . $RequestFormListID,
                        PossibleNone => $RequestFields{LeerWert},
                        Size         => 1,
                        Class        => 'W50pc',
                        SelectedID   => $RequestFields{Defaultvalue},
                        Translation  => 1,
                        Max          => 200,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderDropdown',
                        Data => {
                            %Param,
                        },
                    );
                }

                if ( $RequestFields{Typ} eq "Text" && $RequestForm{RequiredField} == 1 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    #generate output
                    $Param{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $Param{FeldName}         = $RequestFields{Name} . '-' . $RequestFormListID;

                    $IfValue = $RequestFields{Name} . '-' . $RequestFormListID;
                    if ( $Param{$IfValue} ) {
                        $Param{FeldDefaultvalue} = $Param{$IfValue};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderTextRequired',
                        Data => {
                            %Param,
                        },
                    );
                }
                if ( $RequestFields{Typ} eq "Text" && $RequestForm{RequiredField} == 2 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    #generate output
                    $Param{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $Param{FeldName}         = $RequestFields{Name} . '-' . $RequestFormListID;

                    $IfValue = $RequestFields{Name} . '-' . $RequestFormListID;
                    if ( $Param{$IfValue} ) {
                        $Param{FeldDefaultvalue} = $Param{$IfValue};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderText',
                        Data => {
                            %Param,
                        },
                    );
                }

                if ( $RequestFields{Typ} eq "TextArea" && $RequestForm{RequiredField} == 1 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    #generate output
                    $Param{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $Param{FeldName}         = $RequestFields{Name} . '-' . $RequestFormListID;
                    $Param{FeldRows}         = $RequestFields{Rows};
                    $Param{FeldCols}         = $RequestFields{Cols};

                    $IfValue = $RequestFields{Name} . '-' . $RequestFormListID;
                    if ( $Param{$IfValue} ) {
                        $Param{FeldDefaultvalue} = $Param{$IfValue};
                    }
                    $Param{FeldName} = $RequestFields{Name} . '-' . $RequestFormListID;

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderTextAreaRequired',
                        Data => {
                            %Param,
                        },
                    );
                }
                if ( $RequestFields{Typ} eq "TextArea" && $RequestForm{RequiredField} == 2 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    #generate output
                    $Param{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $Param{FeldName}         = $RequestFields{Name} . '-' . $RequestFormListID;
                    $Param{FeldRows}         = $RequestFields{Rows};
                    $Param{FeldCols}         = $RequestFields{Cols};

                    $IfValue = $RequestFields{Name} . '-' . $RequestFormListID;
                    if ( $Param{$IfValue} ) {
                        $Param{FeldDefaultvalue} = $Param{$IfValue};
                    }
                    $Param{FeldName} = $RequestFields{Name} . '-' . $RequestFormListID;

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderTextArea',
                        Data => {
                            %Param,
                        },
                    );
                }

                if ( $RequestFields{Typ} eq "Checkbox" && $RequestForm{RequiredField} == 1 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    #generate output
                    $Param{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $Param{FeldName}         = $RequestFields{Name} . '-' . $RequestFormListID;

                    if ( $RequestFields{Defaultvalue} == 1 ) {
                        $Param{FeldChecked} = 'checked';
                    }
                    else {
                        $Param{FeldChecked} = '';
                    }


                    $LayoutObject->Block(
                        Name => 'OverviewListFelderCheckboxRequired',
                        Data => {
                            %Param,
                        },
                    );
                }
                if ( $RequestFields{Typ} eq "Checkbox" && $RequestForm{RequiredField} == 2 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

                    #generate output
                    $Param{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $Param{FeldName}         = $RequestFields{Name} . '-' . $RequestFormListID;

                    if ( $RequestFields{Defaultvalue} == 1 ) {
                        $Param{FeldChecked} = 'checked';
                    }
                    else {
                        $Param{FeldChecked} = '';
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderCheckbox',
                        Data => {
                            %Param,
                        },
                    );
                }

                if ( $RequestFields{Typ} eq "Date" && $RequestForm{RequiredField} == 1 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Day,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Month,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Year,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Hour,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Minute,";

                    my $NewDiffTime = $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0;
                    my $YearPeriodFuture = 5;
                    my $YearPeriodPast   = 0;

                    # date data string
                    $Param{FeldNameString} = $LayoutObject->BuildDateSelection(
                        %Param,
                        Format               => 'DateInputFormatLong',
                        Prefix               => $RequestFields{Name} . '-' . $RequestFormListID,
                        YearPeriodPast       => $YearPeriodPast,
                        YearPeriodFuture     => $YearPeriodFuture,
                        DiffTime             => $NewDiffTime,
                        Class                => $Param{Errors}->{DateInvalid},
                        Validate             => 1,
                        ValidateDateInFuture => 1,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderDateRequired',
                        Data => {
                            %Param,
                        },
                    );
                }
                if ( $RequestFields{Typ} eq "Date" && $RequestForm{RequiredField} == 2 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Day,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Month,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Year,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Hour,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Minute,";

                    my $NewDiffTime = $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0;
                    my $YearPeriodFuture = 5;
                    my $YearPeriodPast   = 0;

                    # date data string
                    $Param{FeldNameString} = $LayoutObject->BuildDateSelection(
                        %Param,
                        Format               => 'DateInputFormatLong',
                        Prefix               => $RequestFields{Name} . '-' . $RequestFormListID,
                        YearPeriodPast       => $YearPeriodPast,
                        YearPeriodFuture     => $YearPeriodFuture,
                        DiffTime             => $NewDiffTime,
                        Class                => $Param{Errors}->{DateInvalid},
                        Validate             => 1,
                        ValidateDateInFuture => 1,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderDate',
                        Data => {
                            %Param,
                        },
                    );
                }

                if ( $RequestFields{Typ} eq "DateShort" && $RequestForm{RequiredField} == 1 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Day,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Month,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Year,";

                    my $NewDiffTime  = $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0;
                    my $PeriodFuture = 5;
                    my $PeriodPast   = 0;

                    # date data string
                    $Param{FeldNameString} = $LayoutObject->BuildDateSelection(
                        %Param,
                        Format               => 'DateInputFormat',
                        Prefix               => $RequestFields{Name} . '-' . $RequestFormListID,
                        YearPeriodPast       => $PeriodPast,
                        YearPeriodFuture     => $PeriodFuture,
                        DiffTime             => $NewDiffTime,
                        Class                => $Param{Errors}->{DateInvalid},
                        Validate             => 1,
                        RequestFormateInFuture => 1,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderDateShortRequired',
                        Data => {
                            %Param,
                        },
                    );
                }
                if ( $RequestFields{Typ} eq "DateShort" && $RequestForm{RequiredField} == 2 ) {

                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Day,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Month,";
                    $Param{RequestFormBlockIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Year,";

                    my $PeriodFuture = 5;
                    my $PeriodPast   = 0;

                    # date data string
                    $Param{FeldNameString} = $LayoutObject->BuildDateSelection(
                        %Param,
                        Format               => 'DateInputFormat',
                        Prefix               => $RequestFields{Name} . '-' . $RequestFormListID,
                        YearPeriodPast       => $PeriodPast,
                        YearPeriodFuture     => $PeriodFuture,
                        Class                => $Param{Errors}->{DateInvalid},
                        Validate             => 1,
                        ValidateDateInFuture => 1,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderDateShort',
                        Data => {
                            %Param,
                        },
                    );
                }

        }

        if ( $RequestForm{Headline} ) {

            if ( $RequestForm{Description} ) {
                $RequestForm{Description} =~ s/(.*)<(.*)>/$2/ig;
                $RequestForm{Description} =~ s/</&lt;/ig;
                $RequestForm{Description} =~ s/>/&gt;/ig;
                $RequestForm{Description} =~ s/\n/<br\/>/ig;
                $Param{Description} = $RequestForm{Description};
            }

            $Param{FeldNameHeadline} = 'Headline-' . $RequestFormListID;
            $Param{RequestFormBlockIDs} .= 'Headline-' . $RequestFormListID . ",";

            $Param{Headline} = $RequestForm{Headline};
            $LayoutObject->Block(
                Name => 'OverviewListFelderHeadline',
                Data => {
                    %Param,
                },
            );
            $Param{Description} = '';
        }

        $CheckFields++;
    }

    # output overview result
    $LayoutObject->Block(
        Name => 'OverviewListFelderRequestFormIDs',
        Data => {
            %Param,
        },
    );

    if ( $CheckFields >= 1 ) {

        # get output back
        return $LayoutObject->Output(
            TemplateFile => 'RequestCustomerTicketMessageBlock',
            Data         => \%Param,
        );
    }
    else {

        # get output back
        return $LayoutObject->Output(
            TemplateFile => 'RequestCustomerTicketMessageBlockEmpty',
            Data         => \%Param,
        );

    }
}

1;
