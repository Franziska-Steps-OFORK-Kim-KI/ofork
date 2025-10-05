# --
# Kernel/Modules/AdminProcesses.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AdminProcesses.pm,v 1.1.1.1 2020/03/26 09:40:35 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminProcesses;

use strict;
use warnings;

use Kernel::System::Valid;
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

    my $ParamObject             = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessesObject         = $Kernel::OM->Get('Kernel::System::Processes');
    my $LogObject               = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');
    my $Notification            = $ParamObject->GetParam( Param => 'Notification' ) || '';
    my $ProcessStepObject       = $Kernel::OM->Get('Kernel::System::ProcessStep');
    my $ProcessConditionsObject = $Kernel::OM->Get('Kernel::System::ProcessConditions');
    my $ProcessTransitionObject = $Kernel::OM->Get('Kernel::System::ProcessTransition');
    my $Config                  = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");


    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'ProcessID' )
            || '';
        my %Data = $ProcessesObject->ProcessGet( ID => $ID );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Process updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_Edit(
            Action    => 'Change',
            ProcessID => $ID,
            %Data,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # delete
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Delete' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'ProcessID' )
            || '';

        my $Remove = $ProcessesObject->ProcessDelete(
            ID => $ID,
        );

        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Equipment updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # delete
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'DeleteStep' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'ProcessID' )
            || '';

        my ( %GetParam, %Errors );
        for my $Parameter (qw(ProcessStepID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        my $Remove = $ProcessStepObject->ProcessStepDelete(
            ProcessStepID => $GetParam{ProcessStepID},
        );

        my %Data = $ProcessesObject->ProcessGet( ID => $ID );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Equipment updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_Edit(
            Action    => 'Change',
            ProcessID => $ID,
            %Data,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change step
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'EditStep' ) {

        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'ProcessID' )
            || '';

        my ( %GetParam, %Errors );
        for my $Parameter (qw(ProcessStepNum ProcessStepID ID StepName Color Description GroupID StepArtID StateID QueueID SetArticleID ApproverGroupID ApproverEmail NotifyAgent)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        if ( !$GetParam{StepName} ) {
            $Errors{StepNameInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            my $ProcessStepID = $ProcessStepObject->ProcessStepUpdate(
                ProcessStepID   => $GetParam{ProcessStepID},
                Name            => $GetParam{StepName},
                Color           => $GetParam{Color},
                Description     => $GetParam{Description},
                GroupID         => $GetParam{GroupID},
                StepArtID       => $GetParam{StepArtID},
                SetArticleID    => $GetParam{SetArticleID},
                ApproverGroupID => $GetParam{ApproverGroupID},
                ApproverEmail   => $GetParam{ApproverEmail},
                NotifyAgent     => $GetParam{NotifyAgent},
                ValidID         => 1,
                UserID          => $Self->{UserID},
            );

            my $Success = $ProcessTransitionObject->ProcessTransitionUpdate(
                ProcessStepID => $GetParam{ProcessStepID},
                StateID       => $GetParam{StateID},
                QueueID       => $GetParam{QueueID},
                UserID        => $Self->{UserID},
            );
        }

        my %Data = $ProcessesObject->ProcessGet( ID => $ID );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Process updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_EditStep(
            Action    => 'Change',
            StepID    => $GetParam{ProcessStepID},
            ProcessID => $ID,
            %Data,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }


    # ------------------------------------------------------------ #
    # dtop process step end
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessStepStopEnd' ) {

        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'ProcessID' )
            || '';

        my ( %GetParam, %Errors );
        for my $Parameter (qw(ProcessStepID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        my $ProcessStepID = $ProcessStepObject->ProcessStepApprovalStopEnd(
            ProcessID       => $ID,
            ProcessStepID   => $GetParam{ProcessStepID},
            UserID          => $Self->{UserID},
        );

        my %Data = $ProcessesObject->ProcessGet( ID => $ID );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Process updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_EditStep(
            Action    => 'Change',
            StepID    => $GetParam{ProcessStepID},
            ProcessID => $ID,
            %Data,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------ #
    # next parallel step
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'NextProcessStepParallel' ) {

        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'ProcessID' )
            || '';

        my ( %GetParam, %Errors );
        for my $Parameter (qw(NextStepEnd NextProcessName WithConditions WithConditionsNext FromStepNo FromStepNext FromStepGo TypeID StateID QueueID ServiceID SLAID Title Type Queue State Service SLA CustomerUser Owner FromCustomer User ProcessStepID StepArt Color ApprovalSet ApprovalArt SetArticleID StepNoTo StepNoToSend ID SetNextStepID Transition NextDescription NextGroupID NextStepArtParallelID NextApproverGroupID NextApproverEmail WithConditionsEnd NotifyAgent)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        if ( !$GetParam{NextProcessName} ) {
            $Errors{NextProcessNameInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                ID => $GetParam{ProcessStepID},
            );

            $GetParam{ProcessStep} = $ProcessStepData{ProcessStep} + 1;
            $GetParam{StepNoFrom} = $GetParam{ProcessStepID};
            $GetParam{SetFirstParallel} = 0;
            $GetParam{ParallelSe}       = 0;
            $GetParam{SetParallel}      = 1;

		    my %ProcessTransitionListSum = $ProcessTransitionObject->ProcessTransitionSumList(
		        ProcessID => $ID,
		    );
            my $ProcessIDSum = 0;
            for my $IDsum ( keys %ProcessTransitionListSum ) {
            	$ProcessIDSum ++;
            }

            if ( $ProcessStepData{ParallelStep} && $ProcessStepData{ParallelStep} >= 1 ) {
            	$GetParam{ParallelStep} = $ProcessStepData{ProcessStep} + 1;
            }
            else {
            	$GetParam{ParallelStep} = $ProcessStepData{ProcessStep} + 1;

			    my $ProcessStepID = $ProcessStepObject->SearchParallelStep(
			        ProcessID => $ID,
			    );

                if ( !$ProcessStepID ) {
                	$GetParam{SetFirstParallel} = $ProcessStepData{ProcessStep};
                }
            }

            if ( $ProcessIDSum >= 1 ) {
            	$GetParam{SetFirstParallel} = '';
            }

            my %ProcessParallelSeList = $ProcessStepObject->ProcessStepParallelSe(
                ProcessID => $ID,
            );

            for my $EndParallel ( keys %ProcessParallelSeList ) {
            	$GetParam{SetParallel} = $GetParam{SetParallel} + 1;
            }

            my $ProcessStepID = $ProcessStepObject->NextProcessStepParallel(
                ProcessID        => $ID,
                ProcessStepID    => $GetParam{ProcessStepID},
                ProcessStep      => $GetParam{ProcessStep},
                Name             => $GetParam{NextProcessName},
                StepNo           => 1,
                StepNoFrom       => $GetParam{StepNoFrom},
                StepNoTo         => $GetParam{StepNoTo},
                Color            => $ProcessStepData{Color},
                Description      => $GetParam{NextDescription},
                GroupID          => $GetParam{NextGroupID},
                StepArtID        => $GetParam{NextStepArtParallelID},
                SetArticleID     => $GetParam{SetArticleID},
                ApproverGroupID  => $GetParam{NextApproverGroupID},
                ApproverEmail    => $GetParam{NextApproverEmail},
                ApprovalSet      => 0,
                ParallelStep     => $GetParam{ParallelStep},
                SetFirstParallel => $GetParam{SetFirstParallel},
                SetParallel      => $GetParam{SetParallel},
                ParallelSe       => $GetParam{ParallelSe},
                NotifyAgent      => $GetParam{NotifyAgent},
                ValidID          => 1,
                UserID           => $Self->{UserID},
            );

        }

        my %Data = $ProcessesObject->ProcessGet( ID => $ID );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Process updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_Edit(
            Action    => 'Change',
            StepID    => $GetParam{ProcessStepID},
            ProcessID => $ID,
            %Data,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------ #
    # next process step
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'NextProcessStep' ) {

        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'ProcessID' )
            || '';

        my ( %GetParam, %Errors );
        for my $Parameter (qw(NextStepEnd NextProcessName WithConditions WithConditionsNext FromStepNo FromStepNext FromStepGo TypeID StateID QueueID ServiceID SLAID Title Type Queue State Service SLA CustomerUser Owner FromCustomer User ProcessStepID StepArt Color ApprovalSet ApprovalArt SetArticleID StepNoTo StepNoToSend ID SetNextStepID Transition NextDescription NextGroupID NextStepArtID NextApproverGroupID NextApproverEmail WithConditionsEnd NotifyAgent)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        if ( !$GetParam{NextProcessName} ) {
            $Errors{NextProcessNameInvalid} = 'ServerError';
        }

        if ( $GetParam{StepNoToSend} eq "End" ) {
            %Errors = ();
        }

        if ( !$GetParam{FromStepNo} ) {
            $GetParam{FromStepNo} = $GetParam{FromStepNext};
        }

        if ( !$GetParam{FromStepNo} ) {
            $GetParam{FromStepNo} = $GetParam{FromStepGo};
        }

        if ( $GetParam{SetNextStepID} ) {

            %Errors = ();

            my $ProcessStepID = $ProcessStepObject->ToSelectedProcessStep(
                ProcessID     => $ID,
                ProcessStepID => $GetParam{ProcessStepID},
                SetNextStepID => $GetParam{SetNextStepID},
                FromStepNo    => $GetParam{FromStepNo},
                UserID        => $Self->{UserID},
            );
        }

        # if no errors occurred
        if ( !%Errors ) {

            my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                ID => $GetParam{ProcessStepID},
            );

            $GetParam{ProcessStep} = $ProcessStepData{ProcessStep} + 1;
            $GetParam{StepNoFrom} = $GetParam{ProcessStepID};
            
            if ( $GetParam{StepNoTo} eq "New" ) {
                $GetParam{StepNoTo} = 0;
            }

            if ( $GetParam{SetNextStepID} eq "New" ) {
                $GetParam{StepNoTo} = 0;
            }
            else {
                $GetParam{StepNoTo} = $GetParam{SetNextStepID};
            }

            if ( $GetParam{StepNoToSend} eq "End" ) {

                if ( $GetParam{StepArt} ) {

                    if ( $GetParam{WithConditionsEnd} ) {

                        my $ProcessStepID = $ProcessStepObject->ProcessStepEndWithConditions(
                            ProcessID       => $ID,
                            ProcessStepID   => $GetParam{ProcessStepID},
                            UserID          => $Self->{UserID},
                        );

                        my $SuccessConditions = $ProcessConditionsObject->ProcessConditionsAdd(
                            ProcessID     => $ID,
                            ProcessStepID => $GetParam{ProcessStepID},
                            ProcessStepNo => $GetParam{ProcessStep},
                            Title         => $GetParam{Title},
                            Type          => $GetParam{Type},
                            Queue         => $GetParam{Queue},
                            State         => $GetParam{State},
                            Service       => $GetParam{Service},
                            SLA           => $GetParam{SLA},
                            CustomerUser  => $GetParam{FromCustomer},
                            Owner         => $GetParam{User},
                            UserID        => $Self->{UserID},
                        );
                    }
                    else {

                        my $ProcessStepID = $ProcessStepObject->ProcessStepWithoutEnd(
                            ProcessID       => $ID,
                            ProcessStepID   => $GetParam{ProcessStepID},
                            UserID          => $Self->{UserID},
                        );
                    }
                }
                else {
    
                    if ( $GetParam{ApprovalArt} && $GetParam{ApprovalArt} == 1 ) {

                        my $ProcessStepID = $ProcessStepObject->ProcessStepApprovalEnd(
                            ProcessID       => $ID,
                            ProcessStepID   => $GetParam{ProcessStepID},
                            UserID          => $Self->{UserID},
                        );
                    }
                    else {

                        my $ProcessStepID = $ProcessStepObject->ProcessStepNoApprovalEnd(
                            ProcessID       => $ID,
                            ProcessStepID   => $GetParam{ProcessStepID},
                            UserID          => $Self->{UserID},
                        );
                    }
                }

                if ( $GetParam{ApprovalArt} && $GetParam{ApprovalArt} == 1 ) {
                    $GetParam{StepNo} = 1;
                }
                else {
                    $GetParam{StepNo} = 2;
                }

                my $Success = $ProcessTransitionObject->ProcessTransitionAdd(
                    ProcessID     => $ID,
                    ProcessStepID => $GetParam{ProcessStepID},
                    ProcessStepNo => $GetParam{ProcessStep},
                    StepNo        => $GetParam{FromStepNo},
                    TypeID        => $GetParam{TypeID},
                    StateID       => $GetParam{StateID},
                    QueueID       => $GetParam{QueueID},
                    ServiceID     => $GetParam{ServiceID},
                    SLAID         => $GetParam{SLAID},
                    UserID        => $Self->{UserID},
                );
            }
            else {

                if ( $GetParam{ApprovalSet} ) {

                    $GetParam{StepNo} = $ProcessStepData{StepNo} + 1;
                    $GetParam{ProcessStepTransition} = $GetParam{ProcessStep} -1;

                    my $ProcessStepID = $ProcessStepObject->NextProcessStep(
                        ProcessID       => $ID,
                        ProcessStepID   => $GetParam{ProcessStepID},
                        ProcessStep     => $GetParam{ProcessStep},
                        Name            => $GetParam{NextProcessName},
                        StepNo          => $GetParam{StepNo},
                        StepNoFrom      => $GetParam{StepNoFrom},
                        StepNoTo        => $GetParam{StepNoTo},
                        Color           => $GetParam{Color},
                        Description     => $GetParam{NextDescription},
                        GroupID         => $GetParam{NextGroupID},
                        StepArtID       => $GetParam{NextStepArtID},
                        SetArticleID    => $GetParam{SetArticleID},
                        ApproverGroupID => $GetParam{NextApproverGroupID},
                        ApproverEmail   => $GetParam{NextApproverEmail},
                        ApprovalSet     => 1,
                        NotifyAgent     => $GetParam{NotifyAgent},
                        ValidID         => 1,
                        UserID          => $Self->{UserID},
                    );

                    my $Success = $ProcessTransitionObject->ProcessTransitionAdd(
                        ProcessID     => $ID,
                        ProcessStepID => $ProcessStepID,
                        ProcessStepNo => $GetParam{ProcessStep},
                        StepNo        => $GetParam{FromStepNo},
                        TypeID        => $GetParam{TypeID},
                        StateID       => $GetParam{StateID},
                        QueueID       => $GetParam{QueueID},
                        ServiceID     => $GetParam{ServiceID},
                        SLAID         => $GetParam{SLAID},
                        UserID        => $Self->{UserID},
                    );
                }
                else {

                    if ( $GetParam{WithConditions} || $GetParam{WithConditionsNext} ) {

                        $GetParam{StepNo} = $ProcessStepData{StepNo} + 1;
                        $GetParam{ProcessStepTransition} = $GetParam{ProcessStep} -1;

                        my $SuccessConditions = $ProcessConditionsObject->ProcessConditionsAdd(
                            ProcessID     => $ID,
                            ProcessStepID => $GetParam{ProcessStepID},
                            ProcessStepNo => $GetParam{ProcessStep},
                            Title         => $GetParam{Title},
                            Type          => $GetParam{Type},
                            Queue         => $GetParam{Queue},
                            State         => $GetParam{State},
                            Service       => $GetParam{Service},
                            SLA           => $GetParam{SLA},
                            CustomerUser  => $GetParam{FromCustomer},
                            Owner         => $GetParam{User},
                            UserID        => $Self->{UserID},
                        );

                        my $DynamicFieldObject             = $Kernel::OM->Get('Kernel::System::DynamicField');
                        my $DynamicProcessFieldsObject     = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');
                        my $DynamicFieldBackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
                        my $ParamObject                    = $Kernel::OM->Get('Kernel::System::Web::Request');
                        my $ProcessDynamicConditionsObject = $Kernel::OM->Get('Kernel::System::ProcessDynamicConditions');
                    
                        my $DynamicFieldList = $DynamicFieldObject->DynamicFieldList(
                            Valid      => 1,
                            ObjectType => 'Ticket',
                            ResultType => 'HASH',
                        );

                        my %DynamicProcessFieldList = $DynamicProcessFieldsObject->DynamicProcessFieldList(
                            ProcessID     => $ID,
                            ProcessStepID => $GetParam{ProcessStepID},
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
                    
                                my $ParamName = 'DynamicField_' . $DynamicField->{Name};
                                $GetParam{$ParamName} = $ParamObject->GetParam( Param => $ParamName );

                                if ( $DynamicField->{FieldType} eq 'DateTime' ) {
                
                                    my $ParamNameDay       = $ParamName . 'Day';
                                    my $ParamNameMonth     = $ParamName . 'Month';
                                    my $ParamNameDayYear   = $ParamName . 'Year';
                                    my $ParamNameDayHour   = $ParamName . 'Hour';
                                    my $ParamNameDayMinute = $ParamName . 'Minute';
                
                                    $GetParam{$ParamNameDay}       = $ParamObject->GetParam( Param => $ParamNameDay );
                                    $GetParam{$ParamNameMonth}     = $ParamObject->GetParam( Param => $ParamNameMonth );
                                    $GetParam{$ParamNameDayYear}   = $ParamObject->GetParam( Param => $ParamNameDayYear );
                                    $GetParam{$ParamNameDayHour}   = $ParamObject->GetParam( Param => $ParamNameDayHour );
                                    $GetParam{$ParamNameDayMinute} = $ParamObject->GetParam( Param => $ParamNameDayMinute );
                
                                    if ( $GetParam{$ParamNameDay} <= 9 ) {
                                        $GetParam{$ParamNameDay} = '0'. $GetParam{$ParamNameDay};
                                    }
                                    if ( $GetParam{$ParamNameMonth} <= 9 ) {
                                        $GetParam{$ParamNameMonth} = '0'. $GetParam{$ParamNameMonth};
                                    }
                                    if ( $GetParam{$ParamNameDayHour} <= 9 ) {
                                        $GetParam{$ParamNameDayHour} = '0'. $GetParam{$ParamNameDayHour};
                                    }
                                    if ( $GetParam{$ParamNameDayMinute} <= 9 ) {
                                        $GetParam{$ParamNameDayMinute} = '0'. $GetParam{$ParamNameDayMinute};
                                    }
                
                                    $GetParam{$ParamName} = $GetParam{$ParamNameDayYear} . '-' . $GetParam{$ParamNameMonth} . '-' . $GetParam{$ParamNameDay} . ' ' . $GetParam{$ParamNameDayHour} . ':' . $GetParam{$ParamNameDayMinute} . ':00';
                                }

                                my $Success = $ProcessDynamicConditionsObject->ProcessDynamicConditionsAdd(
                                    ProcessID      => $ID,
                                    ProcessStepID  => $GetParam{ProcessStepID},
                                    DynamicFieldID => $DynamicFieldToSet,
                                    DynamicValue   => $GetParam{$ParamName},
                                    UserID         => $Self->{UserID},
                                );
                            }
                            $DynamicCheckNum        = 0;
                            $DynamicProcessFieldNum = 0;
                        }

                        my $ProcessStepID = $ProcessStepObject->NextProcessStep(
                            ProcessID      => $ID,
                            ProcessStepID  => $GetParam{ProcessStepID},
                            ProcessStep    => $GetParam{ProcessStep},
                            Name           => $GetParam{NextProcessName},
                            StepNo         => 2,
                            StepNoFrom     => $GetParam{StepNoFrom},
                            StepNoTo       => $GetParam{StepNoTo},
                            Color          => $GetParam{Color},
                            Description    => $GetParam{NextDescription},
                            GroupID        => $GetParam{NextGroupID},
                            StepArtID      => $GetParam{NextStepArtID},
                            SetArticleID   => $GetParam{SetArticleID},
                            NotifyAgent    => $GetParam{NotifyAgent},
                            ApprovalSet    => 0,
                            ValidID        => 1,
                            WithConditions => 1,
                            UserID         => $Self->{UserID},
                        );

                        my $SuccessTransition = $ProcessTransitionObject->ProcessTransitionAdd(
                            ProcessID     => $ID,
                            ProcessStepID => $ProcessStepID,
                            ProcessStepNo => $GetParam{ProcessStep},
                            StepNo        => $GetParam{FromStepNo},
                            TypeID        => $GetParam{TypeID},
                            StateID       => $GetParam{StateID},
                            QueueID       => $GetParam{QueueID},
                            ServiceID     => $GetParam{ServiceID},
                            SLAID         => $GetParam{SLAID},
                            UserID        => $Self->{UserID},
                        );
                    }
                    else {

                        $GetParam{StepNo} = $ProcessStepData{StepNo};
                        $GetParam{ProcessStepTransition} = $GetParam{ProcessStep} -1;

                        if ( !$GetParam{SetNextStepID} ) {

                            my $ProcessStepID = $ProcessStepObject->NextProcessStep(
                                ProcessID       => $ID,
                                ProcessStepID   => $GetParam{ProcessStepID},
                                ProcessStep     => $GetParam{ProcessStep},
                                Name            => $GetParam{NextProcessName},
                                StepNo          => 1,
                                StepNoFrom      => $GetParam{StepNoFrom},
                                StepNoTo        => $GetParam{StepNoTo},
                                Color           => $ProcessStepData{Color},
                                Description     => $GetParam{NextDescription},
                                GroupID         => $GetParam{NextGroupID},
                                StepArtID       => $GetParam{NextStepArtID},
                                SetArticleID    => $GetParam{SetArticleID},
                                ApproverGroupID => $GetParam{NextApproverGroupID},
                                ApproverEmail   => $GetParam{NextApproverEmail},
                                NotifyAgent     => $GetParam{NotifyAgent},
                                ApprovalSet     => 0,
                                ValidID         => 1,
                                UserID          => $Self->{UserID},
                            );
    
                            my $SuccessTransition = $ProcessTransitionObject->ProcessTransitionAdd(
                                ProcessID     => $ID,
                                ProcessStepID => $ProcessStepID,
                                ProcessStepNo => $GetParam{ProcessStep},
                                StepNo        => $GetParam{FromStepNo},
                                TypeID        => $GetParam{TypeID},
                                StateID       => $GetParam{StateID},
                                QueueID       => $GetParam{QueueID},
                                ServiceID     => $GetParam{ServiceID},
                                SLAID         => $GetParam{SLAID},
                                UserID        => $Self->{UserID},
                            );
                        }
                        else {

                            my $SuccessTransition = $ProcessTransitionObject->ProcessTransitionAdd(
                                ProcessID     => $ID,
                                ProcessStepID => $GetParam{ProcessStepID},
                                ProcessStepNo => $GetParam{ProcessStep},
                                StepNo        => $GetParam{FromStepNo},
                                TypeID        => $GetParam{TypeID},
                                StateID       => $GetParam{StateID},
                                QueueID       => $GetParam{QueueID},
                                ServiceID     => $GetParam{ServiceID},
                                SLAID         => $GetParam{SLAID},
                                UserID        => $Self->{UserID},
                            );
                        }
                    }
                }
            }
        }

        my %Data = $ProcessesObject->ProcessGet( ID => $ID );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Process updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_Edit(
            Action    => 'Change',
            StepID    => $GetParam{ProcessStepID},
            ProcessID => $ID,
            %Data,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------ #
    # process step end
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessStepEnd' ) {

        my $ID = $ParamObject->GetParam( Param => 'ID' )
            || $ParamObject->GetParam( Param => 'ProcessID' )
            || '';

        my ( %GetParam, %Errors );
        for my $Parameter (qw( ProcessStepID ID )) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
            ID => $GetParam{ProcessStepID},
        );

        my $Success = $ProcessStepObject->ProcessStepEnd(
            ProcessID     => $ID,
            ProcessStepID => $GetParam{ProcessStepID},
            UserID        => $Self->{UserID},
        );

        my %Data = $ProcessesObject->ProcessGet( ID => $ID );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Process updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_Edit(
            Action    => 'Change',
            StepID    => $GetParam{ProcessStepID},
            ProcessID => $ID,
            %Data,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'CreateFirstProcessStep' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Note = '';
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ProcessStepNum ID StepName Color Description GroupID StepArtID SetArticleID ApproverGroupID ApproverEmail NotifyAgent)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        if ( !$GetParam{StepName} ) {
            $Errors{StepNameInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            my $ProcessStepID = $ProcessStepObject->ProcessStepAdd(
                ProcessID       => $GetParam{ID},
                Name            => $GetParam{StepName},
                Color           => $GetParam{Color},
                ProcessStep     => $GetParam{ProcessStepNum},
                StepNo          => $GetParam{ProcessStepNum},
                StepNoFrom      => 0,
                Description     => $GetParam{Description},
                GroupID         => $GetParam{GroupID},
                StepArtID       => $GetParam{StepArtID},
                SetArticleID    => $GetParam{SetArticleID},
                ApproverGroupID => $GetParam{ApproverGroupID},
                ApproverEmail   => $GetParam{ApproverEmail},
                NotifyAgent     => $GetParam{NotifyAgent},
                ValidID         => 1,
                UserID          => $Self->{UserID},
            );
        }

        my %Data = $ProcessesObject->ProcessGet( ID => $GetParam{ID} );

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Note
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Note,
            )
            : '';
        $Self->_Edit(
            Action    => 'Change',
            ProcessID => $GetParam{ID},
            %GetParam,
            %Errors,
            %Data,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Note = '';
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Description QueueID SetArticleIDProcess ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        my %Data = $ProcessesObject->ProcessGet( ID => $GetParam{ID} );

        # check for needed data
        if ( !$GetParam{Name} ) {
            $Errors{NameInvalid} = 'ServerError';
        }

        # check for needed data
        if ( !$GetParam{Description} ) {
            $Errors{DescriptionInvalid} = 'ServerError';
        }

        # check for needed data
        if ( !$GetParam{QueueID} ) {
            $Errors{QueueIDInvalid} = 'ServerError';
        }

        # check for needed data
        if ( !$GetParam{SetArticleIDProcess} ) {
            $Errors{SetArticleIDProcessInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            my $Success = $ProcessesObject->ProcessUpdate(
                ID                  => $GetParam{ID},
                Name                => $GetParam{Name},
                Description         => $GetParam{Description},
                QueueID             => $GetParam{QueueID},
                SetArticleIDProcess => $GetParam{SetArticleIDProcess},
                ValidID             => $GetParam{ValidID},
                UserID              => 1,
            );
        }
        else {
            $Note = $LogObject->GetLogEntry(
                Type => 'Error',
                What => 'Message',
            );
        }
 
        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Note
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Note,
            )
            : '';
        $Self->_Edit(
            Action => 'Change',
            ProcessID => $GetParam{ID},
            %GetParam,
            %Errors,
            %Data
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my %GetParam = ();

        $GetParam{Name} = $ParamObject->GetParam( Param => 'Name' );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
        );

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

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Note = '';
        my $ProcessID;
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Description QueueID SetArticleIDProcess ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        if ( !$GetParam{Name} ) {
            $Errors{NameInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            # add Equipment
            $ProcessID = $ProcessesObject->ProcessAdd(
                %GetParam,
                UserID => $Self->{UserID}
            );

            if ($ProcessID) {

                # redirect
                return $LayoutObject->Redirect(
                    OP => "Action=AdminProcesses;Subaction=Change;ID=$ProcessID",
                );
            }
            else {
                $Note = $LogObject->GetLogEntry(
                    Type => 'Error',
                    What => 'Message',
                );
            }
        }

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Note
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Note,
            )
            : '';
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
            %Errors,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Equipment updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminProcesses',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                = $Kernel::OM->Get('Kernel::System::Valid');
    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ProcessesObject            = $Kernel::OM->Get('Kernel::System::Processes');
    my $ProcessStepObject          = $Kernel::OM->Get('Kernel::System::ProcessStep');
    my $ProcessFieldsObject        = $Kernel::OM->Get('Kernel::System::ProcessFields');
    my $DynamicProcessFieldsObject = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');
    my $ProcessTransitionObject    = $Kernel::OM->Get('Kernel::System::ProcessTransition');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        Class      => 'Modernize',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => \%Param,
    );

    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
    my %QueueList = $QueueObject->QueueList(
        Valid  => 1,
        UserID => $Self->{UserID},
    );

    my %ProcessesData = $ProcessesObject->ProcessGet(
        ID => $Param{ProcessID},
    );

    $Param{QueueStartStrg} = $LayoutObject->BuildSelection(
        Class        => '',
        Data         => \%QueueList,
        Name         => 'QueueID',
        SelectedID   => $ProcessesData{QueueID},
        PossibleNone => 1,
        Sort         => 'AlphanumericValue',
        Translation  => 0,
    );

    my %SetArticle = (
        '1' => 'yes',
        '2' => 'no',
    );
    $Param{SetArticleIDProcessOption} = $LayoutObject->BuildSelection(
        Data         => \%SetArticle,
        Name         => 'SetArticleIDProcess',
        Class        => '',
        SelectedID   => $Param{SetArticleIDProcess} || 2,
        PossibleNone => 0,
        Sort         => 'NumericValue',
        Translation  => 1,
    );

    if ( $Param{ProcessID} ) {

        my @ProcessStepValue = $ProcessStepObject->ProcessStepValue(
            ProcessID => $Param{ProcessID},
        );
        @ProcessStepValue = sort { $a <=> $b } @ProcessStepValue; 
        @ProcessStepValue = reverse @ProcessStepValue;

        my $AllValue    = $ProcessStepValue[0];
        my $CheckValue  = 0;
        my $SetDivValue = 0;
        my %ProcessStepDetailNext      = ();
        my %ProcessStepDetailNextCheck = ();
        my %ProcessStepDetailNextToTwo = ();

        for my $ProcessValue ( 1...$AllValue ) {

            my %ProcessStep = $ProcessStepObject->ProcessStepListValue(
                ProcessID => $Param{ProcessID},
                Value     => $ProcessValue,
            );

            $CheckValue ++;

            %ProcessStepDetailNext      = ();
            my %ProcessStepDetail       = ();
            my $NextProcessStepID       = '';
            %ProcessStepDetailNext      = ();
            %ProcessStepDetailNextToTwo = ();
            %ProcessStepDetailNextCheck = ();

            for my $ProcessStepID ( sort { $ProcessStep{$a} <=> $ProcessStep{$b} } keys %ProcessStep ) {

                $SetDivValue ++;

                %ProcessStepDetail = $ProcessStepObject->ProcessStepGet(
                    ID => $ProcessStepID,
                );

                $NextProcessStepID = $ProcessStepObject->SearchNextProcessStepWithConditions(
                    ProcessID   => $Param{ProcessID},
                    ProcessStep => $ProcessStepDetail{ProcessStep},
                    StepNoFrom  => $ProcessStepID,
                );

                if ( $NextProcessStepID ) {

                    %ProcessStepDetailNextCheck = $ProcessStepObject->ProcessStepGet(
                        ID => $NextProcessStepID,
                    );
                }

                if ( !$ProcessStepDetail{NotApproved} )  {
                    $ProcessStepDetail{NotApproved} = 0;
                }

                my %ProcessFieldList = $ProcessFieldsObject->ProcessFieldList(
                    ProcessID     => $Param{ProcessID},
                    ProcessStepID => $ProcessStepID,
                );
                my $ProcessFieldSize = keys %ProcessFieldList;

                my %DynamicProcessFieldList = $DynamicProcessFieldsObject->DynamicProcessFieldList(
                    ProcessID     => $Param{ProcessID},
                    ProcessStepID => $ProcessStepID,
                );
                my $ProcessFieldSizeDynamic = keys %DynamicProcessFieldList;

                $ProcessFieldSize = $ProcessFieldSize + $ProcessFieldSizeDynamic;

                $ProcessStepDetail{StepValue} = $ProcessValue;
                $ProcessStepDetail{ProcessFieldSize} = $ProcessFieldSize;
                $ProcessStepDetail{ProcessStepSize} = $SetDivValue;

                if ( $ProcessStepDetail{StepArtID} == 2 ) {
                    $ProcessStepDetail{ProcessStepArt} = 'Approval';
                }
                else {
                    $ProcessStepDetail{ProcessStepArt} = 'Work step';
                }

                if ( $ProcessStepDetail{ParallelStep} ) {
                	$SetDivValue = 2;
                }
                else {
                	$SetDivValue = 1;
                }

			    my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionSumList(
			        ProcessID => $Param{ProcessID},
			    );

                if ( ! %ProcessTransitionList && $CheckValue == 1 ) {
                	$SetDivValue = 1;
                }

                if ( %ProcessTransitionList && $CheckValue == 1 ) {
                	$SetDivValue = 1;
                }

                if ( $SetDivValue == 1 ) {
                    $LayoutObject->Block(
                        Name => 'Process',
                        Data => { %Param, %ProcessStepDetail, },
                    );
                }

                if ( $ProcessStepDetail{WithoutConditionEnd} && $ProcessStepDetail{WithoutConditionEnd} == 1 ) {

                    $LayoutObject->Block(
                        Name => 'ProcessStep',
                        Data => { %Param, %ProcessStepDetail, },
                    );

                    $LayoutObject->Block(
                        Name => 'ProcessStepEndWithoutConditions',
                        Data => { %Param, %ProcessStepDetail, },
                    );
                }
                elsif ( ( $ProcessStepDetailNextCheck{WithConditions} && $ProcessStepDetailNextCheck{WithConditions} == 1 ) && ( !$ProcessStepDetail{ToIDFromOne} && !$ProcessStepDetail{ToIDFromTwo} ) ) {

                    $LayoutObject->Block(
                        Name => 'ProcessStep',
                        Data => { %Param, %ProcessStepDetail, },
                    );

                    $LayoutObject->Block(
                        Name => 'ProcessStepNextWithConditions',
                        Data => { %Param, %ProcessStepDetailNextCheck, },
                    );
                }
                elsif ( $ProcessStepDetail{NotApproved} && $ProcessStepDetail{NotApproved} == 1 ) {

                    $LayoutObject->Block(
                        Name => 'ProcessStep',
                        Data => { %Param, %ProcessStepDetail, },
                    );

                    $LayoutObject->Block(
                        Name => 'ProcessStepEnd',
                        Data => { %Param, %ProcessStepDetail, },
                    );
                }
                elsif ( $ProcessStepDetail{StepEnd} && $ProcessStepDetail{StepEnd} == 1 ) {

                    $LayoutObject->Block(
                        Name => 'ProcessStep',
                        Data => { %Param, %ProcessStepDetail, },
                    );

                    $LayoutObject->Block(
                        Name => 'ProcessEnd',
                        Data => { %Param, %ProcessStepDetail, },
                    );
                }
                elsif ( $ProcessStepDetail{ToIDFromOne} || $ProcessStepDetail{ToIDFromTwo} ) {

                    $LayoutObject->Block(
                        Name => 'ProcessStep',
                        Data => { %Param, %ProcessStepDetail, },
                    );

                    if ( $ProcessStepDetail{ToIDFromOne} ) {

                        %ProcessStepDetailNext = $ProcessStepObject->ProcessStepGet(
                            ID => $ProcessStepDetail{ToIDFromOne},
                        );
                        if ( $ProcessStepDetailNext{StepArtID} == 1 ) {
                            $ProcessStepDetailNext{ProcessStepArt} = 'Work step';
                        }
                        else {
                            $ProcessStepDetailNext{ProcessStepArt} = 'Approval';
                        }
                    }

                    if ( $ProcessStepDetail{ToIDFromTwo} ) {

                        %ProcessStepDetailNextToTwo = $ProcessStepObject->ProcessStepGet(
                            ID => $ProcessStepDetail{ToIDFromTwo},
                        );
                        if ( $ProcessStepDetailNextToTwo{StepArtID} == 1 ) {
                            $ProcessStepDetailNextToTwo{ProcessStepArt} = 'Work step';
                        }
                        else {
                            $ProcessStepDetailNextToTwo{ProcessStepArt} = 'Approval';
                        }
                    }

                    if ( $ProcessStepDetailNextCheck{WithConditions} && $ProcessStepDetailNextCheck{WithConditions} == 1 ) {
    
                        $LayoutObject->Block(
                            Name => 'ProcessStepNextWithConditions',
                            Data => { %Param, %ProcessStepDetailNextCheck, },
                        );
                    }

                    if ( $ProcessStepDetail{ToIDFromOne} && $ProcessStepDetail{ToIDFromOne} <= $ProcessStepID ) {

                        $LayoutObject->Block(
                            Name => 'ProcessStepNextDown',
                            Data => { %Param, %ProcessStepDetailNext, },
                        );
                    }

                    if ( $ProcessStepDetail{ToIDFromOne} && $ProcessStepDetail{ToIDFromOne} > $ProcessStepID ) {

                        $LayoutObject->Block(
                            Name => 'ProcessStepNextUp',
                            Data => { %Param, %ProcessStepDetailNext, },
                        );
                    }
                    
                    if ( $ProcessStepDetail{ToIDFromTwo} && $ProcessStepDetail{ToIDFromTwo} <= $ProcessStepID ) {

                        $LayoutObject->Block(
                            Name => 'ProcessStepNextDownNoTwo',
                            Data => { %Param, %ProcessStepDetailNextToTwo, },
                        );
                    }

                    if ( $ProcessStepDetail{ToIDFromTwo} && $ProcessStepDetail{ToIDFromTwo} > $ProcessStepID ) {

                        $LayoutObject->Block(
                            Name => 'ProcessStepNextUpNoTwo',
                            Data => { %Param, %ProcessStepDetailNextToTwo, },
                        );
                    }

                }
                else {

                    $LayoutObject->Block(
                        Name => 'ProcessStep',
                        Data => { %Param, %ProcessStepDetail, },
                    );
                }

                %ProcessStepDetailNext      = ();
                %ProcessStepDetailNext      = ();
                %ProcessStepDetailNextToTwo = ();
                %ProcessStepDetailNextCheck = ();
            }

            %ProcessStepDetailNext = ();
            $SetDivValue           = 0;
            $ProcessStepDetailNext{WithConditions} = 0;

            if ( $CheckValue > 1 && $CheckValue == $AllValue ) {

                $LayoutObject->Block(
                    Name => 'ProcessStepDeleteLink',
                    Data => { %Param, %ProcessStepDetail, },
                );
            }
        }

        if ( !@ProcessStepValue )   {

            $Param{ProcessValidOption} = $LayoutObject->BuildSelection(
                Data       => \%ValidList,
                Name       => 'ProcessValidID',
                Class      => 'Modernize',
                SelectedID => $Param{ProcessValidID} || $ValidListReverse{valid},
            );

            my %Transitions = (
                '1'      => 'Without action',
                'Type'   => 'Type',
                'State'  => 'State',
                'Queue'  => 'Queue',
            );

            $Param{TransitionOption} = $LayoutObject->BuildSelection(
                Data         => \%Transitions,
                Name         => 'Transition',
                Class        => '',
                SelectedID   => $Param{Transition},
                PossibleNone => 1,
                Sort         => 'NumericValue',
                Translation  => 1,
            );

            my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');
            my %TypeList = $TypeObject->TypeList(
                Valid  => 1,
                UserID => $Self->{UserID},
            );    
            $Param{TypeStrg} = $LayoutObject->BuildSelection(
                Class        => 'Modernize',
                Data         => \%TypeList,
                Name         => 'TypeID',
                SelectedID   => $Param{TypeID},
                PossibleNone => 1,
                Sort         => 'AlphanumericValue',
                Translation  => 0,
            );

            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
#            my %StateList = $StateObject->StateList(
#                Valid  => 1,
#                UserID => $Self->{UserID},
#            );
            my %StateList = $StateObject->StateGetStatesByType(
                StateType => ['open'],
                Result    => 'HASH',
            );

            $Param{StateStrg} = $LayoutObject->BuildSelection(
                Class        => 'Modernize',
                Data         => \%StateList,
                Name         => 'StateID',
                SelectedID   => $Param{StateID},
                PossibleNone => 1,
                Sort         => 'AlphanumericValue',
                Translation  => 0,
            );

            $Param{GroupOption} = $LayoutObject->BuildSelection(
                Data => {
                    $Kernel::OM->Get('Kernel::System::Group')->GroupList(
                        Valid => 1,
                        )
                },
                Translation  => 0,
                Name         => 'GroupID',
                PossibleNone => 1,
                SelectedID   => $Param{GroupID},
                Class        => 'Modernize Validate_Required ' . ( $Param{Errors}->{'GroupIDInvalid'} || '' ),
            );

            my %CustomerApprover = (
                '1'      => 'yes',
            );

            $Param{ApproverGroupOption} = $LayoutObject->BuildSelection(
                Data         => \%CustomerApprover,
                Name         => 'ApproverGroupID',
                Class        => 'Modernize',
                SelectedID   => $Param{ApproverGroupID},
                PossibleNone => 1,
                Sort         => 'NumericValue',
                Translation  => 1,
            );

            my %StepArt = (
                '1' => 'Work step',
                '2' => 'Approval',

            );

            $Param{StepArtIDOption} = $LayoutObject->BuildSelection(
                Data         => \%StepArt,
                Name         => 'StepArtID',
                Class        => 'Modernize Validate_Required ' . ( $Param{Errors}->{'GroupIDInvalid'} || '' ),
                SelectedID   => $Param{StepArtID},
                PossibleNone => 1,
                Sort         => 'NumericValue',
                Translation  => 1,
            );

            my %SetArticleNew = (
                '1' => 'yes',
                '2' => 'no',
            );
            $Param{SetArticleIDOption} = $LayoutObject->BuildSelection(
                Data         => \%SetArticleNew,
                Name         => 'SetArticleID',
                Class        => '',
                SelectedID   => $Param{SetArticleID} || 2,
                PossibleNone => 0,
                Sort         => 'NumericValue',
                Translation  => 1,
            );

            my %NotifyArt = (
                'yes' => 'yes',
                'no' => 'no',

            );

            $Param{NotifyAgentOption} = $LayoutObject->BuildSelection(
                Data         => \%NotifyArt,
                Name         => 'NotifyAgent',
                Class        => 'Modernize ',
                SelectedID   => $Param{NotifyAgent} || $NotifyArt{yes},
                PossibleNone => 0,
                Sort         => 'NumericValue',
                Translation  => 1,
            );

            $LayoutObject->Block(
                Name => 'CreateFirstProcessStep',
                Data => { %Param, },
            );

        }
    }

    return 1;
}

sub _EditStep {
    my ( $Self, %Param ) = @_;

    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject         = $Kernel::OM->Get('Kernel::System::Valid');
    my $ParamObject         = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ProcessesObject     = $Kernel::OM->Get('Kernel::System::Processes');
    my $ProcessStepObject   = $Kernel::OM->Get('Kernel::System::ProcessStep');
    my $ProcessFieldsObject = $Kernel::OM->Get('Kernel::System::ProcessFields');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        Class      => 'Modernize',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
    );

    my %SetArticle = (
        '1' => 'yes',
        '2' => 'no',
    );
    $Param{SetArticleIDProcessOption} = $LayoutObject->BuildSelection(
        Data         => \%SetArticle,
        Name         => 'SetArticleIDProcess',
        Class        => '',
        SelectedID   => $Param{SetArticleIDProcess} || 2,
        PossibleNone => 0,
        Sort         => 'NumericValue',
        Translation  => 1,
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => \%Param,
    );

    if ( $Param{StepID} ) {

        my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
            ID => $Param{StepID},
        );

        $LayoutObject->Block(
            Name => 'ProcessStepsOverview',
            Data => { %Param, %ProcessStepData, },
        );

        if ( $ProcessStepData{StepArtID} == 2 ) {
            $Param{ApprovalVisibility} = 'visible';
        }
        else {
            $Param{ApprovalVisibility} = 'hidden';
        }

        my %SetArticleNew = (
            '1' => 'yes',
            '2' => 'no',
        );
        $Param{SetArticleIDOption} = $LayoutObject->BuildSelection(
            Data         => \%SetArticleNew,
            Name         => 'SetArticleID',
            Class        => '',
            SelectedID   => $ProcessStepData{SetArticleID} || 2,
            PossibleNone => 0,
            Sort         => 'NumericValue',
            Translation  => 1,
        );

        my %Transitions = (
            '1'      => 'Without action',
            'Type'   => 'Type',
            'State'  => 'State',
            'Queue'  => 'Queue',
        );
        $Param{TransitionOption} = $LayoutObject->BuildSelection(
            Data         => \%Transitions,
            Name         => 'Transition',
            Class        => '',
            SelectedID   => $Param{Transition},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 1,
        );

        my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');
        my %TypeList = $TypeObject->TypeList(
            Valid  => 1,
            UserID => $Self->{UserID},
        );    
        $Param{TypeStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => \%TypeList,
            Name         => 'TypeID',
            SelectedID   => $Param{TypeID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );

        my $ProcessTransitionObject = $Kernel::OM->Get('Kernel::System::ProcessTransition');
        my %ProcessTransition = $ProcessTransitionObject->ProcessStepTransitionGet(
            ProcessStepID => $Param{StepID},
        );

        my $StateObject = $Kernel::OM->Get('Kernel::System::State');
#        my %StateList = $StateObject->StateList(
#            Valid  => 1,
#            UserID => $Self->{UserID},
#        );

        my %StateList = $StateObject->StateGetStatesByType(
            StateType => ['open'],
            Result    => 'HASH',
        );

        my %NotifyArt = (
            'yes' => 'yes',
            'no' => 'no',
        );

        $Param{NotifyAgentOption} = $LayoutObject->BuildSelection(
            Data         => \%NotifyArt,
            Name         => 'NotifyAgent',
            Class        => 'Modernize ',
            SelectedID   => $ProcessStepData{NotifyAgent} || $NotifyArt{yes},
            PossibleNone => 0,
            Sort         => 'NumericValue',
            Translation  => 1,
        );

        $Param{StateStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => \%StateList,
            Name         => 'StateID',
            SelectedID   => $ProcessTransition{StateID} || $Param{StateID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );

        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
        my %QueueList = $QueueObject->QueueList(
            Valid  => 1,
            UserID => $Self->{UserID},
        );
        $Param{QueueStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => \%QueueList,
            Name         => 'QueueID',
            SelectedID   => $ProcessTransition{QueueID} || $Param{QueueID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );

        my %ProcessesData = $ProcessesObject->ProcessGet(
            ID => $ProcessStepData{ProcessID},
        );

        $Param{QueueStartStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => \%QueueList,
            Name         => 'QueueID',
            SelectedID   => $ProcessesData{QueueID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );

        $Param{QueueNewStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => \%QueueList,
            Name         => 'QueueID',
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );

        my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
        my %ServiceList = $ServiceObject->ServiceList(
            Valid  => 1,
            UserID => $Self->{UserID},
        );
        $Param{ServiceStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => \%ServiceList,
            Name         => 'ServiceID',
            SelectedID   => $Param{ServiceID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );

        my $SLAObject = $Kernel::OM->Get('Kernel::System::SLA');
        my %SLAList = $SLAObject->SLAList(
            Valid  => 1,
            UserID => $Self->{UserID},
        );
        $Param{SLAStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => \%SLAList,
            Name         => 'SLAID',
            SelectedID   => $Param{SLAID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );

        my %GroupList = $Kernel::OM->Get('Kernel::System::Group')->GroupList( Valid => 1 );
        $Param{GroupOption} = $LayoutObject->BuildSelection(
            Data         => \%GroupList,
            PossibleNone => 1,
            Name         => 'GroupID',
            Class        => 'Modernize Validate_Required ' . ( $Param{Errors}->{'GroupIDInvalid'} || '' ),
            SelectedID   => $ProcessStepData{GroupID},
        );

        $Param{NextGroupOption} = $LayoutObject->BuildSelection(
            Data         => \%GroupList,
            PossibleNone => 1,
            Name         => 'NextGroupID',
            Class        => 'Modernize Validate_Required ' . ( $Param{Errors}->{'GroupIDInvalid'} || '' ),
        );

        my %CustomerApprover = (
            '1'      => 'yes',
        );

        $Param{ApproverGroupOption} = $LayoutObject->BuildSelection(
            Data         => \%CustomerApprover,
            Name         => 'ApproverGroupID',
            PossibleNone => 1,
            SelectedID   => $ProcessStepData{ApproverGroupID},
            Class        => 'Modernize',
        );

        $Param{NextApproverGroupOption} = $LayoutObject->BuildSelection(
            Data         => \%CustomerApprover,
            Name         => 'NextApproverGroupID',
            PossibleNone => 1,
            Class        => 'Modernize',
        );

        my %StepArt = (
            '1' => 'Work step',
            '2' => 'Approval',
        );

        my %StepArtParallel = (
            '1' => 'Work step',
        );

        $Param{StepArtIDOption} = $LayoutObject->BuildSelection(
            Data         => \%StepArt,
            Name         => 'StepArtID',
            Class        => 'Modernize Validate_Required ' . ( $Param{Errors}->{'StepArtIDInvalid'} || '' ),
            SelectedID   => $ProcessStepData{StepArtID},
            PossibleNone => 1,
            Sort         => 'NumericKey',
            Translation  => 1,
        );

        if ( $ProcessStepData{StepArtID} == 1 ) {
            $Param{StepArtIDOptionName} = 'Work step';
        }
        else {
            $Param{StepArtIDOptionName} = 'Approval';
        }

        $Param{NextStepArtIDOption} = $LayoutObject->BuildSelection(
            Data         => \%StepArt,
            Name         => 'NextStepArtID',
            Class        => 'Modernize Validate_Required ' . ( $Param{Errors}->{'NextStepArtIDInvalid'} || '' ),
            PossibleNone => 1,
            Sort         => 'NumericKey',
            Translation  => 1,
        );

        $Param{NextStepArtParallelIDOption} = $LayoutObject->BuildSelection(
            Data         => \%StepArtParallel,
            Name         => 'NextStepArtParallelID',
            Class        => 'Modernize Validate_Required ' . ( $Param{Errors}->{'NextStepArtParallelIDInvalid'} || '' ),
            PossibleNone => 1,
            Sort         => 'NumericKey',
            Translation  => 1,
        );

        my %ProcessStepTo = $ProcessStepObject->ProcessStepListTo(
            ProcessID   => $ProcessStepData{ProcessID},
            ProcessStep => $ProcessStepData{ProcessStep},
        );
        $ProcessStepTo{'End'} = 'End';
        $ProcessStepTo{'New'} = 'New';

        $Param{StepNoToOption} = $LayoutObject->BuildSelection(
            Data         => \%ProcessStepTo,
            Name         => 'StepNoTo',
            Class        => 'Validate_Required ' . ( $Param{Errors}->{'StepNoToInvalid'} || '' ),
            PossibleNone => 1,
            Sort         => 'NumericKey',
            Translation  => 1,
        );

        $LayoutObject->Block(
            Name => 'ChangeProcessStep',
            Data => { %Param, %ProcessStepData, },
        );

        if ( $ProcessStepData{ProcessStep} > 1 ) {

            $LayoutObject->Block(
                Name => 'ChangeProcessStepTransition',
                Data => { %Param, %ProcessStepData, },
            );
        }
        else {

            $LayoutObject->Block(
                Name => 'ChangeProcessStepTransitionFirst',
                Data => { %Param, %ProcessStepData, },
            );
        }

        my $ProcessStepDataProcessStep = $ProcessStepData{ProcessStep} + 1;

        my $SearchNextProcessStepOne = $ProcessStepObject->SearchNextProcessStepApproval(
            ProcessID   => $ProcessStepData{ProcessID},
            ProcessStep => $ProcessStepDataProcessStep,
            StepNoFrom  => $Param{StepID},
            StepNo      => 1,
        );

        my $SearchNextProcessStepTo = $ProcessStepObject->SearchNextProcessStepApproval(
            ProcessID   => $ProcessStepData{ProcessID},
            ProcessStep => $ProcessStepDataProcessStep,
            StepNoFrom  => $Param{StepID},
            StepNo      => 2,
        );

        if ( $ProcessStepData{StepArtID} == 2 ) {

            $LayoutObject->Block(
                Name => 'ApprovalStep',
                Data => { %Param, %ProcessStepData, },
            );

            if ( $SearchNextProcessStepOne < 1 && $ProcessStepData{ToIDFromOne} < 1 ) {

                if ( $ProcessStepData{WithoutConditionEnd} && $ProcessStepData{WithoutConditionEnd} == 1 ) {

                    $LayoutObject->Block(
                        Name => 'ApprovalStepNoNextStepOK',
                        Data => { %Param, %ProcessStepData, },
                    );
                }
                else {

                    $LayoutObject->Block(
                        Name => 'ApprovalStepNoNextStep',
                        Data => { %Param, %ProcessStepData, },
                    );
                }
            }
            else {

                $LayoutObject->Block(
                    Name => 'ApprovalStepNoNextStepOK',
                    Data => { %Param, %ProcessStepData, },
                );
            }

            if ( $SearchNextProcessStepTo < 1  && $ProcessStepData{NotApproved} < 1 && $ProcessStepData{ToIDFromTwo} < 1 ) {

                $LayoutObject->Block(
                    Name => 'ApprovalStepNoNextStepNotApproved',
                    Data => { %Param, %ProcessStepData, },
                );
            }
            else {

                $LayoutObject->Block(
                    Name => 'ApprovalStepNoNextStepNotApprovedOK',
                    Data => { %Param, %ProcessStepData, },
                );
            }

        }

        my $NextProcessStepID   = '';
        my $SearchProcessStepID = '';

        if ( $ProcessStepData{StepArtID} == 1 ) {

            $LayoutObject->Block(
                Name => 'NextStep',
                Data => { %Param, %ProcessStepData, },
            );

            if ( !$ProcessStepData{StepEnd} == 1 ) {

                $SearchProcessStepID = $ProcessStepObject->SearchNextStepNoFrom(
                    ProcessID  => $ProcessStepData{ProcessID},
                    StepNoFrom => $ProcessStepData{ProcessStepID},
                    StepNo     => 1,
                );

                if ( $SearchProcessStepID <= 0 && !$ProcessStepData{ToIDFromOne} ) {

                    if ( $ProcessStepData{WithoutConditionEnd} <= 0 || !$ProcessStepData{WithoutConditionEnd} ) {

                        $LayoutObject->Block(
                            Name => 'SetNextStep',
                            Data => { %Param, %ProcessStepData, },
                        );
                    }
#                    else {
#
#                        $LayoutObject->Block(
#                            Name => 'SetNextStepOK',
#                            Data => { %Param, %ProcessStepData, },
#                        );
#                    }
                }
                else {

                    $LayoutObject->Block(
                        Name => 'SetNextStepOK',
                        Data => { %Param, %ProcessStepData, },
                    );
                }
    
                $NextProcessStepID = $ProcessStepObject->SearchNextProcessStepWithConditions(
                    StepNoFrom => $ProcessStepData{ProcessStepID},
                    ProcessID  => $ProcessStepData{ProcessID},
                );
    
                if ( !$NextProcessStepID && !$ProcessStepData{ToIDFromTwo} && !$ProcessStepData{WithConditionsEnd} ) {

                    $LayoutObject->Block(
                        Name => 'SetNextStepWithConditions',
                        Data => { %Param, %ProcessStepData, },
                    );
                }
                else {

                    $LayoutObject->Block(
                        Name => 'SetNextStepWithConditionsOK',
                        Data => { %Param, %ProcessStepData, },
                    );
                }
            }
        }

        if ( $SearchNextProcessStepOne >= 1  && $ProcessStepData{NotApproved} >= 1 ) {


#            $LayoutObject->Block(
#                Name => 'StepEnd',
#                Data => { %Param, %ProcessStepData, },
#            );

            return 1;
        }

        if ( $ProcessStepData{StepEnd} == 1 ) {

            $LayoutObject->Block(
                Name => 'StepEnd',
                Data => { %Param, %ProcessStepData, },
            );
        }
        elsif ( $SearchProcessStepID >= 1 && $NextProcessStepID >= 1 ) {

#            $LayoutObject->Block(
#                Name => 'SetNextStepOK',
#                Data => { %Param, %ProcessStepData, },
#            );

            $LayoutObject->Block(
                Name => 'StepFinish',
                Data => { %Param, %ProcessStepData, },
            );
        }
        else {

#            $LayoutObject->Block(
#                Name => 'SetNextStepOK',
#                Data => { %Param, %ProcessStepData, },
#            );

            if ( !$ProcessStepData{ToIDFromOne} && !$ProcessStepData{ToIDFromTwo} ) {

                $LayoutObject->Block(
                    Name => 'SetStepEnd',
                    Data => { %Param, %ProcessStepData, },
                );
            }
        }
    }

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessesObject  = $Kernel::OM->Get('Kernel::System::Processes');
    my $ValidObject         = $Kernel::OM->Get('Kernel::System::Valid');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    my %List = $ProcessesObject->ProcessesList(
        ValidID => 0,
    );
    my $ListSize = keys %List;
    $Param{AllItemsCount} = $ListSize;

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    # get valid list
    my %ValidList = $ValidObject->ValidList();
    for my $ListKey ( sort { $List{$a} cmp $List{$b} } keys %List ) {

        my %Data = $ProcessesObject->ProcessGet(
            ID => $ListKey,
        );
        $LayoutObject->Block(
            Name => 'OverviewResultRow',
            Data => {
                Valid => $ValidList{ $Data{ValidID} },
                %Data,
            },
        );
    }
    return 1;
}

1;
