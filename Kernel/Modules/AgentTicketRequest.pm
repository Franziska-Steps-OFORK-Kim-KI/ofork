# --
# Kernel/Modules/AgentTicketRequest.pm - to handle customer messages
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AgentTicketRequest.pm,v 1.74 2016/12/13 14:38:03 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketRequest;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;
use Mail::Address;

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

    # get params
    my %GetParam;
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    for my $Key (
        qw( Subject From FromCustomer Body PriorityID TypeID ServiceID SLAID Expand Dest FromChatID RequestID RequestFormIDs RequestFormBlockIDs BodyAlt)
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    if ( !$GetParam{From} ) {
    	$GetParam{From} = $GetParam{FromCustomer};
    }

    # ACL compatibility translation
    my %ACLCompatGetParam;
    $ACLCompatGetParam{OwnerID} = $GetParam{NewUserID};

    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $BackendObject          = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $TypeObject             = $Kernel::OM->Get('Kernel::System::Type');
    my $RequestObject          = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFieldsObject    = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestFormObject      = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $TicketRequestObject    = $Kernel::OM->Get('Kernel::System::TicketRequest');
    my $TimeObject             = $Kernel::OM->Get('Kernel::System::Time');
    my $LinkObject             = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $GroupObject            = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject             = $Kernel::OM->Get('Kernel::System::User');
    my $CustomerUserObject     = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $SendmailObject         = $Kernel::OM->Get('Kernel::System::Email');
    my $RequestFormBlockObject = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $QueueObject            = $Kernel::OM->Get('Kernel::System::Queue');

    # MultipleCustomer From-field
    my @MultipleCustomer;
    my $CustomersNumber
        = $ParamObject->GetParam( Param => 'CustomerTicketCounterFromCustomer' ) || 0;
    my $Selected = $ParamObject->GetParam( Param => 'CustomerSelected' ) || '';

    # hash for check duplicated entries
    my %AddressesList;

    # get check item object
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    if ($CustomersNumber) {
        my $CustomerCounter = 1;
        for my $Count ( 1 ... $CustomersNumber ) {
            my $CustomerElement = $ParamObject->GetParam( Param => 'CustomerTicketText_' . $Count );
            my $CustomerSelected = ( $Selected eq $Count ? 'checked="checked"' : '' );
            my $CustomerKey = $ParamObject->GetParam( Param => 'CustomerKey_' . $Count )
                || '';

            if ($CustomerElement) {

                my $CountAux         = $CustomerCounter++;
                my $CustomerError    = '';
                my $CustomerErrorMsg = 'CustomerGenericServerErrorMsg';
                my $CustomerDisabled = '';

                if ( $GetParam{From} ) {
                    $GetParam{From} .= ', ' . $CustomerElement;
                }
                else {
                    $GetParam{From} = $CustomerElement;
                }

                # check email address
                for my $Email ( Mail::Address->parse($CustomerElement) ) {
                    if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) )
                    {
                        $CustomerErrorMsg = $CheckItemObject->CheckErrorType()
                            . 'ServerErrorMsg';
                        $CustomerError = 'ServerError';
                    }
                }

                # check for duplicated entries
                if ( defined $AddressesList{$CustomerElement} && $CustomerError eq '' ) {
                    $CustomerErrorMsg = 'IsDuplicatedServerErrorMsg';
                    $CustomerError    = 'ServerError';
                }

                if ( $CustomerError ne '' ) {
                    $CustomerDisabled = 'disabled="disabled"';
                    $CountAux         = $Count . 'Error';
                }

                push @MultipleCustomer, {
                    Count            => $CountAux,
                    CustomerElement  => $CustomerElement,
                    CustomerSelected => $CustomerSelected,
                    CustomerKey      => $CustomerKey,
                    CustomerError    => $CustomerError,
                    CustomerErrorMsg => $CustomerErrorMsg,
                    CustomerDisabled => $CustomerDisabled,
                };
                $AddressesList{$CustomerElement} = 1;
            }
        }
    }

    if ( !$GetParam{Body} ) {
        $GetParam{Body} = $GetParam{BodyAlt};
    }

    my $IfNoValid = 0;

    my %Request = $RequestObject->RequestGet(
        RequestID => $GetParam{RequestID},
    );

    if ( !$Request{SubjectChangeable} || $Request{SubjectChangeable} == 2 ) {
        $GetParam{Subject} = $Request{Subject};
    }

    if ( !$GetParam{Subject} ) {
        $GetParam{Subject} = $Request{Subject};
    }

    if ( !$GetParam{Dest} ) {
        if ( $Request{ValidID} == 2 ) {
            $IfNoValid++;
        }

        my $QueueName = $QueueObject->QueueLookup(
            QueueID => $Request{Queue},
        );
        $GetParam{Dest} = "$Request{Queue}||$QueueName";
        $Param{Dest}    = "$Request{Queue}||$QueueName";
    }

        my %CustomerData;



    if ( $IfNoValid >= 1 ) {

        my $Output .= $LayoutObject->Header();
        $Output    .= $LayoutObject->NavigationBar();
        $Output    .= $Self->_MaskNewNoValid(
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    if ( $GetParam{RequestFormIDs} ) {
        my @RequestFormIDArray = split( /,/, $GetParam{RequestFormIDs} );
        for my $NewValues (@RequestFormIDArray) {
            my @FeldCheck = split( /-/, $NewValues );
            if ( $FeldCheck[1] && ( $FeldCheck[1] !~ /[a-z]/ig && $FeldCheck[0] !~ /Headline/ && $FeldCheck[0] !~ /Description/  ) ) {
                my %RequestForm = $RequestFormObject->RequestFormGet(
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
                    if ( $RequestFields{Typ} eq "Checkbox" && ( $GetParam{$NewValues} && $GetParam{$NewValues} ne 'Nein' ) ) {
                        $GetParam{$NewValues} = "Ja";
                    }
                    elsif ( !$GetParam{$NewValues} ) {
                        $GetParam{$NewValues} = "";
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

    my @RequestIDArrayBlock;
    if ( $GetParam{RequestFormIDs} ) {
        @RequestIDArrayBlock = split( /,/, $GetParam{RequestFormIDs} );
    }
    
    my $CheckRequestFormIDBlock = '';
    my $NewBlockValues         = '';

    for my $NewValuesBlock (@RequestIDArrayBlock) {

        my @FeldCheckBlock = split( /-/, $NewValuesBlock );
        my %RequestFieldsBlock;

        if ( $FeldCheckBlock[1] && $FeldCheckBlock[1] !~ /[a-z]/ig ) {
            my %RequestFormBlock = $RequestFormObject->RequestFormGet(
                RequestFormID => $FeldCheckBlock[1],
            );
            $CheckRequestFormIDBlock = $RequestFormBlock{ID};
            if ( $RequestFormBlock{FeldID} ) {
                %RequestFieldsBlock = $RequestFieldsObject->RequestFieldsGet(
                    RequestFieldsID => $RequestFormBlock{FeldID},
                );
            }
        }
        if (
            $FeldCheckBlock[1]
            && ( $FeldCheckBlock[1] !~ /[a-z]/ig && $FeldCheckBlock[0] !~ /Headline/ && $FeldCheckBlock[0] !~ /Description/ )
            )
        {
            if ( $RequestFieldsBlock{Typ} eq "Dropdown" ) {

                my $GoGetParamNew = "RequestFormBlockIDs" . $CheckRequestFormIDBlock;

                for my $Key ($GoGetParamNew) {

                    $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );

                    if ( $GetParam{$Key} ) {

                        my @RequestFormIDArray = split( /,/, $GetParam{$Key} );

                        for my $NewValues (@RequestFormIDArray) {
                            my @FeldCheck = split( /-/, $NewValues );
                            if (
                                $FeldCheck[1]
                                && ( $FeldCheck[1] !~ /[a-z]/ig )
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
                                        $NewBlockValues
                                            .= $CheckRequestFormIDBlock . '='
                                            . $NewValues . '='
                                            . $GetParam{$NewValues} . '#';
                                    }
                                }
                                else {
                                    $GetParam{$NewValues} = $ParamObject->GetParam( Param => $NewValues );
                                    $NewBlockValues
                                        .= $CheckRequestFormIDBlock . '='
                                        . $NewValues . '='
                                        . $GetParam{$NewValues} . '#';

                                    if ( $RequestFields{Typ} eq "Checkbox" && !$GetParam{$NewValues} ) {
                                        $GetParam{$NewValues} = 'Nein';
                                        $NewBlockValues
                                            .= $CheckRequestFormIDBlock . '='
                                            . $NewValues . '='
                                            . $GetParam{$NewValues} . '#';
                                    }
                                    if ( $RequestFields{Typ} eq "Checkbox" && $GetParam{$NewValues} ) {
                                        $NewBlockValues
                                            .= $CheckRequestFormIDBlock . '='
                                            . $NewValues . '='
                                            . $GetParam{$NewValues} . '#';
                                    }
                                    elsif ( !$GetParam{$NewValues} ) {
                                        $GetParam{$NewValues} = "";
                                        $NewBlockValues
                                            .= $CheckRequestFormIDBlock . '='
                                            . $NewValues . '='
                                            . $GetParam{$NewValues} . '#';
                                    }
                                }
                            }
                            else {
                                $GetParam{$NewValues} = $ParamObject->GetParam( Param => $NewValues );
                                $NewBlockValues
                                    .= $CheckRequestFormIDBlock . '='
                                    . $NewValues . '='
                                    . $GetParam{$NewValues} . '#';
                                if ( !$GetParam{$NewValues} ) {
                                    $GetParam{$NewValues} = "-";
                                    $NewBlockValues
                                        .= $CheckRequestFormIDBlock . '='
                                        . $NewValues . '='
                                        . $GetParam{$NewValues} . '#';
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    $GetParam{BlockValues} = $NewBlockValues;

    if ( !$GetParam{TypeID} ) {
        if ( $Request{Type} && $Request{Type} ne "0" ) {
            $GetParam{TypeID} = $Request{Type};
        }
        else {
            $GetParam{TypeID} = '';
        }
    }

    # get Dynamic fields from ParamObject
    my %DynamicFieldValues;

    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # reduce the dynamic fields to only the ones that are designed for customer interface
    my @CustomerDynamicFields;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsCustomerInterfaceCapable',
        );
        next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

        push @CustomerDynamicFields, $DynamicFieldConfig;
    }
    $DynamicField = \@CustomerDynamicFields;

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value form the web request
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } =
            $BackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
            );
    }

    # convert dynamic field values into a structure for ACLs
    my %DynamicFieldACLParameters;
    DYNAMICFIELD:
    for my $DynamicField ( sort keys %DynamicFieldValues ) {
        next DYNAMICFIELD if !$DynamicField;
        next DYNAMICFIELD if !$DynamicFieldValues{$DynamicField};

        $DynamicFieldACLParameters{ 'DynamicField_' . $DynamicField }
            = $DynamicFieldValues{$DynamicField};
    }
    $GetParam{DynamicField} = \%DynamicFieldACLParameters;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    if ( $GetParam{FromChatID} ) {
        if ( !$ConfigObject->Get('ChatEngine::Active') ) {
            return $LayoutObject->FatalError(
                Message => Translatable('Chat is not active.'),
            );
        }

        # Check chat participant
        my %ChatParticipant = $Kernel::OM->Get('Kernel::System::Chat')->ChatParticipantCheck(
            ChatID      => $GetParam{FromChatID},
            ChatterType => 'Customer',
            ChatterID   => $Self->{UserID},
        );

        if ( !%ChatParticipant ) {
            return $LayoutObject->FatalError(
                Message => Translatable('No permission.'),
            );
        }
    }

    if ( !$Self->{Subaction} ) {

        #Get default Queue ID if none is set
        my $QueueDefaultID;
        if ( !$GetParam{Dest} && !$Param{ToSelected} ) {
            my $QueueDefault = $Config->{'QueueDefault'} || '';
            if ($QueueDefault) {
                $QueueDefaultID = $QueueObject->QueueLookup( Queue => $QueueDefault );
                if ($QueueDefaultID) {
                    $Param{ToSelected} = $QueueDefaultID . '||' . $QueueDefault;
                }
                $ACLCompatGetParam{QueueID} = $QueueDefaultID;
            }

            # warn if there is no (valid) default queue and the customer can't select one
            elsif ( !$Config->{'Queue'} ) {
                $LayoutObject->CustomerFatalError(
                    Message => $LayoutObject->{LanguageObject}
                        ->Translate(
                        'Check SysConfig setting for %s::QueueDefault.',
                        $Self->{Action}
                        ),
                    Comment => Translatable('Please contact your administrator'),
                );
                return;
            }
        }
        elsif ( $GetParam{Dest} ) {
            my ( $QueueIDParam, $QueueParam ) = split( /\|\|/, $GetParam{Dest} );
            my $QueueIDLookup = $QueueObject->QueueLookup( Queue => $QueueParam );
            if ( $QueueIDLookup && $QueueIDLookup eq $QueueIDParam ) {
                my $CustomerPanelOwnSelection
                    = $Kernel::OM->Get('Kernel::Config')->Get('CustomerPanelOwnSelection');
                if ( %{ $CustomerPanelOwnSelection // {} } ) {
                    $Param{ToSelected}
                        = $QueueIDParam . '||' . $CustomerPanelOwnSelection->{$QueueParam};
                }
                else {
                    $Param{ToSelected} = $GetParam{Dest};
                }
                $ACLCompatGetParam{QueueID} = $QueueIDLookup;
            }
        }

        my %Ticket;
        if ( $Self->{TicketID} ) {
            %Ticket = $TicketObject->TicketGet( TicketID => $Self->{TicketID} );
        }

        # get split article if given
        # get ArticleID
        my %Article;
        my %CustomerData;
        my $ArticleFrom = '';
        my %SplitTicketData;
        if ( $GetParam{ArticleID} ) {

            my $Access = $TicketObject->TicketPermission(
                Type     => 'ro',
                TicketID => $Self->{TicketID},
                UserID   => $Self->{UserID}
            );

            if ( !$Access ) {
                return $LayoutObject->NoPermission(
                    Message    => Translatable('You need ro permission!'),
                    WithHeader => 'yes',
                );
            }

            # Get information from original ticket (SplitTicket).
            %SplitTicketData = $TicketObject->TicketGet(
                TicketID      => $Self->{TicketID},
                DynamicFields => 1,
                UserID        => $Self->{UserID},
            );

            my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle(
                TicketID  => $Self->{TicketID},
                ArticleID => $GetParam{ArticleID},
            );

            %Article = $ArticleBackendObject->ArticleGet(
                TicketID  => $Self->{TicketID},
                ArticleID => $GetParam{ArticleID},
            );

            # check if article is from the same TicketID as we checked permissions for.
            if ( $Article{TicketID} ne $Self->{TicketID} ) {
                return $LayoutObject->ErrorScreen(
                    Message => $LayoutObject->{LanguageObject}
                        ->Translate( 'Article does not belong to ticket %s!', $Self->{TicketID} ),
                );
            }

            $Article{Subject} = $TicketObject->TicketSubjectClean(
                TicketNumber => $Ticket{TicketNumber},
                Subject      => $Article{Subject} || '',
            );

            # save article from for addresses list
            $ArticleFrom = $Article{From};

            # if To is present
            # and is no a queue
            # and also is no a system address
            # set To as article from
            if ( IsStringWithData( $Article{To} ) ) {
                my %Queues = $QueueObject->QueueList();

                if ( $ConfigObject->{CustomerPanelOwnSelection} ) {
                    for my $Queue ( sort keys %{ $ConfigObject->{CustomerPanelOwnSelection} } ) {
                        my $Value = $ConfigObject->{CustomerPanelOwnSelection}->{$Queue};
                        $Queues{$Queue} = $Value;
                    }
                }

                my %QueueLookup = reverse %Queues;
                my %SystemAddressLookup
                    = reverse $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressList();
                my @ArticleFromAddress;
                my $SystemAddressEmail;

                if ($ArticleFrom) {
                    @ArticleFromAddress = Mail::Address->parse($ArticleFrom);
                    $SystemAddressEmail = $ArticleFromAddress[0]->address();
                }

                if ( !defined $QueueLookup{ $Article{To} } && defined $SystemAddressLookup{$SystemAddressEmail} ) {
                    $ArticleFrom = $Article{To};
                }
            }

            # body preparation for plain text processing
            $Article{Body} = $LayoutObject->ArticleQuote(
                TicketID           => $Article{TicketID},
                ArticleID          => $GetParam{ArticleID},
                FormID             => $Self->{FormID},
                UploadCacheObject  => $UploadCacheObject,
                AttachmentsInclude => 1,
            );
            if ( $LayoutObject->{BrowserRichText} ) {
                $Article{ContentType} = 'text/html';
            }
            else {
                $Article{ContentType} = 'text/plain';
            }

                my %SafetyCheckResult = $Kernel::OM->Get('Kernel::System::HTMLUtils')->Safety(
                    String       => $Article{Body},

                # Strip out external content if BlockLoadingRemoteContent is enabled.
                NoExtSrcLoad => $ConfigObject->Get('Ticket::Frontend::BlockLoadingRemoteContent'),

                # Disallow potentially unsafe content.
                NoApplet     => 1,
                NoObject     => 1,
                NoEmbed      => 1,
                NoSVG        => 1,
                NoJavaScript => 1,
                );
                $Article{Body} = $SafetyCheckResult{String};

            # show customer info
            if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
                if ( $SplitTicketData{CustomerUserID} ) {
                    %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                        User => $SplitTicketData{CustomerUserID},
                    );
                }
                elsif ( $SplitTicketData{CustomerID} ) {
                    %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                        CustomerID => $SplitTicketData{CustomerID},
                    );
                }
            }
            if ( $SplitTicketData{CustomerUserID} ) {
                my %CustomerUserList = $CustomerUserObject->CustomerSearch(
                    UserLogin => $SplitTicketData{CustomerUserID},
                );
                for my $KeyCustomerUserList ( sort keys %CustomerUserList ) {
                    $Article{From} = $CustomerUserList{$KeyCustomerUserList};
                }
            }
        }


        # multiple addresses list
        # check email address
        my $CountFrom = scalar @MultipleCustomer || 1;
        my %CustomerDataFrom;
        if ( $Article{CustomerUserID} ) {
            %CustomerDataFrom = $CustomerUserObject->CustomerUserDataGet(
                User => $Article{CustomerUserID},
            );
        }

        for my $Email ( Mail::Address->parse($ArticleFrom) ) {

            my $CountAux         = $CountFrom;
            my $CustomerError    = '';
            my $CustomerErrorMsg = 'CustomerGenericServerErrorMsg';
            my $CustomerDisabled = '';
            my $CustomerSelected = $CountFrom eq '1' ? 'checked="checked"' : '';
            my $EmailAddress     = $Email->address();
            if ( !$CheckItemObject->CheckEmail( Address => $EmailAddress ) )
            {
                $CustomerErrorMsg = $CheckItemObject->CheckErrorType()
                    . 'ServerErrorMsg';
                $CustomerError = 'ServerError';
            }

            # check for duplicated entries
            if ( defined $AddressesList{$Email} && $CustomerError eq '' ) {
                $CustomerErrorMsg = 'IsDuplicatedServerErrorMsg';
                $CustomerError    = 'ServerError';
            }

            if ( $CustomerError ne '' ) {
                $CustomerDisabled = 'disabled="disabled"';
                $CountAux         = $CountFrom . 'Error';
            }

            my $Phrase = '';
            if ( $Email->phrase() ) {
                $Phrase = $Email->phrase();
            }

            my $CustomerKey = '';
            if (
                defined $CustomerDataFrom{UserEmail}
                && $CustomerDataFrom{UserEmail} eq $EmailAddress
                )
            {
                $CustomerKey = $Article{CustomerUserID};
            }
            elsif ($EmailAddress) {
                my %List = $CustomerUserObject->CustomerSearch(
                    PostMasterSearch => $EmailAddress,
                );

                for my $UserLogin ( sort keys %List ) {

                    # Set right one if there is more than one customer user with the same email address.
                    if ( $Phrase && $List{$UserLogin} =~ /$Phrase/ ) {
                        $CustomerKey = $UserLogin;
                    }
                }
            }

            my $CustomerElement = $EmailAddress;
            if ($Phrase) {
                $CustomerElement = $Phrase . " <$EmailAddress>";
            }

            if ( $CustomerSelected && $CustomerKey ) {
                %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                    User => $CustomerKey,
                );
            }

            push @MultipleCustomer, {
                Count            => $CountAux,
                CustomerElement  => $CustomerElement,
                CustomerSelected => $CustomerSelected,
                CustomerKey      => $CustomerKey,
                CustomerError    => $CustomerError,
                CustomerErrorMsg => $CustomerErrorMsg,
                CustomerDisabled => $CustomerDisabled,
            };
            $AddressesList{$EmailAddress} = 1;
            $CountFrom++;
        }

        # create html strings for all dynamic fields
        my %DynamicFieldHTML;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $PossibleValuesFilter;

            my $IsACLReducible = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );

            if ($IsACLReducible) {

                # get PossibleValues
                my $PossibleValues = $BackendObject->PossibleValuesGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                );

                # check if field has PossibleValues property in its configuration
                if ( IsHashRefWithData($PossibleValues) ) {

                    # convert possible values key => value to key => key for ACLs using a Hash slice
                    my %AclData = %{$PossibleValues};
                    @AclData{ keys %AclData } = keys %AclData;

                    # set possible values filter from ACLs
                    my $ACL = $TicketObject->TicketAcl(
                        %GetParam,
                        %ACLCompatGetParam,
                        Action         => $Self->{Action},
                        TicketID       => $Self->{TicketID},
                        ReturnType     => 'Ticket',
                        ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                        Data           => \%AclData,
                        CustomerUserID => $Self->{UserID},
                    );
                    if ($ACL) {
                        my %Filter = $TicketObject->TicketAclData();

                        # convert Filer key => key back to key => value using map
                        %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                            keys %Filter;
                    }
                }
            }

            # get field html
            $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } =
                $BackendObject->EditFieldRender(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $PossibleValuesFilter,
                Mandatory =>
                    $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
                LayoutObject    => $LayoutObject,
                ParamObject     => $ParamObject,
                AJAXUpdate      => 1,
                UpdatableFields => $Self->_GetFieldsToUpdate(),
                );
        }

        # print form ...
        my $Output .= $LayoutObject->Header();
        $Output    .= $LayoutObject->NavigationBar();
        $Output    .= $Self->_MaskNew(
            %GetParam,
            %ACLCompatGetParam,
            CustomerData     => \%CustomerData,
            CustomerUserID   => $CustomerData{UserLogin} || '',
            ToSelected       => $Param{ToSelected},
            DynamicFieldHTML => \%DynamicFieldHTML,
            FromChatID       => $GetParam{FromChatID} || '',
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'StoreNew' ) {

        my $NextScreen = $Config->{NextScreenAfterNewTicket};
        my %Error;

        # get destination queue
        my $Dest = $GetParam{Dest} || '';
        my ( $NewQueueID, $To ) = split( /\|\|/, $Dest );
        if ( !$To ) {
            $NewQueueID = $ParamObject->GetParam( Param => 'NewQueueID' ) || '';
            $To = 'System';
        }

        # fallback, if no destination is given
        if ( !$NewQueueID ) {
            my $Queue = $ParamObject->GetParam( Param => 'Queue' )
                || $Config->{'QueueDefault'}
                || '';
            if ($Queue) {
                my $QueueID = $QueueObject->QueueLookup( Queue => $Queue );
                $NewQueueID = $QueueID;
                $To         = $Queue;
            }
        }

        my $CustomerUser = $ParamObject->GetParam( Param => 'CustomerUser' )
            || $ParamObject->GetParam( Param => 'PreSelectedCustomerUser' )
            || $ParamObject->GetParam( Param => 'SelectedCustomerUser' )
            || '';
        my $SelectedCustomerUser = $ParamObject->GetParam( Param => 'SelectedCustomerUser' )
            || '';
        my $CustomerID = $ParamObject->GetParam( Param => 'CustomerID' ) || '';
        my $ExpandCustomerName = $ParamObject->GetParam( Param => 'ExpandCustomerName' )
            || 0;
        my %FromExternalCustomer;
        $FromExternalCustomer{Customer} = $ParamObject->GetParam( Param => 'PreSelectedCustomerUser' )
            || $ParamObject->GetParam( Param => 'CustomerUser' )
            || '';

        if ( $ParamObject->GetParam( Param => 'OwnerAllRefresh' ) ) {
            $GetParam{OwnerAll} = 1;
            $ExpandCustomerName = 3;
        }
        if ( $ParamObject->GetParam( Param => 'ResponsibleAllRefresh' ) ) {
            $GetParam{ResponsibleAll} = 1;
            $ExpandCustomerName = 3;
        }
        if ( $ParamObject->GetParam( Param => 'ClearFrom' ) ) {
            $GetParam{From} = '';
            $ExpandCustomerName = 3;
        }
        for my $Count ( 1 .. 2 ) {
            my $Item = $ParamObject->GetParam( Param => "ExpandCustomerName$Count" ) || 0;
            if ( $Count == 1 && $Item ) {
                $ExpandCustomerName = 1;
            }
            elsif ( $Count == 2 && $Item ) {
                $ExpandCustomerName = 2;
            }
        }

        # If is an action about attachments
        my $IsUpload = 0;

        # attachment delete
        my @AttachmentIDs = map {
            my ($ID) = $_ =~ m{ \A AttachmentDelete (\d+) \z }xms;
            $ID ? $ID : ();
        } $ParamObject->GetParamNames();

        my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

        COUNT:
        for my $Count ( reverse sort @AttachmentIDs ) {
            my $Delete = $ParamObject->GetParam( Param => "AttachmentDelete$Count" );
            next COUNT if !$Delete;
            $Error{AttachmentDelete} = 1;
            $UploadCacheObject->FormIDRemoveFile(
                FormID => $Self->{FormID},
                FileID => $Count,
            );
            $IsUpload = 1;
        }

        # attachment upload
        if ( $ParamObject->GetParam( Param => 'AttachmentUpload' ) ) {
            $IsUpload = 1;
            $Error{AttachmentUpload} = 1;
            my %UploadStuff = $ParamObject->GetUploadAll(
                Param => 'file_upload',
            );
            $UploadCacheObject->FormIDAddFile(
                FormID      => $Self->{FormID},
                Disposition => 'attachment',
                %UploadStuff,
            );
        }

        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

        # create html strings for all dynamic fields
        my %DynamicFieldHTML;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $PossibleValuesFilter;

            my $IsACLReducible = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );

            if ($IsACLReducible) {

                # get PossibleValues
                my $PossibleValues = $BackendObject->PossibleValuesGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                );

                # check if field has PossibleValues property in its configuration
                if ( IsHashRefWithData($PossibleValues) ) {

                    # convert possible values key => value to key => key for ACLs using a Hash slice
                    my %AclData = %{$PossibleValues};
                    @AclData{ keys %AclData } = keys %AclData;

                    # set possible values filter from ACLs
                    my $ACL = $TicketObject->TicketAcl(
                        %GetParam,
                        Action         => $Self->{Action},
                        TicketID       => $Self->{TicketID},
                        ReturnType     => 'Ticket',
                        ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                        Data           => \%AclData,
                        CustomerUserID => $Self->{UserID},
                    );
                    if ($ACL) {
                        my %Filter = $TicketObject->TicketAclData();

                        # convert Filer key => key back to key => value using map
                        %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                            keys %Filter;
                    }
                }
            }

            my $ValidationResult;

            # do not validate on attachment upload or GetParam Expand
            if ( !$IsUpload && !$GetParam{Expand} ) {

                $ValidationResult = $BackendObject->EditFieldValueValidate(
                    DynamicFieldConfig   => $DynamicFieldConfig,
                    PossibleValuesFilter => $PossibleValuesFilter,
                    ParamObject          => $ParamObject,
                    Mandatory =>
                        $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
                );

                if ( !IsHashRefWithData($ValidationResult) ) {
                    my $Output = $LayoutObject->Header( Title => 'Error' );
                    $Output .= $LayoutObject->CustomerError(
                        Message =>
                            $LayoutObject->{LanguageObject}
                            ->Translate(
                            'Could not perform validation on field %s!',
                            $DynamicFieldConfig->{Label}
                            ),
                        Comment => Translatable('Please contact your administrator'),
                    );
                    $Output .= $LayoutObject->Footer();
                    return $Output;
                }

                # propagate validation error to the Error variable to be detected by the frontend
                if ( $ValidationResult->{ServerError} ) {
                    $Error{ $DynamicFieldConfig->{Name} } = ' ServerError';
                }
            }

            # get field html
            $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } =
                $BackendObject->EditFieldRender(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $PossibleValuesFilter,
                Mandatory =>
                    $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
                ServerError  => $ValidationResult->{ServerError}  || '',
                ErrorMessage => $ValidationResult->{ErrorMessage} || '',
                LayoutObject => $LayoutObject,
                ParamObject  => $ParamObject,
                AJAXUpdate   => 1,
                UpdatableFields => $Self->_GetFieldsToUpdate(),
                );
        }

        # expand customer name
        my %CustomerUserData;
        if ( $ExpandCustomerName == 1 ) {

            # search customer
            my %CustomerUserList;
            %CustomerUserList = $CustomerUserObject->CustomerSearch(
                Search           => $GetParam{From},
                CustomerUserOnly => 1,
            );

            # check if just one customer user exists
            # if just one, fillup CustomerUserID and CustomerID
            $Param{CustomerUserListCount} = 0;
            for my $KeyCustomerUser ( sort keys %CustomerUserList ) {
                $Param{CustomerUserListCount}++;
                $Param{CustomerUserListLast}     = $CustomerUserList{$KeyCustomerUser};
                $Param{CustomerUserListLastUser} = $KeyCustomerUser;
            }
            if ( $Param{CustomerUserListCount} == 1 ) {
                $GetParam{From}            = $Param{CustomerUserListLast};
                $Error{ExpandCustomerName} = 1;
                my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                    User => $Param{CustomerUserListLastUser},
                );
                if ( $CustomerUserData{UserCustomerID} ) {
                    $CustomerID = $CustomerUserData{UserCustomerID};
                }
                if ( $CustomerUserData{UserLogin} ) {
                    $CustomerUser = $CustomerUserData{UserLogin};
                    $FromExternalCustomer{Customer} = $CustomerUserData{UserLogin};
                }
                if ( $FromExternalCustomer{Customer} ) {
                    my %ExternalCustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                        User => $FromExternalCustomer{Customer},
                    );
                    $FromExternalCustomer{Email} = $ExternalCustomerUserData{UserEmail};
                }
            }

            # if more than one customer user exist, show list
            # and clean CustomerUserID and CustomerID
            else {

                # don't check email syntax on multi customer select
                $ConfigObject->Set(
                    Key   => 'CheckEmailAddresses',
                    Value => 0
                );
                $CustomerID = '';

                # clear from if there is no customer found
                if ( !%CustomerUserList ) {
                    $GetParam{From} = '';
                }
                $Error{ExpandCustomerName} = 1;
            }
        }

        # get from and customer id if customer user is given
        elsif ( $ExpandCustomerName == 2 ) {
            %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                User => $CustomerUser,
            );
            my %CustomerUserList = $CustomerUserObject->CustomerSearch(
                UserLogin => $CustomerUser,
            );
            for my $KeyCustomerUser ( sort keys %CustomerUserList ) {
                $GetParam{From} = $CustomerUserList{$KeyCustomerUser};
            }
            if ( $CustomerUserData{UserCustomerID} ) {
                $CustomerID = $CustomerUserData{UserCustomerID};
            }
            if ( $CustomerUserData{UserLogin} ) {
                $CustomerUser = $CustomerUserData{UserLogin};
            }
            if ( $FromExternalCustomer{Customer} ) {
                my %ExternalCustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                    User => $FromExternalCustomer{Customer},
                );
                $FromExternalCustomer{Email} = $ExternalCustomerUserData{UserMailString};
            }
            $Error{ExpandCustomerName} = 1;
        }

        # if a new destination queue is selected
        elsif ( $ExpandCustomerName == 3 ) {
            $Error{NoSubmit} = 1;
            $CustomerUser = $SelectedCustomerUser;
        }

        # 'just' no submit
        elsif ( $ExpandCustomerName == 4 ) {
            $Error{NoSubmit} = 1;
        }

        # show customer info
        my %CustomerData;
        if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
            if ( $CustomerUser || $SelectedCustomerUser ) {
                %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                    User => $CustomerUser || $SelectedCustomerUser,
                );
            }
            elsif ($CustomerID) {
                %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                    CustomerID => $CustomerID,
                );
            }
        }

        # rewrap body if no rich text is used
        if ( $GetParam{Body} && !$LayoutObject->{BrowserRichText} ) {
            $GetParam{Body} = $LayoutObject->WrapPlainText(
                MaxCharacters => $ConfigObject->Get('Ticket::Frontend::TextAreaNote'),
                PlainText     => $GetParam{Body},
            );
        }

        # if there is FromChatID, get related messages and prepend them to body
        if ( $GetParam{FromChatID} ) {
            my @ChatMessages = $Kernel::OM->Get('Kernel::System::Chat')->ChatMessageList(
                ChatID => $GetParam{FromChatID},
            );
        }

        # check queue
        if ( !$NewQueueID && !$IsUpload && !$GetParam{Expand} ) {
            $Error{QueueInvalid} = 'ServerError';
        }

        # prevent tamper with (Queue/Dest), see bug#9408
        if ( $NewQueueID && !$IsUpload ) {

            # get the original list of queues to display
            my $Tos = $Self->_GetTos(
                %GetParam,
                %ACLCompatGetParam,
                QueueID => $NewQueueID,
            );

            # check if current selected QueueID exists in the list of queues,\
            # otherwise rise an error
            if ( !$Tos->{$NewQueueID} ) {
                $Error{QueueInvalid} = 'ServerError';
            }

            # set the correct queue name in $To if it was altered
            if ( $To ne $Tos->{$NewQueueID} ) {
                $To = $Tos->{$NewQueueID};
            }
        }

        # check subject
        if ( !$GetParam{Subject} && !$IsUpload ) {
            $Error{SubjectInvalid} = 'ServerError';
        }

        if ( !$SelectedCustomerUser && !$IsUpload ) {
            $SelectedCustomerUser = $GetParam{From};
            $CustomerID           = $GetParam{From};
        }

        if ( !$SelectedCustomerUser && !$IsUpload ) {
            $Error{FromCustomerInvalid} = 'FromCustomerInvalid';
        }

        # check body
        if ( !$GetParam{Body} && !$IsUpload ) {
            $Error{BodyInvalid} = 'ServerError';
        }
        if ( $GetParam{Expand} ) {
            %Error = ();
            $Error{Expand} = 1;
        }

        # check mandatory service
        if (
            $ConfigObject->Get('Ticket::Service')
            && $Config->{Service}
            && $Config->{ServiceMandatory}
            && !$GetParam{ServiceID}
            && !$IsUpload
            )
        {
            $Error{'ServiceIDInvalid'} = 'ServerError';
        }

        # check mandatory sla
        if (
            $ConfigObject->Get('Ticket::Service')
            && $Config->{SLA}
            && $Config->{SLAMandatory}
            && !$GetParam{SLAID}
            && !$IsUpload
            )
        {
            $Error{'SLAIDInvalid'} = 'ServerError';
        }

        my @RequestIDArrayCheck = split( /,/, $GetParam{RequestFormIDs} );
        for my $NewValues (@RequestIDArrayCheck) {
            if ( $GetParam{$NewValues} ne "-" ) {
                my @FeldCheck = split( /-/, $NewValues );
            }
        }

        if (%Error) {

            $GetParam{RequestFormIDs} = '';

            # html output
            my $Output .= $LayoutObject->Header();
            $Output    .= $LayoutObject->NavigationBar();
            $Output    .= $Self->_MaskNew(
                Attachments => \@Attachments,
                %GetParam,
                CustomerID       => $LayoutObject->Ascii2Html( Text => $CustomerID ),
                CustomerUser     => $CustomerUser,
                CustomerData     => \%CustomerData,
                ToSelected       => $Dest,
                QueueID          => $NewQueueID,
                DynamicFieldHTML => \%DynamicFieldHTML,
                Errors           => \%Error,
                MultipleCustomer     => \@MultipleCustomer,
                FromExternalCustomer => \%FromExternalCustomer,
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck( Type => 'Customer' );

        # if customer is not allowed to set priority, set it to default
        if ( !$Config->{Priority} ) {
            $GetParam{PriorityID} = '';
            $GetParam{Priority}   = $Config->{PriorityDefault};
        }

        my %CheckRequestOne = $RequestObject->RequestGet(
            RequestID => $GetParam{RequestID},
        );

        if ( !$SelectedCustomerUser ) {
            $SelectedCustomerUser = $GetParam{From};
        }

        if ( !$CustomerID ) {
            $CustomerID = $GetParam{From};
        }

        my $TicketID = 0;
        if ( $CheckRequestOne{ProcessID} && $CheckRequestOne{ProcessID} >= 1 ) {

            my $ProcessesObject = $Kernel::OM->Get('Kernel::System::Processes');
            my %ProcessData = $ProcessesObject->ProcessGet(
                ID => $CheckRequestOne{ProcessID},
            );

            my $ProzessTitle = $ProcessData{Name} . ' - ' . $GetParam{Subject};

            # create new ticket, do db insert
            $TicketID = $TicketObject->TicketCreate(
                QueueID      => $ProcessData{QueueID},
                TypeID       => $GetParam{TypeID},
                ServiceID    => $GetParam{ServiceID},
                SLAID        => $GetParam{SLAID},
                Title        => $ProzessTitle,
                PriorityID   => $GetParam{PriorityID},
                Priority     => $GetParam{Priority},
                Lock         => 'unlock',
                State        => $Config->{StateDefault},
                CustomerID   => $CustomerID,
                CustomerUser => $SelectedCustomerUser,
                OwnerID      => 1,
                UserID       => 1,
            );
        }
        else {

            # create new ticket, do db insert
            $TicketID = $TicketObject->TicketCreate(
                QueueID      => $NewQueueID,
                TypeID       => $GetParam{TypeID},
                ServiceID    => $GetParam{ServiceID},
                SLAID        => $GetParam{SLAID},
                Title        => $GetParam{Subject},
                PriorityID   => $GetParam{PriorityID},
                Priority     => $GetParam{Priority},
                Lock         => 'unlock',
                State        => $Config->{StateDefault},
                CustomerID   => $CustomerID,
                CustomerUser => $SelectedCustomerUser,
                OwnerID      => 1,
                UserID       => 1,
            );
        }

        my $RequestFormName = $LayoutObject->{LanguageObject}->Translate( 'Request' );

        my $ArticleBody = '<b>' . $RequestFormName . ': ' . $Request{Name} . '</b><br><br><div id="Request">';

        if ($TicketID) {

            my $TicketIDSuccess = $TicketRequestObject->TicketIDRequestAdd(
                TicketID  => $TicketID,
                RequestID => $GetParam{RequestID},
                UserID    => 1,
            );

            my %CheckRequest = $RequestObject->RequestGet(
                RequestID => $GetParam{RequestID},
            );

            if ( $CheckRequest{OwnerID} ) {
                my $OwnerSuccess = $TicketObject->TicketOwnerSet(
                    TicketID  => $TicketID,
                    UserID    => 1,
                    NewUserID => $CheckRequest{OwnerID},
                );
            }

            if ( $CheckRequest{ResponsibleID} ) {
                my $ResponsibleSuccess = $TicketObject->TicketResponsibleSet(
                    TicketID  => $TicketID,
                    UserID    => 1,
                    NewUserID => $CheckRequest{ResponsibleID},
                );
            }

            my $ShowConfigItem = $ConfigObject->Get('Ticket::Frontend::ConfigItemZoomSearch');
            if ( $ShowConfigItem && $ShowConfigItem >= 1 ) {

                if ( $Request{ShowConfigItem} eq "1" ) {

                    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

                    my $ClassList = $GeneralCatalogObject->ItemList(
                        Class => 'ITSM::ConfigItem::Class',
                        Valid => 1,
                    );

                    for my $Class ( %{$ClassList} ) {
                        if ( $Class =~ /^\d+$/ ) {

                            my $CheckConfigItemsID = 'ConfigItemID' . $Class;
                            my @ConfigItemArray = $ParamObject->GetArray( Param => $CheckConfigItemsID );

                            for my $ConfigItemID ( @ConfigItemArray) {

                                my $True = $LinkObject->LinkAdd(
                                    SourceObject => 'Ticket',
                                    SourceKey    => $TicketID,
                                    TargetObject => 'ITSMConfigItem',
                                    TargetKey    => $ConfigItemID,
                                    Type         => 'RelevantTo',
                                    State        => 'Valid',
                                    UserID       => 1,
                                );

                            }
                        }
                    }
                }
            }

            my @RequestIDArray     = split( /,/, $GetParam{RequestFormIDs} );
            my $DateString        = '';
            my $DateKey           = '';
            my $CheckRequestFormID = '';
            my %RequestFields;
            my $TypArt           = '';
            my $CheckNum         = 0;
            my $FeldCheckDate    = '';
            my $CheckNumAll      = 0;
            my $CheckNumAllCheck = 0;

            for my $NewValues (@RequestIDArray) {
                $CheckNumAll++;
            }

            for my $NewValues (@RequestIDArray) {
                my @FeldCheck = split( /-/, $NewValues );

                $CheckNum++;
                $CheckNumAllCheck++;

                if ( $CheckNum == 1 ) {
                    $TypArt        = $FeldCheck[1];
                    $FeldCheckDate = $FeldCheck[0];
                }

                if ( $FeldCheck[1] && $FeldCheck[1] !~ /[a-z]/ig ) {
                    my %RequestForm = $RequestFormObject->RequestFormGet(
                        RequestFormID => $FeldCheck[1],
                    );
                    $CheckRequestFormID = $RequestForm{ID};
                    if ( $RequestForm{FeldID} ) {
                        %RequestFields = $RequestFieldsObject->RequestFieldsGet(
                            RequestFieldsID => $RequestForm{FeldID},
                        );
                    }
                    else {
                        $RequestFields{Labeling} = $RequestForm{Description};
                    }
                }

                if (
                    $FeldCheck[1]
                    && ( $FeldCheck[1] !~ /[a-z]/ig && $FeldCheck[0] !~ /Headline/ && $FeldCheck[0] !~ /Description/  )
                    )
                {
                    if ( $RequestFields{Typ} eq "Multiselect" ) {
                        my @CheckMulti = split( /,/, $GetParam{$NewValues} );
                        my $NewRequestFieldInhalt = '';
                        for my $NewMulti (@CheckMulti) {

                            my $RequestFieldInhalt = $RequestFieldsObject->RequestFieldsWertLookup(
                                RequestFieldKey => $NewMulti,
                            );
                            $NewRequestFieldInhalt .= $RequestFieldInhalt . ', ';
                        }
                        $NewRequestFieldInhalt = substr ($NewRequestFieldInhalt, 0, -2);
                        $ArticleBody .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>' . $RequestFields{Labeling} . '</strong>:</div> <div style="display:block;float:left;padding:5px;">' . $NewRequestFieldInhalt . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID     => $TicketID,
                            RequestID    => $GetParam{RequestID},
                            FeldKey      => $FeldCheck[0],
                            FeldValue    => $NewRequestFieldInhalt,
                            FeldLabeling => $RequestFields{Labeling},
                            UserID       => 1,
                        );
                        $CheckNum = 0;
                    }
                    elsif ( $RequestFields{Typ} eq "Dropdown" ) {
                        my $RequestFieldInhalt = $RequestFieldsObject->RequestFieldsWertLookup(
                            RequestFieldKey => $GetParam{$NewValues},
                        );
                        $ArticleBody .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>' . $RequestFields{Labeling} . '</strong>: </div> <div style="display:block;float:left;padding:5px;">' . $RequestFieldInhalt . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID     => $TicketID,
                            RequestID    => $GetParam{RequestID},
                            FeldKey      => $FeldCheck[0],
                            FeldValue    => $RequestFieldInhalt,
                            FeldLabeling => $RequestFields{Labeling},
                            UserID       => 1,
                        );
                        my $GoGetParamNew = "RequestFormBlockIDs" . $CheckRequestFormID;
                        my %GetParamNew;
                        for my $Key ($GoGetParamNew) {
                            $GetParamNew{$Key} = $ParamObject->GetParam( Param => $Key );
                        }
                        $ArticleBody .= $Self->_SetBlockHTML(
                            TicketID           => $TicketID,
                            RequestID           => $GetParam{RequestID},
                            UserID             => 1,
                            CheckRequestFormID  => $CheckRequestFormID,
                            GetParam           => \%GetParamNew,
                            RequestFormBlockIDs => $GetParamNew{$GoGetParamNew},
                        );
                        $CheckNum = 0;
                    }
                    else {
                        if ( $RequestFields{Typ} eq 'TextArea' ) {
                             $GetParam{$NewValues} = $LayoutObject->Ascii2RichText( String => $GetParam{$NewValues} );
                        }
                        $ArticleBody .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>' . $RequestFields{Labeling} . '</strong>: </div> <div style="display:block;float:left;padding:5px;">' . $GetParam{$NewValues} . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID         => $TicketID,
                            RequestID         => $GetParam{RequestID},
                            FeldKey          => $FeldCheck[0],
                            FeldValue        => $GetParam{$NewValues},
                            FeldLabeling => $RequestFields{Labeling},
                            UserID           => 1,
                        );
                        $CheckNum = 0;
                    }
                }
                elsif ( $FeldCheck[0] =~ /Headline/ ) {

                    $ArticleBody .= '<div style="width:100%;display:block;">' . $GetParam{$NewValues} . '</div>';
                    my $Success = $TicketRequestObject->TicketRequestAdd(
                        TicketID         => $TicketID,
                        RequestID         => $GetParam{RequestID},
                        FeldKey          => $FeldCheck[0],
                        FeldValue        => $GetParam{$NewValues},
                        FeldLabeling => $GetParam{$NewValues},
                        UserID           => 1,
                    );
                    $CheckNum = 0;
                }
                elsif ( $FeldCheck[0] =~ /Description/ ) {

                    $ArticleBody .= '<div style="width:100%;display:block;">' . $GetParam{$NewValues} . '</div>';
                    my $Success = $TicketRequestObject->TicketRequestAdd(
                        TicketID         => $TicketID,
                        RequestID         => $GetParam{RequestID},
                        FeldKey          => $FeldCheck[0],
                        FeldValue        => $GetParam{$NewValues},
                        FeldLabeling => $GetParam{$NewValues},
                        UserID           => 1,
                    );
                    $CheckNum = 0;
                }
                else {

                    $DateKey = $FeldCheck[0];

                    if ( $NewValues =~ /Day/ig && $CheckNum == 1 ) {
                        $DateString .= $GetParam{$NewValues};
                    }
                    if ( $NewValues =~ /Month/ig ) {
                        $DateString .= "." . $GetParam{$NewValues};
                    }
                    if ( $NewValues =~ /Year/ig ) {
                        $DateString .= "." . $GetParam{$NewValues};
                    }

                    if ( $CheckNumAllCheck == $CheckNumAll && $CheckNum == 3 ) {
                        my %RequestForm = $RequestFormObject->RequestFormGet(
                            RequestFormID => $TypArt,
                        );
                        %RequestFields = $RequestFieldsObject->RequestFieldsGet(
                            RequestFieldsID => $RequestForm{FeldID},
                        );
                        $ArticleBody
                            .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>'
                            . $RequestFields{Labeling}
                            . '</strong>: </div> <div style="display:block;float:left;padding:5px;">'
                            . $DateString
                            . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID     => $TicketID,
                            RequestID    => $GetParam{RequestID},
                            FeldKey      => $DateKey,
                            FeldValue    => $DateString,
                            FeldLabeling => $RequestFields{Labeling},
                            UserID       => 1,
                        );
                    }

                    if ( $FeldCheckDate ne "$FeldCheck[0]" ) {

                        my %RequestForm = $RequestFormObject->RequestFormGet(
                            RequestFormID => $TypArt,
                        );
                        %RequestFields = $RequestFieldsObject->RequestFieldsGet(
                            RequestFieldsID => $RequestForm{FeldID},
                        );
                        $ArticleBody
                            .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>'
                            . $RequestFields{Labeling}
                            . '</strong>: </div> <div style="display:block;float:left;padding:5px;">'
                            . $DateString
                            . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID     => $TicketID,
                            RequestID    => $GetParam{RequestID},
                            FeldKey      => $DateKey,
                            FeldValue    => $DateString,
                            FeldLabeling => $RequestFields{Labeling},
                            UserID       => 1,
                        );

                        $DateString    = '';
                        $DateKey       = '';
                        $FeldCheckDate = '';
                        $CheckNum      = 0;

                        if ( $NewValues =~ /Day/ig ) {
                            $DateString .= $GetParam{$NewValues};
                        }

                    }

                    my $CheckDateString = 0;
                    if ( $NewValues =~ /Hour/ig ) {

                        if ( $GetParam{$NewValues} eq "1" ) {
                        	$GetParam{$NewValues} = "01";
                        }
                        if ( $GetParam{$NewValues} eq "2" ) {
                        	$GetParam{$NewValues} = "02";
                        }
                        if ( $GetParam{$NewValues} eq "3" ) {
                        	$GetParam{$NewValues} = "03";
                        }
                        if ( $GetParam{$NewValues} eq "4" ) {
                        	$GetParam{$NewValues} = "04";
                        }
                        if ( $GetParam{$NewValues} eq "5" ) {
                        	$GetParam{$NewValues} = "05";
                        }
                        if ( $GetParam{$NewValues} eq "6" ) {
                        	$GetParam{$NewValues} = "06";
                        }
                        if ( $GetParam{$NewValues} eq "7" ) {
                        	$GetParam{$NewValues} = "07";
                        }
                        if ( $GetParam{$NewValues} eq "8" ) {
                        	$GetParam{$NewValues} = "08";
                        }
                        if ( $GetParam{$NewValues} eq "9" ) {
                        	$GetParam{$NewValues} = "09";
                        }


                        $DateString .= " " . $GetParam{$NewValues};
                    }
                    else {
                    	$CheckDateString ++;
                    }

                    if ( $CheckDateString == 3 ) {
                        $DateString .= " 00";
                        $NewValues = "Minute";
                        $GetParam{"Minute"} = 5;
                    }

                    if ( $NewValues =~ /Minute/ig ) {

                        if ( $GetParam{$NewValues} eq "1" ) {
                        	$GetParam{$NewValues} = "01";
                        }
                        if ( $GetParam{$NewValues} eq "2" ) {
                        	$GetParam{$NewValues} = "02";
                        }
                        if ( $GetParam{$NewValues} eq "3" ) {
                        	$GetParam{$NewValues} = "03";
                        }
                        if ( $GetParam{$NewValues} eq "4" ) {
                        	$GetParam{$NewValues} = "04";
                        }
                        if ( $GetParam{$NewValues} eq "5" ) {
                        	$GetParam{$NewValues} = "05";
                        }
                        if ( $GetParam{$NewValues} eq "6" ) {
                        	$GetParam{$NewValues} = "06";
                        }
                        if ( $GetParam{$NewValues} eq "7" ) {
                        	$GetParam{$NewValues} = "07";
                        }
                        if ( $GetParam{$NewValues} eq "8" ) {
                        	$GetParam{$NewValues} = "08";
                        }
                        if ( $GetParam{$NewValues} eq "9" ) {
                        	$GetParam{$NewValues} = "09";
                        }


                        $DateString .= ":" . $GetParam{$NewValues};
                        $FeldCheck[1] =~ s/Minute//ig;
                        my %RequestForm = $RequestFormObject->RequestFormGet(
                            RequestFormID => $FeldCheck[1],
                        );
                        %RequestFields = $RequestFieldsObject->RequestFieldsGet(
                            RequestFieldsID => $RequestForm{FeldID},
                        );
                        $ArticleBody .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>' . $RequestFields{Labeling} . '</strong>: </div> <div style="display:block;float:left;padding:5px;">' . $DateString . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID         => $TicketID,
                            RequestID         => $GetParam{RequestID},
                            FeldKey          => $DateKey,
                            FeldValue        => $DateString,
                            FeldLabeling => $RequestFields{Labeling},
                            UserID           => 1,
                        );
                        $DateString = '';
                        $DateKey    = '';
                        $FeldCheckDate = '';
                        $CheckNum = 0;
                    }
                }
            }

            if ( $CheckRequest{ProcessID} && $CheckRequest{ProcessID} >= 1 ) {

                my $ProcessesObject = $Kernel::OM->Get('Kernel::System::Processes');

                my %ProcessData = $ProcessesObject->ProcessGet(
                    ID => $CheckRequest{ProcessID},
                );
            
                my %CheckTicket = $TicketObject->TicketGet(
                    TicketID      => $TicketID,
                    DynamicFields => 0,
                    UserID        => 1,
                    Silent        => 1,
                );

                my $ProcessStepObject                    = $Kernel::OM->Get('Kernel::System::ProcessStep');
                my $ProcessFieldsObject                  = $Kernel::OM->Get('Kernel::System::ProcessFields');
                my $DynamicProcessFieldsObject           = $Kernel::OM->Get('Kernel::System::DynamicProcessFields');
                my $ProcessConditionsObject              = $Kernel::OM->Get('Kernel::System::ProcessConditions');
                my $ProcessTransitionObject              = $Kernel::OM->Get('Kernel::System::ProcessTransition');
                my $TicketProcessesObject                = $Kernel::OM->Get('Kernel::System::TicketProcesses');
                my $TicketProcessStepObject              = $Kernel::OM->Get('Kernel::System::TicketProcessStep');
                my $TicketProcessFieldsObject            = $Kernel::OM->Get('Kernel::System::TicketProcessFields');
                my $TicketDynamicProcessFieldsObject     = $Kernel::OM->Get('Kernel::System::TicketDynamicProcessFields');
                my $TicketProcessConditionsObject        = $Kernel::OM->Get('Kernel::System::TicketProcessConditions');
                my $TicketProcessTransitionObject        = $Kernel::OM->Get('Kernel::System::TicketProcessTransition');
                my $TicketProcessDynamicConditionsObject = $Kernel::OM->Get('Kernel::System::TicketProcessDynamicConditions');
                my $TicketProcessesMergeObject           = $Kernel::OM->Get('Kernel::System::TicketProcessesMerge');
                my $ProcessDynamicConditionsObject       = $Kernel::OM->Get('Kernel::System::ProcessDynamicConditions');
        
                my %ProcessDataTransver = $ProcessesObject->ProcessGet(
                    ID => $CheckRequest{ProcessID},
                );
                my $NewID = $TicketProcessesObject->ProcessAdd(
                    Name         => $ProcessDataTransver{Name},
                    Description  => $ProcessDataTransver{Description},
                    QueueID      => $ProcessDataTransver{QueueID},
                    SetArticleID => $ProcessDataTransver{SetArticleIDProcess},
                    ValidID      => $ProcessDataTransver{ValidID},
                    UserID       => 1,
                    TicketID     => $TicketID,
                );
        
                my %ProcessStepList = $ProcessStepObject->StepList(
                    Valid => 1,
                    ProcessID => $CheckRequest{ProcessID},
                );
        
                my $ProcessStepValue = 0;
                my $NewProcessStepID = '';
                my $StepActive           = 0;
                my $StepActiveCheck      = 0;
                my $ValueCheck           = 0;
                my $StepActiveCheckFirst = 0;
                my $CheckTheNext         = 0;

                for my $ProcessStepListID ( sort { $a <=> $b } keys %ProcessStepList ) {
        
                    my %ProcessStepData = $ProcessStepObject->ProcessStepGet(
                        ID => $ProcessStepListID,
                    );
        
                    $ValueCheck ++;
        
                    if ( $ValueCheck == 2 && !$ProcessStepData{ParallelStep} ) {
                        $CheckTheNext = 1;
                    }
        
                    if ( $ProcessStepData{ParallelStep} && $ValueCheck > 1 && $StepActiveCheckFirst < 1 && $CheckTheNext <= 0 ) {
                        $StepActiveCheck ++;
                        $StepActive = 1;
                    }
                    else {
        
                        if ( $ValueCheck > 1 && $StepActiveCheck >= 1 ) {
                            $StepActive = 0;
                            $StepActiveCheckFirst = 1;
                        }
                    }
                
                    if ( $ProcessStepData{ProcessID} == $CheckRequest{ProcessID} ) {
        
                        $ProcessStepValue ++;
        
                        if ( $ProcessStepValue == 1 ) {
        
                            if ( $ProcessStepData{ApproverEmail} eq "Vorgesetzter" ) {

                                my %TicketRequestList = $TicketRequestObject->TicketRequestOverview(
                                    TicketID => $TicketID,
                                    UserID   => 1,
                                );

                                my $AntragFeldSchluessel
                                    = $RequestFieldsObject->RequestFieldsSchluesselLookup(
                                    RequestFieldValue => $TicketRequestList{Vorgesetzter},
                                    );

                                $ProcessStepData{ApproverEmail} = $AntragFeldSchluessel;
                            }

                            $NewProcessStepID = $TicketProcessStepObject->ProcessStepAdd(
                                Name                => $ProcessStepData{Name},
                                ProcessID           => $NewID,
                                ProcessStep         => $ProcessStepData{ProcessStep},
                                StepNo              => $ProcessStepData{StepNo},
                                StepNoFrom          => $ProcessStepData{StepNoFrom},
                                StepNoTo            => $ProcessStepData{StepNoTo},
                                Color               => $ProcessStepData{Color},
                                Description         => $ProcessStepData{Description},
                                GroupID             => $ProcessStepData{GroupID},
                                StepArtID           => $ProcessStepData{StepArtID},
                                ApproverGroupID     => $ProcessStepData{ApproverGroupID},
                                ApproverEmail       => $ProcessStepData{ApproverEmail},
                                ValidID             => $ProcessStepData{ValidID},
                                StepEnd             => $ProcessStepData{StepEnd},
                                NotApproved         => $ProcessStepData{NotApproved},
                                ToIDFromOne         => $ProcessStepData{ToIDFromOne},
                                WithoutConditionEnd => $ProcessStepData{WithoutConditionEnd},
                                WithConditions      => $ProcessStepData{WithConditions},
                                ToIDFromTwo         => $ProcessStepData{ToIDFromTwo},
                                WithConditionsEnd   => $ProcessStepData{WithConditionsEnd},
                                SetArticleID        => $ProcessStepData{SetArticleID},
                                NotifyAgent         => $ProcessStepData{NotifyAgent},
                                TicketID            => $TicketID,
                                StepActive          => 1,
                                ParallelStep        => $ProcessStepData{ParallelStep},
                                SetParallel         => $ProcessStepData{SetParallel},
                                UserID              => 1,
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
        
                                if ( $ProcessStepData{ApproverGroupID} && $ProcessStepData{ApproverGroupID} == 1 )  {
            
                                    my %Ticket = $TicketObject->TicketGet(
                                        TicketID      => $TicketID,
                                        DynamicFields => 0,
                                        UserID        => 1,
                                        Silent        => 1,
                                    );
            
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
        
                                my $NotificationSubject = '[Ticket#'. $CheckTicket{TicketNumber} .'] - Process: ' . $ProcessDataTransver{Name} . ' - approval required';
        
                                my $NotificationBodyPre = 'Process-Description: ' . $ProcessDataTransver{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt: ' . $ProcessStepData{Name};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Arbeitsschritt-Description: ' . $ProcessStepData{Description};
                                $NotificationBodyPre .= '<br><br>';
                                $NotificationBodyPre .= 'Genehmigung erforderlich.<br>Bitte klicken Sie auf eine Entscheidung.';
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
                                    . "ProcessApproval.pl?ProcessID=$NewID;ProcessStepID=$NewProcessStepID;TicketID=$TicketID;Art=genehmigt\">Genehmigen</a>
                                \n<br>\n<br>oder\n<br>\n<br>
                                <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                    . "ProcessApproval.pl?ProcessID=$NewID;ProcessStepID=$NewProcessStepID;TicketID=$TicketID;Art=abgelehnt\">Ablehnen</a>
                                \n\n<br><br>
                    
                                </div>
        
                                <div style=\"color:black;width:100%;font-size:14px;font-family:Helvetica, Arial, sans-serif;font-weight:normal;\">
        
                                Es wurde folgende Anfrage gestellt:\n\n<br><br>
                    
                                $NotificationBodyPre
                                ";
        
                                if ( !$ProcessStepData{ApproverGroupID} || $ProcessStepData{ApproverGroupID} < 1 )  {
        
                                    $NotificationBody .= "
                                    <a href=\"$HttpType://$FQDN" . "/$ScriptAlias"
                                        . "index.pl?Action=AgentTicketZoom;TicketID=$TicketID\">$HttpType://$FQDN/$ScriptAlias"
                                        . "index.pl?Action=AgentTicketZoom;TicketID=$TicketID</a>
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
                                        TicketID     => $TicketID,
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
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$TicketID\">$HttpType://$FQDN/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$TicketID</a>
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
                                        TicketID     => $TicketID,
                                        CreateUserID => 1,
                                    );

                                }
                            }
                        }
                        else {
        
                            $NewProcessStepID = $TicketProcessStepObject->ProcessStepAdd(
                                Name                => $ProcessStepData{Name},
                                ProcessID           => $NewID,
                                ProcessStep         => $ProcessStepData{ProcessStep},
                                StepNo              => $ProcessStepData{StepNo},
                                StepNoFrom          => $ProcessStepData{StepNoFrom},
                                StepNoTo            => $ProcessStepData{StepNoTo},
                                Color               => $ProcessStepData{Color},
                                Description         => $ProcessStepData{Description},
                                GroupID             => $ProcessStepData{GroupID},
                                StepArtID           => $ProcessStepData{StepArtID},
                                ApproverGroupID     => $ProcessStepData{ApproverGroupID},
                                ApproverEmail       => $ProcessStepData{ApproverEmail},
                                ValidID             => $ProcessStepData{ValidID},
                                StepEnd             => $ProcessStepData{StepEnd},
                                NotApproved         => $ProcessStepData{NotApproved},
                                ToIDFromOne         => $ProcessStepData{ToIDFromOne},
                                WithoutConditionEnd => $ProcessStepData{WithoutConditionEnd},
                                WithConditions      => $ProcessStepData{WithConditions},
                                ToIDFromTwo         => $ProcessStepData{ToIDFromTwo},
                                WithConditionsEnd   => $ProcessStepData{WithConditionsEnd},
                                SetArticleID        => $ProcessStepData{SetArticleID},
                                TicketID            => $TicketID,
                                ParallelStep        => $ProcessStepData{ParallelStep},
                                SetParallel         => $ProcessStepData{SetParallel},
                                NotifyAgent         => $ProcessStepData{NotifyAgent},
                                StepActive          => $StepActive,
                                UserID              => 1,
                            );

                            if ( $StepActive >= 1 ) {
        
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
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$TicketID\">$HttpType://$FQDN/$ScriptAlias"
                                    . "index.pl?Action=AgentTicketZoom;TicketID=$TicketID</a>
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
                                        TicketID     => $TicketID,
                                        CreateUserID => 1,
                                    );

                                }
                            }
                        }
        
                        my $Success = $TicketProcessesMergeObject->ProcessMergeAdd(
                            OldID    => $ProcessStepData{ProcessStepID},
                            NewID    => $NewProcessStepID,
                            TicketID => $TicketID,
                        );
        
                        my %ProcessFieldList = $ProcessFieldsObject->ProcessFieldList(
                            ProcessID     => $CheckRequest{ProcessID},
                            ProcessStepID => $ProcessStepData{ProcessStepID},
                        );
        
                        for my $ProcessFieldID ( keys %ProcessFieldList ) {
        
                            my %ProcessStepField = $ProcessFieldsObject->ProcessFieldGet(
                                ProcessFieldID => $ProcessFieldID,
                            );
        
                            my $FieldID = $TicketProcessFieldsObject->ProcessFieldAdd(
                                ProcessID     => $NewID,
                                ProcessStepID => $NewProcessStepID,
                                FieldID       => $ProcessStepField{FieldID},
                                Required      => $ProcessStepField{Required},
                                Sequence      => $ProcessStepField{Sequence},
                                UserID        => 1,
                                TicketID      => $TicketID,
                            );
                        }
        
                        my %DynamicProcessFieldList = $DynamicProcessFieldsObject->DynamicProcessFieldList(
                            ProcessID     => $CheckRequest{ProcessID},
                            ProcessStepID => $ProcessStepData{ProcessStepID},
                        );
        
                        for my $DynamicProcessFieldID ( keys %DynamicProcessFieldList ) {
        
                            my %DynamicStepField = $DynamicProcessFieldsObject->DynamicProcessFieldGet(
                                ProcessFieldID => $DynamicProcessFieldID,
                            );
        
                            my $FieldID = $TicketDynamicProcessFieldsObject->DynamicProcessFieldAdd(
                                ProcessID      => $NewID,
                                ProcessStepID  => $NewProcessStepID,
                                DynamicFieldID => $DynamicStepField{DynamicFieldID},
                                UserID         => 1,
                                Required       => $DynamicStepField{Required},
                                TicketID       => $TicketID,
                            );
                        }
        
                        my %ProcessConditionsList = $ProcessDynamicConditionsObject->ProcessDynamicConditionsList(
                            ProcessID     => $CheckRequest{ProcessID},
                            ProcessStepID => $ProcessStepData{ProcessStepID},
                        );
        
                        for my $DynamicConditionsID ( keys %ProcessConditionsList ) {
        
                            my %DynamicConditions = $ProcessDynamicConditionsObject->ProcessDynamicConditionsGet(
                                DynamicConditionsID => $DynamicConditionsID,
                            );
        
                            my $Success = $TicketProcessDynamicConditionsObject->ProcessDynamicConditionsAdd(
                                ProcessID      => $NewID,
                                ProcessStepID  => $NewProcessStepID,
                                DynamicFieldID => $DynamicConditions{DynamicFieldID},
                                DynamicValue   => $DynamicConditions{DynamicValue},
                                TicketID       => $TicketID,
                                UserID         => 1,
                            );
                        }
        
                        my %ProcessConditionsListTwo = $ProcessConditionsObject->ProcessConditionsAllList(
                            ProcessID     => $CheckRequest{ProcessID},
                            ProcessStepID => $ProcessStepData{ProcessStepID},
                        );
        
                        for my $ConditionsFieldID ( keys %ProcessConditionsListTwo ) {
        
                            my %ProcessConditions = $ProcessConditionsObject->ProcessConditionsGet(
                                ProcessConditionsID => $ConditionsFieldID,
                            );
        
                            my $Success = $TicketProcessConditionsObject->ProcessConditionsAdd(
                                ProcessID     => $NewID,
                                ProcessStepID => $NewProcessStepID,
                                ProcessStepNo => $ProcessConditions{ProcessStepNo},
                                Title         => $ProcessConditions{Title},
                                Type          => $ProcessConditions{Type},
                                Queue         => $ProcessConditions{Queue},
                                State         => $ProcessConditions{State},
                                Service       => $ProcessConditions{Service},
                                SLA           => $ProcessConditions{SLA},
                                CustomerUser  => $ProcessConditions{CustomerUser},
                                Owner         => $ProcessConditions{Owner},
                                UserID        => 1,
                                TicketID      => $TicketID,
                            );
                        }
         
                         my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionAllList(
                            ProcessID     => $CheckRequest{ProcessID},
                            ProcessStepID => $ProcessStepData{ProcessStepID},
                        );
         
                         for my $TransitionFieldID ( keys %ProcessTransitionList ) {
        
                            my %ProcessTransition = $ProcessTransitionObject->ProcessTransitionGet(
                                ProcessTransitionID => $TransitionFieldID,
                            );
        
                            my $Success = $TicketProcessTransitionObject->ProcessTransitionAdd(
                                ProcessID     => $NewID,
                                ProcessStepID => $NewProcessStepID,
                                ProcessStepNo => $ProcessTransition{ProcessStepNo},
                                StepNo        => $ProcessTransition{StepNo},
                                TypeID        => $ProcessTransition{TypeID},
                                StateID       => $ProcessTransition{StateID},
                                QueueID       => $ProcessTransition{QueueID},
                                ServiceID     => $ProcessTransition{ServiceID},
                                SLAID         => $ProcessTransition{SLAID},
                                UserID        => 1,
                                TicketID      => $TicketID,
                            );
                        }
         
                    }
                }
        
                my %ProcessStepTicketList = $TicketProcessStepObject->ProcessStepTicketList(
                    TicketID => $TicketID,
                );
        
                for my $NewTicketProcessStepID ( keys %ProcessStepTicketList ) {
        
                    my %ProcessStepDataNew = $TicketProcessStepObject->ProcessStepGet(
                        ID => $NewTicketProcessStepID,
                    );
        
                    if ( $ProcessStepDataNew{StepNoFrom} ) {
        
                        my $Success = $TicketProcessesMergeObject->ProcessMergeStepNoFromUpdate(
                            OldID         => $ProcessStepDataNew{StepNoFrom},
                            ProcessStepID => $NewTicketProcessStepID,
                            TicketID      => $TicketID,
                        );
                    }
        
                    if ( $ProcessStepDataNew{ToIDFromOne} ) {
        
                        my $Success = $TicketProcessesMergeObject->ProcessMergeToIDFromOneUpdate(
                            OldID         => $ProcessStepDataNew{ToIDFromOne},
                            TicketID      => $TicketID,
                            ProcessStepID => $NewTicketProcessStepID,
                        );
                    }

                    if ( $ProcessStepDataNew{ToIDFromTwo} ) {
        
                        my $Success = $TicketProcessesMergeObject->ProcessMergeToIDFromTwoUpdate(
                            OldID         => $ProcessStepDataNew{ToIDFromTwo},
                            TicketID      => $TicketID,
                            ProcessStepID => $NewTicketProcessStepID,
                        );
                    }
        
                }
        
                my $ProcessMergeDeleteSucess = $TicketProcessesMergeObject->ProcessMergeDelete(
                    TicketID => $TicketID,
                );
        
                my $Success = $TicketObject->TicketProcessSet(
                    TicketID  => $TicketID,
                    ProcessID => $NewID,
                );
        
                my $ProcessFormName = $LayoutObject->{LanguageObject}->Translate( 'Process' );
                my $ArticleBody = '<b>' . $ProcessFormName . ': ' . $ProcessData{Name} . '</b><br><br><div id="Process">';
                $ArticleBody .= '</div>';
           }
        }

        $ArticleBody .= '</div>';

        # set ticket dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

            # set the value
            my $Success = $BackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $TicketID,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        if ( $GetParam{Body} eq "-" ) {
            $GetParam{Body} = $ArticleBody;
        }
        if ( !$GetParam{Body} ) {
            $GetParam{Body} = $ArticleBody;
        }


        my $MimeType = 'text/plain';
        if ( $LayoutObject->{BrowserRichText} ) {
            $MimeType = 'text/html';

            # verify html document
            $GetParam{Body} = $LayoutObject->RichTextDocumentComplete(
                String => $GetParam{Body},
            );
        }

        my $PlainBody = $GetParam{Body};

        if ( $LayoutObject->{BrowserRichText} ) {
            $PlainBody = $LayoutObject->RichText2Ascii( String => $GetParam{Body} );
        }

        # create article
        my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
            UserLogin => $Self->{UserLogin},
        );

        my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );


        my %SetCustomerUser = $CustomerUserObject->CustomerUserDataGet(
            User => $CustomerUser,
        );

        if ( !$SetCustomerUser{UserMailString} ) {
            $SetCustomerUser{UserMailString} = $GetParam{From};
        }

        my $From      = "$Self->{UserFirstname} $Self->{UserLastname} <$Self->{UserEmail}>";
        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            TicketID         => $TicketID,
            SenderType       => $Config->{SenderType},
            From             => $SetCustomerUser{UserMailString},
            To               => $To,
            Subject          => $GetParam{Subject},
            Body             => $GetParam{Body},
            MimeType         => $MimeType,
            Charset          => $LayoutObject->{UserCharset},
            UserID           => 1,
            IsVisibleForCustomer => 1,
            HistoryType      => $Config->{HistoryType},
            HistoryComment       => $Config->{HistoryComment} || '%%',
            AutoResponseType => ( $ConfigObject->Get('AutoResponseForWebTickets') )
            ? 'auto reply'
            : '',
            OrigHeader => {
                From    => $SetCustomerUser{UserMailString},
                To      => $Self->{UserLogin},
                Subject => $GetParam{Subject},
                Body    => $PlainBody,
            },
            Queue => $QueueObject->QueueLookup( QueueID => $NewQueueID ),
        );

        if ( !$ArticleID ) {
            my $Output = $LayoutObject->Header( Title => 'Error' );
            $Output .= $LayoutObject->CustomerError();
            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        # set article dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Article';

            # set the value
            my $Success = $BackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ArticleID,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        # Permissions check were done earlier
        if ( $GetParam{FromChatID} ) {
            my $ChatObject = $Kernel::OM->Get('Kernel::System::Chat');
            my %Chat       = $ChatObject->ChatGet(
                ChatID => $GetParam{FromChatID},
            );
            my @ChatMessageList = $ChatObject->ChatMessageList(
                ChatID => $GetParam{FromChatID},
            );
            my $ChatArticleID;

            if (@ChatMessageList) {
                my $JSONBody = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
                    Data => \@ChatMessageList,
                );

                my $ChatArticleType = 'chat-external';

                $ChatArticleID = $TicketObject->ArticleCreate(

                    #NoAgentNotify => $NoAgentNotify,
                    TicketID    => $TicketID,
                    ArticleType => $ChatArticleType,
                    SenderType  => $Config->{SenderType},

                    From => $From,

                    # To               => $To,
                    Subject        => $Kernel::OM->Get('Kernel::Language')->Translate('Chat'),
                    Body           => $JSONBody,
                    MimeType       => 'application/json',
                    Charset        => $LayoutObject->{UserCharset},
                    UserID         => $ConfigObject->Get('CustomerPanelUserID'),
                    HistoryType    => $Config->{HistoryType},
                    HistoryComment => $Config->{HistoryComment} || '%%',
                    Queue          => $QueueObject->QueueLookup( QueueID => $NewQueueID ),
                );
            }
            if ($ChatArticleID) {
                $ChatObject->ChatDelete(
                    ChatID => $GetParam{FromChatID},
                );
            }
        }

        # get pre loaded attachment
        my @AttachmentData = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $Self->{FormID},
        );

        # get submitted attachment
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'file_upload',
        );
        if (%UploadStuff) {
            push @AttachmentData, \%UploadStuff;
        }

        # write attachments
        ATTACHMENT:
        for my $Attachment (@AttachmentData) {

            # skip, deleted not used inline images
            my $ContentID = $Attachment->{ContentID};
            if (
                $ContentID
                && ( $Attachment->{ContentType} =~ /image/i )
                && ( $Attachment->{Disposition} eq 'inline' )
                )
            {
                my $ContentIDHTMLQuote = $LayoutObject->Ascii2Html(
                    Text => $ContentID,
                );

                # workaround for link encode of rich text editor, see bug#5053
                my $ContentIDLinkEncode = $LayoutObject->LinkEncode($ContentID);
                $GetParam{Body} =~ s/(ContentID=)$ContentIDLinkEncode/$1$ContentID/g;

                # ignore attachment if not linked in body
                next ATTACHMENT if $GetParam{Body} !~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i;
            }

            # write existing file to backend
            $ArticleBackendObject->ArticleWriteAttachment(
                %{$Attachment},
                ArticleID => $ArticleID,
                UserID    => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        my %CustomerCheckRequest = $RequestObject->RequestGet(
            RequestID => $GetParam{RequestID},
        );

        my %TicketNumberSend = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 0,
            UserID        => 1,
        );

        # remove pre submitted attachments
        $UploadCacheObject->FormIDRemove( FormID => $Self->{FormID} );

        # redirect
        return $LayoutObject->Redirect(
            OP => "Action=AgentTicketZoom;TicketID=$TicketID",
        );
    }

    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {

        my $Dest         = $ParamObject->GetParam( Param => 'Dest' ) || '';
        my $CustomerUser = $Self->{UserID};
        my $QueueID      = '';
        if ( $Dest =~ /^(\d{1,100})\|\|.+?$/ ) {
            $QueueID = $1;
        }

        # get list type
        my $TreeView = 0;
        if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
            $TreeView = 1;
        }

        my $Tos = $Self->_GetTos(
            %GetParam,
            %ACLCompatGetParam,
            QueueID => $QueueID,
        );

        my $NewTos;

        if ($Tos) {
            TOs:
            for my $KeyTo ( sort keys %{$Tos} ) {
                next TOs if ( $Tos->{$KeyTo} eq '-' );
                $NewTos->{"$KeyTo||$Tos->{$KeyTo}"} = $Tos->{$KeyTo};
            }
        }
        my $Priorities = $Self->_GetPriorities(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
        );
        my $Services = $Self->_GetServices(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
        );
        my $SLAs = $Self->_GetSLAs(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
            Services       => $Services,
        );
        my $Types = $Self->_GetTypes(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
        );

        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $IsACLReducible = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );
            next DYNAMICFIELD if !$IsACLReducible;

            my $PossibleValues = $BackendObject->PossibleValuesGet(
                DynamicFieldConfig => $DynamicFieldConfig,
            );

            # convert possible values key => value to key => key for ACLs using a Hash slice
            my %AclData = %{$PossibleValues};
            @AclData{ keys %AclData } = keys %AclData;

            # set possible values filter from ACLs
            my $ACL = $TicketObject->TicketAcl(
                %GetParam,
                %ACLCompatGetParam,
                Action         => $Self->{Action},
                QueueID        => $QueueID || 0,
                ReturnType     => 'Ticket',
                ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data           => \%AclData,
                CustomerUserID => $Self->{UserID},
            );
            if ($ACL) {
                my %Filter = $TicketObject->TicketAclData();

                # convert Filer key => key back to key => value using map
                %{$PossibleValues} = map { $_ => $PossibleValues->{$_} } keys %Filter;
            }

            my $DataValues = $BackendObject->BuildSelectionDataGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                PossibleValues     => $PossibleValues,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
            ) || $PossibleValues;

            # add dynamic field to the list of fields to update
            push(
                @DynamicFieldAJAX,
                {
                    Name        => 'DynamicField_' . $DynamicFieldConfig->{Name},
                    Data        => $DataValues,
                    SelectedID  => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                    Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                    Max         => 100,
                }
            );
        }

        my $JSON = $LayoutObject->BuildSelectionJSON(
            [
                {
                    Name         => 'Dest',
                    Data         => $NewTos,
                    SelectedID   => $Dest,
                    Translation  => 0,
                    PossibleNone => 1,
                    TreeView     => $TreeView,
                    Max          => 100,
                },
                {
                    Name         => 'ServiceID',
                    Data         => $Services,
                    SelectedID   => $GetParam{ServiceID},
                    PossibleNone => 1,
                    Translation  => 0,
                    TreeView     => $TreeView,
                    Max          => 100,
                },
                {
                    Name         => 'SLAID',
                    Data         => $SLAs,
                    SelectedID   => $GetParam{SLAID},
                    PossibleNone => 1,
                    Translation  => 0,
                    Max          => 100,
                },
                @DynamicFieldAJAX,
            ],
        );
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    else {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No Subaction!'),
            Comment => Translatable('Please contact your administrator'),
        );
    }

}

