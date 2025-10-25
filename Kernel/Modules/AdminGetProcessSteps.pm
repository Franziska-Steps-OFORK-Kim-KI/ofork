# --
# Kernel/Modules/AdminGetProcessSteps.pm - to handle customer messages
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminGetProcessSteps.pm,v 1.21 2016/12/13 14:37:23 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminGetProcessSteps;

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

    if ( $Self->{Subaction} eq "GetProcessSteps" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ProcessID ProcessStepID StepNo)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # html output
        my $Output = $Self->_MaskNew(
            ProcessID     => $GetParam{ProcessID},
            ProcessStepID => $GetParam{ProcessStepID},
            StepNo        => $GetParam{StepNo},
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

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessFieldsObject        = $Kernel::OM->Get('Kernel::System::ProcessFields');
    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');
    my $ProcessStepObject          = $Kernel::OM->Get('Kernel::System::ProcessStep');
    my $ProcessTransitionObject    = $Kernel::OM->Get('Kernel::System::ProcessTransition');

    my %ProcessFieldList = $ProcessFieldsObject->ProcessFieldList(
        ProcessID     => $Param{ProcessID},
        ProcessStepID => $Param{ProcessStepID},
    );

    if ( $Param{StepNo} == 2 ) {

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
                    $Param{FieldIsSetStepValue} = $ProcessField;
                    $Param{FieldIsSetStep}      = $SetField{$FieldToSet};
                }
            }
    
            my %Field = $ProcessFieldsObject->ProcessFieldGet(
                ProcessFieldID => $ProcessField,
            );
    
            if ( $Field{Required} == 1 ) {
                $LayoutObject->Block(
                    Name => 'FieldIsSetStep',
                    Data => { %Param, },
                );
            }
            else {
                $LayoutObject->Block(
                    Name => 'FieldIsSetStepRequired',
                    Data => { %Param, },
                );
            }
        }
    
        my $DynamicFieldObject         = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');
    
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
    
                $Param{DynamicFieldIsSetStep} = $DynamicField->{Label};
                $Param{DynamicFieldIsSetStepValue} = $DynamicProcessFieldNum;
    
                my %DynamicProcessFieldData = $DynamicProcessFieldsObject->DynamicProcessFieldGet(
                    ProcessFieldID => $DynamicProcessFieldNum,
                );
    
                if ( $DynamicProcessFieldData{Required} && $DynamicProcessFieldData{Required} == 2 ) {
    
                    $LayoutObject->Block(
                        Name => 'DynamicFieldIsSetStepRequired',
                        Data => { %Param, },
                    );
                }
                else {

                    $LayoutObject->Block(
                        Name => 'DynamicFieldIsSetStep',
                        Data => { %Param, },
                    );
                }
            }
            $DynamicCheckNum        = 0;
            $DynamicProcessFieldNum = 0;
        }

        my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionAllList(
            ProcessID     => $Param{ProcessID},
            ProcessStepID => $Param{ProcessStepID},
        );

        my $ProcessStepID = $ProcessStepObject->SearchNextProcessStepWithConditions(
            ProcessID  => $Param{ProcessID},
            StepNoFrom => $Param{ProcessStepID},
        );

        if ( $ProcessStepID ) {

            my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionAllList(
                ProcessID     => $Param{ProcessID},
                ProcessStepID => $ProcessStepID,
            );

            for my $ProcessTransitionID ( keys %ProcessTransitionList ) {

                my %ProcessTransition = $ProcessTransitionObject->ProcessTransitionGet(
                    ProcessTransitionID => $ProcessTransitionID,
                );

                if ( $ProcessTransition{StateID} && $ProcessTransition{StateID} >= 1 ) {

                    my $StateObject = $Kernel::OM->Get('Kernel::System::State');
                    my $State = $StateObject->StateLookup(
                        StateID => $ProcessTransition{StateID},
                    );

                    $LayoutObject->Block(
                        Name => 'ProcessTransition',
                        Data => { 
                            %Param,
                            Name  => 'State',
                            Value => $State,
                        },
                    );
                }

                if ( $ProcessTransition{TypeID} && $ProcessTransition{TypeID} >= 1 ) {

                    my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');
                    my $Type = $TypeObject->TypeLookup( TypeID => $ProcessTransition{TypeID} );

                    $LayoutObject->Block(
                        Name => 'ProcessTransition',
                        Data => { 
                            %Param,
                            Name  => 'Type',
                            Value => $Type,
                        },
                    );
                }

                if ( $ProcessTransition{QueueID} && $ProcessTransition{QueueID} >= 1 ) {

                    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
                    my $Queue = $QueueObject->QueueLookup( QueueID => $ProcessTransition{QueueID} );

                    $LayoutObject->Block(
                        Name => 'ProcessTransition',
                        Data => { 
                            %Param,
                            Name  => 'Queue',
                            Value => $Queue,
                        },
                    );
                }
            }

            my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                ID => $ProcessStepID,
            );

            $LayoutObject->Block(
                Name => 'ProcessStep',
                Data => { 
                    %Param,
                    Name        => $ProcessStepData{Name},
                    Description => $ProcessStepData{Description},
                },

            );
        }
    }
    else {

        my $ProcessStepID = $ProcessStepObject->SearchNextStepNoFrom(
            ProcessID  => $Param{ProcessID},
            StepNoFrom => $Param{ProcessStepID},
            StepNo     => 1,
        );

        if ( $ProcessStepID ) {

            my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionAllList(
                ProcessID     => $Param{ProcessID},
                ProcessStepID => $ProcessStepID,
            );

            for my $ProcessTransitionID ( keys %ProcessTransitionList ) {

                my %ProcessTransition = $ProcessTransitionObject->ProcessTransitionGet(
                    ProcessTransitionID => $ProcessTransitionID,
                );

                if ( $ProcessTransition{StateID} && $ProcessTransition{StateID} >= 1 ) {

                    my $StateObject = $Kernel::OM->Get('Kernel::System::State');
                    my $State = $StateObject->StateLookup(
                        StateID => $ProcessTransition{StateID},
                    );

                    $LayoutObject->Block(
                        Name => 'ProcessTransition',
                        Data => { 
                            %Param,
                            Name  => 'State',
                            Value => $State,
                        },
                    );
                }

                if ( $ProcessTransition{TypeID} && $ProcessTransition{TypeID} >= 1 ) {

                    my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');
                    my $Type = $TypeObject->TypeLookup( TypeID => $ProcessTransition{TypeID} );

                    $LayoutObject->Block(
                        Name => 'ProcessTransition',
                        Data => { 
                            %Param,
                            Name  => 'Type',
                            Value => $Type,
                        },
                    );
                }

                if ( $ProcessTransition{QueueID} && $ProcessTransition{QueueID} >= 1 ) {

                    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
                    my $Queue = $QueueObject->QueueLookup( QueueID => $ProcessTransition{QueueID} );

                    $LayoutObject->Block(
                        Name => 'ProcessTransition',
                        Data => { 
                            %Param,
                            Name  => 'Queue',
                            Value => $Queue,
                        },
                    );
                }
            }

            my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                ID => $ProcessStepID,
            );

            $LayoutObject->Block(
                Name => 'ProcessStep',
                Data => { 
                    %Param,
                    Name        => $ProcessStepData{Name},
                    Description => $ProcessStepData{Description},
                },
            );
        }



    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AdminGetProcessSteps',
        Data         => \%Param,
    );

}

1;
