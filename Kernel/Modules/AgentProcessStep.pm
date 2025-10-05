# --
# Kernel/Modules/AgentProcessStep.pm - to handle customer messages
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AgentProcessStep.pm,v 1.21 2016/12/13 14:37:23 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentProcessStep;

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

    my $ParamObject                   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessFieldsObject           = $Kernel::OM->Get('Kernel::System::TicketProcessFields');
    my $DynamicProcessFieldsObject    = $Kernel::OM->Get('Kernel::System::TicketDynamicProcessFields');
    my $ProcessStepObject             = $Kernel::OM->Get('Kernel::System::TicketProcessStep');
    my $TicketProcessStepValueObject  = $Kernel::OM->Get('Kernel::System::TicketProcessStepValue');
    my $TicketProcessesObject         = $Kernel::OM->Get('Kernel::System::TicketProcesses');
    my $TicketProcessConditionsObject = $Kernel::OM->Get('Kernel::System::TicketProcessConditions');
    my $TicketProcessTransitionObject = $Kernel::OM->Get('Kernel::System::TicketProcessTransition');

    if ( $Self->{Subaction} eq "Store" ) {

        # get params
        my %GetParam;
        for my $Param (
            qw(ProcessID ProcessStepID Report StepTitle StepTypeID StepQueueID StepStateID StepServiceID StepSLAID FromCustomer User TicketID StepApproval)
            )
        {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        my %CheckTicket = $TicketObject->TicketGet(
            TicketID      => $GetParam{TicketID},
            DynamicFields => 0,
            UserID        => 1,
            Silent        => 1,
        );

        my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my @Articles      = $ArticleObject->ArticleList(
            TicketID  => $GetParam{TicketID},
            OnlyFirst => 1,
        );
        my $SetArticleID = 0;
        for my $ArticleIDHash (@Articles) {
            for my $ArticleID ( keys %{$ArticleIDHash} ) {
                if ( $ArticleID eq "ArticleID" ) {
                    $SetArticleID = ${$ArticleIDHash}{$ArticleID};
                }
            }
        }
        my $ArticleBackendObject
            = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle(
            TicketID  => $GetParam{TicketID},
            ArticleID => $SetArticleID,
            );
        my %ArticleCheck = $ArticleBackendObject->ArticleGet(
            TicketID  => $GetParam{TicketID},
            ArticleID => $SetArticleID,
        );
        $ArticleCheck{Body} =~ s/\n/<br>/g;
        $ArticleCheck{Body} =~ s/\r/<br>/g;
        my $ArticleBody = $ArticleCheck{Body};

        if ( $GetParam{StepTitle} ) {

            my $TitleSuccess = $TicketObject->TicketTitleUpdate(
                Title    => $GetParam{StepTitle},
                TicketID => $GetParam{TicketID},
                UserID   => 1,
            );
        }

        if ( $GetParam{StepTypeID} && $GetParam{StepTypeID} >= 1 ) {

            my $TypeSuccess = $TicketObject->TicketTypeSet(
                TypeID   => $GetParam{StepTypeID},
                TicketID => $GetParam{TicketID},
                UserID   => 1,
            );
        }

        if ( $GetParam{StepQueueID} && $GetParam{StepQueueID} >= 1 ) {

            my $QueueSuccess = $TicketObject->TicketQueueSet(
                QueueID  => $GetParam{StepQueueID},
                TicketID => $GetParam{TicketID},
                UserID   => 1,
            );
        }

        if ( $GetParam{StepStateID} && $GetParam{StepStateID} >= 1 ) {

            my $StateSuccess = $TicketObject->TicketStateSet(
                StateID      => $GetParam{StepStateID},
                TicketID     => $GetParam{TicketID},
                NoPermission => 1,
                UserID       => 1,
            );
        }

        if ( $GetParam{FromCustomer} ) {

            my @CustomerEmailOne = split(/\</, $GetParam{FromCustomer});
            my @CustomerEmail = split(/\>/, $CustomerEmailOne[1]);

            my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

            my %CustomerList = $CustomerUserObject->CustomerSearch(
                PostMasterSearch => $CustomerEmail[0],
                Valid            => 1,
            );

            my $CustomerLogin = '';
            for my $Customer ( keys %CustomerList ) {
                $CustomerLogin = $Customer;
            }

            my %User = $CustomerUserObject->CustomerUserDataGet(
                User => $CustomerLogin,
            );

            my $CustomerSuccess = $TicketObject->TicketCustomerSet(
                No       => $User{CustomerID},
                User     => $CustomerLogin,
                TicketID => $GetParam{TicketID},
                UserID   => 1,
            );
        }

        if ( $GetParam{User} && $GetParam{User} >= 1 ) {

            my $UserSuccess = $TicketObject->TicketOwnerSet(
                TicketID  => $GetParam{TicketID},
                NewUserID => $GetParam{User},
                UserID    => 1,
            );
        }

        my $Sucess = $TicketProcessStepValueObject->ProcessFieldValueAdd(
            TicketID      => $GetParam{TicketID},
            ProcessID     => $GetParam{ProcessID},
            ProcessStepID => $GetParam{ProcessStepID},
            Report        => $GetParam{Report},
            Title         => $GetParam{StepTitle},
            TypeID        => $GetParam{StepTypeID},
            QueueID       => $GetParam{StepQueueID},
            StateID       => $GetParam{StepStateID},
            FromCustomer  => $GetParam{FromCustomer},
            User          => $GetParam{User},
            Approval      => $GetParam{StepApproval},
            UserID        => $Self->{UserID},
        );

        my %ProcessDataCheck = $TicketProcessesObject->ProcessGet(
            ID => $GetParam{ProcessID},
        ); 

        if ( $ProcessDataCheck{SetArticleID} && $ProcessDataCheck{SetArticleID} == 1 ) {

            my %ProcessStepDataCheck = $ProcessStepObject->ProcessStepGet(
                ID => $GetParam{ProcessStepID},
            );  

            my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
            my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );
            my $QueueObject          = $Kernel::OM->Get('Kernel::System::Queue');

            my $NextQueueID = $ProcessDataCheck{QueueID};
            if ( $GetParam{StepQueueID} ) {
                $NextQueueID = $GetParam{StepQueueID};
            }

            my $Approved = Translatable("Approved");
            my $NotApproved = Translatable("Not approved");

            if ( $GetParam{StepApproval} && $GetParam{StepApproval} == 1 ) {
                $GetParam{Report} .= "<br><br>-----<br>$Approved<br>";
            }

            if ( $GetParam{StepApproval} && $GetParam{StepApproval} == 2 ) {
                $GetParam{Report} .= "<br><br>-----<br>$NotApproved<br>";
            }

            my $From      = "$Self->{UserFirstname} $Self->{UserLastname} <$Self->{UserEmail}>";
            my $ArticleID = $ArticleBackendObject->ArticleCreate(
                TicketID         => $GetParam{TicketID},
                SenderType       => 'agent',
                From             => $From,
                To               => $From,
                Subject          => $ProcessStepDataCheck{Name},
                Body             => $GetParam{Report},
                MimeType         => 'text/html',
                Charset          => $LayoutObject->{UserCharset},
                UserID           => 1,
                IsVisibleForCustomer => 1,
                HistoryType      => 'AddNote',
                HistoryComment       => 'New process step' || '%%',
                AutoResponseType => '',
                OrigHeader => {
                    From    => $From,
                    To      => $Self->{UserLogin},
                    Subject => $GetParam{StepTitle},
                    Body    => $GetParam{Report},
                },
                Queue => $QueueObject->QueueLookup( QueueID => $NextQueueID ),
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
            ProcessID     => $GetParam{ProcessID},
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

                my $Sucess = $TicketProcessStepValueObject->ProcessDynamicFieldValueAdd(
                    TicketID       => $GetParam{TicketID},
                    ProcessID      => $GetParam{ProcessID},
                    ProcessStepID  => $GetParam{ProcessStepID},
                    DynamicfieldID => $DynamicFieldToSet,
                    FieldValue     => $GetParam{$ParamName},
                    UserID         => $Self->{UserID},
                );

                my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

                # set the value
                my $DynamicFieldSuccess = $DynamicFieldBackendObject->ValueSet(
                    DynamicFieldConfig => $DynamicField,
                    ObjectID           => $GetParam{TicketID},
                    Value              => $GetParam{$ParamName},
                    UserID             => $Self->{UserID},
                );
            }
            $DynamicCheckNum        = 0;
            $DynamicProcessFieldNum = 0;
        }

        my $ProcessStepID = '';

        if ( $GetParam{StepApproval} ) {

            if ( $GetParam{StepApproval} == 1 ) {
    
                my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                    ID => $GetParam{ProcessStepID},
                );      

                if ( $ProcessStepData{ToIDFromOne} && $ProcessStepData{ToIDFromOne} >= 1 ) {
    
                    if ( $GetParam{ProcessStepID} > $ProcessStepData{ToIDFromOne} ) {
    
                        $ProcessStepID = $ProcessStepData{ToIDFromOne};
    
                        my $Success = $ProcessStepObject->ProcessStepReadyReset(
                            ToProcessStepID => $ProcessStepData{ToIDFromOne},
                            TicketID        => $GetParam{TicketID},
                        );
                    }
                    else {

                        $ProcessStepID = $ProcessStepData{ToIDFromOne};

                        my $Success = $ProcessStepObject->ProcessStepReadyResetForward(
                            ToProcessStepID => $ProcessStepData{ToIDFromOne},
                            TicketID        => $GetParam{TicketID},
                        );
                    }
                }
                else {    
    
                    my %CheckProcessStepData = $ProcessStepObject->ProcessStepGet(
                        ID => $GetParam{ProcessStepID},
                    );  

                    my $ProcessEnd = 0;
                    if ( $CheckProcessStepData{WithoutConditionEnd} && $CheckProcessStepData{WithoutConditionEnd} == 1 ) {

                        my $SuccessEnd = $TicketProcessesObject->ProcessEnd(
                            ProcessID => $GetParam{ProcessID},
                            TicketID  => $GetParam{TicketID},
                        );
    
                        my $StateObject = $Kernel::OM->Get('Kernel::System::State');
                        my $StateID = $StateObject->StateLookup(
                            State => 'closed successful',
                        );
    
                        my $StateSuccess = $TicketObject->TicketStateSet(
                            StateID      => $StateID,
                            TicketID     => $GetParam{TicketID},
                            NoPermission => 1,
                            UserID       => 1,
                        );

                        $TicketObject->TicketLockSet(
                            TicketID => $GetParam{TicketID},
                            Lock     => 'unlock',
                            UserID   => 1,
                        );

                        $ProcessStepID = $GetParam{ProcessStepID};
                        $ProcessEnd    = 1;

                        my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                            ProcessStepID => $GetParam{ProcessStepID},
                            TicketID      => $GetParam{TicketID},
                        );
    
                        if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
            
                            my $TypeSuccess = $TicketObject->TicketTypeSet(
                                TypeID   => $TicketTransition{TypeID},
                                TicketID => $GetParam{TicketID},
                                UserID   => 1,
                            );
                        }
    
                        if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {
    
                            my $QueueSuccess = $TicketObject->TicketQueueSet(
                                QueueID  => $TicketTransition{QueueID},
                                TicketID => $GetParam{TicketID},
                                UserID   => 1,
                            );
                        }
                    }
                    else {

                        $ProcessStepID = $ProcessStepObject->SearchToIDFromOne(
                            ProcessStepID => $GetParam{ProcessStepID},
                            StepNo        => 1,
                            TicketID      => $GetParam{TicketID},
                        );

                        if ( !$ProcessStepID || $ProcessStepID == 0 ) {

                            $ProcessStepID = $Self->SearchToIDFromOneNext(
                                ProcessStepID => $GetParam{ProcessStepID},
                                TicketID      => $GetParam{TicketID},
                            );
                        }

                        my $ProcessStepIDNext = $TicketProcessTransitionObject->SearchNextParallel(
                            ProcessStepID => $ProcessStepID,
                            TicketID      => $GetParam{TicketID},
                        );
                        my $ProcessStepIDCheck = $ProcessStepObject->SearchNextProcessStepParallel(
                            ProcessStepID => $ProcessStepIDNext,
                            TicketID      => $GetParam{TicketID},
                        );

                        for my $SetNextStep ( $ProcessStepID .. $ProcessStepIDCheck ) {

                            my $Success = $ProcessStepObject->ProcessStepReadyUpdate(
                                ProcessStepID => $SetNextStep,
                                StepActive    => 1,
                                TicketID      => $GetParam{TicketID},
                            );

                            my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                                ID => $SetNextStep,
                            );   

                            my $TicketProcessesObject = $Kernel::OM->Get('Kernel::System::TicketProcesses');
                            my %ProcessDataTransver = $TicketProcessesObject->ProcessGet(
                                ID => $GetParam{ProcessID},
                            ); 

                            if ( $ProcessStepData{StepArtID} == 2) {
    
                                # get needed objects
                                my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                                my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                                my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                                my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                                my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
    
                                my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                                my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';
    
                                my $To = $ProcessStepData{ApproverEmail};

                                my %Ticket = $TicketObject->TicketGet(
                                    TicketID      => $GetParam{TicketID},
                                    DynamicFields => 0,
                                    UserID        => 1,
                                    Silent        => 1,
                                );

                                if ( $ProcessStepData{ApproverGroupID} && $ProcessStepData{ApproverGroupID} == 1 )  {
    
                                    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    
                                    my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                                        User => $Ticket{CustomerUserID},
                                    );
    
                                    if ( $To ) {
                                        $To .= ',' . $CustomerUser{UserEmail};
                                    }
                                    else {
                                        $To .= $CustomerUser{UserEmail};
                                    }
                                }

                                if ( !$ProcessStepData{NotifyAgent} ) {
                                    $ProcessStepData{NotifyAgent} = 'yes';
                                }

                                if ( $ProcessStepData{NotifyAgent} eq "yes" )  {

                                    if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {
    
                                        my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                                            GroupID => $ProcessStepData{GroupID},
                                            Type    => 'ro',
                                        );
        
                                        for my $UserLogin ( keys %ApproverUsers ) {
                               
                                            if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {
        
                                                my %ApproverUser = $UserObject->GetUserData(
                                                    UserID => $UserLogin,
                                                );
        
                                                if ( $To ) {
                                                    $To .= ',' . $ApproverUser{UserEmail};
                                                }
                                                else {
                                                    $To .= $ApproverUser{UserEmail};
                                                }
                                            }
                                        }
                                    }
                                }

                                my $SetFullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                                    UserLogin => $Ticket{CustomerUserID},
                                );

                                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - approval required';
    
                                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                                $NotificationBodyPre .= '<br><br>';

                                if ( $ProcessStepData{SetArticleID} && $ProcessStepData{SetArticleID} == 1 ) {
                                    $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $GetParam{Report};
                                }
                                else {
                                    $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                                }

                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Genehmigung erforderlich.<br>Bitte klicken Sie auf eine Entscheidung.';
                                $NotificationBodyPre .= '<br><br>';

                                $NotificationBodyPre .= 'Antragsteller: ' . $SetFullName;
                                $NotificationBodyPre .= '<br><br>';

                                $NotificationBodyPre .= $ArticleBody;
                                $NotificationBodyPre .= '<br><br>';

                                my $HttpType    = $ConfigObject->Get('HttpType');
                                my $FQDN        = $ConfigObject->Get('FQDN');
                                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
    
                                my $NotificationBody = "<!DOCTYPE html>
                                <html lang=\"de-DE\">
                                <head>
                                <meta charset=\"utf-8\">
                                </head>
                                <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
            
                                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
            
                                Es wurde eine Anfrage eingereicht welche genehmigungspflichtig ist.\n<br>
                                Zum Genehmigen oder Ablehnen bitte einen der nachstehenden links klicken.\n<br><br>
    
                                </div>
    
                                <div style=\"color:blue;width:100%;font-size:16px;font-family:Helvetica, Arial, sans-serif;font-weight:bold;\">
    
                                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                    . "ProcessApproval.pl?ProcessID=$GetParam{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$GetParam{TicketID};Art=genehmigt\">Genehmigen</a>
                                \n<br>\n<br>oder\n<br>\n<br>
                                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                    . "ProcessApproval.pl?ProcessID=$GetParam{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$GetParam{TicketID};Art=abgelehnt\">Ablehnen</a>
                                \n\n<br><br>
            
                                </div>
    
                                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
                                Es wurde folgende Anfrage gestellt:\n\n<br><br>
            
                                $NotificationBodyPre
                                ";
    
                                if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {
    
                                    $NotificationBody .= "
                                    <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                        . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                                        . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                                    \n\n<br><br>
                                    ";
    
                                }
    
                                $NotificationBody .= "
                                </div>
    
                                </body>
                                </html>
                                ";

                                if ( $To ne '' ) {

                                    my $Sent = $EmailObject->Send(
                                        From     => $From,
                                        To       => $To,
                                        Subject  => $NotificationSubject,
                                        MimeType => 'text/html',
                                        Charset  => 'utf-8',
                                        Body     => $NotificationBody,
                                    );

                                    my $Success = $TicketObject->HistoryAdd(
                                        Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                                        HistoryType  => 'SendAgentNotification',
                                        TicketID     => $GetParam{TicketID},
                                        CreateUserID => 1,
                                    );

                                }
                            }
                            else {
    
                                # get needed objects
                                my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                                my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                                my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                                my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                                my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
    
                                my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                                my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';
    
                                my $To = '';
    
                                my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                                    GroupID => $ProcessStepData{GroupID},
                                    Type    => 'ro',
                                );

                                if ( !$ProcessStepData{NotifyAgent} ) {
                                    $ProcessStepData{NotifyAgent} = 'yes';
                                }

                                if ( $ProcessStepData{NotifyAgent} eq "yes" )  {

                                    my $GroupUserValue = 0;
                                    for my $UserLogin ( keys %ApproverUsers ) {
                           
                                        if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {
    
                                           $GroupUserValue ++;
    
                                            my %ApproverUser = $UserObject->GetUserData(
                                                UserID => $UserLogin,
                                            );
    
                                            if ( $GroupUserValue == 1 ) {
                                        $To .= $ApproverUser{UserEmail};
                                            }
                                            else {
                                                $To .= ',' . $ApproverUser{UserEmail};
                                            }
                                        }
                                    }
                                }
    
                                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - ' . $ProcessStepData{Name};
    
                                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Aktion erforderlich.';
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= $ArticleBody;
                                $NotificationBodyPre .= '<br><br>';

                                my $HttpType    = $ConfigObject->Get('HttpType');
                                my $FQDN        = $ConfigObject->Get('FQDN');
                                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
    
                                my $NotificationBody = "<!DOCTYPE html>
                                <html lang=\"de-DE\">
                                <head>
                                <meta charset=\"utf-8\">
                                </head>
                                <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
            
                                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
            
                                Es wurde eine Anfrage eingereicht welche bearbeitet werden muss.\n<br>
    
                                Es wurde folgende Anfrage gestellt:\n\n<br><br>
            
                                $NotificationBodyPre
            
                                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                                \n\n<br><br>
    
                                </div>
    
                                </body>
                                </html>
                                ";

                                if ( $To ne '' ) {

                                    my $Sent = $EmailObject->Send(
                                        From     => $From,
                                        To       => $To,
                                        Subject  => $NotificationSubject,
                                        MimeType => 'text/html',
                                        Charset  => 'utf-8',
                                        Body     => $NotificationBody,
                                    );

                                    my $Success = $TicketObject->HistoryAdd(
                                        Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                                        HistoryType  => 'SendAgentNotification',
                                        TicketID     => $GetParam{TicketID},
                                        CreateUserID => 1,
                                    );

                                }
                            }
                        }
                    }
                }

                my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                    ProcessStepID => $ProcessStepID,
                    TicketID      => $GetParam{TicketID},
                );

                if ( $TicketTransition{StateID} && $TicketTransition{StateID} >= 1 ) {

                    my $StateSuccess = $TicketObject->TicketStateSet(
                        StateID      => $TicketTransition{StateID},
                        TicketID     => $GetParam{TicketID},
                        NoPermission => 1,
                        UserID       => 1,
                    );
                }

                if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
        
                    my $TypeSuccess = $TicketObject->TicketTypeSet(
                        TypeID   => $TicketTransition{TypeID},
                        TicketID => $GetParam{TicketID},
                        UserID   => 1,
                    );
                }

                if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {

                    my $QueueSuccess = $TicketObject->TicketQueueSet(
                        QueueID  => $TicketTransition{QueueID},
                        TicketID => $GetParam{TicketID},
                        UserID   => 1,
                    );
                }

                my $Success = $ProcessStepObject->ProcessStepReadyUpdate(
                    ProcessStepID => $ProcessStepID,
                    StepActive    => 1,
                    TicketID      => $GetParam{TicketID},
                );
            }

            if ( $GetParam{StepApproval} == 2 ) {
    
                my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                    ID => $GetParam{ProcessStepID},
                );      

                if ( $ProcessStepData{ToIDFromTwo} && $ProcessStepData{ToIDFromTwo} >= 1 ) {
    
                    if ( $GetParam{ProcessStepID} > $ProcessStepData{ToIDFromTwo} ) {
    
                        $ProcessStepID = $ProcessStepData{ToIDFromTwo};

                        my $Success = $ProcessStepObject->ProcessStepReadyReset(
                            ToProcessStepID => $ProcessStepData{ToIDFromTwo},
                            TicketID        => $GetParam{TicketID},
                        );
                    }
                    else {
    
                        $ProcessStepID = $ProcessStepData{ToIDFromTwo};

                        my $Success = $ProcessStepObject->ProcessStepReadyResetForward(
                            ToProcessStepID => $ProcessStepData{ToIDFromTwo},
                            TicketID        => $GetParam{TicketID},
                        );
                    }
                }
                else {    
    
                    my %CheckProcessStepData = $ProcessStepObject->ProcessStepGet(
                        ID => $GetParam{ProcessStepID},
                    );   

                    my $ProcessEnd = 0;

                    if ( $CheckProcessStepData{NotApproved} && $CheckProcessStepData{NotApproved} == 1 ) {

                        my $SuccessEnd = $TicketProcessesObject->ProcessEnd(
                            ProcessID => $GetParam{ProcessID},
                            TicketID  => $GetParam{TicketID},
                        );
    
                        my $StateObject = $Kernel::OM->Get('Kernel::System::State');
                        my $StateID = $StateObject->StateLookup(
                            State => 'closed successful',
                        );
    
                        my $StateSuccess = $TicketObject->TicketStateSet(
                            StateID      => $StateID,
                            TicketID     => $GetParam{TicketID},
                            NoPermission => 1,
                            UserID       => 1,
                        );

                        $TicketObject->TicketLockSet(
                            TicketID => $GetParam{TicketID},
                            Lock     => 'unlock',
                            UserID   => 1,
                        );

                        $ProcessStepID = $GetParam{ProcessStepID};
                        $ProcessEnd    = 1;

                        my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                            ProcessStepID => $GetParam{ProcessStepID},
                            TicketID      => $GetParam{TicketID},
                        );
    
                        if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
            
                            my $TypeSuccess = $TicketObject->TicketTypeSet(
                                TypeID   => $TicketTransition{TypeID},
                                TicketID => $GetParam{TicketID},
                                UserID   => 1,
                            );
                        }
    
                        if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {
    
                            my $QueueSuccess = $TicketObject->TicketQueueSet(
                                QueueID  => $TicketTransition{QueueID},
                                TicketID => $GetParam{TicketID},
                                UserID   => 1,
                            );
                        }
                    }
                    else {

                        $ProcessStepID = $ProcessStepObject->SearchToIDFromTwo(
                            ProcessStepID => $GetParam{ProcessStepID},
                            StepNo        => 2,
                            TicketID      => $GetParam{TicketID},
                        );
                    }
    
                    my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                        ID => $ProcessStepID,
                    );    
    
                    my %ProcessDataTransver = $TicketProcessesObject->ProcessGet(
                        ID => $GetParam{ProcessID},
                    );    

                    if ( $ProcessEnd < 1 ) {

                        if ( $ProcessStepData{StepArtID} == 2 ) {
    
                            # get needed objects
                            my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                            my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                            my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                            my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                            my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
    
                            my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                            my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';
    
                            my $To = $ProcessStepData{ApproverEmail};

                            my %Ticket = $TicketObject->TicketGet(
                                TicketID      => $GetParam{TicketID},
                                DynamicFields => 0,
                                UserID        => 1,
                                Silent        => 1,
                            );

                            if ( $ProcessStepData{ApproverGroupID} && $ProcessStepData{ApproverGroupID} == 1 )  {
    
                                my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    
                                my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                                    User => $Ticket{CustomerUserID},
                                );
    
                                if ( $To ) {
                                    $To .= ',' . $CustomerUser{UserEmail};
                                }
                                else {
                                    $To .= $CustomerUser{UserEmail};
                                }
                            }

                            if ( !$ProcessStepData{NotifyAgent} ) {
                                $ProcessStepData{NotifyAgent} = 'yes';
                            }

                            if ( $ProcessStepData{NotifyAgent} eq "yes" )  {

                                if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {
    
                                    my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                                        GroupID => $ProcessStepData{GroupID},
                                        Type    => 'ro',
                                    );
        
                                    for my $UserLogin ( keys %ApproverUsers ) {
                               
                                        if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {
        
                                            my %ApproverUser = $UserObject->GetUserData(
                                                UserID => $UserLogin,
                                            );
        
                                            if ( $To ) {
                                                $To .= ',' . $ApproverUser{UserEmail};
                                            }
                                            else {
                                                $To .= $ApproverUser{UserEmail};
                                            }
                                        }
                                    }
                                }
                            }

                            my $SetFullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                                UserLogin => $Ticket{CustomerUserID},
                            );

                            my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - approval required';
    
                            my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                            $NotificationBodyPre .= '<br><br>';

                            if ( $ProcessStepData{SetArticleID} && $ProcessStepData{SetArticleID} == 1 ) {
                                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $GetParam{Report};
                            }
                            else {
                                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                            }

                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= 'Genehmigung erforderlich.<br>Bitte klicken Sie auf eine Entscheidung.';
                            $NotificationBodyPre .= '<br><br>';

                            $NotificationBodyPre .= 'Antragsteller: ' . $SetFullName;
                            $NotificationBodyPre .= '<br><br>';

                            $NotificationBodyPre .= $ArticleBody;
                            $NotificationBodyPre .= '<br><br>';

                            my $HttpType    = $ConfigObject->Get('HttpType');
                            my $FQDN        = $ConfigObject->Get('FQDN');
                            my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
    
                            my $NotificationBody = "<!DOCTYPE html>
                            <html lang=\"de-DE\">
                            <head>
                            <meta charset=\"utf-8\">
                            </head>
                            <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
            
                            <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
            
                            Es wurde eine Anfrage eingereicht welche genehmigungspflichtig ist.\n<br>
                            Zum Genehmigen oder Ablehnen bitte einen der nachstehenden links klicken.\n<br><br>
    
                            </div>
    
                            <div style=\"color:blue;width:100%;font-size:16px;font-family:Helvetica, Arial, sans-serif;font-weight:bold;\">
    
                            <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                . "ProcessApproval.pl?ProcessID=$GetParam{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$GetParam{TicketID};Art=genehmigt\">Genehmigen</a>
                            \n<br>\n<br>oder\n<br>\n<br>
                            <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                . "ProcessApproval.pl?ProcessID=$GetParam{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$GetParam{TicketID};Art=abgelehnt\">Ablehnen</a>
                            \n\n<br><br>
            
                            </div>
    
                            <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
    
                            Es wurde folgende Anfrage gestellt:\n\n<br><br>
            
                            $NotificationBodyPre
                            ";
    
                            if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {
    
                                $NotificationBody .= "
                                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                                \n\n<br><br>
                                ";
    
                            }
    
                            $NotificationBody .= "
                            </div>
    
                            </body>
                            </html>
                            ";

                            if ( $To ne '' ) {

                                my $Sent = $EmailObject->Send(
                                    From     => $From,
                                    To       => $To,
                                    Subject  => $NotificationSubject,
                                    MimeType => 'text/html',
                                    Charset  => 'utf-8',
                                    Body     => $NotificationBody,
                                );

                                my $Success = $TicketObject->HistoryAdd(
                                    Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                                    HistoryType  => 'SendAgentNotification',
                                    TicketID     => $GetParam{TicketID},
                                    CreateUserID => 1,
                                );

                            }
                        }
                        else {
    
                            # get needed objects
                            my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                            my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                            my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                            my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                            my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
    
                            my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                            my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';
    
                            my $To = '';
    
                            my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                                GroupID => $ProcessStepData{GroupID},
                                Type    => 'ro',
                            );

                            if ( !$ProcessStepData{NotifyAgent} ) {
                                $ProcessStepData{NotifyAgent} = 'yes';
                            }

                            if ( $ProcessStepData{NotifyAgent} eq "yes" )  {

                                my $GroupUserValue = 0;
                                for my $UserLogin ( keys %ApproverUsers ) {
                           
                                    if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {
    
                                       $GroupUserValue ++;
    
                                        my %ApproverUser = $UserObject->GetUserData(
                                            UserID => $UserLogin,
                                        );
    
                                        if ( $GroupUserValue == 1 ) {
                                            $To .= $ApproverUser{UserEmail};
                                        }
                                        else {
                                            $To .= ',' . $ApproverUser{UserEmail};
                                        }
                                    }
                                }
                            }
    
                            my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - ' . $ProcessStepData{Name};
    
                            my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= 'Aktion erforderlich.';
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= $ArticleBody;
                            $NotificationBodyPre .= '<br><br>';

                            my $HttpType    = $ConfigObject->Get('HttpType');
                            my $FQDN        = $ConfigObject->Get('FQDN');
                            my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
    
                            my $NotificationBody = "<!DOCTYPE html>
                            <html lang=\"de-DE\">
                            <head>
                            <meta charset=\"utf-8\">
                            </head>
                            <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
            
                            <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
            
                            Es wurde eine Anfrage eingereicht welche bearbeitet werden muss.\n<br>
    
                            Es wurde folgende Anfrage gestellt:\n\n<br><br>
            
                            $NotificationBodyPre
            
                            <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                                . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                            \n\n<br><br>
    
                            </div>
    
                            </body>
                            </html>
                            ";

                            if ( $To ne '' ) {

                                my $Sent = $EmailObject->Send(
                                    From     => $From,
                                    To       => $To,
                                    Subject  => $NotificationSubject,
                                    MimeType => 'text/html',
                                    Charset  => 'utf-8',
                                    Body     => $NotificationBody,
                                );

                                my $Success = $TicketObject->HistoryAdd(
                                    Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                                    HistoryType  => 'SendAgentNotification',
                                    TicketID     => $GetParam{TicketID},
                                    CreateUserID => 1,
                                );

                            }
                        }
                    }
                }

                my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                    ProcessStepID => $ProcessStepID,
                    TicketID      => $GetParam{TicketID},
                );

                if ( $TicketTransition{StateID} && $TicketTransition{StateID} >= 1 ) {

                    my $StateSuccess = $TicketObject->TicketStateSet(
                        StateID      => $TicketTransition{StateID},
                        TicketID     => $GetParam{TicketID},
                        NoPermission => 1,
                        UserID       => 1,
                    );
                }

                if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
        
                    my $TypeSuccess = $TicketObject->TicketTypeSet(
                        TypeID   => $TicketTransition{TypeID},
                        TicketID => $GetParam{TicketID},
                        UserID   => 1,
                    );
                }

                if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {

                    my $QueueSuccess = $TicketObject->TicketQueueSet(
                        QueueID  => $TicketTransition{QueueID},
                        TicketID => $GetParam{TicketID},
                        UserID   => 1,
                    );
                }

                my $Success = $ProcessStepObject->ProcessStepReadyUpdate(
                    ProcessStepID => $ProcessStepID,
                    StepActive    => 1,
                    TicketID      => $GetParam{TicketID},
                );
            }
        }

        if ( !$GetParam{StepApproval} ) {

            my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                ID => $GetParam{ProcessStepID},
            );

            if ( $ProcessStepData{StepEnd} && $ProcessStepData{StepEnd} == 1 ) {

                my $SuccessEnd = $TicketProcessesObject->ProcessEnd(
                    ProcessID => $GetParam{ProcessID},
                    TicketID  => $GetParam{TicketID},
                );

                my $StateObject = $Kernel::OM->Get('Kernel::System::State');
                my $StateID = $StateObject->StateLookup(
                    State => 'closed successful',
                );

                my $StateSuccess = $TicketObject->TicketStateSet(
                    StateID      => $StateID,
                    TicketID     => $GetParam{TicketID},
                    NoPermission => 1,
                    UserID       => 1,
                );

                $TicketObject->TicketLockSet(
                    TicketID => $GetParam{TicketID},
                    Lock     => 'unlock',
                    UserID   => 1,
                );

            }
            else {

                my %ProcessConditionsList = $TicketProcessConditionsObject->ProcessConditionsList(
                    ProcessID     => $GetParam{ProcessID},
                    ProcessStepID => $GetParam{ProcessStepID},
                );

                my $CheckConditionID = '';
                for my $ConditionID ( keys %ProcessConditionsList ) {
                    $CheckConditionID = $ConditionID;
                }

                my $AllConditions = 0;
                my $IfConditions = 0;
                if ( $CheckConditionID ) {

                    my %Conditions = $TicketProcessConditionsObject->ProcessConditionsGet(
                        ProcessConditionsID => $CheckConditionID,
                    );
    
                    if ( $Conditions{Queue} && $Conditions{Queue} >= 1 ) {
                        $AllConditions ++;
                    }
                    if ( $Conditions{Title} && $Conditions{Title} ne '' ) {
                        $AllConditions ++;
                    }
                    if ( $Conditions{CustomerUser} && $Conditions{CustomerUser} ne '' ) {
                        $AllConditions ++;
                    }
                    if ( $Conditions{Owner} && $Conditions{Owner} >= 1 ) {
                        $AllConditions ++;
                    }
    
                    if ( $Conditions{Queue} >= 1 && $Conditions{Queue} == $GetParam{StepQueueID} ) {
                        $IfConditions ++;
                    }
                    if  ( $Conditions{Title} && $GetParam{StepTitle} =~ m/$Conditions{Title}/ ) {
                        $IfConditions ++;
                    }
                    if  ( $Conditions{CustomerUser} && $GetParam{FromCustomer} eq "$Conditions{CustomerUser}" ) {
                        $IfConditions ++;
                    }
                    if ( $Conditions{Owner} ) {
                        if ( $Conditions{Owner} >= 1 && $Conditions{Owner} == $GetParam{User} ) {
                            $IfConditions ++;
                        }
                    }
                }

                my $DynamicFieldObject                   = $Kernel::OM->Get('Kernel::System::DynamicField');
                my $DynamicProcessFieldsObject           = $Kernel::OM->Get('Kernel::System::TicketDynamicProcessFields');
                my $DynamicFieldBackendObject            = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
                my $ParamObject                          = $Kernel::OM->Get('Kernel::System::Web::Request');
                my $TicketProcessDynamicConditionsObject = $Kernel::OM->Get('Kernel::System::TicketProcessDynamicConditions');

                my $DynamicFieldList = $DynamicFieldObject->DynamicFieldList(
                    Valid      => 1,
                    ObjectType => 'Ticket',
                    ResultType => 'HASH',
                );
            
                my %DynamicProcessFieldList = $DynamicProcessFieldsObject->DynamicProcessFieldList(
                    ProcessID     => $GetParam{ProcessID},
                    ProcessStepID => $GetParam{ProcessStepID},
                );

                my %ProcessDynamicConditionsList = $TicketProcessDynamicConditionsObject->ProcessDynamicConditionsList(
                    ProcessID     => $GetParam{ProcessID},
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

                        for my $ProcessConditionID ( keys %ProcessDynamicConditionsList ) {

                            if ( $ProcessDynamicConditionsList{$ProcessConditionID} == $DynamicFieldToSet ) {

                                $AllConditions ++;

                                my %DynamicConditions = $TicketProcessDynamicConditionsObject->ProcessDynamicConditionsGet(
                                    DynamicConditionsID => $ProcessConditionID,
                                );

                                if ( $DynamicConditions{DynamicValue} eq "$GetParam{$ParamName}" ) {
                                    $IfConditions ++;
                                }
                            }
                        }
                    }
                    $DynamicCheckNum        = 0;
                    $DynamicProcessFieldNum = 0;
                }

                my $SetStepNo = 1;
                if ( ( $AllConditions >= 1 && $IfConditions >= 1 ) && $AllConditions == $IfConditions ) {
                    $SetStepNo = 2;
                }

                if ( $SetStepNo == 1 ) {

                    if ( $ProcessStepData{ToIDFromOne} && $ProcessStepData{ToIDFromOne} >= 1 ) {
        
                       if ( $GetParam{ProcessStepID} > $ProcessStepData{ToIDFromOne} ) {
        
                            $ProcessStepID = $ProcessStepData{ToIDFromOne};
        
                            my $Success = $ProcessStepObject->ProcessStepReadyReset(
                                ToProcessStepID => $ProcessStepData{ToIDFromOne},
                                TicketID        => $GetParam{TicketID},
                            );
                        }
                        else {

                            $ProcessStepID = $ProcessStepData{ToIDFromOne};

                            my $Success = $ProcessStepObject->ProcessStepReadyResetForward(
                                ToProcessStepID => $ProcessStepData{ToIDFromOne},
                                TicketID        => $GetParam{TicketID},
                            );
                        }
                    }
                    else {

                        my %CheckProcessStepData = $ProcessStepObject->ProcessStepGet(
                            ID => $GetParam{ProcessStepID},
                        ); 
    
                        if ( $CheckProcessStepData{WithoutConditionEnd} && $CheckProcessStepData{WithoutConditionEnd} == 1 ) {
    
                            my $SuccessEnd = $TicketProcessesObject->ProcessEnd(
                                ProcessID => $GetParam{ProcessID},
                                TicketID  => $GetParam{TicketID},
                            );
            
                            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
                            my $StateID = $StateObject->StateLookup(
                                State => 'closed successful',
                            );
            
                            my $StateSuccess = $TicketObject->TicketStateSet(
                                StateID      => $StateID,
                                TicketID     => $GetParam{TicketID},
                                NoPermission => 1,
                                UserID       => 1,
                            );
    
                            $TicketObject->TicketLockSet(
                                TicketID => $GetParam{TicketID},
                                Lock     => 'unlock',
                                UserID   => 1,
                            );    

                            my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                                ProcessStepID => $GetParam{ProcessStepID},
                                TicketID      => 1,
                            );
            
                            if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
                    
                                my $TypeSuccess = $TicketObject->TicketTypeSet(
                                    TypeID   => $TicketTransition{TypeID},
                                    TicketID => $GetParam{TicketID},
                                    UserID   => 1,
                                );
                            }
            
                            if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {
            
                                my $QueueSuccess = $TicketObject->TicketQueueSet(
                                    QueueID  => $TicketTransition{QueueID},
                                    TicketID => $GetParam{TicketID},
                                    UserID   => 1,
                                );
                            }
    
                            # load new URL in window
                            my $ReturnURL = "Action=AgentTicketZoom;TicketID=$GetParam{TicketID};";
                    
                            return $LayoutObject->PopupClose(
                                URL => $ReturnURL,
                            );
                        }
                        else {
    
                            $ProcessStepID = $ProcessStepObject->SearchToIDFromOne(
                                ProcessStepID => $GetParam{ProcessStepID},
                                StepNo        => 1,
                                TicketID      => $GetParam{TicketID},
                            );

                            my $Success = $ProcessStepObject->ProcessStepReadyUpdate(
                                ProcessStepID => $ProcessStepID,
                                StepActive    => 1,
                                TicketID      => $GetParam{TicketID},
                            );

                            my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                                ID => $ProcessStepID,
                            );

                            # get needed objects
                            my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                            my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                            my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                            my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                            my $UserObject          = $Kernel::OM->Get('Kernel::System::User');

                            my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                            my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';

                            my $To = '';

                            my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                                GroupID => $ProcessStepData{GroupID},
                                Type    => 'ro',
                            );

                            if ( !$ProcessStepData{NotifyAgent} ) {
                               $ProcessStepData{NotifyAgent} = 'yes';
                        }

                            if ( $ProcessStepData{NotifyAgent} eq "yes" )  {

                                my $GroupUserValue = 0;
                                for my $UserLogin ( keys %ApproverUsers ) {
                       
                                    if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {

                                       $GroupUserValue ++;

                                        my %ApproverUser = $UserObject->GetUserData(
                                            UserID => $UserLogin,
                                        );

                                        if ( $GroupUserValue == 1 ) {
                                            $To .= $ApproverUser{UserEmail};
                                        }
                                        else {
                                            $To .= ',' . $ApproverUser{UserEmail};
                                        }
                                    }
                                }
                            }

                            my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessStepData{Name} . ' - ' . $ProcessStepData{Name};

                            my $NotificationBodyPre = 'Process-Description: ' . $ProcessStepData{Description};
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= 'Aktion erforderlich.';
                            $NotificationBodyPre .= '<br><br>';
                            $NotificationBodyPre .= $ArticleBody;
                            $NotificationBodyPre .= '<br><br>';

                            my $HttpType    = $ConfigObject->Get('HttpType');
                            my $FQDN        = $ConfigObject->Get('FQDN');
                            my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

                            my $NotificationBody = "<!DOCTYPE html>
                            <html lang=\"de-DE\">
                            <head>
                            <meta charset=\"utf-8\">
                            </head>
                            <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
        
                            <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
        
                            Es wurde eine Anfrage eingereicht welche bearbeitet werden muss.\n<br>

                            Es wurde folgende Anfrage gestellt:\n\n<br><br>
        
                            $NotificationBodyPre
        
                            <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                                . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                            \n\n<br><br>

                            </div>

                            </body>
                            </html>
                            ";

                            if ( $To ne '' ) {

                                my $Sent = $EmailObject->Send(
                                    From     => $From,
                                    To       => $To,
                                    Subject  => $NotificationSubject,
                                    MimeType => 'text/html',
                                    Charset  => 'utf-8',
                                    Body     => $NotificationBody,
                                );

                                my $Success = $TicketObject->HistoryAdd(
                                    Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                                    HistoryType  => 'SendAgentNotification',
                                    TicketID     => $GetParam{TicketID},
                                    CreateUserID => 1,
                                );
                            }
                        }
                    }
                }
                if ( $SetStepNo == 2 ) {

                    if ( $ProcessStepData{ToIDFromTwo} && $ProcessStepData{ToIDFromTwo} >= 1 ) {
        
                        if ( $GetParam{ProcessStepID} > $ProcessStepData{ToIDFromTwo} ) {
        
                            $ProcessStepID = $ProcessStepData{ToIDFromTwo};

                            my $Success = $ProcessStepObject->ProcessStepReadyReset(
                                ToProcessStepID => $ProcessStepData{ToIDFromTwo},
                                TicketID        => $GetParam{TicketID},
                            );
                        }
                        else {
        
                            $ProcessStepID = $ProcessStepData{ToIDFromTwo};

                            my $Success = $ProcessStepObject->ProcessStepReadyResetForward(
                                ToProcessStepID => $ProcessStepData{ToIDFromTwo},
                                TicketID        => $GetParam{TicketID},
                            );
                        }
                    }
                    else {

                        my %CheckProcessStepData = $ProcessStepObject->ProcessStepGet(
                            ID => $GetParam{ProcessStepID},
                        ); 
    
                        if ( $CheckProcessStepData{WithConditionsEnd} && $CheckProcessStepData{WithConditionsEnd} == 1 ) {
    
                            my $SuccessEnd = $TicketProcessesObject->ProcessEnd(
                                ProcessID => $GetParam{ProcessID},
                                TicketID  => $GetParam{TicketID},
                            );
            
                            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
                            my $StateID = $StateObject->StateLookup(
                                State => 'closed successful',
                            );
            
                            my $StateSuccess = $TicketObject->TicketStateSet(
                                StateID      => $StateID,
                                TicketID     => $GetParam{TicketID},
                                NoPermission => 1,
                                UserID       => 1,
                            );
    
                            $TicketObject->TicketLockSet(
                                TicketID => $GetParam{TicketID},
                                Lock     => 'unlock',
                                UserID   => 1,
                            );    

                            my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                                ProcessStepID => $GetParam{ProcessStepID},
                                TicketID      => $GetParam{TicketID},
                            );
            
                            if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
                    
                                my $TypeSuccess = $TicketObject->TicketTypeSet(
                                    TypeID   => $TicketTransition{TypeID},
                                    TicketID => $GetParam{TicketID},
                                    UserID   => 1,
                                );
                            }
            
                            if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {
            
                                my $QueueSuccess = $TicketObject->TicketQueueSet(
                                    QueueID  => $TicketTransition{QueueID},
                                    TicketID => $GetParam{TicketID},
                                    UserID   => 1,
                                );
                            }
    
                            # load new URL in window
                            my $ReturnURL = "Action=AgentTicketZoom;TicketID=$GetParam{TicketID};";
                    
                            return $LayoutObject->PopupClose(
                                URL => $ReturnURL,
                            );
                        }
                        else {
    
                            $ProcessStepID = $ProcessStepObject->SearchToIDFromTwo(
                                ProcessStepID => $GetParam{ProcessStepID},
                                StepNo        => 2,
                                TicketID      => $GetParam{TicketID},
                            );
                        }
                    }
                }

                if ( !$ProcessStepID ) {

                    # load new URL in window
                    my $ReturnURL = "Action=AgentTicketZoom;TicketID=$GetParam{TicketID};ProcessError=$GetParam{ProcessStepID};";
            
                    return $LayoutObject->PopupClose(
                        URL => $ReturnURL,
                    );

                }

                my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                    ID => $ProcessStepID,
                );  
    
                my %ProcessDataTransver = $TicketProcessesObject->ProcessGet(
                    ID => $GetParam{ProcessID},
                );    

                if ( $ProcessStepData{StepArtID} == 2 ) {

                    # get needed objects
                    my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                    my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                    my $UserObject          = $Kernel::OM->Get('Kernel::System::User');

                    my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                    my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';

                    my $To = $ProcessStepData{ApproverEmail};

                    my %Ticket = $TicketObject->TicketGet(
                        TicketID      => $GetParam{TicketID},
                        DynamicFields => 0,
                        UserID        => 1,
                        Silent        => 1,
                    );

                    if ( $ProcessStepData{ApproverGroupID} && $ProcessStepData{ApproverGroupID} == 1 )  {

                        my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

                        my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                            User => $Ticket{CustomerUserID},
                        );

                        if ( $To ) {
                            $To .= ',' . $CustomerUser{UserEmail};
                        }
                        else {
                            $To .= $CustomerUser{UserEmail};
                        }
                    }

                    if ( !$ProcessStepData{NotifyAgent} ) {
                        $ProcessStepData{NotifyAgent} = 'yes';
                    }

                    if ( $ProcessStepData{NotifyAgent} eq "yes" )  {

                        if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {

                            my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                                GroupID => $ProcessStepData{GroupID},
                                Type    => 'ro',
                            );
    
                            for my $UserLogin ( keys %ApproverUsers ) {
                           
                                if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {
    
                                    my %ApproverUser = $UserObject->GetUserData(
                                        UserID => $UserLogin,
                                    );
    
                                    if ( $To ) {
                                        $To .= ',' . $ApproverUser{UserEmail};
                                    }
                                    else {
                                        $To .= $ApproverUser{UserEmail};
                                    }
                                }
                            }
                        }
                    }

                    my $SetFullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                        UserLogin => $Ticket{CustomerUserID},
                    );

                    my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - approval required';

                    my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                    $NotificationBodyPre .= '<br><br>';
                    $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                    $NotificationBodyPre .= '<br><br>';

                    if ( $ProcessStepData{SetArticleID} && $ProcessStepData{SetArticleID} == 1 ) {
                        $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $GetParam{Report};
                    }
                    else {
                        $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                    }

                    $NotificationBodyPre .= '<br><br>';
                    $NotificationBodyPre .= 'Genehmigung erforderlich.<br>Bitte klicken Sie auf eine Entscheidung.';
                    $NotificationBodyPre .= '<br><br>';

                    $NotificationBodyPre .= 'Antragsteller: ' . $SetFullName;
                    $NotificationBodyPre .= '<br><br>';

                    $NotificationBodyPre .= $ArticleBody;
                    $NotificationBodyPre .= '<br><br>';


                    my $HttpType    = $ConfigObject->Get('HttpType');
                    my $FQDN        = $ConfigObject->Get('FQDN');
                    my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

                    my $NotificationBody = "<!DOCTYPE html>
                    <html lang=\"de-DE\">
                    <head>
                    <meta charset=\"utf-8\">
                    </head>
                    <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
        
                    <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
        
                    Es wurde eine Anfrage eingereicht welche genehmigungspflichtig ist.\n<br>
                    Zum Genehmigen oder Ablehnen bitte einen der nachstehenden links klicken.\n<br><br>

                    </div>

                    <div style=\"color:blue;width:100%;font-size:16px;font-family:Helvetica, Arial, sans-serif;font-weight:bold;\">

                    <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                        . "ProcessApproval.pl?ProcessID=$GetParam{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$GetParam{TicketID};Art=genehmigt\">Genehmigen</a>
                    \n<br>\n<br>oder\n<br>\n<br>
                    <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                        . "ProcessApproval.pl?ProcessID=$GetParam{ProcessID};ProcessStepID=$ProcessStepID;TicketID=$GetParam{TicketID};Art=abgelehnt\">Ablehnen</a>
                    \n\n<br><br>
        
                    </div>

                    <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">

                    Es wurde folgende Anfrage gestellt:\n\n<br><br>
        
                    $NotificationBodyPre
                    ";

                    if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {

                        $NotificationBody .= "
                        <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                            . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                            . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                        \n\n<br><br>
                        ";

                    }

                    $NotificationBody .= "
                    </div>

                    </body>
                    </html>
                    ";

                    if ( $To ne '' ) {

                        my $Sent = $EmailObject->Send(
                            From     => $From,
                            To       => $To,
                            Subject  => $NotificationSubject,
                            MimeType => 'text/html',
                            Charset  => 'utf-8',
                            Body     => $NotificationBody,
                        );

                        my $Success = $TicketObject->HistoryAdd(
                            Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                            HistoryType  => 'SendAgentNotification',
                            TicketID     => $GetParam{TicketID},
                            CreateUserID => 1,
                        );

                    }
                }
                else {

                    # get needed objects
                    my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                    my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                    my $UserObject          = $Kernel::OM->Get('Kernel::System::User');

                    my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                    my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';

                    my $To = '';

                    my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                        GroupID => $ProcessStepData{GroupID},
                        Type    => 'ro',
                    );

                    if ( !$ProcessStepData{NotifyAgent} ) {
                       $ProcessStepData{NotifyAgent} = 'yes';
                    }

                    if ( $ProcessStepData{NotifyAgent} eq "yes" )  {

                        my $GroupUserValue = 0;
                        for my $UserLogin ( keys %ApproverUsers ) {
                       
                            if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {

                               $GroupUserValue ++;

                                my %ApproverUser = $UserObject->GetUserData(
                                    UserID => $UserLogin,
                                );

                                if ( $GroupUserValue == 1 ) {
                                    $To .= $ApproverUser{UserEmail};
                                }
                                else {
                                    $To .= ',' . $ApproverUser{UserEmail};
                                }
                            }
                        }
                    }

                    my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - ' . $ProcessStepData{Name};

                    my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                    $NotificationBodyPre .= '<br><br>';
                    $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                    $NotificationBodyPre .= '<br><br>';
                    $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                    $NotificationBodyPre .= '<br><br>';
                    $NotificationBodyPre .= 'Aktion erforderlich.';
                    $NotificationBodyPre .= '<br><br>';
                    $NotificationBodyPre .= $ArticleBody;
                    $NotificationBodyPre .= '<br><br>';

                    my $HttpType    = $ConfigObject->Get('HttpType');
                    my $FQDN        = $ConfigObject->Get('FQDN');
                    my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

                    my $NotificationBody = "<!DOCTYPE html>
                    <html lang=\"de-DE\">
                    <head>
                    <meta charset=\"utf-8\">
                    </head>
                    <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
        
                    <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
        
                    Es wurde eine Anfrage eingereicht welche bearbeitet werden muss.\n<br>

                    Es wurde folgende Anfrage gestellt:\n\n<br><br>
        
                    $NotificationBodyPre
        
                    <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                        . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                        . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                    \n\n<br><br>

                    </div>

                    </body>
                    </html>
                    ";

                    if ( !$ProcessStepData{ParallelStep} ) {

                        my $ProcessStepIDReadyCheck = $ProcessStepObject->SeachAllReadySteps(
                            ProcessStepID => $ProcessStepID,
                            ProcessID     => $GetParam{ProcessID},
                        );

                        if ( !$ProcessStepIDReadyCheck ) {

                            my $ProcessStepReady = $ProcessStepObject->ProcessStepReadyUpdate(
                                ProcessStepID => $ProcessStepID,
                                StepActive    => 1,
                                TicketID      => $GetParam{TicketID},
                            );


                            if ( $To ne '' ) {

                                my $Sent = $EmailObject->Send(
                                    From     => $From,
                                    To       => $To,
                                    Subject  => $NotificationSubject,
                                    MimeType => 'text/html',
                                    Charset  => 'utf-8',
                                    Body     => $NotificationBody,
                                );

                                my $Success = $TicketObject->HistoryAdd(
                                    Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                                    HistoryType  => 'SendAgentNotification',
                                    TicketID     => $GetParam{TicketID},
                                    CreateUserID => 1,
                                );
                            }
                        }
                    }
                }

                my %TicketTransition = $TicketProcessTransitionObject->ProcessTicketTransitionGet(
                    ProcessStepID => $ProcessStepID,
                    TicketID      => $GetParam{TicketID},
                );

                if ( $TicketTransition{StateID} && $TicketTransition{StateID} >= 1 ) {

                    my $StateSuccess = $TicketObject->TicketStateSet(
                        StateID      => $TicketTransition{StateID},
                        TicketID     => $GetParam{TicketID},
                        NoPermission => 1,
                        UserID       => 1,
                    );
                }

                if ( $TicketTransition{TypeID} && $TicketTransition{TypeID} >= 1 ) {
        
                    my $TypeSuccess = $TicketObject->TicketTypeSet(
                        TypeID   => $TicketTransition{TypeID},
                        TicketID => $GetParam{TicketID},
                        UserID   => 1,
                    );
                }

                if ( $TicketTransition{QueueID} && $TicketTransition{QueueID} >= 1 ) {

                    my $QueueSuccess = $TicketObject->TicketQueueSet(
                        QueueID  => $TicketTransition{QueueID},
                        TicketID => $GetParam{TicketID},
                        UserID   => 1,
                    );
                }

                my $ProcessStepIDNext = $TicketProcessTransitionObject->SearchNextParallel(
                    ProcessStepID => $GetParam{ProcessStepID},
                    TicketID      => $GetParam{TicketID},
                );

                my $ReadyCheck = '';
                my $ProcessStepIDCheck = $ProcessStepObject->SearchNextProcessStepParallel(
                    ProcessStepID => $ProcessStepIDNext,
                    TicketID      => $GetParam{TicketID},
                );

                if ( $ProcessStepIDCheck ) {
                    $ReadyCheck = 1;
                }

                if ( $ProcessStepID != $ProcessStepIDNext && !$ReadyCheck ) {
                    $ProcessStepID = $ProcessStepIDNext;
                }

                if ( !$ReadyCheck ) {

                    my $ProcessStepIDNextCheck = $TicketProcessTransitionObject->SearchNextParallel(
                        ProcessStepID => $ProcessStepID,
                        TicketID      => $GetParam{TicketID},
                    );

                    if ( $ProcessStepID ) {

                        my $CheckReadyOne = $ProcessStepObject->SeachAllReadySteps(
                            ProcessStepID => $ProcessStepID,
                            ProcessID     => $GetParam{ProcessID}
                        );

                        if ( !$CheckReadyOne ) {

                            if ( !$ProcessStepIDNextCheck ) {
                                $ProcessStepIDNextCheck = $ProcessStepID;
                            }

                            my %ProcessStepDataCheck = $ProcessStepObject->ProcessStepGet(
                                ID => $ProcessStepIDNextCheck,
                            );

                            if ( $ProcessStepDataCheck{ParallelStep} ) {

                                my $Success = $ProcessStepObject->ProcessStepReadyUpdateParallel(
                                    ProcessStepID     => $ProcessStepID,
                                    ProcessStepIDNext => $ProcessStepIDNextCheck,
                                    StepActive        => 1,
                                );

                            }

                            my @ProcessStepListBetween = $ProcessStepObject->ProcessStepParallelBetweenList(
                                ProcessStepID     => $ProcessStepID,
                                ProcessStepIDNext => $ProcessStepIDNextCheck,
                            );

                            if ( $ProcessStepID == $ProcessStepIDNextCheck ) {
                                push @ProcessStepListBetween, $ProcessStepID;
                            }

                            for my $ProcessStepIDBetween ( @ProcessStepListBetween ) {

                                  my $ProcessStepReady = $ProcessStepObject->ProcessStepReadyUpdate(
                                    ProcessStepID => $ProcessStepIDBetween,
                                    StepActive    => 1,
                                );

                                my %ProcessStepDataBetween = $ProcessStepObject->ProcessStepGet(
                                    ID => $ProcessStepIDBetween,
                                );  
                
                                my %ProcessDataTransverBetween = $TicketProcessesObject->ProcessGet(
                                    ID => $GetParam{ProcessID},
                                );

                                # get needed objects
                                my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                                my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                                my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                                my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                                my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
        
                                my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                                my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';
        
                                my $To = '';
        
                                my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                                    GroupID => $ProcessStepDataBetween{GroupID},
                                    Type    => 'ro',
                                );

                                if ( !$ProcessStepDataBetween{NotifyAgent} ) {
                                    $ProcessStepDataBetween{NotifyAgent} = 'yes';
                                }

                                if ( $ProcessStepDataBetween{NotifyAgent} eq "yes" )  {

                                    my $GroupUserValue = 0;
                                    for my $UserLogin ( keys %ApproverUsers ) {
                               
                                        if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {
        
                                           $GroupUserValue ++;
        
                                            my %ApproverUser = $UserObject->GetUserData(
                                                UserID => $UserLogin,
                                            );
        
                                            if ( $GroupUserValue == 1 ) {
                                                $To .= $ApproverUser{UserEmail};
                                            }
                                            else {
                                                $To .= ',' . $ApproverUser{UserEmail};
                                            }
                                        }
                                    }
                                }

                                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransverBetween{Name} . ' - ' . $ProcessStepDataBetween{Name};
        
                                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransverBetween{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepDataBetween{Name};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepDataBetween{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Aktion erforderlich.';
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= $ArticleBody;
                                $NotificationBodyPre .= '<br><br>';

                                my $HttpType    = $ConfigObject->Get('HttpType');
                                my $FQDN        = $ConfigObject->Get('FQDN');
                                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
        
                                my $NotificationBody = "<!DOCTYPE html>
                                <html lang=\"de-DE\">
                                <head>
                                <meta charset=\"utf-8\">
                                </head>
                                <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
                
                                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
                
                                Es wurde eine Anfrage eingereicht welche bearbeitet werden muss.\n<br>
        
                                Es wurde folgende Anfrage gestellt:\n\n<br><br>
                
                                $NotificationBodyPre
                
                                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                                \n\n<br><br>
        
                                </div>
        
                                </body>
                                </html>
                                ";

                                if ( $To ne '' ) {

                                    my $Sent = $EmailObject->Send(
                                        From     => $From,
                                        To       => $To,
                                        Subject  => $NotificationSubject,
                                        MimeType => 'text/html',
                                        Charset  => 'utf-8',
                                        Body     => $NotificationBody,
                                    );

                                    my $Success = $TicketObject->HistoryAdd(
                                        Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                                        HistoryType  => 'SendAgentNotification',
                                        TicketID     => $GetParam{TicketID},
                                        CreateUserID => 1,
                                    );

                                }
                            }
                        }
                    }
                    else {

                        my $CheckReady = $ProcessStepObject->SeachAllReadySteps(
                            ProcessStepID => $ProcessStepID,
                            ProcessID     => $GetParam{ProcessID}
                        );

                        if ( !$CheckReady ) {

                            my $Success = $ProcessStepObject->ProcessStepReadyUpdate(
                                ProcessStepID => $ProcessStepID,
                                StepActive    => 1,
                                TicketID      => $GetParam{TicketID},
                            );
                        }

                        my @ProcessStepListEnd = $ProcessStepObject->ProcessStepParallelEndList(
                            ProcessStepID => $ProcessStepID,
                            ProcessID     => $GetParam{ProcessID},
                        );

                        for my $ProcessStepIDEnd ( @ProcessStepListEnd ) {

                            my %ProcessStepDataIfActive = $ProcessStepObject->ProcessStepGet(
                                ID => $ProcessStepIDEnd,
                            );

                            if ( !$ProcessStepDataIfActive{StepActive} || $ProcessStepDataIfActive{StepActive} == 0 ) {

                                my $Success = $ProcessStepObject->ProcessStepReadyUpdate(
                                    ProcessStepID => $ProcessStepIDEnd,
                                    StepActive    => 1,
                                    TicketID      => $GetParam{TicketID},
                                );

                                my %ProcessStepDataBetween = $ProcessStepObject->ProcessStepGet(
                                    ID => $ProcessStepIDEnd,
                                );  
                
                                my %ProcessDataTransverBetween = $TicketProcessesObject->ProcessGet(
                                    ID => $GetParam{ProcessID},
                                );

                                # get needed objects
                                my $EmailObject         = $Kernel::OM->Get('Kernel::System::Email');
                                my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
                                my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
                                my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
                                my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
        
                                my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');
                                my $From = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';
        
                                my $To = '';
        
                                my %ApproverUsers = $GroupObject->PermissionGroupUserGet(
                                    GroupID => $ProcessStepData{GroupID},
                                    Type    => 'ro',
                                );

                                if ( !$ProcessStepDataBetween{NotifyAgent} ) {
                                    $ProcessStepDataBetween{NotifyAgent} = 'yes';
                                }

                                if ( $ProcessStepDataBetween{NotifyAgent} eq "yes" )  {
        
                                    my $GroupUserValue = 0;
                                    for my $UserLogin ( keys %ApproverUsers ) {
                               
                                        if ( $ApproverUsers{$UserLogin} ne "root\@localhost" ) {
        
                                           $GroupUserValue ++;
        
                                            my %ApproverUser = $UserObject->GetUserData(
                                                UserID => $UserLogin,
                                            );
        
                                            if ( $GroupUserValue == 1 ) {
                                                $To .= $ApproverUser{UserEmail};
                                            }
                                            else {
                                                $To .= ',' . $ApproverUser{UserEmail};
                                            }
                                        }
                                    }
                                }
        
                                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransverBetween{Name} . ' - ' . $ProcessStepDataBetween{Name};
        
                                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransverBetween{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepDataBetween{Name};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepDataBetween{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Aktion erforderlich.';
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= $ArticleBody;
                                $NotificationBodyPre .= '<br><br>';

                                my $HttpType    = $ConfigObject->Get('HttpType');
                                my $FQDN        = $ConfigObject->Get('FQDN');
                                my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
        
                                my $NotificationBody = "<!DOCTYPE html>
                                <html lang=\"de-DE\">
                                <head>
                                <meta charset=\"utf-8\">
                                </head>
                                <body style=\"font-size:14px;font-family:Helvetica, Arial, sans-serif;\">
                
                                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
                
                                Es wurde eine Anfrage eingereicht welche bearbeitet werden muss.\n<br>
        
                                Es wurde folgende Anfrage gestellt:\n\n<br><br>
                
                                $NotificationBodyPre
                
                                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}\">$HttpType://$FQDN/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$GetParam{TicketID}</a>
                                \n\n<br><br>
        
                                </div>
        
                                </body>
                                </html>
                                ";

                                if ( $To ne '' ) {
 
                                    my $Sent = $EmailObject->Send(
                                        From     => $From,
                                        To       => $To,
                                        Subject  => $NotificationSubject,
                                        MimeType => 'text/html',
                                        Charset  => 'utf-8',
                                        Body     => $NotificationBody,
                                    );

                                    my $Success = $TicketObject->HistoryAdd(
                                        Name         => 'Mitteilung Prozess-Schritt ' . $NotificationSubject . ' an: ' . $To,
                                        HistoryType  => 'SendAgentNotification',
                                        TicketID     => $GetParam{TicketID},
                                        CreateUserID => 1,
                                    );

                                }
                            }
                        }
                    }
                }
            }
        }

        # load new URL in window
        my $ReturnURL = "Action=AgentTicketZoom;TicketID=$GetParam{TicketID}";

        return $LayoutObject->PopupClose(
            URL => $ReturnURL,
        );
    }
}

1;