sub _GetPriorities {
    my ( $Self, %Param ) = @_;

    # get priority
    my %Priorities;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %Priorities = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );
    }
    return \%Priorities;
}

sub _GetTypes {
    my ( $Self, %Param ) = @_;

    # get type
    my %Type;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %Type = $Kernel::OM->Get('Kernel::System::Ticket')->TicketTypeList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );
    }
    return \%Type;
}

sub _GetServices {
    my ( $Self, %Param ) = @_;

    # get service
    my %Service;

    # check needed
    return \%Service if !$Param{QueueID} && !$Param{TicketID};

    # get options for default services for unknown customers
    my $DefaultServiceUnknownCustomer
        = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::Default::UnknownCustomer');

    # get service list
    if ( $Param{CustomerUserID} || $DefaultServiceUnknownCustomer ) {
        %Service = $Kernel::OM->Get('Kernel::System::Ticket')->TicketServiceList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );
    }
    return \%Service;
}

sub _GetSLAs {
    my ( $Self, %Param ) = @_;

    # get sla
    my %SLA;
    if ( $Param{ServiceID} && $Param{Services} && %{ $Param{Services} } ) {
        if ( $Param{Services}->{ $Param{ServiceID} } ) {
            %SLA = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSLAList(
                %Param,
                Action         => $Self->{Action},
                CustomerUserID => $Self->{UserID},
            );
        }
    }
    return \%SLA;
}

