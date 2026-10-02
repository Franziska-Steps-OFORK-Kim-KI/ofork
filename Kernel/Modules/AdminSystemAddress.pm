# --
# Kernel/Modules/AdminSystemAddress.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: AdminSystemAddress.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminSystemAddress;

use strict;
use warnings;

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

    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject         = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');

    #create local object
    my $CheckItemObject = Kernel::System::CheckItem->new( %{$Self} );

    # ------------------------------------------------------------ #
    # check the mailbox of a system address for Exchange Online OAuth2 (AJAX)
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'OAuth2Check' ) {

        $LayoutObject->ChallengeTokenCheck();

        my $ID   = $ParamObject->GetParam( Param => 'ID' ) || '';
        my %Data = $ID ? $SystemAddressObject->SystemAddressGet( ID => $ID ) : ();

        my %Result = %Data
            ? $Kernel::OM->Get('Kernel::System::OAuth2::MicrosoftMailboxCheck')->MailboxCheck( Address => $Data{Name} )
            : ( Successful => 0, Checks => [ { Name => 'Address', Successful => 0, Message => 'System address not found.' } ] );

        my $LanguageObject = $LayoutObject->{LanguageObject};
        my @Checks         = map {
            {
                Name       => $_->{Name},
                Successful => $_->{Successful} ? 1 : 0,
                Message    => $LanguageObject->Translate( $_->{Message}, @{ $_->{MessageData} || [] } ),
            }
        } @{ $Result{Checks} || [] };

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $LayoutObject->JSONEncode(
                Data => {
                    Successful => $Result{Successful} ? 1 : 0,
                    Checks     => \@Checks,
                },
            ),
            Type    => 'inline',
            NoCache => 1,
        );
    }

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my %Data = $SystemAddressObject->SystemAddressGet(
            ID => $ID,
        );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Change',
            %Data,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSystemAddress',
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
        for my $Parameter (qw(ID Name Realname QueueID Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check needed data
        for my $Needed (qw(Name Realname QueueID ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # check email address
        if (
            $GetParam{Name}
            && !$CheckItemObject->CheckEmail( Address => $GetParam{Name} )
            )
        {
            $Errors{NameInvalid} = 'ServerError';
            $Errors{ErrorType}   = $CheckItemObject->CheckErrorType();
        }

        # check if a system address exist with this name
        my $NameExists = $SystemAddressObject->NameExistsCheck(
            Name => $GetParam{Name},
            ID   => $GetParam{ID}
        );
        if ($NameExists) {
            $Errors{NameInvalid} = 'ServerError';
            $Errors{ErrorType}   = 'AlreadyUsed';
        }

        # Check if system address is used by auto response.
        my $SystemAddressIsUsed = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressIsUsed(
            SystemAddressID => $GetParam{ID},
        );
        if ( $SystemAddressIsUsed && $GetParam{ValidID} > 1 ) {
            $Errors{ValidIDInvalid}      = 'ServerError';
            $Errors{SystemAddressIsUsed} = 1;
        }

        # if no errors occurred
        if ( !%Errors ) {

            # update email system address
            if (
                $SystemAddressObject->SystemAddressUpdate(
                    %GetParam,
                    UserID => $Self->{UserID},
                )
                )
            {
                # if the user would like to continue editing system e-mail address, just redirect to the edit screen
                # otherwise return to overview
                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                    && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                    )
                {
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Change;ID=$GetParam{ID}"
                    );
                }
                else {
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
                }
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action => 'Change',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSystemAddress',
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
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSystemAddress',
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
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Realname QueueID Comment ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check needed data
        for my $Needed (qw(Name Realname QueueID ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # check email address
        if (
            $GetParam{Name}
            && !$CheckItemObject->CheckEmail( Address => $GetParam{Name} )
            )
        {
            $Errors{NameInvalid} = 'ServerError';
            $Errors{ErrorType}   = $CheckItemObject->CheckErrorType();
        }

        # check if a system address exist with this name
        my $NameExists = $SystemAddressObject->NameExistsCheck(
            Name => $GetParam{Name},
        );
        if ($NameExists) {
            $Errors{NameInvalid} = 'ServerError';
            $Errors{ErrorType}   = 'AlreadyUsed';
        }

        # if no errors occurred
        if ( !%Errors ) {

            # add user
            my $AddressID = $SystemAddressObject->SystemAddressAdd(
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($AddressID) {
                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify(
                    Info => Translatable('System e-mail address added!'),
                );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminSystemAddress',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action => 'Add',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSystemAddress',
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
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminSystemAddress',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            %Param,
            OAuth2Active => $Self->_OAuth2Active(),
        },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # Get valid list.
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my %ValidList   = $ValidObject->ValidList();

    # If there is queue using this system address, disable invalid selection on edit screen.
    if ( $Param{Action} eq 'Change' ) {
        $Param{SystemAddressIsUsed} = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressIsUsed(
            SystemAddressID => $Param{ID},
        );
        if ( $Param{SystemAddressIsUsed} ) {
            my @ValidIDsList = $ValidObject->ValidIDsGet();
            %ValidList = map { $_ => $ValidList{$_} } @ValidIDsList;
        }
    }

    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );
    $Param{QueueOption} = $LayoutObject->AgentQueueListOption(
        Data           => { $Kernel::OM->Get('Kernel::System::Queue')->QueueList( Valid => 1 ), },
        Name           => 'QueueID',
        SelectedID     => $Param{QueueID},
        Class          => 'Modernize Validate_Required ' . ( $Param{Errors}->{'QueueIDInvalid'} || '' ),
        OnChangeSubmit => 0,
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    # Add the correct server error msg for the system email address.
    if ( $Param{Name} && $Param{Errors}->{ErrorType} ) {
        $LayoutObject->Block(
            Name => 'Email' . $Param{Errors}->{ErrorType} . 'ServerErrorMsg',
            Data => {},
        );
    }
    else {
        $LayoutObject->Block(
            Name => "RequiredFieldServerErrorMsg",
            Data => {},
        );
    }

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Output       = '';

    my $OAuth2Active = $Self->_OAuth2Active();

    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            %Param,
            OAuth2Active => $OAuth2Active,
        },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => {
            %Param,
            ColSpan => $OAuth2Active ? 7 : 6,
        },
    );
    if ($OAuth2Active) {
        $LayoutObject->Block( Name => 'OverviewResultOAuth2Header' );
    }

    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
    my %List                = $SystemAddressObject->SystemAddressList(
        Valid => 0,
    );

    # get valid list
    my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

    # get queue list
    my %QueueList = $Kernel::OM->Get('Kernel::System::Queue')->QueueList();

    for my $ListKey ( sort { $List{$a} cmp $List{$b} } keys %List ) {

        my %Data = $SystemAddressObject->SystemAddressGet( ID => $ListKey );
        $LayoutObject->Block(
            Name => 'OverviewResultRow',
            Data => {
                Valid => $ValidList{ $Data{ValidID} },
                Queue => $QueueList{ $Data{QueueID} },
                %Data,
            },
        );
        if ($OAuth2Active) {
            $LayoutObject->Block(
                Name => 'OverviewResultRowOAuth2',
                Data => \%Data,
            );
        }
    }
    return 1;
}

sub _OAuth2Active {
    my ( $Self, %Param ) = @_;

    my $SendmailModule = $Kernel::OM->Get('Kernel::Config')->Get('SendmailModule') // '';

    return $SendmailModule eq 'Kernel::System::Email::SMTPTLSOAuth2' ? 1 : 0;
}

1;
