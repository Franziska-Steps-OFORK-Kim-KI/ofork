# --
# Kernel/Modules/AdminSetProcessConditions.pm - to handle customer messages
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminSetProcessConditions.pm,v 1.21 2016/12/13 14:37:23 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminSetProcessConditions;

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

    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessFieldsObject        = $Kernel::OM->Get('Kernel::System::ProcessFields');
    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');

    if ( $Self->{Subaction} eq "ProcessConditions" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ProcessID ProcessStepID FieldID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        if ( $GetParam{FieldAction} eq "Add" ) {

            my $ID = $ProcessFieldsObject->ProcessFieldAdd(
                ProcessID     => $GetParam{ProcessID},
                ProcessStepID => $GetParam{ProcessStepID},
                FieldID       => $GetParam{FieldID},
                Required      => $GetParam{Required},
                UserID        => 1,
            );
        }

        if ( $GetParam{FieldAction} eq "Delete" ) {

            my $Sucess = $ProcessFieldsObject->ProcessFieldDelete(
                ProcessFieldID => $GetParam{ProcessFieldID},
            );
        }

        # html output
        my $Output = $Self->_MaskNew(
            ProcessID     => $GetParam{ProcessID},
            ProcessStepID => $GetParam{ProcessStepID},
            %Param,
            %GetParam,
        );

        $Output .= $LayoutObject->Footer(
            Type => 'Small',
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

    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessFieldsObject = $Kernel::OM->Get('Kernel::System::ProcessFields');

    my %ProcessFieldList = $ProcessFieldsObject->ProcessFieldList(
        ProcessID     => $Param{ProcessID},
        ProcessStepID => $Param{ProcessStepID},
    );

    $LayoutObject->Block(
        Name => 'SetFieldListsResult',
        Data => { %Param, },
    );

    $LayoutObject->Block(
        Name => 'DynamicSetFieldListsResult',
        Data => { %Param, },
    );

    my %SetField = (
        '1'  => 'Title',
        '3'  => 'Queue',
        '7'  => 'CustomerUser',
        '8'  => 'Owner',
    );

    for my $ProcessField ( sort keys %ProcessFieldList ) {

        for my $FieldToSet ( sort { uc( $SetField{$a} ) cmp uc( $SetField{$b} ) } keys %SetField ) {

            if ( $ProcessFieldList{$ProcessField} == $FieldToSet ) {
                $Param{FieldIsSetStepValue} = $FieldToSet;
                $Param{FieldIsSetStep}      = $SetField{$FieldToSet};
            }
        }


        if ( $Param{FieldIsSetStepValue} == 1 ) {

            $LayoutObject->Block(
                Name => 'ConditionFieldTitle',
                Data => { %Param, },
            );
        }

#        if ( $Param{FieldIsSetStepValue} == 2 ) {
#
#            my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');
#            my %TypeList = $TypeObject->TypeList(
#                Valid => 1,
#            );
#            $Param{TypeOption} = $LayoutObject->BuildSelection(
#                Data         => \%TypeList,
#                Name         => 'Type',
#                Class        => '',
#                PossibleNone => 1,
#                Sort         => 'NumericValue',
#                Translation  => 1,
#            );
#
#            $LayoutObject->Block(
#                Name => 'ConditionFieldType',
#                Data => { %Param, },
#            );
#        }

        if ( $Param{FieldIsSetStepValue} == 3 ) {

            my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
            my %QueueList = $QueueObject->QueueList(
                Valid => 1,
            );
            $Param{QueueOption} = $LayoutObject->BuildSelection(
                Data         => \%QueueList,
                Name         => 'Queue',
                Class        => '',
                PossibleNone => 1,
                Sort         => 'NumericValue',
                Translation  => 1,
            );

            $LayoutObject->Block(
                Name => 'ConditionFieldQueue',
                Data => { %Param, },
            );
        }

#        if ( $Param{FieldIsSetStepValue} == 4 ) {
#
#            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
#            my %StateList = $StateObject->StateList(
#                Valid  => 1,
#                UserID => $Self->{UserID},
#            );
#            $Param{StateOption} = $LayoutObject->BuildSelection(
#                Data         => \%StateList,
#                Name         => 'State',
#                Class        => '',
#                PossibleNone => 1,
#                Sort         => 'NumericValue',
#                Translation  => 1,
#            );
#
#            $LayoutObject->Block(
#                Name => 'ConditionFieldState',
#                Data => { %Param, },
#            );
#        }

#        if ( $Param{FieldIsSetStepValue} == 5 ) {
#
#            my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
#            my %ServiceList = $ServiceObject->ServiceList(
#                Valid  => 1,
#                UserID => $Self->{UserID},
#            );
#            $Param{ServiceOption} = $LayoutObject->BuildSelection(
#                Data         => \%ServiceList,
#                Name         => 'Service',
#                Class        => '',
#                PossibleNone => 1,
#                Sort         => 'NumericValue',
#                Translation  => 1,
#            );
#
#            if ( %ServiceList ) {
#                $LayoutObject->Block(
#                    Name => 'ConditionFieldService',
#                    Data => { %Param, },
#                );
#            }
#        }

#        if ( $Param{FieldIsSetStepValue} == 6 ) {
#
#            my $SLAObject = $Kernel::OM->Get('Kernel::System::SLA');
#            my %SLAList = $SLAObject->SLAList(
#                Valid  => 1,
#                UserID => $Self->{UserID},
#            );
#            $Param{SLAOption} = $LayoutObject->BuildSelection(
#                Data         => \%SLAList,
#                Name         => 'SLA',
#                Class        => '',
#                PossibleNone => 1,
#                Sort         => 'NumericValue',
#                Translation  => 1,
#            );
#
#            if ( %SLAList ) {
#                $LayoutObject->Block(
#                    Name => 'ConditionFieldSLA',
#                    Data => { %Param, },
#                );
#            }
#        }

        if ( $Param{FieldIsSetStepValue} == 7 ) {

            $LayoutObject->Block(
                Name => 'ConditionFieldCustomerUser',
                Data => { %Param, },
            );
        }

        if ( $Param{FieldIsSetStepValue} == 8 ) {

            my $UserObject = $Kernel::OM->Get('Kernel::System::User');
            my %UserList = $UserObject->UserList(
                Type   => 'Long',
                Valid  => 1,
            );
            $Param{OwnerOption} = $LayoutObject->BuildSelection(
                Data         => \%UserList,
                Name         => 'User',
                Class        => '',
                PossibleNone => 1,
                Sort         => 'NumericValue',
                Translation  => 1,
            );

            if ( %UserList ) {
                $LayoutObject->Block(
                    Name => 'ConditionFieldOwner',
                    Data => { %Param, },
                );
            }
        }
    }

    my $DynamicFieldObject         = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');
    my $DynamicFieldBackendObject  = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldList(
        Valid      => 1,
        ObjectType => 'Ticket',
        ResultType => 'HASH',
    );

    my %DynamicProcessFieldList = $DynamicProcessFieldsObject->DynamicProcessFieldList(
        ProcessID     => $Param{ProcessID},
        ProcessStepID => $Param{ProcessStepID},
    );

    my $DynamicCheckNum        = 0;
    my $DynamicProcessFieldNum = 0;
    my %DynamicFieldHTML;
    for my $DynamicFieldToSet ( sort { uc( ${$DynamicFieldList}{$a} ) cmp uc( ${$DynamicFieldList}{$b} ) } keys %{$DynamicFieldList} ) {

        for my $DynamicProcessField ( keys %DynamicProcessFieldList ) {

            if ( $DynamicProcessFieldList{$DynamicProcessField} == $DynamicFieldToSet ) {
                $DynamicCheckNum = 1;
                $DynamicProcessFieldNum = $DynamicProcessField;
            }
        }

        if ( $DynamicCheckNum == 1 ) {

            my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
                ID => $DynamicFieldToSet, 
            );

            # get field html
            $DynamicFieldHTML{ $DynamicField->{Name} } = $DynamicFieldBackendObject->EditFieldRender(
                DynamicFieldConfig => $DynamicField,
                LayoutObject       => $LayoutObject,
                ParamObject        => $ParamObject,
                Class              => '',
                AJAXUpdate         => 0,
            );

            $Param{$DynamicField->{Name}} = ${$DynamicFieldHTML{ $DynamicField->{Name} }}{Field};
            ${$DynamicFieldHTML{ $DynamicField->{Name} }}{Field} =~ s/Modernize//g;

            $Param{DynamicFieldIsSetStep} = $DynamicField->{Label};
            $Param{DynamicFieldIsSetStepValue} = $DynamicProcessFieldNum;
            $LayoutObject->Block(
                Name => 'DynamicFieldIsSetStep',
                Data => { 
                    %Param,
                    Field => ${$DynamicFieldHTML{ $DynamicField->{Name} }}{Field},
                },
            );

            if ( $DynamicField->{FieldType} eq "Text" ) {

                $LayoutObject->Block(
                    Name => 'DynamicFieldRegex',
                    Data => { 
                        %Param,
                    },
                );
            }
            else {

                $LayoutObject->Block(
                    Name => 'DynamicFieldNoRegex',
                    Data => { 
                        %Param,
                    },
                );
            }
        }
        $DynamicCheckNum        = 0;
        $DynamicProcessFieldNum = 0;
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AdminSetProcessConditions',
        Data         => \%Param,
    );
}

1;