sub _GetTos {
    my ( $Self, %Param ) = @_;

    # check own selection
    my %NewTos = ( '', '-' );
    my $Module
        = $Kernel::OM->Get('Kernel::Config')->Get('CustomerPanel::NewTicketQueueSelectionModule')
        || 'Kernel::Output::HTML::CustomerNewTicket::QueueSelectionGeneric';
    if ( $Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
        my $Object = $Module->new(
            %{$Self},
            SystemAddress => $Kernel::OM->Get('Kernel::System::SystemAddress'),
            Debug         => $Self->{Debug},
        );

        # log loaded module
        if ( $Self->{Debug} && $Self->{Debug} > 1 ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'debug',
                Message  => "Module: $Module loaded!",
            );
        }
        %NewTos = (
            $Object->Run(
                Env       => $Self,
                ACLParams => \%Param
            ),
            ( '', => '-' )
        );
    }
    else {
        return $Kernel::OM->Get('Kernel::Output::HTML::Layout')->FatalDie(
            Message => "Could not load $Module!",
        );
    }

    return \%NewTos;
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $TypeObject             = $Kernel::OM->Get('Kernel::System::Type');
    my $RequestObject           = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFieldsObject    = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestFormObject      = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $TicketRequestObject    = $Kernel::OM->Get('Kernel::System::TicketRequest');
    my $TimeObject             = $Kernel::OM->Get('Kernel::System::Time');
    my $LinkObject             = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $GroupObject            = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject             = $Kernel::OM->Get('Kernel::System::User');
    my $CustomerUserObject     = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $SendmailObject         = $Kernel::OM->Get('Kernel::System::Email');
    my $RequestFormBlockObject = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $QueueObject            = $Kernel::OM->Get('Kernel::System::Queue');

    $Param{FormID} = $Self->{FormID};
    $Param{Errors}->{QueueInvalid} = $Param{Errors}->{QueueInvalid} || '';

    my $DynamicFieldNames = $Self->_GetFieldsToUpdate(
        OnlyDynamicFields => 1,
    );

    # create a string with the quoted dynamic field names separated by commas
    if ( IsArrayRefWithData($DynamicFieldNames) ) {
        for my $Field ( @{$DynamicFieldNames} ) {
            $Param{DynamicFieldNamesStrg} .= ", '" . $Field . "'";
        }
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get list type
    my $TreeView = 0;
    if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
        $TreeView = 1;
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Config       = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

    # prepare errors
    if ( $Param{Errors} ) {
        for ( sort keys %{ $Param{Errors} } ) {
            $Param{$_} = $Param{Errors}->{$_};
            my $test = $Param{$_};
        }
    }

    my %Request = $RequestObject->RequestGet(
        RequestID => $Param{RequestID},
    );

    $Param{NoBodydisplay}           = 'display:none';
    $Param{NoBodyAltdisplay}        = 'display:inline';
    $Param{"BodyValidate_Required"} = '';
    $Param{RequestName}             = $Request{Name};

    # output overview result
    $LayoutObject->Block(
        Name => 'OverviewFelderList',
        Data => {
            %Param,
        },
    );

    if ( !$Request{SubjectChangeable} || $Request{SubjectChangeable} == 2 ) {

        $LayoutObject->Block(
            Name => 'SubjectNoChangeable',
            Data => {
                %Param,
            },
        );
    }
    else {

        $LayoutObject->Block(
            Name => 'SubjectChangeable',
            Data => {
                %Param,
            },
        );
    }

    if ( $Param{FromCustomerInvalid} ) {
        $LayoutObject->Block( Name => 'FromServerErrorMsg' );
    }

    my %RequestFormList = $RequestFormObject->RequestFormList(
        RequestID => $Param{RequestID},
        UserID   => 1,
    );

    my $IfValue;
    for my $RequestFormListID (
        sort { $RequestFormList{$a} <=> $RequestFormList{$b} }
        keys %RequestFormList
        )
    {

        #get RequestForm
        my %RequestForm = $RequestFormObject->RequestFormGet(
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

        $Param{ToolTipUnder}  = $RequestForm{ToolTip};
        if ( $RequestForm{ToolTipUnder} ) {
            $Param{ToolTipUnder}  =~ s/\n/<br>/g;
        }
        else {
             $Param{ToolTipUnder} = '';
        }

        if ( !$RequestForm{Headline} && !$RequestForm{Description} ) {

                #get RequestField
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
                $Param{FeldName}     = $RequestFields{Name};

                if ( $RequestFields{Typ} eq "Multiselect" && $RequestForm{RequiredField} == 1 ) {

                    my @DefaultvalueValue;
                    if ( $RequestFields{Defaultvalue} ) {
                        @DefaultvalueValue = split( /,/, $RequestFields{Defaultvalue} );
                    }

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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
                        Class        => 'Validate_Required Modernize',
                        SelectedID   => \@DefaultvalueValue,
                        Translation  => 0,
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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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
                        Class        => 'Modernize',
                        SelectedID   => \@DefaultvalueValue,
                        Translation  => 0,
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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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
                        Class        => 'Validate_Required Modernize',
                        SelectedID   => $RequestFields{Defaultvalue},
                        Translation  => 0,
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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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
                        Class        => 'Modernize',
                        SelectedID   => $RequestFields{Defaultvalue},
                        Translation  => 0,
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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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

                    $Param{RequestFormIDs} .= $RequestFields{Name} . '-' . $RequestFormListID . ",";

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

                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Day,";
                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Month,";
                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Year,";
                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Hour,";
                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Minute,";

                    my $NewDiffTime  = $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0;
                    my $PeriodFuture = 5;
                    my $PeriodPast   = 0;

                    # date data string
                    $Param{FeldNameString} = $LayoutObject->BuildDateSelection(
                        %Param,
                        Format               => 'DateInputFormatLong',
                        Prefix               => $RequestFields{Name} . '-' . $RequestFormListID,
                        YearPeriodPast       => $PeriodPast,
                        YearPeriodFuture     => $PeriodFuture,
                        DiffTime             => $NewDiffTime,
                        Class                => $Param{Errors}->{DateInvalid},
                        Validate             => 1,
                       RequestFormateInFuture => 1,
                    );

                    $LayoutObject->Block(
                        Name => 'OverviewListFelderDateRequired',
                        Data => {
                            %Param,
                        },
                    );
                }
                if ( $RequestFields{Typ} eq "Date" && $RequestForm{RequiredField} == 2 ) {

                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Day,";
                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Month,";
                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Year,";
                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Hour,";
                    $Param{RequestFormIDs}
                        .= $RequestFields{Name} . '-' . $RequestFormListID . "Minute,";

                    my $NewDiffTime  = $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0;
                    my $PeriodFuture = 5;
                    my $PeriodPast   = 0;

                    # date data string
                    $Param{FeldNameString} = $LayoutObject->BuildDateSelection(
                        %Param,
                        Format               => 'DateInputFormatLong',
                        Prefix               => $RequestFields{Name} . '-' . $RequestFormListID,
                        YearPeriodPast       => $PeriodPast,
                        YearPeriodFuture     => $PeriodFuture,
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

                $Param{RequestFormIDs}
                    .= $RequestFields{Name} . '-' . $RequestFormListID . "Day,";
                $Param{RequestFormIDs}
                    .= $RequestFields{Name} . '-' . $RequestFormListID . "Month,";
                $Param{RequestFormIDs}
                    .= $RequestFields{Name} . '-' . $RequestFormListID . "Year,";

                my $NewDiffTime  = $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0;
                my $PeriodFuture = 5;
                my $PeriodPast   = 0;

                # date data string
                $Param{FeldNameString} = $LayoutObject->BuildDateSelection(
                    %Param,
                    Format                 => 'DateInputFormat',
                    Prefix                 => $RequestFields{Name} . '-' . $RequestFormListID,
                    YearPeriodPast         => $PeriodPast,
                    YearPeriodFuture       => $PeriodFuture,
                    DiffTime               => $NewDiffTime,
                    Class                  => $Param{Errors}->{DateInvalid},
                    Validate               => 1,
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

                $Param{RequestFormIDs}
                    .= $RequestFields{Name} . '-' . $RequestFormListID . "Day,";
                $Param{RequestFormIDs}
                    .= $RequestFields{Name} . '-' . $RequestFormListID . "Month,";
                $Param{RequestFormIDs}
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
                $RequestForm{Description} =~ s/\n/<br\/>/ig;
                $Param{Description} = $RequestForm{Description};
                $Param{FeldNameDescription} = 'Description-' . $RequestFormListID;
                $Param{RequestFormIDs} .= 'Description-' . $RequestFormListID . ",";
            }

            $Param{FeldNameHeadline} = 'Headline-' . $RequestFormListID;
            $Param{RequestFormIDs} .= 'Headline-' . $RequestFormListID . ",";

            $Param{Headline} = $RequestForm{Headline};
            $LayoutObject->Block(
                Name => 'OverviewListFelderHeadline',
                Data => {
                    %Param,
                },
            );
            $Param{Description} = '';
        }
    }

    # output overview result
    $LayoutObject->Block(
        Name => 'OverviewListFelderRequestFormIDs',
        Data => {
            %Param,
        },
    );

    my $ShowConfigItem = $ConfigObject->Get('Ticket::Frontend::ConfigItemZoomSearch');
    if ( $ShowConfigItem && $ShowConfigItem >= 1 ) {

        if ( $Request{ShowConfigItem} eq "1" ) {

            my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
            my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

            my $ClassList = $GeneralCatalogObject->ItemList(
                Class => 'ITSM::ConfigItem::Class',
                Valid => 1,
            );

            my $VersionID;
            my $CheckItem   = 0;
            my %ConfigItems = ();

            for my $Class ( %{$ClassList} ) {
                if ( $Class =~ /^\d+$/ ) {

                    my @ShowConfigItems = split( /,/, $Request{ShowConfigItems} );

                    for my $CheckIfClass ( @ShowConfigItems ) {
                        if ( $CheckIfClass == $Class ) {

                            # start search
                            my $SearchResultList = $ConfigItemObject->ConfigItemSearchExtended(
                                ClassIDs => [$Class],
                                What     => [
                                    {
                                        "[%]{'Version'}[%]{'Owner'}[%]{'Content'}" => $Self->{UserLogin},
                                    },
                                ],
                            );

                            $Param{Class} = ${$ClassList}{$Class};

                            for my $ConfigItemID ( @{$SearchResultList} ) {
        
                                my $VersionRef = $ConfigItemObject->VersionGet(
                                    ConfigItemID => $ConfigItemID,
                                );
                                if ( $VersionRef->{Name} ) {
                                    $CheckItem++;
                                    $ConfigItems{ $VersionRef->{ConfigItemID} } = $VersionRef->{Name};
                                }
                            }

                            #generate output
                            $Param{ConfigItemStrg} = $LayoutObject->BuildSelection(
                                Data         => \%ConfigItems,
                                Name         => 'ConfigItemID' . $Class,
                                PossibleNone => 1,
                                Multiple     => 1,
                                Size         => 5,
                                Class        => 'Modernize',
                                Translation  => 0,
                                Max          => 200,
                            );

                            if ( $CheckItem >= 1 ) {
                                $LayoutObject->Block(
                                    Name => 'ConfigItemClass',
                                    Data => {
                                        %Param,
                                    },
                                );
                            }
                        }
                    }
                }

                $CheckItem   = 0;
                %ConfigItems = ();
            }
        }
    }

    if ( $Config->{Queue} ) {

        # check own selection
        my %NewTos = ( '', '-' );
        my $Module = $ConfigObject->Get('CustomerPanel::NewTicketQueueSelectionModule')
            || 'Kernel::Output::HTML::CustomerNewTicket::QueueSelectionGeneric';
        if ( $Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
            my $Object = $Module->new(
                %{$Self},
                SystemAddress => $Kernel::OM->Get('Kernel::System::SystemAddress'),
                Debug         => $Self->{Debug},
            );

            # log loaded module
            if ( $Self->{Debug} && $Self->{Debug} > 1 ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'debug',
                    Message  => "Module: $Module loaded!",
                );
            }
            %NewTos = (
                $Object->Run(
                    Env       => $Self,
                    ACLParams => \%Param
                ),
                ( '', => '-' )
            );
        }
        else {
            return $LayoutObject->FatalError();
        }

        # build to string
        if (%NewTos) {
            for ( sort keys %NewTos ) {
                $NewTos{"$_||$NewTos{$_}"} = $NewTos{$_};
                delete $NewTos{$_};
            }
        }
        $Param{ToStrg} = $LayoutObject->AgentQueueListOption(
            Data       => \%NewTos,
            Multiple   => 0,
            Size       => 0,
            Name       => 'Dest',
            Class      => "Validate_Required Modernize " . $Param{Errors}->{QueueInvalid},
            SelectedID => $Param{ToSelected} || $Param{QueueID},
            TreeView   => $TreeView,
        );
        $LayoutObject->Block(
            Name => 'Queue',
            Data => {
                %Param,
                QueueInvalid => $Param{Errors}->{QueueInvalid},
            },
        );

    }

    # customer info string
    if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
        $Param{CustomerTable} = $LayoutObject->AgentCustomerViewTable(
            Data => $Param{CustomerData},
            Max  => $ConfigObject->Get('Ticket::Frontend::CustomerInfoComposeMaxSize'),
        );
        $LayoutObject->Block(
            Name => 'CustomerTable',
            Data => \%Param,
        );
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # From external
    my $ShowErrors = 1;
    if (
        defined $Param{FromExternalCustomer} &&
        defined $Param{FromExternalCustomer}->{Email} &&
        defined $Param{FromExternalCustomer}->{Customer}
        )
    {
        $ShowErrors = 0;
        $LayoutObject->AddJSData(
            Key   => 'FromExternalCustomerName',
            Value => $Param{FromExternalCustomer}->{Customer},
        );
        $LayoutObject->AddJSData(
            Key   => 'FromExternalCustomerEmail',
            Value => $Param{FromExternalCustomer}->{Email},
        );
    }
    my $CustomerCounter = 0;
    if ( $Param{MultipleCustomer} ) {
        for my $Item ( @{ $Param{MultipleCustomer} } ) {
            if ( !$ShowErrors ) {

                # set empty values for errors
                $Item->{CustomerError}    = '';
                $Item->{CustomerDisabled} = '';
                $Item->{CustomerErrorMsg} = 'CustomerGenericServerErrorMsg';
            }
            $LayoutObject->Block(
                Name => 'MultipleCustomer',
                Data => $Item,
            );
            $LayoutObject->Block(
                Name => $Item->{CustomerErrorMsg},
                Data => $Item,
            );
            if ( $Item->{CustomerError} ) {
                $LayoutObject->Block(
                    Name => 'CustomerErrorExplantion',
                );
            }
            $CustomerCounter++;
        }
    }

    if ( !$CustomerCounter ) {
        $Param{CustomerHiddenContainer} = 'Hidden';
    }

    # set customer counter
    $LayoutObject->Block(
        Name => 'MultipleCustomerCounter',
        Data => {
            CustomerCounter => $CustomerCounter++,
        },
    );

    if ( $Param{FromInvalid} && $Param{Errors} && !$Param{Errors}->{FromErrorType} ) {
        $LayoutObject->Block( Name => 'FromServerErrorMsg' );
    }
    if ( $Param{Errors}->{FromErrorType} || !$ShowErrors ) {
        $Param{FromInvalid} = '';
    }

    # get priority
    if ( $Config->{Priority} ) {
        my %Priorities = $TicketObject->TicketPriorityList(
            %Param,
            CustomerUserID => $Self->{UserID},
            Action         => $Self->{Action},
        );

        # build priority string
        my %PrioritySelected;
        if ( $Param{PriorityID} ) {
            $PrioritySelected{SelectedID} = $Param{PriorityID};
        }
        else {
            $PrioritySelected{SelectedValue} = $Config->{PriorityDefault} || '3 normal';
        }
        $Param{PriorityStrg} = $LayoutObject->BuildSelection(
            Data  => \%Priorities,
            Name  => 'PriorityID',
            Class => 'Modernize',
            %PrioritySelected,
        );
        $LayoutObject->Block(
            Name => 'Priority',
            Data => \%Param,
        );
    }

    # types
    if ( $ConfigObject->Get('Ticket::Type') && $Config->{'TicketType'} ) {
        my %Type = $TicketObject->TicketTypeList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );

        if ( $Config->{'TicketTypeDefault'} && !$Param{TypeID} ) {
            my %ReverseType = reverse %Type;
            $Param{TypeID} = $ReverseType{ $Config->{'TicketTypeDefault'} };
        }

        $Param{TypeStrg} = $LayoutObject->BuildSelection(
            Data         => \%Type,
            Name         => 'TypeID',
            SelectedID   => $Param{TypeID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
            Class => "Validate_Required Modernize " . ( $Param{Errors}->{TypeIDInvalid} || '' ),
        );
        $LayoutObject->Block(
            Name => 'TicketType',
            Data => {
                %Param,
                TypeIDInvalid => $Param{Errors}->{TypeIDInvalid},
                }
        );
    }

    # services
    if ( $ConfigObject->Get('Ticket::Service') && $Config->{Service} ) {
        my %Services;
        if ( $Param{QueueID} || $Param{TicketID} ) {
            %Services = $TicketObject->TicketServiceList(
                %Param,
                Action         => $Self->{Action},
                CustomerUserID => $Self->{UserID},
            );
        }

        if ( $Config->{ServiceMandatory} ) {
            $Param{ServiceStrg} = $LayoutObject->BuildSelection(
                Data       => \%Services,
                Name       => 'ServiceID',
                SelectedID => $Param{ServiceID},
                Class      => "Validate_Required Modernize "
                    . ( $Param{Errors}->{ServiceIDInvalid} || '' ),
                PossibleNone => 1,
                TreeView     => $TreeView,
                Sort         => 'TreeView',
                Translation  => 0,
                Max          => 200,
            );
            $LayoutObject->Block(
                Name => 'TicketServiceMandatory',
                Data => \%Param,
            );
        }
        else {
            $Param{ServiceStrg} = $LayoutObject->BuildSelection(
                Data         => \%Services,
                Name         => 'ServiceID',
                SelectedID   => $Param{ServiceID},
                Class        => 'Modernize',
                PossibleNone => 1,
                TreeView     => $TreeView,
                Sort         => 'TreeView',
                Translation  => 0,
                Max          => 200,
            );
            if ( %Services ) {
                $LayoutObject->Block(
                    Name => 'TicketService',
                    Data => \%Param,
                );
            }
        }

        # reset previous ServiceID to reset SLA-List if no service is selected
        if ( !$Services{ $Param{ServiceID} || '' } ) {
            $Param{ServiceID} = '';
        }
        my %SLA;
        if ( $Config->{SLA} ) {
            if ( $Param{ServiceID} ) {
                %SLA = $TicketObject->TicketSLAList(
                    %Param,
                    Action         => $Self->{Action},
                    CustomerUserID => $Self->{UserID},
                );
            }

            if ( $Config->{SLAMandatory} ) {
                $Param{SLAStrg} = $LayoutObject->BuildSelection(
                    Data       => \%SLA,
                    Name       => 'SLAID',
                    SelectedID => $Param{SLAID},
                    Class      => "Validate_Required Modernize "
                        . ( $Param{Errors}->{SLAIDInvalid} || '' ),
                    PossibleNone => 1,
                    Sort         => 'AlphanumericValue',
                    Translation  => 0,
                    Max          => 200,
                );
                $LayoutObject->Block(
                    Name => 'TicketSLAMandatory',
                    Data => \%Param,
                );
            }
            else {
                $Param{SLAStrg} = $LayoutObject->BuildSelection(
                    Data       => \%SLA,
                    Name       => 'SLAID',
                    SelectedID => $Param{SLAID},
                    Class        => 'Modernize',
                    PossibleNone => 1,
                    Sort         => 'AlphanumericValue',
                    Translation  => 0,
                    Max          => 200,
                );
                if ( %SLA ) {
                    $LayoutObject->Block(
                        Name => 'TicketSLA',
                        Data => \%Param,
                    );
                }
            }
        }
    }

    # prepare errors
    if ( $Param{Errors} ) {
        for ( sort keys %{ $Param{Errors} } ) {
            $Param{$_} = $Param{Errors}->{$_};
        }
    }

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # reduce the dynamic fields to only the ones that are designed for customer interface
    my @CustomerDynamicFields;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsCustomerInterfaceCapable
            = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsCustomerInterfaceCapable',
            );
        next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

        push @CustomerDynamicFields, $DynamicFieldConfig;
    }
    $DynamicField = \@CustomerDynamicFields;

    # Dynamic fields
    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # skip fields that HTML could not be retrieved
        next DYNAMICFIELD if !IsHashRefWithData(
            $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} }
        );

        # get the html strings form $Param
        my $DynamicFieldHTML = $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} };

        $LayoutObject->Block(
            Name => 'DynamicField',
            Data => {
                Name  => $DynamicFieldConfig->{Name},
                Label => $DynamicFieldHTML->{Label},
                Field => $DynamicFieldHTML->{Field},
            },
        );

        # example of dynamic fields order customization
        $LayoutObject->Block(
            Name => 'DynamicField_' . $DynamicFieldConfig->{Name},
            Data => {
                Name  => $DynamicFieldConfig->{Name},
                Label => $DynamicFieldHTML->{Label},
                Field => $DynamicFieldHTML->{Field},
            },
        );
    }

    if ( $Request{ShowAttachment} == 1 || !$Request{ShowAttachment} ) {
        $LayoutObject->Block(
            Name => 'ShowAttachment',
        );
    }

    # show customer edit link
    my $OptionCustomer = $LayoutObject->Permission(
        Action => 'AdminCustomerUser',
        Type   => 'rw',
    );

    my $ShownOptionsBlock;

    if ($OptionCustomer) {

        # check if need to call Options block
        if ( !$ShownOptionsBlock ) {
            $LayoutObject->Block(
                Name => 'TicketOptions',
                Data => {
                    %Param,
                },
            );

            # set flag to "true" in order to prevent calling the Options block again
            $ShownOptionsBlock = 1;
        }

        $LayoutObject->Block(
            Name => 'OptionCustomer',
            Data => {
                %Param,
            },
        );
    }

    # show attachments
    ATTACHMENT:
    for my $Attachment ( @{ $Param{Attachments} } ) {
        if (
            $Attachment->{ContentID}
            && $LayoutObject->{BrowserRichText}
            && ( $Attachment->{ContentType} =~ /image/i )
            && ( $Attachment->{Disposition} eq 'inline' )
            )
        {
            next ATTACHMENT;
        }
        $LayoutObject->Block(
            Name => 'Attachment',
            Data => $Attachment,
        );
    }

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

        $LayoutObject->Block(
            Name => 'RichText',
            Data => \%Param,
        );
    }

    # Permissions have been checked before in Run()
    if ( $Param{FromChatID} ) {
        my @ChatMessages = $Kernel::OM->Get('Kernel::System::Chat')->ChatMessageList(
            ChatID => $Param{FromChatID},
        );
        $LayoutObject->Block(
            Name => 'ChatArticlePreview',
            Data => {
                ChatMessages => \@ChatMessages,
            },
        );
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentTicketRequest',
        Data         => \%Param,
    );
}

