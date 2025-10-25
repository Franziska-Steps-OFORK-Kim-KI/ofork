# --
# Kernel/Modules/AgentProcessTicket.pm - to handle process tickets
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AgentProcessTicket.pm,v 1.74 2016/12/13 14:38:03 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentProcessTicket;

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

    # get params
    my %GetParam;
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    for my $Key (
        qw( Subject Body PriorityID TypeID ServiceID SLAID Expand FromChatID ID FromTicketID )
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    # ACL compatibility translation
    my %ACLCompatGetParam;
    $ACLCompatGetParam{OwnerID} = $GetParam{NewUserID};

    # MultipleCustomer From-field
    my @MultipleCustomer;
    my $CustomersNumber = $ParamObject->GetParam( Param => 'CustomerTicketCounterFromCustomer' ) || 0;
    my $Selected = $ParamObject->GetParam( Param => 'CustomerSelected' ) || '';

    # hash for check duplicated entries
    my %AddressesList;

    # get object
    my $CheckItemObject           = $Kernel::OM->Get('Kernel::System::CheckItem');
    my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $BackendObject             = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $TypeObject                = $Kernel::OM->Get('Kernel::System::Type');
    my $TimeObject                = $Kernel::OM->Get('Kernel::System::Time');
    my $LinkObject                = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $GroupObject               = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject                = $Kernel::OM->Get('Kernel::System::User');
    my $CustomerUserObject        = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $SendmailObject            = $Kernel::OM->Get('Kernel::System::Email');
    my $QueueObject               = $Kernel::OM->Get('Kernel::System::Queue');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ProcessesObject           = $Kernel::OM->Get('Kernel::System::Processes');
    my $UploadCacheObject         = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    my $IfNoValid = 0;

    my %ProcessData = $ProcessesObject->ProcessGet(
        ID => $GetParam{ID},
    );

    if ( !$GetParam{Subject} ) {
        $GetParam{Subject} = $ProcessData{Name};
    }

    if ( !$GetParam{Body} ) {
        $GetParam{Body} = $ProcessData{Description};
    }

    my %CustomerData;

    # get Dynamic fields from ParamObject
    my %DynamicFieldValues;

    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

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

        my %Ticket;
        if ( $Self->{TicketID} ) {
            %Ticket = $TicketObject->TicketGet( TicketID => $Self->{TicketID} );
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # if there is no ticket id!
        if ( $Self->{TicketID} && $Self->{Subaction} eq 'Created' ) {

            # notify info
            $Output .= $LayoutObject->Notify(
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'Ticket "%s" created!',
                    $Ticket{TicketNumber},
                ),
                Link => $LayoutObject->{Baselink}
                    . 'Action=AgentTicketZoom;TicketID='
                    . $Ticket{TicketID},
            );
        }

        # store last queue screen
        if (
            $Self->{LastScreenOverview}
            && $Self->{LastScreenOverview} !~ /Action=AgentTicketPhone/
            && $Self->{RequestedURL} !~ /Action=AgentTicketPhone.*LinkTicketID=/
            )
        {
            $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
                SessionID => $Self->{SessionID},
                Key       => 'LastScreenOverview',
                Value     => $Self->{RequestedURL},
            );
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

            # Strip out external content if BlockLoadingRemoteContent is enabled.
            if ( $ConfigObject->Get('Ticket::Frontend::BlockLoadingRemoteContent') ) {
                my %SafetyCheckResult = $Kernel::OM->Get('Kernel::System::HTMLUtils')->Safety(
                    String       => $Article{Body},
                    NoExtSrcLoad => 1,
                );
                $Article{Body} = $SafetyCheckResult{String};
            }

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

        # get user preferences
        my %UserPreferences = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
            UserID => $Self->{UserID},
        );

        # store the dynamic fields default values or used specific default values to be used as
        # ACLs info for all fields
        my %DynamicFieldDefaults;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if !IsHashRefWithData( $DynamicFieldConfig->{Config} );
            next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

            # get default value from dynamic field config (if any)
            my $DefaultValue = $DynamicFieldConfig->{Config}->{DefaultValue} || '';

            # override the value from user preferences if is set
            if ( $UserPreferences{ 'UserDynamicField_' . $DynamicFieldConfig->{Name} } ) {
                $DefaultValue = $UserPreferences{ 'UserDynamicField_' . $DynamicFieldConfig->{Name} };
            }

            next DYNAMICFIELD if $DefaultValue eq '';
            next DYNAMICFIELD if ref $DefaultValue eq 'ARRAY' && !IsArrayRefWithData($DefaultValue);

            $DynamicFieldDefaults{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $DefaultValue;
        }
        $GetParam{DynamicField} = \%DynamicFieldDefaults;

        # create html strings for all dynamic fields
        my %DynamicFieldHTML;

        my %SplitTicketParam;

        # in case of split a TicketID and ArticleID are always given, send the TicketID to calculate
        # ACLs based on parent information
        if ( $Self->{TicketID} && $Article{ArticleID} ) {
            $SplitTicketParam{TicketID} = $Self->{TicketID};
        }

        # fix to bug# 8068 Field & DynamicField preselection on TicketSplit
        # when splitting a ticket the selected attributes must remain in the new ticket screen
        # this information will be available in the SplitTicketParam hash
        if ( $SplitTicketParam{TicketID} ) {

            # Get information from original ticket (SplitTicket).
            my %SplitTicketData = $TicketObject->TicketGet(
                TicketID      => $SplitTicketParam{TicketID},
                DynamicFields => 1,
                UserID        => $Self->{UserID},
            );

            # set simple IDs to pass them to the mask
            for my $SplitedParam (qw(TypeID ServiceID SLAID PriorityID)) {
                $SplitTicketParam{$SplitedParam} = $SplitTicketData{$SplitedParam};
            }

            # set StateID as NextStateID
            $SplitTicketParam{NextStateID} = $SplitTicketData{StateID};

            # set Owner and Responsible
            $SplitTicketParam{UserSelected}            = $SplitTicketData{OwnerID};
            $SplitTicketParam{ResponsibleUserSelected} = $SplitTicketData{ResponsibleID};

            # set additional information needed for Owner and Responsible
            if ( $SplitTicketData{QueueID} ) {
                $SplitTicketParam{QueueID} = $SplitTicketData{QueueID};
            }
            $SplitTicketParam{AllUsers} = 1;

            # set the selected queue in format ID||Name
            $SplitTicketParam{ToSelected} = $SplitTicketData{QueueID} . '||' . $SplitTicketData{Queue};

            for my $Key ( sort keys %SplitTicketData ) {
                if ( $Key =~ /DynamicField\_(.*)/ ) {
                    $SplitTicketParam{DynamicField}{$1} = $SplitTicketData{$Key};
                    delete $SplitTicketParam{$Key};
                }
            }
        }

        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $PossibleValuesFilter;

            my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );

            if ($IsACLReducible) {

                # get PossibleValues
                my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
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
                        %SplitTicketParam,
                        Action        => $Self->{Action},
                        ReturnType    => 'Ticket',
                        ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
                        Data          => \%AclData,
                        UserID        => $Self->{UserID},
                    );
                    if ($ACL) {
                        my %Filter = $TicketObject->TicketAclData();

                        # convert Filer key => key back to key => value using map
                        %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                            keys %Filter;
                    }
                }
            }

            # to store dynamic field value from database (or undefined)
            my $Value;

            # in case of split a TicketID and ArticleID are always given, Get the value
            # from DB this cases
            if ( $Self->{TicketID} && $Article{ArticleID} ) {

                # select TicketID or ArticleID to get the value depending on dynamic field configuration
                my $ObjectID = $DynamicFieldConfig->{ObjectType} eq 'Ticket'
                    ? $Self->{TicketID}
                    : $Article{ArticleID};

                # get value stored on the database (split)
                $Value = $DynamicFieldBackendObject->ValueGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $ObjectID,
                );
            }

            # otherwise (on a new ticket). Check if the user has a user specific default value for
            # the dynamic field, otherwise will use Dynamic Field default value
            else {

                # override the value from user preferences if is set
                if ( $UserPreferences{ 'UserDynamicField_' . $DynamicFieldConfig->{Name} } ) {
                    $Value = $UserPreferences{ 'UserDynamicField_' . $DynamicFieldConfig->{Name} };
                }
            }

            # get field html
            $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldRender(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $PossibleValuesFilter,
                Value                => $Value,
                LayoutObject         => $LayoutObject,
                ParamObject          => $ParamObject,
                AJAXUpdate           => 1,
                UpdatableFields      => $Self->_GetFieldsToUpdate(),
                Mandatory            => $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
            );
        }

        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

        # get and format default subject and body
        my $Subject = $Article{Subject};
        if ( !$Subject ) {
            $Subject = $LayoutObject->Output(
                Template => $Config->{Subject} || '',
            );
        }
        my $Body = $Article{Body} || '';
        if ( !$Body ) {
            $Body = $LayoutObject->Output(
                Template => $Config->{Body} || '',
            );
        }

        # make sure body is rich text (if body is based on config)
        if ( !$GetParam{ArticleID} && $LayoutObject->{BrowserRichText} ) {
            $Body = $LayoutObject->Ascii2RichText(
                String => $Body,
            );
        }

        # in case of ticket split set $Self->{QueueID} as the QueueID of the original ticket,
        # in order to set correct ACLs on page load (initial). See bug 8687.
        if (
            IsHashRefWithData( \%SplitTicketParam )
            && $SplitTicketParam{QueueID}
            && !$Self->{QueueID}
            )
        {
            $Self->{QueueID} = $SplitTicketParam{QueueID};
        }

        # Get predefined QueueID (if no queue from split ticket is set).
        if ( !$Self->{QueueID} && $GetParam{Dest} ) {

            my @QueueParts = split( /\|\|/, $GetParam{Dest} );
            $Self->{QueueID} = $QueueParts[0];
            $SplitTicketParam{ToSelected} = $GetParam{Dest};
        }

        # html output
        my $Services = $Self->_GetServices(
            %GetParam,
            %ACLCompatGetParam,
            %SplitTicketParam,
            CustomerUserID => $CustomerData{UserLogin} || '',
            QueueID        => $Self->{QueueID}         || 1,
        );
        my $SLAs = $Self->_GetSLAs(
            %GetParam,
            %ACLCompatGetParam,
            %SplitTicketParam,
            CustomerUserID => $CustomerData{UserLogin} || '',
            QueueID        => $Self->{QueueID}         || 1,
            Services       => $Services,
        );
        $Output .= $Self->_MaskNew(
            QueueID    => $Self->{QueueID},
            NextStates => $Self->_GetNextStates(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                CustomerUserID => $CustomerData{UserLogin} || '',
                QueueID        => $Self->{QueueID}         || 1,
            ),
            Priorities => $Self->_GetPriorities(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                CustomerUserID => $CustomerData{UserLogin} || '',
                QueueID        => $Self->{QueueID}         || 1,
            ),
            Types => $Self->_GetTypes(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                CustomerUserID => $CustomerData{UserLogin} || '',
                QueueID        => $Self->{QueueID}         || 1,
            ),
            Services          => $Services,
            SLAs              => $SLAs,
            StandardTemplates => $Self->_GetStandardTemplates(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                QueueID => $Self->{QueueID} || '',
            ),
            Users => $Self->_GetUsers(
                %GetParam,
                %ACLCompatGetParam,
                QueueID => $Self->{QueueID},
                %SplitTicketParam,
            ),
            ResponsibleUsers => $Self->_GetResponsibles(
                %GetParam,
                %ACLCompatGetParam,
                QueueID => $Self->{QueueID},
                %SplitTicketParam,
            ),
            To => $Self->_GetTos(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                CustomerUserID => $CustomerData{UserLogin} || '',
                QueueID => $Self->{QueueID},
            ),
            TimeUnits => $Self->_GetTimeUnits(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                ArticleID => $Article{ArticleID},
            ),
            From         => $Article{From},
            Subject      => $Subject,
            Body         => $Body,
            CustomerUser => $SplitTicketData{CustomerUserID},
            CustomerID   => $SplitTicketData{CustomerID},
            CustomerData => \%CustomerData,
            Attachments  => \@Attachments,
            LinkTicketID => $GetParam{LinkTicketID} || '',
            FromChatID   => $GetParam{FromChatID} || '',
            ID           => $GetParam{ID},
            %SplitTicketParam,
            DynamicFieldHTML => \%DynamicFieldHTML,
            MultipleCustomer => \@MultipleCustomer,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'StoreNew' ) {

        my $Queue = $QueueObject->QueueLookup( QueueID => $ProcessData{QueueID} );
        my $Dest = $Queue;

        my %Error;
        my %StateData;
        if ( $GetParam{NextStateID} ) {
            %StateData = $Kernel::OM->Get('Kernel::System::State')->StateGet(
                ID => $GetParam{NextStateID},
            );
        }
        my $NextState = $StateData{Name} || '';

        # see if only a name has been passed
        if ( $Dest && $Dest !~ m{ \A (\d+)? \| \| .+ \z }xms ) {

            # see if we can get an ID for this queue name
            my $DestID = $QueueObject->QueueLookup(
                Queue => $Dest,
            );

            if ($DestID) {
                $Dest = $DestID . '||' . $Dest;
            }
            else {
                $Dest = '';
            }
        }

        my ( $NewQueueID, $To ) = split( /\|\|/, $Dest );
        $GetParam{QueueID} = $NewQueueID;

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

        if (%Error) {

            # html output
            my $Output .= $LayoutObject->Header();
            $Output    .= $LayoutObject->NavigationBar();
            $Output    .= $Self->_MaskNew(
                Attachments => \@Attachments,
                %GetParam,
                ToSelected       => $Dest,
                QueueID          => $NewQueueID,
                DynamicFieldHTML => \%DynamicFieldHTML,
                Errors           => \%Error,
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

        # create new ticket, do db insert
        my $TicketID = $TicketObject->TicketCreate(
            QueueID      => $NewQueueID,
            TypeID       => $GetParam{TypeID},
            ServiceID    => $GetParam{ServiceID},
            SLAID        => $GetParam{SLAID},
            Title        => $GetParam{Subject},
            PriorityID   => 3,
            Lock         => 'unlock',
            State        => $Config->{StateDefault},
            CustomerNo   => $CustomerID,
            CustomerUser => $SelectedCustomerUser,
            OwnerID      => $Self->{UserID},
            UserID       => $Self->{UserID},
        );

        if ( $GetParam{FromTicketID} ) {

            # link the tickets
            $Kernel::OM->Get('Kernel::System::LinkObject')->LinkAdd(
                SourceObject => 'Ticket',
                SourceKey    => $TicketID,
                TargetObject => 'Ticket',
                TargetKey    => $GetParam{FromTicketID},
                Type         => 'Normal',
                State        => 'Valid',
                UserID       => 1,
            );
        }

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
            ID => $GetParam{ID},
        );
        my $NewID = $TicketProcessesObject->ProcessAdd(
            Name         => $ProcessDataTransver{Name},
            Description  => $ProcessDataTransver{Description},
            QueueID      => $ProcessDataTransver{QueueID},
            SetArticleID => $ProcessDataTransver{SetArticleIDProcess},
            ValidID      => $ProcessDataTransver{ValidID},
            UserID       => $Self->{UserID},
            TicketID     => $TicketID,
        );

        my %ProcessStepList = $ProcessStepObject->StepList(
            Valid => 1,
            ProcessID => $GetParam{ID},
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

            if ( $ProcessStepData{ProcessID} == $GetParam{ID} ) {

                $ProcessStepValue ++;

                if ( $ProcessStepValue == 1 ) {

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
                        UserID              => $Self->{UserID},
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
                        ParallelStep        => $ProcessStepData{ParallelStep},
                        SetParallel         => $ProcessStepData{SetParallel},
                        NotifyAgent         => $ProcessStepData{NotifyAgent},
                        StepActive          => $StepActive,
                        SetParallel         => $ProcessStepData{SetParallel},
                        TicketID            => $TicketID,
                        UserID              => $Self->{UserID},
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
                    ProcessID     => $GetParam{ID},
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
                        UserID        => $Self->{UserID},
                        TicketID      => $TicketID,
                    );
                }

                my %DynamicProcessFieldList = $DynamicProcessFieldsObject->DynamicProcessFieldList(
                    ProcessID     => $GetParam{ID},
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
                        UserID         => $Self->{UserID},
                        Required       => $DynamicStepField{Required},
                        TicketID       => $TicketID,
                    );
                }

                my %ProcessConditionsList = $ProcessDynamicConditionsObject->ProcessDynamicConditionsList(
                    ProcessID     => $GetParam{ID},
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
                        UserID         => $Self->{UserID},
                    );
                }

                my %ProcessConditionsListTwo = $ProcessConditionsObject->ProcessConditionsAllList(
                    ProcessID     => $GetParam{ID},
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
                        UserID        => $Self->{UserID},
                        TicketID      => $TicketID,
                    );
                }
 
                 my %ProcessTransitionList = $ProcessTransitionObject->ProcessTransitionAllList(
                    ProcessID     => $GetParam{ID},
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
                        UserID        => $Self->{UserID},
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

        if ($TicketID) {

            my $ShowConfigItem = $ConfigObject->Get('Ticket::Frontend::ConfigItemZoomSearch');
            if ( $ShowConfigItem && $ShowConfigItem >= 1 ) {

                if ( $ProcessData{ShowConfigItem} eq "1" ) {

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

        my $From      = "$Self->{UserFirstname} $Self->{UserLastname} <$Self->{UserEmail}>";
        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            TicketID         => $TicketID,
            SenderType       => 'customer',
            From             => $From,
            To               => $To,
            Subject          => $GetParam{Subject},
            Body             => $GetParam{Body},
            MimeType         => $MimeType,
            Charset          => $LayoutObject->{UserCharset},
            UserID           => 1,
            IsVisibleForCustomer => 1,
            HistoryType      => 'NewTicket',
            HistoryComment       => 'New process ticket' || '%%',
            AutoResponseType => ( $ConfigObject->Get('AutoResponseForWebTickets') )
            ? 'auto reply'
            : '',
            OrigHeader => {
                From    => $From,
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

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check own selection
    my %NewTos;
    if ( $ConfigObject->Get('Ticket::Frontend::NewQueueOwnSelection') ) {
        %NewTos = %{ $ConfigObject->Get('Ticket::Frontend::NewQueueOwnSelection') };
    }
    else {

        # SelectionType Queue or SystemAddress?
        my %Tos;
        if ( $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') eq 'Queue' ) {
            %Tos = $Kernel::OM->Get('Kernel::System::Ticket')->MoveList(
                %Param,
                Type    => 'create',
                Action  => $Self->{Action},
                QueueID => $Self->{QueueID},
                UserID  => $Self->{UserID},
            );
        }
        else {
            %Tos = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressQueueList();
        }

        # get create permission queues
        my %UserGroups = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
            UserID => $Self->{UserID},
            Type   => 'create',
        );

        my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
        my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');

        # build selection string
        QUEUEID:
        for my $QueueID ( sort keys %Tos ) {

            my %QueueData = $QueueObject->QueueGet( ID => $QueueID );

            # permission check, can we create new tickets in queue
            next QUEUEID if !$UserGroups{ $QueueData{GroupID} };

            my $String = $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionString')
                || '<Realname> <<Email>> - Queue: <Queue>';
            $String =~ s/<Queue>/$QueueData{Name}/g;
            $String =~ s/<QueueComment>/$QueueData{Comment}/g;

            # remove trailing spaces
            if ( !$QueueData{Comment} ) {
                $String =~ s{\s+\z}{};
            }

            if ( $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') ne 'Queue' ) {
                my %SystemAddressData = $SystemAddressObject->SystemAddressGet(
                    ID => $Tos{$QueueID},
                );
                $String =~ s/<Realname>/$SystemAddressData{Realname}/g;
                $String =~ s/<Email>/$SystemAddressData{Name}/g;
            }
            $NewTos{$QueueID} = $String;
        }
    }

    # add empty selection
    $NewTos{''} = '-';
    return \%NewTos;
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $TypeObject          = $Kernel::OM->Get('Kernel::System::Type');
    my $TimeObject          = $Kernel::OM->Get('Kernel::System::Time');
    my $LinkObject          = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
    my $CustomerUserObject  = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $SendmailObject      = $Kernel::OM->Get('Kernel::System::Email');
    my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');
    my $ProcessesObject     = $Kernel::OM->Get('Kernel::System::Processes');

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

    my %ProcessData = $ProcessesObject->ProcessGet(
        ID => $Param{ID},
    );
    
    $Param{Name} = $ProcessData{Name};

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

    $Param{NoBodydisplay}           = 'display:none';
    $Param{NoBodyAltdisplay}        = 'display:inline';
    $Param{"BodyValidate_Required"} = '';

    # output overview result
    $LayoutObject->Block(
        Name => 'OverviewFelderList',
        Data => {
            %Param,
        },
    );

    $LayoutObject->Block(
        Name => 'SubjectChangeable',
        Data => {
            %Param,
        },
    );

    if ( $Param{FromCustomerInvalid} ) {
        $LayoutObject->Block( Name => 'FromServerErrorMsg' );
    }


#    my $ShowConfigItem = $ConfigObject->Get('Ticket::Frontend::ConfigItemZoomSearch');
#    if ( $ShowConfigItem && $ShowConfigItem >= 1 ) {
#
#        if ( $Request{ShowConfigItem} eq "1" ) {
#
#            my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
#            my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
#
#            my $ClassList = $GeneralCatalogObject->ItemList(
#                Class => 'ITSM::ConfigItem::Class',
#                Valid => 1,
#            );
#
#            my $VersionID;
#            my $CheckItem   = 0;
#            my %ConfigItems = ();
#
#            for my $Class ( %{$ClassList} ) {
#                if ( $Class =~ /^\d+$/ ) {
#
#                    my @ShowConfigItems = split( /,/, $Request{ShowConfigItems} );
#
#                    for my $CheckIfClass ( @ShowConfigItems ) {
#                        if ( $CheckIfClass == $Class ) {
#
#                            # start search
#                            my $SearchResultList = $ConfigItemObject->ConfigItemSearchExtended(
#                                ClassIDs => [$Class],
#                                What     => [
#                                    {
#                                        "[%]{'Version'}[%]{'Owner'}[%]{'Content'}" => $Self->{UserLogin},
#                                    },
#                                ],
#                            );
#
#                            $Param{Class} = ${$ClassList}{$Class};
#
#                            for my $ConfigItemID ( @{$SearchResultList} ) {
#        
#                                my $VersionRef = $ConfigItemObject->VersionGet(
#                                    ConfigItemID => $ConfigItemID,
#                                );
#                                if ( $VersionRef->{Name} ) {
#                                    $CheckItem++;
#                                    $ConfigItems{ $VersionRef->{ConfigItemID} } = $VersionRef->{Name};
#                                }
#                            }
#
#                            #generate output
#                            $Param{ConfigItemStrg} = $LayoutObject->BuildSelection(
#                                Data         => \%ConfigItems,
#                                Name         => 'ConfigItemID' . $Class,
#                                PossibleNone => 1,
#                                Multiple     => 1,
#                                Size         => 5,
#                                Class        => 'Modernize',
#                                Translation  => 0,
#                                Max          => 200,
#                            );
#
#                            if ( $CheckItem >= 1 ) {
#                                $LayoutObject->Block(
#                                    Name => 'ConfigItemClass',
#                                    Data => {
#                                        %Param,
#                                    },
#                                );
#                            }
#                        }
#                    }
#                }
#
#                $CheckItem   = 0;
#                %ConfigItems = ();
#            }
#        }
#    }

    # build to string
    my %NewTo;
    if ( $Param{To} ) {
        for my $KeyTo ( sort keys %{ $Param{To} } ) {
            $NewTo{"$KeyTo||$Param{To}->{$KeyTo}"} = $Param{To}->{$KeyTo};
        }
    }
    if ( !$Param{ToSelected} ) {
        my $UserDefaultQueue = $ConfigObject->Get('Ticket::Frontend::UserDefaultQueue') || '';

        if ($UserDefaultQueue) {
            my $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( Queue => $UserDefaultQueue );
            if ($QueueID) {
                $Param{ToSelected} = "$QueueID||$UserDefaultQueue";
            }
        }
    }
    if ( $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') eq 'Queue' ) {
        $Param{ToStrg} = $LayoutObject->AgentQueueListOption(
            Class          => 'Validate_Required Modernize',
            Data           => \%NewTo,
            Multiple       => 0,
            Size           => 0,
            Name           => 'Dest',
            TreeView       => $TreeView,
            SelectedID     => $Param{ToSelected},
            OnChangeSubmit => 0,
        );
    }
    else {
        $Param{ToStrg} = $LayoutObject->BuildSelection(
            Class       => 'Validate_Required Modernize',
            Data        => \%NewTo,
            Name        => 'Dest',
            TreeView    => $TreeView,
            SelectedID  => $Param{ToSelected},
            Translation => 0,
        );
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

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

    $LayoutObject->Block(
        Name => 'ShowAttachment',
    );

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
        TemplateFile => 'AgentProcessTicket',
        Data         => \%Param,
    );
}

sub _GetNextStates {
    my ( $Self, %Param ) = @_;

    my %NextStates;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %NextStates = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
    return \%NextStates;
}

sub _GetUsers {
    my ( $Self, %Param ) = @_;

    # get users
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # just show only users with selected custom queue
    if ( $Param{QueueID} && !$Param{AllUsers} ) {
        my @UserIDs = $TicketObject->GetSubscribedUserIDsByQueueID(%Param);
        for my $KeyGroupMember ( sort keys %AllGroupsMembers ) {
            my $Hit = 0;
            for my $UID (@UserIDs) {
                if ( $UID eq $KeyGroupMember ) {
                    $Hit = 1;
                }
            }
            if ( !$Hit ) {
                delete $AllGroupsMembers{$KeyGroupMember};
            }
        }
    }

    # show all system users
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone') ) {
        %ShownUsers = %AllGroupsMembers;
    }

    # show all users who are owner or rw in the queue group
    elsif ( $Param{QueueID} ) {
        my $GID = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID( QueueID => $Param{QueueID} );
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'owner',
        );
        for my $KeyMember ( sort keys %MemberList ) {
            if ( $AllGroupsMembers{$KeyMember} ) {
                $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
            }
        }
    }

    # workflow
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Owner',
        Data          => \%ShownUsers,
        UserID        => $Self->{UserID},
    );

    return { $TicketObject->TicketAclData() } if $ACL;

    return \%ShownUsers;
}

