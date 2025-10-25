# --
# Kernel/Modules/AdminProcessFields.pm - to handle customer messages
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AdminProcessFields.pm,v 1.21 2016/12/13 14:37:23 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminProcessFields;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

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
    my $ProcessStepObject          = $Kernel::OM->Get('Kernel::System::ProcessStep');
    my $LanguageObject             = $Kernel::OM->Get('Kernel::Language');

    if ( $Self->{Subaction} eq "AdminProcessField" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ProcessID ProcessStepID FieldID FieldAction Required ProcessFieldID DynamicFieldID DynamicProcessFieldID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
            ID => $GetParam{ProcessStepID},
        );

        if ( $ProcessStepData{StepArtID} == 2 ) {

            my $Output = $LanguageObject->Translate("Not required if subject to approval");

            # get output back
            return $LayoutObject->Attachment(
                ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
                Content     => $Output,
                Type        => 'inline',
                NoCache     => '1',
            );
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

        # get output back
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $Output,
            Type        => 'inline',
            NoCache     => '1',
        );
    }

    if ( $Self->{Subaction} eq "ProcessField" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ProcessID ProcessStepID FieldID FieldAction Required ProcessFieldID DynamicFieldID DynamicProcessFieldID)
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
        my $Output = $Self->_ProcessMaskNew(
            ProcessID     => $GetParam{ProcessID},
            ProcessStepID => $GetParam{ProcessStepID},
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

    if ( $Self->{Subaction} eq "DynamicAdminProcessField" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ProcessID ProcessStepID FieldID FieldAction Required ProcessFieldID DynamicFieldID DynamicFieldID)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        if ( $GetParam{FieldAction} eq "DynamicAdd" ) {

            my $ID = $DynamicProcessFieldsObject->DynamicProcessFieldAdd(
                ProcessID      => $GetParam{ProcessID},
                ProcessStepID  => $GetParam{ProcessStepID},
                DynamicFieldID => $GetParam{DynamicFieldID},
                Required       => $GetParam{Required},
                UserID         => 1,
            );
        }

        if ( $GetParam{FieldAction} eq "DynamicDelete" ) {

            my $Sucess = $DynamicProcessFieldsObject->DynamicProcessFieldDelete(
                DynamicFieldID => $GetParam{DynamicFieldID},
            );
        }


        # html output
        my $Output = $Self->_DynamicMaskNew(
            ProcessID     => $GetParam{ProcessID},
            ProcessStepID => $GetParam{ProcessStepID},
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

    my $CheckNum        = 0;
    my $ProcessFieldNum = 0;
    for my $FieldToSet ( sort { uc( $SetField{$a} ) cmp uc( $SetField{$b} ) } keys %SetField ) {

        for my $ProcessField ( keys %ProcessFieldList ) {

            if ( $ProcessFieldList{$ProcessField} == $FieldToSet ) {
                $CheckNum ++;
                $ProcessFieldNum = $ProcessField;
            }
        }

        if ( $CheckNum == 1 ) {

        }
        else {

            $Param{FieldToSetStep}      = $SetField{$FieldToSet};
            $Param{FieldToSetStepValue} = $FieldToSet;
            $LayoutObject->Block(
                Name => 'FieldToSetStep',
                Data => { %Param, },
            );
        }
        $CheckNum        = 0;
        $ProcessFieldNum = 0;
    }

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

            $LayoutObject->Block(
                Name => 'DynamicFieldIsSetStep',
                Data => { %Param, },
            );

            my %DynamicProcessFieldData = $DynamicProcessFieldsObject->DynamicProcessFieldGet(
                ProcessFieldID => $DynamicProcessFieldNum,
            );

            if ( $DynamicProcessFieldData{Required} && $DynamicProcessFieldData{Required} == 2 ) {

                $LayoutObject->Block(
                    Name => 'DynamicFieldIsSetStepRequired',
                    Data => { %Param, },
                );
            }
        }
        else {

            my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
                ID => $DynamicFieldToSet, 
            );

            $Param{DynamicFieldToSetStep}      = $DynamicField->{Label};
            $Param{DynamicFieldToSetStepValue} = $DynamicFieldToSet;

            if ( $DynamicField->{InternalField} <= 0 ) {
                $LayoutObject->Block(
                    Name => 'DynamicFieldToSetStep',
                    Data => { %Param, },
                );
            }
        }
        $DynamicCheckNum        = 0;
        $DynamicProcessFieldNum = 0;
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AdminProcessFields',
        Data         => \%Param,
    );

}

sub _ProcessMaskNew {
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

    my %SetField = (
        '1'  => 'Title',
        '3'  => 'Queue',
        '7'  => 'CustomerUser',
        '8'  => 'Owner',
    );

    my $CheckNum        = 0;
    my $ProcessFieldNum = 0;
    for my $FieldToSet ( sort { uc( $SetField{$a} ) cmp uc( $SetField{$b} ) } keys %SetField ) {

        for my $ProcessField ( keys %ProcessFieldList ) {

            if ( $ProcessFieldList{$ProcessField} == $FieldToSet ) {
                $CheckNum ++;
                $ProcessFieldNum = $ProcessField;
            }
        }

        if ( $CheckNum == 1 ) {

        }
        else {

            $Param{FieldToSetStep}      = $SetField{$FieldToSet};
            $Param{FieldToSetStepValue} = $FieldToSet;
            $LayoutObject->Block(
                Name => 'FieldToSetStep',
                Data => { %Param, },
            );
        }
        $CheckNum        = 0;
        $ProcessFieldNum = 0;
    }

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

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AdminProcessFields',
        Data         => \%Param,
    );

}

sub _DynamicMaskNew {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $DynamicFieldObject         = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');

    $LayoutObject->Block(
        Name => 'DynamicSetFieldListsResult',
        Data => { %Param, },
    );

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

            $LayoutObject->Block(
                Name => 'DynamicFieldIsSetStep',
                Data => { %Param, },
            );

            my %DynamicProcessFieldData = $DynamicProcessFieldsObject->DynamicProcessFieldGet(
                ProcessFieldID => $DynamicProcessFieldNum,
            );

            if ( $DynamicProcessFieldData{Required} && $DynamicProcessFieldData{Required} == 2 ) {

                $LayoutObject->Block(
                    Name => 'DynamicFieldIsSetStepRequired',
                    Data => { %Param, },
                );
            }
        }
        else {

            my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
                ID => $DynamicFieldToSet, 
            );

            $Param{DynamicFieldToSetStep}      = $DynamicField->{Label};
            $Param{DynamicFieldToSetStepValue} = $DynamicFieldToSet;

            if ( $DynamicField->{InternalField} <= 0 ) {

                $LayoutObject->Block(
                    Name => 'DynamicFieldToSetStep',
                    Data => { %Param, },
                );
            }
        }
        $DynamicCheckNum        = 0;
        $DynamicProcessFieldNum = 0;
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AdminProcessFields',
        Data         => \%Param,
    );

}

1;
