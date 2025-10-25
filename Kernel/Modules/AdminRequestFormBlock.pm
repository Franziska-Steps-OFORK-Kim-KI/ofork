# --
# Kernel/Modules/AdminRequestFormBlock.pm - admin frontend to manage slas
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminRequestFormBlock.pm,v 1.5 2016/09/20 12:33:23 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminRequestFormBlock;

use strict;
use warnings;

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

    my $ParamObject             = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
    my $RequestObject           = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFieldsObject     = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestFormObject       = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $RequestFormBlockObject  = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $GroupObject             = $Kernel::OM->Get('Kernel::System::Group');
    my $QueueObject             = $Kernel::OM->Get('Kernel::System::Queue');
    my $RequestCategoriesObject = $Kernel::OM->Get('Kernel::System::RequestCategories');
    my $TypeObject              = $Kernel::OM->Get('Kernel::System::Type');

    # ------------------------------------------------------------ #
    # edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ShowBlock' ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(RequestID RequestFormID RequestFormValueID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # html output
        my $Output .= $Self->_MaskNew(
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

    my $ParamObject             = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
    my $RequestObject           = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFieldsObject     = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestFormObject       = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $RequestFormBlockObject  = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $GroupObject             = $Kernel::OM->Get('Kernel::System::Group');
    my $QueueObject             = $Kernel::OM->Get('Kernel::System::Queue');
    my $RequestCategoriesObject = $Kernel::OM->Get('Kernel::System::RequestCategories');
    my $TypeObject              = $Kernel::OM->Get('Kernel::System::Type');
    my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');

    my ( $Self, %Param ) = @_;

    # get params
    my %RequestData;
    $RequestData{RequestID} = $Param{RequestID} || '';

    my %RequestFormListDetails;
    $RequestFormListDetails{RequestName}    = $RequestData{Name};
    $RequestFormListDetails{RequestFormIDs} = '';

    my %RequestFormList = $RequestFormBlockObject->RequestFormBlockList(
        RequestFormID      => $Param{RequestFormID},
        RequestFormValueID => $Param{RequestFormValueID},
        RequestID          => $RequestData{RequestID},
        UserID             => $Self->{UserID},
    );

    if (%RequestFormList) {

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewFelderList',
            Data => { %RequestFormListDetails, %Param, },
        );

        for my $RequestFormListID (
            sort { $RequestFormList{$a} <=> $RequestFormList{$b} }
            keys %RequestFormList
            )
        {

            $RequestFormListDetails{FeldAktuellBlockID} = $RequestFormListID;

            #get RequestForm
            my %RequestForm
                = $RequestFormBlockObject->RequestFormBlockGet( RequestFormID => $RequestFormListID, );

            $RequestFormListDetails{FeldAktuellID}   = $RequestForm{RequestFormID};
            $RequestFormListDetails{RequestFormValue} = $RequestForm{RequestFormValue};

            $LayoutObject->Block(
                Name => 'OverviewListFieldsRow',
                Data => { %Param, },
            );

            $RequestFormListDetails{Order}   = $RequestForm{Order};
            $RequestFormListDetails{ToolTip}       = $RequestForm{ToolTip};
            $RequestFormListDetails{RequestFormID} = $RequestFormListID;

            $RequestFormListDetails{RequestFormIDs} .= "$RequestFormListID,";

            $RequestFormListDetails{ValidID} = $RequestForm{ValidID};

            if ( !$RequestForm{Headline} && !$RequestForm{Description} )
            {

                #get RequestFeld
                my %RequestFields
                    = $RequestFieldsObject->RequestFieldsGet(
                    RequestFieldsID => $RequestForm{FeldID},
                    );

                #get RequestFieldsWerte
                my %RequestFieldsWerte
                    = $RequestFieldsObject->RequestFieldsWerteGet( ID => $RequestFields{ID}, );

                #get list
                my %RequestFieldsListe
                    = $RequestFieldsObject->RequestFieldsWerteList( FeldID => $RequestForm{FeldID}, );

                my %RequestWerteDropdown = ();
                if (%RequestFieldsListe) {
                    for my $RequestFieldsWerteID ( sort keys %RequestFieldsListe ) {

                        #get RequestFieldsWerte
                        my %RequestFieldsWerte
                            = $RequestFieldsObject->RequestFieldsWerteGet(
                            ID => $RequestFieldsWerteID,
                            );
                        $RequestWerteDropdown{ $RequestFieldsWerte{Schluessel} }
                            = $RequestFieldsWerte{Inhalt};
                    }
                }

                $RequestFormListDetails{FieldLabeling} = $RequestFields{Labeling};
                $RequestFormListDetails{FieldName}         = $RequestFields{Name};

                if ( $RequestFields{Typ} eq "Multiselect" && $RequestForm{RequiredField} == 1 ) {

                    my @DefaultvalueValue;
                    if ( $RequestFields{Defaultvalue} ) {
                        @DefaultvalueValue = split( /,/, $RequestFields{Defaultvalue} );
                    }

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    #generate output
                    $RequestFormListDetails{FieldNameStrg} = $LayoutObject->BuildSelection(
                        Data         => \%RequestWerteDropdown,
                        Name         => $RequestFields{Name},
                        PossibleNone => $RequestFields{LeerWert},
                        Multiple     => 1,
                        Size         => 5,
                        Class        => 'Validate_Required',
                        SelectedID   => \@DefaultvalueValue,
                        Translation  => 1,
                        Max          => 200,
                    );

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsMultiselectRequired',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }
                if ( $RequestFields{Typ} eq "Multiselect" && $RequestForm{RequiredField} == 2 ) {

                    my @DefaultvalueValue;
                    if ( $RequestFields{Defaultvalue} ) {
                        @DefaultvalueValue = split( /,/, $RequestFields{Defaultvalue} );
                    }

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    #generate output
                    $RequestFormListDetails{FieldNameStrg} = $LayoutObject->BuildSelection(
                        Data         => \%RequestWerteDropdown,
                        Name         => $RequestFields{Name},
                        PossibleNone => $RequestFields{LeerWert},
                        Multiple     => 1,
                        Size         => 5,
                        Class        => 'W50pc',
                        SelectedID   => \@DefaultvalueValue,
                        Translation  => 1,
                        Max          => 200,
                    );

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsMultiselect',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }

                if ( $RequestFields{Typ} eq "Dropdown" && $RequestForm{RequiredField} == 1 ) {

                    if ( $Param{RequestFormValueID} ) {
                        $RequestFields{Defaultvalue} = $Param{RequestFormValueID};
                    }

                    #generate output
                    $RequestFormListDetails{FieldNameStrg} = $LayoutObject->BuildSelection(
                        Data         => \%RequestWerteDropdown,
                        Name         => $RequestFields{Name},
                        PossibleNone => $RequestFields{LeerWert},
                        Size         => 1,
                        Class        => 'Validate_Required',
                        SelectedID   => $RequestFields{Defaultvalue},
                        Translation  => 1,
                        Max          => 200,
                    );

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsDropdownRequired',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }
                if ( $RequestFields{Typ} eq "Dropdown" && $RequestForm{RequiredField} == 2 ) {

                    if ( $Param{RequestFormValueID} ) {
                        $RequestFields{Defaultvalue} = $Param{RequestFormValueID};
                    }

                    #generate output
                    $RequestFormListDetails{FieldNameStrg} = $LayoutObject->BuildSelection(
                        Data         => \%RequestWerteDropdown,
                        Name         => $RequestFields{Name},
                        PossibleNone => $RequestFields{LeerWert},
                        Size         => 1,
                        Class        => 'W50pc',
                        SelectedID   => $RequestFields{Defaultvalue},
                        Translation  => 1,
                        Max          => 200,
                    );

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsDropdown',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }

                if ( $RequestFields{Typ} eq "Text" && $RequestForm{RequiredField} == 1 ) {

                    #generate output
                    $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $RequestFormListDetails{FieldName}         = $RequestFields{Name};

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsTextRequired',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }
                if ( $RequestFields{Typ} eq "Text" && $RequestForm{RequiredField} == 2 ) {

                    #generate output
                    $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $RequestFormListDetails{FieldName}         = $RequestFields{Name};

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsText',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }

                if ( $RequestFields{Typ} eq "TextArea" && $RequestForm{RequiredField} == 1 ) {

                    #generate output
                    $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $RequestFormListDetails{FieldName}         = $RequestFields{Name};
                    $RequestFormListDetails{FeldRows}         = $RequestFields{Rows};
                    $RequestFormListDetails{FeldCols}         = $RequestFields{Cols};

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsTextAreaRequired',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }
                if ( $RequestFields{Typ} eq "TextArea" && $RequestForm{RequiredField} == 2 ) {

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsTextArea',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }

                if ( $RequestFields{Typ} eq "Checkbox" && $RequestForm{RequiredField} == 1 ) {

                    #generate output
                    $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $RequestFormListDetails{FieldName}         = $RequestFields{Name};
                    if ( $RequestFields{Defaultvalue} == 1 ) {
                        $RequestFormListDetails{FeldChecked} = 'checked="checked"';
                    }

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsCheckboxRequired',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }
                if ( $RequestFields{Typ} eq "Checkbox" && $RequestForm{RequiredField} == 2 ) {

                    #generate output
                    $RequestFormListDetails{FeldDefaultvalue} = $RequestFields{Defaultvalue};
                    $RequestFormListDetails{FieldName}         = $RequestFields{Name};
                    if ( $RequestFields{Defaultvalue} == 1 ) {
                        $RequestFormListDetails{FeldChecked} = 'checked="checked"';
                    }

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsCheckbox',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }

                if ( $RequestFields{Typ} eq "Date" && $RequestForm{RequiredField} == 1 ) {

                    # date data string
                    $Param{FieldNameString} = $LayoutObject->BuildDateSelection(
                        %Param,
                        Format           => 'DateInputFormatLong',
                        YearPeriodPast   => 0,
                        YearPeriodFuture => 5,
                        DiffTime         => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime')
                            || 0,
                        Class                => $Param{Errors}->{DateInvalid},
                        Validate             => 1,
                        ValidateDateInFuture => 1,
                    );

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsDateRequired',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }
                if ( $RequestFields{Typ} eq "Date" && $RequestForm{RequiredField} == 2 ) {

                    # date data string
                    $Param{FieldNameString} = $LayoutObject->BuildDateSelection(
                        %Param,
                        Format           => 'DateInputFormatLong',
                        YearPeriodPast   => 0,
                        YearPeriodFuture => 5,
                        DiffTime         => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime')
                            || 0,
                        Class                => $Param{Errors}->{DateInvalid},
                        Validate             => 1,
                        ValidateDateInFuture => 1,
                    );

                    if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                        $RequestFormListDetails{ungueltig} = 'ungültig';
                    }
                    else {
                        $RequestFormListDetails{ungueltig} = '';
                    }

                    if ( $RequestFormListDetails{Order} ) {
                        $Param{Order} = $RequestFormListDetails{Order};
                    }

                    $LayoutObject->Block(
                        Name => 'OverviewListFieldsDate',
                        Data => { %RequestFormListDetails, %Param, },
                    );
                }

            if ( $RequestFields{Typ} eq "DateShort" && $RequestForm{RequiredField} == 1 ) {

                # date data string
                $Param{FieldNameString} = $LayoutObject->BuildDateSelection(
                    %Param,
                    Format           => 'DateInputFormat',
                    YearPeriodPast   => 0,
                    YearPeriodFuture => 5,
                    DiffTime         => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime')
                        || 0,
                    Class                => $Param{Errors}->{DateInvalid},
                    Validate             => 1,
                    ValidateDateInFuture => 1,
                );

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsDateShortRequired',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }
            if ( $RequestFields{Typ} eq "DateShort" && $RequestForm{RequiredField} == 2 ) {

                # date data string
                $Param{FieldNameString} = $LayoutObject->BuildDateSelection(
                    %Param,
                    Format           => 'DateInputFormat',
                    YearPeriodPast   => 0,
                    YearPeriodFuture => 5,
                    DiffTime         => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime')
                        || 0,
                    Class                => $Param{Errors}->{DateInvalid},
                    Validate             => 1,
                    ValidateDateInFuture => 1,
                );

                if ( $RequestFormListDetails{ValidID} && $RequestFormListDetails{ValidID} == 2 ) {
                    $RequestFormListDetails{ungueltig} = 'ungültig';
                }
                else {
                    $RequestFormListDetails{ungueltig} = '';
                }

                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsDateShort',
                    Data => { %RequestFormListDetails, %Param, },
                );
            }

            }

            if ( $RequestForm{Headline} ) {

                $RequestFormListDetails{Headline} = $RequestForm{Headline};
                $Param{Headline}                 = $RequestForm{Headline};
                if ( $RequestFormListDetails{Order} ) {
                    $Param{Order} = $RequestFormListDetails{Order};
                }

                if ( $RequestForm{Description} ) {
                    $RequestForm{Description} =~ s/(.*)<(.*)>/$2/ig;
                    $RequestForm{Description} =~ s/</&lt;/ig;
                    $RequestForm{Description} =~ s/>/&gt;/ig;
                    $RequestForm{Description} =~ s/\n/<br\/>/ig;
                    $Param{Description}                  = $RequestForm{Description};
                    $RequestFormListDetails{Description} = $RequestForm{Description};
                }

                if ( $Param{Description} ) {
                     $Param{Headline} = $Param{Headline} . '<br>' . $Param{Description};
                     $Param{Description} = '';
                }

                $LayoutObject->Block(
                    Name => 'OverviewListFieldsHeadline',
                    Data => { %RequestFormListDetails, %Param, },
                );
                $Param{Description}                 = '';
                $RequestFormListDetails{Description} = '';
            }
        }

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewListFieldsRequestFormIDs',
            Data => { %RequestFormListDetails, %Param, },
        );

        if ( $RequestData{IDError} && $RequestData{IDError} eq "Exists" ) {

            # output sla edit
            $LayoutObject->Block(
                Name => 'DoppeltError',
                Data => { %Param, %RequestData, },
            );
        }

        # get output back
        return $LayoutObject->Output( TemplateFile => 'AdminRequestFormBlock', Data => \%Param );
    }
    else {
        return 'leer';
    }
}

1;