sub _GetResponsibles {
    my ( $Self, %Param ) = @_;

    # get users
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # just show only users with selected custom queue
    if ( $Param{QueueID} && !$Param{AllUsers} ) {
        my @UserIDs = $TicketObject->GetSubscribedUserIDsByQueueID(%Param);
        for my $KeyGroupMember ( sort keys %AllGroupsMembers ) {
            my $Hit = 0;
            for my $UID (@UserIDs) {
                if ( $UID eq $KeyGroupMember ) {
                    $Hit = 1;
                }
            }
            if ( !$Hit ) {
                delete $AllGroupsMembers{$KeyGroupMember};
            }
        }
    }

    # show all system users
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone') ) {
        %ShownUsers = %AllGroupsMembers;
    }

    # show all users who are responsible or rw in the queue group
    elsif ( $Param{QueueID} ) {
        my $GID = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID( QueueID => $Param{QueueID} );
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'responsible',
        );
        for my $KeyMember ( sort keys %MemberList ) {
            if ( $AllGroupsMembers{$KeyMember} ) {
                $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
            }
        }
    }

    # workflow
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Responsible',
        Data          => \%ShownUsers,
        UserID        => $Self->{UserID},
    );

    return { $TicketObject->TicketAclData() } if $ACL;

    return \%ShownUsers;
}

