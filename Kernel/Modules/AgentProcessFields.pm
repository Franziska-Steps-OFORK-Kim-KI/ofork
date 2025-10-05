# --
# Kernel/Modules/AgentProcessFields.pm - to handle customer messages
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AgentProcessFields.pm,v 1.21 2016/12/13 14:37:23 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentProcessFields;

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
    my $ProcessFieldsObject        = $Kernel::OM->Get('Kernel::System::TicketProcessFields');
    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::TicketDynamicProcessFields');
    my $ProcessStepObject          = $Kernel::OM->Get('Kernel::System::TicketProcessStep');

    if ( $Self->{Subaction} eq "AdminProcessField" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ProcessID ProcessStepID FieldID FieldAction Required ProcessFieldID DynamicFieldID DynamicProcessFieldID TicketID StepValue)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
            ID => $GetParam{ProcessStepID},
        );

        if ( $ProcessStepData{Ready} == 1 ) {

            # html output
            my $Output = $Self->_MaskNewValue(
                TicketID      => $GetParam{TicketID},
                ProcessID     => $GetParam{ProcessID},
                ProcessStepID => $GetParam{ProcessStepID},
                StepValue     => $GetParam{StepValue},
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
        elsif ( $ProcessStepData{StepArtID} == 2 ) {

            # html output
            my $Output = $Self->_MaskNewApproval(
                TicketID      => $GetParam{TicketID},
                ProcessID     => $GetParam{ProcessID},
                ProcessStepID => $GetParam{ProcessStepID},
                StepValue     => $GetParam{StepValue},
                %Param,
                %GetParam,
            );
    
            $Output .= $LayoutObject->Footer(
                Type => 'ProcessSmall',
            );
    
            # get output back
            return $LayoutObject->Attachment(
                ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
                Content     => $Output,
                Type        => 'inline',
                NoCache     => '1',
            );
        }
        else {

            # html output
            my $Output = $Self->_MaskNew(
                TicketID      => $GetParam{TicketID},
                ProcessID     => $GetParam{ProcessID},
                ProcessStepID => $GetParam{ProcessStepID},
                StepValue     => $GetParam{StepValue},
                %Param,
                %GetParam,
            );
    
            $Output .= $LayoutObject->Footer(
                Type => 'ProcessSmall',
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

}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessFieldsObject     = $Kernel::OM->Get('Kernel::System::TicketProcessFields');
    my $TicketProcessStepObject = $Kernel::OM->Get('Kernel::System::TicketProcessStep');

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
        '2'  => 'Type',
        '3'  => 'Queue',
        '4'  => 'State',
        '5'  => 'Service',
        '6'  => 'SLA',
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

        my %ProcessFieldDetail = $ProcessFieldsObject->ProcessFieldGet(
            ProcessFieldID => $ProcessField,
        );

        if ( $Param{FieldIsSetStepValue} == 1 ) {

            if ( $ProcessFieldDetail{Required} == 1 ) {

                $LayoutObject->Block(
                    Name => 'ConditionFieldTitle',
                    Data => { %Param, },
                );
            }
            else {

                $LayoutObject->Block(
                    Name => 'ConditionFieldTitleMandatory',
                    Data => { %Param, },
                );
            }
        }

        if ( $Param{FieldIsSetStepValue} == 2 ) {

            # get config object
            my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

            if ( $ConfigObject->Get('Ticket::Type') ) {

                my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');
                my %TypeList = $TypeObject->TypeList(
                    Valid => 1,
                );
    
                if ( $ProcessFieldDetail{Required} == 1 ) {
    
                    $Param{TypeOption} = $LayoutObject->BuildSelection(
                        Data         => \%TypeList,
                        Name         => 'StepTypeID',
                        Class        => '',
                        PossibleNone => 1,
                        Sort         => 'NumericValue',
                        Translation  => 1,
                    );
    
                    $LayoutObject->Block(
                        Name => 'ConditionFieldType',
                        Data => { %Param, },
                    );
                }
                else {
    
                    $Param{TypeOption} = $LayoutObject->BuildSelection(
                        Data         => \%TypeList,
                        Name         => 'StepTypeID',
                        Class        => 'Validate_Required',
                        PossibleNone => 1,
                        Sort         => 'NumericValue',
                        Translation  => 1,
                    );
    
                    $LayoutObject->Block(
                        Name => 'ConditionFieldTypeMandatory',
                        Data => { %Param, },
                    );
                }
            }
        }

        if ( $Param{FieldIsSetStepValue} == 3 ) {

            my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
            my %QueueList = $QueueObject->QueueList(
                Valid => 1,
            );

            if ( $ProcessFieldDetail{Required} == 1 ) {

                $Param{QueueOption} = $LayoutObject->BuildSelection(
                    Data         => \%QueueList,
                    Name         => 'StepQueueID',
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
            else {

                $Param{QueueOption} = $LayoutObject->BuildSelection(
                    Data         => \%QueueList,
                    Name         => 'StepQueueID',
                    Class        => 'Validate_Required',
                    PossibleNone => 1,
                    Sort         => 'NumericValue',
                    Translation  => 1,
                );

                $LayoutObject->Block(
                    Name => 'ConditionFieldQueueMandatory',
                    Data => { %Param, },
                );
            }
        }

#        if ( $Param{FieldIsSetStepValue} == 4 ) {
#
#            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
#            my %StateList = $StateObject->StateList(
#                Valid  => 1,
#                UserID => $Self->{UserID},
#            );
#
#            if ( $ProcessFieldDetail{Required} == 1 ) {
#
#                $Param{StateOption} = $LayoutObject->BuildSelection(
#                    Data         => \%StateList,
#                    Name         => 'StepStateID',
#                    Class        => '',
#                    PossibleNone => 1,
#                    Sort         => 'NumericValue',
#                    Translation  => 1,
#                );
#
#                $LayoutObject->Block(
#                    Name => 'ConditionFieldState',
#                    Data => { %Param, },
#                );
#            }
#            else {
#
#                $Param{StateOption} = $LayoutObject->BuildSelection(
#                    Data         => \%StateList,
#                    Name         => 'StepStateID',
#                    Class        => 'Validate_Required',
#                    PossibleNone => 1,
#                    Sort         => 'NumericValue',
#                    Translation  => 1,
#                );
#
#                $LayoutObject->Block(
#                    Name => 'ConditionFieldStateMandatory',
#                    Data => { %Param, },
#                );
#            }
#        }

#        if ( $Param{FieldIsSetStepValue} == 5 ) {
#
#            my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
#            my %ServiceList = $ServiceObject->ServiceList(
#                Valid  => 1,
#                UserID => $Self->{UserID},
#            );
#
#            if ( $ProcessFieldDetail{Required} == 1 ) {
#
#                $Param{ServiceOption} = $LayoutObject->BuildSelection(
#                    Data         => \%ServiceList,
#                    Name         => 'StepServiceID',
#                    Class        => '',
#                    PossibleNone => 1,
#                    Sort         => 'NumericValue',
#                    Translation  => 1,
#                );
#
#                $LayoutObject->Block(
#                    Name => 'ConditionFieldService',
#                    Data => { %Param, },
#                );
#            }
#            else {
#
#                $Param{ServiceOption} = $LayoutObject->BuildSelection(
#                    Data         => \%ServiceList,
#                    Name         => 'StepServiceID',
#                    Class        => 'Validate_Required',
#                    PossibleNone => 1,
#                    Sort         => 'NumericValue',
#                    Translation  => 1,
#                );
#
#                $LayoutObject->Block(
#                    Name => 'ConditionFieldServiceMandatory',
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
#
#            if ( $ProcessFieldDetail{Required} == 1 ) {
#
#                $Param{SLAOption} = $LayoutObject->BuildSelection(
#                    Data         => \%SLAList,
#                    Name         => 'StepSLAID',
#                    Class        => '',
#                    PossibleNone => 1,
#                    Sort         => 'NumericValue',
#                    Translation  => 1,
#                );
#
#                $LayoutObject->Block(
#                    Name => 'ConditionFieldSLA',
#                    Data => { %Param, },
#                );
#            }
#            else {
#
#                $Param{SLAOption} = $LayoutObject->BuildSelection(
#                    Data         => \%SLAList,
#                    Name         => 'StepSLAID',
#                    Class        => 'Validate_Required',
#                    PossibleNone => 1,
#                    Sort         => 'NumericValue',
#                    Translation  => 1,
#                );
#
#                $LayoutObject->Block(
#                    Name => 'ConditionFieldSLAMandatory',
#                    Data => { %Param, },
#                );
#            }
#        }

        if ( $Param{FieldIsSetStepValue} == 7 ) {

            if ( $ProcessFieldDetail{Required} == 1 ) {

                $LayoutObject->Block(
                    Name => 'ConditionFieldCustomerUser',
                    Data => { %Param, },
                );
            }
            else {

                $LayoutObject->Block(
                    Name => 'ConditionFieldCustomerUserMandatory',
                    Data => { %Param, },
                );
            }
        }

        if ( $Param{FieldIsSetStepValue} == 8 ) {

            my $UserObject = $Kernel::OM->Get('Kernel::System::User');
            my %UserList = $UserObject->UserList(
                Type   => 'Long',
                Valid  => 1,
            );

            if ( $ProcessFieldDetail{Required} == 1 ) {

                $Param{OwnerOption} = $LayoutObject->BuildSelection(
                    Data         => \%UserList,
                    Name         => 'User',
                    Class        => '',
                    PossibleNone => 1,
                    Sort         => 'NumericValue',
                    Translation  => 1,
                );

                $LayoutObject->Block(
                    Name => 'ConditionFieldOwner',
                    Data => { %Param, },
                );
            }
            else {

                $Param{OwnerOption} = $LayoutObject->BuildSelection(
                    Data         => \%UserList,
                    Name         => 'User',
                    Class        => 'Validate_Required',
                    PossibleNone => 1,
                    Sort         => 'NumericValue',
                    Translation  => 1,
                );

                $LayoutObject->Block(
                    Name => 'ConditionFieldOwnerMandatory',
                    Data => { %Param, },
                );
            }
        }
    }

    my $DynamicFieldObject         = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::TicketDynamicProcessFields');
    my $DynamicFieldBackendObject  = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');

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
#    for my $DynamicFieldToSet ( sort { uc( ${$DynamicFieldList}{$a} ) cmp uc( ${$DynamicFieldList}{$b} ) } keys %{$DynamicFieldList} ) {
    for my $DynamicFieldToSet ( sort keys %{$DynamicFieldList} ) {

        for my $DynamicProcessField ( sort keys %DynamicProcessFieldList ) {

            if ( $DynamicProcessFieldList{$DynamicProcessField} == $DynamicFieldToSet ) {
                $DynamicCheckNum = 1;
                $DynamicProcessFieldNum = $DynamicProcessField;
            }
        }

        if ( $DynamicCheckNum == 1 ) {

            my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
                ID => $DynamicFieldToSet, 
            );

            my %ProcessDynamicField = $DynamicProcessFieldsObject->DynamicProcessFieldGet(
                ProcessFieldID => $DynamicProcessFieldNum,
            );

            if ( $ProcessDynamicField{Required} && $ProcessDynamicField{Required} == 2 ) {

                # get field html
                $DynamicFieldHTML{ $DynamicField->{Name} } = $DynamicFieldBackendObject->EditFieldRender(
                    DynamicFieldConfig => $DynamicField,
                    LayoutObject       => $LayoutObject,
                    ParamObject        => $ParamObject,
                    Class              => 'Mandatory',
                    AJAXUpdate         => 0,
                    Mandatory          => 1,
                );
            }
            else {

                # get field html
                $DynamicFieldHTML{ $DynamicField->{Name} } = $DynamicFieldBackendObject->EditFieldRender(
                    DynamicFieldConfig => $DynamicField,
                    LayoutObject       => $LayoutObject,
                    ParamObject        => $ParamObject,
                    Class              => '',
                    AJAXUpdate         => 0,
                );
            }

            $Param{$DynamicField->{Name}} = ${$DynamicFieldHTML{ $DynamicField->{Name} }}{Field};
            ${$DynamicFieldHTML{ $DynamicField->{Name} }}{Field} =~ s/Modernize//g;

            $Param{DynamicFieldIsSetStep} = $DynamicField->{Label};
            $Param{DynamicFieldIsSetStepValue} = $DynamicProcessFieldNum;

            if ( $ProcessDynamicField{Required} && $ProcessDynamicField{Required} == 2 ) {

                $LayoutObject->Block(
                    Name => 'DynamicFieldIsSetStepRequired',
                    Data => { 
                        %Param,
                        Name  => $DynamicField->{Name},
                        Field => ${$DynamicFieldHTML{ $DynamicField->{Name} }}{Field},
                    },
                );
            }
            else {

                $LayoutObject->Block(
                    Name => 'DynamicFieldIsSetStep',
                    Data => { 
                        %Param,
                        Field => ${$DynamicFieldHTML{ $DynamicField->{Name} }}{Field},
                    },
                );
            }
        }
        $DynamicCheckNum        = 0;
        $DynamicProcessFieldNum = 0;
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Config       = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    my %ProcessStepData = $TicketProcessStepObject->ProcessStepGet(
        ID => $Param{ProcessStepID},
    );

    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

    my %StepUsers = $GroupObject->PermissionGroupUserGet(
        GroupID => $ProcessStepData{GroupID},
        Type    => 'ro',
    );

    my %GroupRoleList = $GroupObject->PermissionGroupRoleGet(
        GroupID => $ProcessStepData{GroupID},
        Type    => 'rw',
    );

    my $SetRoleID = 0;
    for my $RoleID ( keys %GroupRoleList ) {
        $SetRoleID = $RoleID;
    }

    my %RoleList = $GroupObject->PermissionUserRoleGet(
        UserID => $Self->{UserID},
    );

    my $UserGroupIDOk = 0;
    for my $SetUserID ( keys %StepUsers ) {

        if ( $SetUserID == $Self->{UserID} ) {
            $UserGroupIDOk ++;
        }
    }

    for my $SetUserRoleID ( keys %RoleList ) {

        if ( $SetUserRoleID == $SetRoleID ) {
            $UserGroupIDOk ++;
        }
    }

    if ( $UserGroupIDOk >= 1 ) {

        $LayoutObject->Block(
            Name => 'GroupIfSet',
            Data => { %Param, },
        );
    }
    else {

        $LayoutObject->Block(
            Name => 'GroupIfNotSet',
            Data => { %Param, },
        );
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentProcessFields',
        Data => { 
            %Param,
            Name        => $ProcessStepData{Name},
            Description => $ProcessStepData{Description},
            StepValue   => $Param{StepValue},
        },
    );

}

sub _MaskNewValue {
    my ( $Self, %Param ) = @_;

    my $LayoutObject                 = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessFieldsObject          = $Kernel::OM->Get('Kernel::System::TicketProcessFields');
    my $TicketProcessStepObject      = $Kernel::OM->Get('Kernel::System::TicketProcessStep');
    my $TicketProcessStepValueObject = $Kernel::OM->Get('Kernel::System::TicketProcessStepValue');

    my %ProcessFieldValue = $TicketProcessStepValueObject->ProcessFieldValueGet(
        TicketID      => $Param{TicketID},
        ProcessID     => $Param{ProcessID},
        ProcessStepID => $Param{ProcessStepID},
    );

    $LayoutObject->Block(
        Name => 'SetFieldListsResult',
        Data => { %Param, %ProcessFieldValue, },
    );

    $LayoutObject->Block(
        Name => 'DynamicSetFieldListsResult',
        Data => { %Param, %ProcessFieldValue, },
    );

    if ( $ProcessFieldValue{Title} ) {

        $LayoutObject->Block(
            Name => 'ConditionFieldTitle',
            Data => { 
                %Param,
                Title => $ProcessFieldValue{Title},
            },
        );
    }

    if ( $ProcessFieldValue{Approval} && $ProcessFieldValue{Approval} == 1 ) {

        $LayoutObject->Block(
            Name => 'FieldApproval',
            Data => { 
                %Param,
                Approval => 'Approved'
            },
        );
    }

    if ( $ProcessFieldValue{Approval} && $ProcessFieldValue{Approval} == 2 ) {

        $LayoutObject->Block(
            Name => 'FieldApproval',
            Data => { 
                %Param,
                Approval => 'Not approved'
            },
        );
    }

    if ( $ProcessFieldValue{TypeID} && $ProcessFieldValue{TypeID} >= 1 ) {

        my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');
        my $Type = $TypeObject->TypeLookup( TypeID => $ProcessFieldValue{TypeID} );

        $LayoutObject->Block(
            Name => 'ConditionFieldType',
            Data => { 
                %Param,
                Type => $Type,
            },
        );
    }

    if ( $ProcessFieldValue{TypeID} && $ProcessFieldValue{TypeID} >= 1 ) {

        my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');
        my $Type = $TypeObject->TypeLookup( TypeID => $ProcessFieldValue{TypeID} );

        $LayoutObject->Block(
            Name => 'ConditionFieldType',
            Data => { 
                %Param,
                Type => $Type,
            },
        );
    }

    if ( $ProcessFieldValue{QueueID} && $ProcessFieldValue{QueueID} >= 1 ) {

        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
        my $Queue = $QueueObject->QueueLookup( QueueID => $ProcessFieldValue{QueueID} );

        $LayoutObject->Block(
            Name => 'ConditionFieldQueue',
            Data => { 
                %Param,
                Queue => $Queue,
            },
        );
    }

    if ( $ProcessFieldValue{StateID} && $ProcessFieldValue{StateID} >= 1 ) {

        my $StateObject = $Kernel::OM->Get('Kernel::System::State');
        my $State = $StateObject->StateLookup(
            StateID => $ProcessFieldValue{StateID},
        );

        $LayoutObject->Block(
            Name => 'ConditionFieldState',
            Data => { 
                %Param,
                State => $State,
            },
        );
    }

    if ( $ProcessFieldValue{FromCustomer}) {

        $LayoutObject->Block(
            Name => 'ConditionFieldFromCustomer',
            Data => { 
                %Param,
                FromCustomer => $ProcessFieldValue{FromCustomer},
            },
        );
    }

    if ( $ProcessFieldValue{User} && $ProcessFieldValue{User} >= 1 ) {

        my $UserObject = $Kernel::OM->Get('Kernel::System::User');
        my %User = $UserObject->GetUserData(
            UserID => $ProcessFieldValue{User},
        );

        my $SetUser = "$User{UserFirstname} $User{UserLastname}";

        $LayoutObject->Block(
            Name => 'ConditionFieldOwner',
            Data => { 
                %Param,
                User => $SetUser,
            },
        );
    }

    my $DynamicFieldObject         = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::TicketDynamicProcessFields');
    my $DynamicFieldBackendObject  = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');

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

            my %ProcessDynamicFieldValue = $TicketProcessStepValueObject->ProcessDynamicFieldValueGet(
                TicketID       => $Param{TicketID},
                ProcessID      => $Param{ProcessID},
                ProcessStepID  => $Param{ProcessStepID},
                DynamicfieldID => $DynamicFieldToSet,
            );

            if ( $ProcessDynamicFieldValue{FieldValue} ) {

                $LayoutObject->Block(
                    Name => 'DynamicFieldIsSetStep',
                    Data => { 
                        %Param,
                        Name       => $DynamicField->{Label},
                        FieldValue => $ProcessDynamicFieldValue{FieldValue},
                    },
                );
            }

        }
        $DynamicCheckNum        = 0;
        $DynamicProcessFieldNum = 0;
    }

    my %ProcessStepData = $TicketProcessStepObject->ProcessStepGet(
        ID => $Param{ProcessStepID},
    );

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentProcessFieldsReady',
        Data => { 
            %Param,
            %ProcessFieldValue,
            Name        => $ProcessStepData{Name},
            Description => $ProcessStepData{Description},
            StepValue   => $Param{StepValue},
        },
    );

}

sub _MaskNewApproval {
    my ( $Self, %Param ) = @_;

    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessFieldsObject     = $Kernel::OM->Get('Kernel::System::TicketProcessFields');
    my $TicketProcessStepObject = $Kernel::OM->Get('Kernel::System::TicketProcessStep');

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Config       = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    my %Approval = (
        '1'  => 'Approved',
        '2'  => 'Not approved',
    );

    $Param{StepApprovalOption} = $LayoutObject->BuildSelection(
        Data         => \%Approval,
        Name         => 'StepApproval',
        Class        => 'Validate_Required',
        PossibleNone => 1,
        Sort         => 'NumericValue',
        Translation  => 1,
    );

    my %ProcessStepData = $TicketProcessStepObject->ProcessStepGet(
        ID => $Param{ProcessStepID},
    );

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentProcessFieldsApproval',
        Data => { 
            %Param,
            Name        => $ProcessStepData{Name},
            Description => $ProcessStepData{Description},
            StepValue   => $Param{StepValue},
        },
    );

}

1;
