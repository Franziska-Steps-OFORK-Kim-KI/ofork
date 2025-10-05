# --
# Kernel/Modules/AdminUserSignature.pm
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de/
# --
# $Id: AdminUserSignature.pm,v 1.1.1.1 2019/12/18 07:26:04 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminUserSignature;

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

    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');
    my $UserObject      = $Kernel::OM->Get('Kernel::System::User');

    my %VisibleType = ( UserLogin => 'User', Signature => 'Signature', );

    # set search limit
    my $SearchLimit = 20000;

    # ------------------------------------------------------------ #
    # allocate user
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'AllocateUser' ) {

        # get params
        $Param{UserLogin} = $ParamObject->GetParam( Param => 'UserLogin' );
        $Param{UserSearch} = $ParamObject->GetParam( Param => 'UserSearch' ) || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # get vip member
        my %SignatureMemberList = $SignatureObject->UserSignatureMemberList(
            UserLogin => $Param{UserLogin},
            Result    => 'HASH',
        );

        # List Vip.
        my %SignatureData = $SignatureObject->SignatureList(
            Valid => 1,
        );

        $Param{Name} = $UserObject->UserName( UserID => $Param{UserLogin} ) . " ($Param{UserLogin})";

        $Output .= $Self->_Change(
            ID              => $Param{UserLogin},
            Name            => $Param{Name},
            Data            => \%SignatureData,
            Selected        => \%SignatureMemberList,
            UserSearch      => $Param{UserSearch},
            SignatureSearch => $Param{SignatureSearch},
            SearchLimit     => $SearchLimit,
            Type            => 'User',
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # allocate Signature
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateSignature' ) {

        # get params
        $Param{SignatureID} = $ParamObject->GetParam( Param => "SignatureID" );
        $Param{UserSearch} = $ParamObject->GetParam( Param => "UserSearch" )
            || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # get vip
        my %Signature = $SignatureObject->SignatureGet(
            ID     => $Param{SignatureID},
            UserID => $Self->{UserID},
        );

        # get user member
        my %UserMemberList = $SignatureObject->UserSignatureMemberList(
            SignatureID  => $Param{SignatureID},
            Result       => 'HASH',
        );

        # search user
        my %UserList = $UserObject->UserSearch(
            Search => $Param{UserSearch},
        );

        my @UserKeyList = sort { $UserList{$a} cmp $UserList{$b} } keys %UserList;

        # set max count
        my $MaxCount = @UserKeyList;
        if ( $MaxCount > $SearchLimit ) {
            $MaxCount = $SearchLimit;
        }

        my %UserData;

        # output rows
        for my $Counter ( 1 .. $MaxCount ) {

            # get
            my %User = $UserObject->GetUserData(
                UserID => $UserKeyList[ $Counter - 1 ],
            );
            my $UserName = $UserObject->UserName(
                UserID => $UserKeyList[ $Counter - 1 ]
            );
            my $User = "$UserName <$User{UserEmail}> ($User{UserID})";
            $UserData{ $User{UserID} } = $User;
        }

        $Output .= $Self->_Change(
            ID          => $Param{SignatureID},
            Name        => $Signature{Name},
            ItemList    => \@UserKeyList,
            Data        => \%UserData,
            Selected    => \%UserMemberList,
            UserSearch  => $Param{UserSearch},
            SearchLimit => $SearchLimit,
            Type        => 'Signature',
            %Param,
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # allocate user save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateUserSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        $Param{UserLogin} = $ParamObject->GetParam( Param => 'ID' );

        $Param{UserSearch} = $ParamObject->GetParam( Param => 'UserSearch' )
            || '*';

        my @SignatureIDsSelected = $ParamObject->GetArray( Param => 'ItemsSelected' );
        my @SignatureIDsAll      = $ParamObject->GetArray( Param => 'ItemsAll' );

        # create hash with selected ids
        my %SignatureIDSelected = map { $_ => 1 } @SignatureIDsSelected;

        # check all used vip ids
        for my $SignatureID (@SignatureIDsAll) {
            my $Active = $SignatureIDSelected{$SignatureID} ? 1 : 0;

            # set user signature member
            $SignatureObject->UserSignatureMemberAdd(
                UserLogin   => $Param{UserLogin},
                SignatureID => $SignatureID,
                Active      => $Active,
                UserID      => $Self->{UserID},
            );
        }

        # redirect to overview
        return $LayoutObject->Redirect(
            OP =>
                "Action=$Self->{Action};UserSearch=$Param{UserSearch}"
        );
    }

    # ------------------------------------------------------------ #
    # allocate signature save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateSignatureSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        $Param{SignatureID} = $ParamObject->GetParam( Param => "ID" );

        $Param{UserSearch} = $ParamObject->GetParam( Param => 'UserSearch' )
            || '*';

        my @UserLoginsSelected
            = $ParamObject->GetArray( Param => 'ItemsSelected' );
        my @UserLoginsAll
            = $ParamObject->GetArray( Param => 'ItemsAll' );

        # create hash with selected users
        my %UserLoginsSelected;
        for my $UserLogin (@UserLoginsSelected) {
            $UserLoginsSelected{$UserLogin} = 1;
        }

        # check all used users
        for my $UserLogin (@UserLoginsAll) {
            my $Active = $UserLoginsSelected{$UserLogin} ? 1 : 0;

            # set customer user vip member
            $SignatureObject->UserSignatureMemberAdd(
                UserLogin   => $UserLogin,
                SignatureID => $Param{SignatureID},
                Active      => $Active,
                UserID      => $Self->{UserID},
            );
        }

        # redirect to overview
        return $LayoutObject->Redirect(
            OP =>
                "Action=$Self->{Action};UserSearch=$Param{UserSearch}"
        );
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        # get params
        $Param{UserSearch} = $ParamObject->GetParam( Param => 'UserSearch' )
            || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # search customer user
        my %UserList
            = $UserObject->UserSearch( Search => $Param{UserSearch}, );
        my @UserKeyList
            = sort { $UserList{$a} cmp $UserList{$b} } keys %UserList;

        # count results
        my $UserCount = @UserKeyList;

        # set max count
        my $MaxCustomerCount = $UserCount;

        if ( $MaxCustomerCount > $SearchLimit ) {
            $MaxCustomerCount = $SearchLimit;
        }

        # output rows
        my %UserRowParam;
        for my $Counter ( 1 .. $MaxCustomerCount ) {

            # set customer user row params
            if ( defined( $UserKeyList[ $Counter - 1 ] ) ) {

                # Get user details
                my %User = $UserObject->GetUserData(
                    UserID => $UserKeyList[ $Counter - 1 ]
                );
                my $UserName = $UserObject->UserName(
                    UserID => $UserKeyList[ $Counter - 1 ]
                );
                $UserRowParam{ $User{UserID} } = "$UserName <$User{UserEmail}> ($User{UserID})";
            }
        }

        my %SignatureData = $SignatureObject->SignatureList(
            Valid => 1,
        );

        $Output .= $Self->_Overview(
            UserCount     => $UserCount,
            UserKeyList   => \@UserKeyList,
            UserData      => \%UserRowParam,
            SignatureData => \%SignatureData,
            SearchLimit   => $SearchLimit,
            UserSearch    => $Param{UserSearch},
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _Change {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $SearchLimit = $Param{SearchLimit};
    my %Data        = %{ $Param{Data} };
    my $Type        = $Param{Type} || 'User';
    my $NeType      = $Type eq 'Signature' ? 'User' : 'Signature';
    my %VisibleType = ( User => 'User', Signature => 'Signature', );
    my %Subaction   = ( User => 'Change', Signature => 'SignatureEdit', );
    my %IDStrg      = ( User => 'ID', Signature => 'SignatureID', );

    my @ItemList = ();

    # overview
    $LayoutObject->Block( Name => 'Overview' );
    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block(
        Name => 'ActionOverview',
        Data => {
            UserSearch => $Param{UserSearch},
        },
    );

    if ( $NeType eq 'User' ) {
        @ItemList = @{ $Param{ItemList} };

        # output search block
        $LayoutObject->Block(
            Name => 'Search',
            Data => {
                %Param,
                UserSearch => $Param{UserSearch},
            },
        );
        $LayoutObject->Block(
            Name => 'SearchAllocateSignature',
            Data => {
                %Param,
                Subaction   => $Param{Subaction},
                SignatureID => $Param{SignatureID},
            },
        );
    }
    else {
        $LayoutObject->Block( Name => 'Filter' );
    }

    $LayoutObject->Block(
        Name => 'AllocateItem',
        Data => {
            ID              => $Param{ID},
            ActionHome      => 'Admin' . $Type,
            Type            => $Type,
            NeType          => $NeType,
            VisibleType     => $VisibleType{$Type},
            VisibleNeType   => $VisibleType{$NeType},
            SubactionHeader => $Subaction{$Type},
            IDHeaderStrg    => $IDStrg{$Type},
            %Param,
        },
    );

    $LayoutObject->Block( Name => "AllocateItemHeader$VisibleType{$NeType}" );

    if ( $NeType eq 'User' ) {

        # output count block
        if ( !@ItemList ) {
            $LayoutObject->Block(
                Name => 'AllocateItemCountLimit',
                Data => { ItemCount => 0 },
            );

            my $ColSpan = 2;

            $LayoutObject->Block(
                Name => 'NoDataFoundMsg',
                Data => {
                    ColSpan => $ColSpan,
                },
            );
        }
        elsif ( @ItemList > $SearchLimit ) {
            $LayoutObject->Block(
                Name => 'AllocateItemCountLimit',
                Data => { ItemCount => ">" . $SearchLimit },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'AllocateItemCount',
                Data => { ItemCount => scalar @ItemList },
            );
        }
    }

    # Vip sorting.
    my %SignatureData;
    if ( $NeType eq 'Signature' ) {
        %SignatureData = %Data;

        # add suffix for correct sorting
        for my $DataKey ( sort keys %Data ) {
            $Data{$DataKey} .= '::';
        }

    }

    # output rows
    for my $ID ( sort { uc( $Data{$a} ) cmp uc( $Data{$b} ) } keys %Data ) {

        # set checked
        my $Checked = $Param{Selected}->{$ID} ? "checked='checked'" : '';

        # Recover original Vip Name
        if ( $NeType eq 'Signature' ) {
            $Data{$ID} = $SignatureData{$ID};
        }

        # output row block
        $LayoutObject->Block(
            Name => 'AllocateItemRow',
            Data => {
                ActionNeHome => 'Admin' . $NeType,
                Name         => $Data{$ID},
                ID           => $ID,
                Checked      => $Checked,
                SubactionRow => $Subaction{$NeType},
                IDRowStrg    => $IDStrg{$NeType},

            },
        );
    }

    # generate output
    return $LayoutObject->Output(
        TemplateFile => 'AdminUserSignature',
        Data         => \%Param,
    );
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $UserCount     = $Param{UserCount};
    my @UserKeyList   = @{ $Param{UserKeyList} };
    my $SearchLimit   = $Param{SearchLimit};
    my %UserData      = %{ $Param{UserData} };
    my %SignatureData = %{ $Param{SignatureData} };

    $LayoutObject->Block( Name => 'Overview' );
    $LayoutObject->Block( Name => 'ActionList' );

    # output search block
    $LayoutObject->Block(
        Name => 'Search',
        Data => {
            %Param,
            UserSearch => $Param{UserSearch},
        },
    );

    # output filter
    $LayoutObject->Block( Name => 'Filter', );

    # output result block
    $LayoutObject->Block(
        Name => 'Result',
        Data => {
            %Param,
            UserCount => $UserCount,
        },
    );

    # output  user count block
    if ( !@UserKeyList ) {
        $$LayoutObject->Block(
            Name => 'ResultUserCountLimit',
            Data => { UserCount => 0 },
        );

        $LayoutObject->Block(
            Name => 'NoDataFoundMsgList',
        );
    }
    elsif ( @UserKeyList > $SearchLimit ) {
        $LayoutObject->Block(
            Name => 'ResultUserCountLimit',
            Data => { UserCount => ">" . $SearchLimit },
        );
    }
    else {
        $LayoutObject->Block(
            Name => 'ResultUserCount',
            Data => { UserCount => scalar @UserKeyList },
        );
    }

    for my $ID (
        sort { uc( $UserData{$a} ) cmp uc( $UserData{$b} ) }
        keys %UserData
        )
    {

        # output user row block
        $LayoutObject->Block(
            Name => 'ResultUserRow',
            Data => {
                %Param,
                ID   => $ID,
                Name => $UserData{$ID},
            },
        );
    }

    my %SignatureDataSort = %SignatureData;

    # add suffix for correct sorting
    for my $SignatureDataKey ( sort keys %SignatureDataSort ) {
        $SignatureDataSort{$SignatureDataKey} .= '::';
    }

    for my $ID (
        sort { uc( $SignatureDataSort{$a} ) cmp uc( $SignatureDataSort{$b} ) }
        keys %SignatureDataSort
        )
    {

        # output vip row block
        $LayoutObject->Block(
            Name => 'ResultSignatureRow',
            Data => {
                %Param,
                ID   => $ID,
                Name => $SignatureData{$ID},
            },
        );
    }

    # generate output
    return $LayoutObject->Output(
        TemplateFile => 'AdminUserSignature',
        Data         => \%Param,
    );
}
1;