sub _GetTimeUnits {
    my ( $Self, %Param ) = @_;

    my $AccountedTime = '';

    # Get accounted time if AccountTime config item is enabled.
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::AccountTime') && defined $Param{ArticleID} ) {
        $AccountedTime = $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleAccountedTimeGet(
            ArticleID => $Param{ArticleID},
        );
    }

    return $AccountedTime ? $AccountedTime : '';
}

sub _GetStandardTemplates {
    my ( $Self, %Param ) = @_;

    my %Templates;
    my $QueueID = $Param{QueueID} || '';

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');

    if ( !$QueueID ) {
        my $UserDefaultQueue = $ConfigObject->Get('Ticket::Frontend::UserDefaultQueue') || '';

        if ($UserDefaultQueue) {
            $QueueID = $QueueObject->QueueLookup( Queue => $UserDefaultQueue );
        }
    }

    # check needed
    return \%Templates if !$QueueID && !$Param{TicketID};

    if ( !$QueueID && $Param{TicketID} ) {

        # get QueueID from the ticket
        my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 0,
            UserID        => $Self->{UserID},
        );
        $QueueID = $Ticket{QueueID} || '';
    }

    # fetch all std. templates
    my %StandardTemplates = $QueueObject->QueueStandardTemplateMemberList(
        QueueID       => $QueueID,
        TemplateTypes => 1,
    );

    # return empty hash if there are no templates for this screen
    return \%Templates if !IsHashRefWithData( $StandardTemplates{Create} );

    # return just the templates for this screen
    return $StandardTemplates{Create};
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

1;