sub _GetFieldsToUpdate {
    my ( $Self, %Param ) = @_;

    my @UpdatableFields;

    # set the fields that can be updatable via AJAXUpdate
    if ( !$Param{OnlyDynamicFields} ) {
        @UpdatableFields = qw( Dest ServiceID SLAID PriorityID );
    }

    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsACLReducible = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );
        next DYNAMICFIELD if !$IsACLReducible;

        push @UpdatableFields, 'DynamicField_' . $DynamicFieldConfig->{Name};
    }

    return \@UpdatableFields;
}

sub _SetBlockHTML {
    my ( $Self, %Param ) = @_;

    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RequestFormBlockObject = $Kernel::OM->Get('Kernel::System::RequestFormBlock');
    my $RequestFieldsObject    = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $RequestObject          = $Kernel::OM->Get('Kernel::System::Request');
    my $TicketRequestObject    = $Kernel::OM->Get('Kernel::System::TicketRequest');
    my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject            = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %GetParam                   = %{ $Param{GetParam} };
    my $TicketID                   = $Param{TicketID};
    my $TicketUserID               = $Param{UserID};
    my $CheckRequestFormID         = $Param{CheckRequestFormID};
    $GetParam{RequestID}           = $Param{RequestID};
    $GetParam{RequestFormBlockIDs} = $Param{RequestFormBlockIDs};

    if ( $GetParam{RequestFormBlockIDs} ) {
        my @RequestFormIDArray = split( /,/, $GetParam{RequestFormBlockIDs} );
        for my $NewValues (@RequestFormIDArray) {
            my @FeldCheck = split( /-/, $NewValues );
            if ( $FeldCheck[1] && ( $FeldCheck[1] !~ /[a-z]/ig ) ) {
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
                        && ( $GetParam{$NewValues} && $GetParam{$NewValues} ne 'Nein' )
                        )
                    {
                        $GetParam{$NewValues} = "Ja";
                    }
                    elsif ( !$GetParam{$NewValues} ) {
                        $GetParam{$NewValues} = "";
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

    my %CheckRequest = $RequestObject->RequestGet(
        RequestID => $GetParam{RequestID},
    );

    my $ArticleBody = '';

    if ( $GetParam{RequestFormBlockIDs} ) {

        $ArticleBody .= '<hr style="background:#000000;height:1px;" /><br/>';

        my @AntragIDArrayBlock = split( /,/, $GetParam{RequestFormBlockIDs} );
        my $DateStringBlock    = '';
        my $DateKeyBlock       = '';

        for my $NewValues (@AntragIDArrayBlock) {
            my @FeldCheck = split( /-/, $NewValues );
            my %RequestFields;
            if ( $FeldCheck[1] && $FeldCheck[1] !~ /[a-z]/ig ) {
                my %RequestForm = $RequestFormBlockObject->RequestFormBlockGet(
                    RequestFormID => $FeldCheck[1],
                );
                if ( $RequestForm{FeldID} ) {
                    %RequestFields = $RequestFieldsObject->RequestFieldsGet(
                        RequestFieldsID => $RequestForm{FeldID},
                    );
                }
                else {
                    $RequestFields{Labeling} = $RequestForm{Description};
                }
            }

            if (
                $FeldCheck[1]
                && ( $FeldCheck[1] !~ /[a-z]/ig && $FeldCheck[0] !~ /Headline/ && $FeldCheck[0] !~ /Description/  )
                )
            {
                if ( $RequestFields{Typ} eq "Multiselect" ) {
                    my @CheckMulti = split( /,/, $GetParam{$NewValues} );
                    my $NewAntragFeldInhalt = '';
                    for my $NewMulti (@CheckMulti) {
                        my $AntragFeldInhalt = $RequestFieldsObject->RequestFieldsWertLookup(
                            RequestFieldKey => $NewMulti,
                        );
                        $NewAntragFeldInhalt .= $AntragFeldInhalt . ', ';
                    }
                    my %CheckRequestForm = $RequestFormBlockObject->RequestFormBlockGet(
                        RequestFormID => $FeldCheck[1],
                    );
                    if ( $CheckRequestFormID == $CheckRequestForm{RequestFormID} ) {
                        $ArticleBody .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>' . $RequestFields{Labeling} . '</strong>:</div> <div style="display:block;float:left;padding:5px;">' . $NewAntragFeldInhalt . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID         => $TicketID,
                            RequestID         => $GetParam{RequestID},
                            FeldKey          => $FeldCheck[0],
                            FeldValue        => $NewAntragFeldInhalt,
                            FeldLabeling => $RequestFields{Labeling},
                            UserID           => $TicketUserID,
                        );
                    }
                }
                elsif ( $RequestFields{Typ} eq "Dropdown" ) {
                    my $AntragFeldInhalt = $RequestFieldsObject->RequestFieldsWertLookup(
                        RequestFieldKey => $GetParam{$NewValues},
                    );
                    my %CheckRequestForm = $RequestFormBlockObject->RequestFormBlockGet(
                        RequestFormID => $FeldCheck[1],
                    );
                    if ( $CheckRequestFormID == $CheckRequestForm{RequestFormID} ) {
                        $ArticleBody .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>' . $RequestFields{Labeling} . '</strong>:</div> <div style="display:block;float:left;padding:5px;">' . $AntragFeldInhalt . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID         => $TicketID,
                            RequestID         => $GetParam{RequestID},
                            FeldKey          => $FeldCheck[0],
                            FeldValue        => $AntragFeldInhalt,
                            FeldLabeling => $RequestFields{Labeling},
                            UserID           => $TicketUserID,
                        );
                    }
                }
                else {
                    my %CheckRequestForm = $RequestFormBlockObject->RequestFormBlockGet(
                        RequestFormID => $FeldCheck[1],
                    );
                    if ( $CheckRequestFormID == $CheckRequestForm{RequestFormID} ) {
                        if ( $RequestFields{Typ} eq 'TextArea' ) {
                             $GetParam{$NewValues} = $LayoutObject->Ascii2RichText( String => $GetParam{$NewValues} );
                        }
                        $ArticleBody .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>' . $RequestFields{Labeling} . '</strong>:</div> <div style="display:block;float:left;padding:5px;">' . $GetParam{$NewValues} . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID         => $TicketID,
                            RequestID         => $GetParam{RequestID},
                            FeldKey          => $FeldCheck[0],
                            FeldValue        => $GetParam{$NewValues},
                            FeldLabeling => $RequestFields{Labeling},
                            UserID           => $TicketUserID,
                        );
                    }
                }
            }
            elsif ( $FeldCheck[0] =~ /Headline/ ) {

                $ArticleBody .= '<div style="width:97%;display:block;padding:5px;">' . $GetParam{$NewValues} . '</div>';
                my $Success = $TicketRequestObject->TicketRequestAdd(
                    TicketID     => $TicketID,
                    RequestID    => $GetParam{RequestID},
                    FeldKey      => $FeldCheck[0],
                    FeldValue    => $GetParam{$NewValues},
                    FeldLabeling => $GetParam{$NewValues},
                    UserID       => 1,
                );
            }
            else {

                $DateKeyBlock = $FeldCheck[0];
                if ( $NewValues =~ /Day/ig ) {
                    $DateStringBlock .= $GetParam{$NewValues};
                }
                if ( $NewValues =~ /Month/ig ) {
                    $DateStringBlock .= "." . $GetParam{$NewValues};
                }
                if ( $NewValues =~ /Year/ig ) {
                    $DateStringBlock .= "." . $GetParam{$NewValues};
                }

                if ( $NewValues =~ /Hour/ig ) {
                    $DateStringBlock .= " " . $GetParam{$NewValues};
                }
                if ( $NewValues =~ /Minute/ig ) {
                    $DateStringBlock .= ":" . $GetParam{$NewValues};
                    $FeldCheck[1] =~ s/Minute//ig;
                    my %RequestForm = $RequestFormBlockObject->RequestFormBlockGet(
                        RequestFormID => $FeldCheck[1],
                    );
                    %RequestFields = $RequestFieldsObject->RequestFieldsGet(
                        RequestFieldsID => $RequestForm{FeldID},
                    );
                    if ( $CheckRequestFormID == $RequestForm{RequestFormID} ) {
                        $ArticleBody .= '<div style="width:150px;display:block;float:left;padding:5px;"><strong>' . $RequestFields{Labeling} . '</strong>:</div> <div style="display:block;float:left;padding:5px;">' . $DateStringBlock . '<br></div><div style="clear:left;"></div>';
                        my $Success = $TicketRequestObject->TicketRequestAdd(
                            TicketID         => $TicketID,
                            RequestID         => $GetParam{RequestID},
                            FeldKey          => $DateKeyBlock,
                            FeldValue        => $DateStringBlock,
                            FeldLabeling => $RequestFields{Labeling},
                            UserID           => $TicketUserID,
                        );
                    }
                    $DateStringBlock = '';
                    $DateKeyBlock    = '';
                }
            }
        }

        $ArticleBody .= '<br/><hr style="background:#000000;height:1px;" />';
    }

    return $ArticleBody;
}

sub _MaskNewNoValid {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentTicketRequestNoValid',
        Data         => \%Param,
    );
}

1;
