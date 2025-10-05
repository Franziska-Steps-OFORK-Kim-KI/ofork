# --
# scripts/DBUpdateTo11/FixUserPreferenceKeys.pm
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: FixUserPreferenceKeys.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --

package scripts::DBUpdateTo11::FixUserPreferenceKeys;

use strict;
use warnings;

use parent qw(scripts::DBUpdateTo11::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
);

=head1 NAME

scripts::DBUpdateTo11::FixUserPreferenceKeys - Make sure that user preferences do not contain
any blacklisted keys.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $Verbose = $Param{CommandlineOptions}->{Verbose} || 0;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my %Blacklisted = (
            User => {
            UserID         => 1,
            UserLogin      => 1,
            UserPw         => 1,
            UserFirstname  => 1,
            UserLastname   => 1,
            UserFullname   => 1,
            UserTitle      => 1,
            ChangeTime     => 1,
            CreateTime     => 1,
            ValidID        => 1,
            'UserIsGroup%' => 1,
        },
        Customer => {
            UserID         => 1,
            UserLogin      => 1,
            UserPassword   => 1,
            UserFirstname  => 1,
            UserLastname   => 1,
            UserFullname   => 1,
            UserStreet     => 1,
            UserCity       => 1,
            UserZip        => 1,
            UserCountry    => 1,
            UserComment    => 1,
            UserCustomerID => 1,
            UserTitle      => 1,
            UserEmail      => 1,
            ChangeTime     => 1,
            ChangeBy       => 1,
            CreateTime     => 1,
            CreateBy       => 1,
            UserPhone      => 1,
            UserMobile     => 1,
            UserFax        => 1,
            UserMailString => 1,
            ValidID        => 1,
            'UserIsGroup%' => 1,
        },
    );

    my %Tables = (
        Customer => 'customer_preferences',
        User     => 'user_preferences',
    );
    my @AffectedTables;

    for my $UserType ( sort keys %Tables ) {
        my $Table  = $Tables{$UserType};
        my $Result = $Self->_BindSQLPreferenceKeys( $Blacklisted{$UserType} );
        my $SQL    = "SELECT COUNT(*) FROM $Table WHERE $Result->{BindSQL}";

        return if !$DBObject->Prepare(
            SQL  => $SQL,
            Bind => $Result->{BindArray},
        );

        while ( my @Row = $DBObject->FetchrowArray() ) {
            push @AffectedTables, $Table if $Row[0];
        }
    }

    if ( !@AffectedTables ) {
        print "         - Blacklisted keys not found in user preference tables.\n\n" if $Verbose;
        return 1;
    }

    for my $UserType ( sort keys %Tables ) {
        my $Table  = $Tables{$UserType};
        my $Result = $Self->_BindSQLPreferenceKeys( $Blacklisted{$UserType} );
        my $SQL    = "DELETE FROM $Table WHERE $Result->{BindSQL}";

        return if !$DBObject->Do(
            SQL  => $SQL,
            Bind => $Result->{BindArray},
        );
    }

    print "         - Cleaned up found blacklisted keys from user preference tables.\n\n" if $Verbose;

    return 1;
}

=begin Internal:

=cut

=head2 _BindSQLPreferenceKeys()

Helper method to build bind SQL string and array.

    my $Result = $Self->_BindSQLPreferenceKeys(
        Key1 => 1,
        Key2 => 1,
        Key3 => 1,
    );

Returns:

    $Result = {
        BindSQL   => 'preferences_key LIKE ? OR preferences_key LIKE ? OR preferences_key LIKE ?',
        BindArray =>  [
            \'Key1',
            \'Key2',
            \'Key3',
        ],
    };

=cut

sub _BindSQLPreferenceKeys {
    my ( $Self, $Keys ) = @_;

    my $BindSQL = '';
    my @Bind;

    my $Count = 0;
    for my $Key ( sort keys %{$Keys} ) {
        $BindSQL .= ' OR ' if $Count;
        $BindSQL .= 'preferences_key LIKE ?';
        push @Bind, \$Key;
        $Count++;
    }

    return {
        BindSQL   => $BindSQL,
        BindArray => \@Bind,
    };
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut