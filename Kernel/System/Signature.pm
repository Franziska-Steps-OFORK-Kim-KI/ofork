# --
# Kernel/System/Signature.pm
# Modified version of the work:
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Signature.pm,v 1.1.1.1 2019/12/18 07:26:04 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Signature;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::Signature - signature lib

=head1 DESCRIPTION

All signature functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 SignatureAdd()

add new signatures

    my $ID = $SignatureObject->SignatureAdd(
        Name        => 'New Signature',
        Text        => "--\nSome Signature Infos",
        ContentType => 'text/plain; charset=utf-8',
        Comment     => 'some comment',
        ValidID     => 1,
        UserID      => 123,
    );

=cut

sub SignatureAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Name Text ContentType ValidID UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO signature (name, text, content_type, comments, valid_id, '
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{Text}, \$Param{ContentType}, \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new signature id
    $DBObject->Prepare(
        SQL  => 'SELECT id FROM signature WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return $ID;
}

=head2 SignatureGet()

get signatures attributes

    my %Signature = $SignatureObject->SignatureGet(
        ID => 123,
    );

=cut

sub SignatureGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need ID!"
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, text, content_type, comments, valid_id, change_time, create_time '
            . ' FROM signature WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    my %Data;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Data = (
            ID          => $Data[0],
            Name        => $Data[1],
            Text        => $Data[2],
            ContentType => $Data[3] || 'text/plain',
            Comment     => $Data[4],
            ValidID     => $Data[5],
            ChangeTime  => $Data[6],
            CreateTime  => $Data[7],
        );
    }

    # no data found
    if ( !%Data ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "SignatureID '$Param{ID}' not found!"
        );
        return;
    }

    return %Data;
}

=head2 SignatureUpdate()

update signature attributes

    $SignatureObject->SignatureUpdate(
        ID          => 123,
        Name        => 'New Signature',
        Text        => "--\nSome Signature Infos",
        ContentType => 'text/plain; charset=utf-8',
        Comment     => 'some comment',
        ValidID     => 1,
        UserID      => 123,
    );

=cut

sub SignatureUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ID Name Text ContentType ValidID UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE signature SET name = ?, text = ?, content_type = ?, comments = ?, '
            . ' valid_id = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Text}, \$Param{ContentType}, \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    return 1;
}

=head2 SignatureList()

get signature list

    my %List = $SignatureObject->SignatureList(
        Valid => 0,  # optional, defaults to 1
    );

returns:

        %List = (
          '1' => 'Some Name' ( Filname ),
          '2' => 'Some Name' ( Filname ),
          '3' => 'Some Name' ( Filname ),
    );

=cut

sub SignatureList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} // 1;

    # create the valid list
    my $ValidIDs = join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # build SQL
    my $SQL = 'SELECT id, name FROM signature';

    # add WHERE statement in case Valid param is set to '1', for valid system address
    if ($Valid) {
        $SQL .= ' WHERE valid_id IN (' . $ValidIDs . ')';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get data from database
    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    # fetch the result
    my %SignatureList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SignatureList{ $Row[0] } = $Row[1];
    }

    return %SignatureList;
}

=item UserSignatureMemberList()

returns a list of user/signature members

    SignatureID: Signature id
    UserLogin: user login
    Result: HASH -> returns a hash of key => vip id, value => vip name
            Name -> returns an array of user names
            ID   -> returns an array of user ids

    Example (get signature of user):

    $SignatureObject->UserSignatureMemberList(
        UserLogin => 'Test',
        Result    => 'HASH',
    );

    Example (get user of signature):

    $SignatureObject->UserSignatureMemberList(
        SignatureID => $ID,
        Result      => 'HASH',
    );

=cut

sub UserSignatureMemberList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{Result} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Result!',
        );
        return;
    }

    # check more needed stuff
    if ( !$Param{SignatureID} && !$Param{UserLogin} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need SignatureID or UserLogin!',
        );
        return;
    }

    # db quote
    for ( sort keys %Param ) {
        $Param{$_} = $DBObject->Quote( $Param{$_} );
    }
    for (qw(SignatureID)) {
        $Param{$_} = $DBObject->Quote( $Param{$_}, 'Integer' );
    }

    # sql
    my %Data;
    my @Data;
    my $SQL = 'SELECT scu.signature_id, scu.user_login, s.name '
        . ' FROM '
        . ' signature_user scu, signature s'
        . ' WHERE s.id = scu.signature_id AND ';

    if ( $Param{SignatureID} ) {
        $SQL .= " scu.signature_id = $Param{SignatureID}";
    }
    elsif ( $Param{UserLogin} ) {
        $SQL .= " scu.user_login = '$Param{UserLogin}'";
    }

    $DBObject->Prepare( SQL => $SQL );

    while ( my @Row = $DBObject->FetchrowArray() ) {

        my $Value = '';
        if ( $Param{SignatureID} ) {
            $Data{ $Row[1] } = $Row[0];
            $Value = $Row[0];
        }
        else {
            $Data{ $Row[0] } = $Row[2];
        }
    }

    # return result
    if ( $Param{Result} eq 'HASH' ) {
        return %Data;
    }
    if ( $Param{Result} eq 'Name' ) {
        @Data = values %Data;
    }
    else {
        @Data = keys %Data;
    }
    return @Data;
}

=item UserSignatureMemberAdd()

to add a member to a signature

if 'Active' is 0, the user is removed from the signature

    $SignatureObject->UserSignatureMemberAdd(
        UserLogin   => 'Test1',
        SignatureID => 6,
        Active      => 1,
        UserID      => 123,
    );

=cut

sub UserSignatureMemberAdd {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    for my $Argument (qw(UserLogin SignatureID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # delete existing relation
    return if !$DBObject->Do(
        SQL => 'DELETE FROM signature_user WHERE user_login = ? AND signature_id = ?',
        Bind => [ \$Param{UserLogin}, \$Param{SignatureID} ],
    );

    # return if relation is not active
    if ( !$Param{Active} ) {
        return;
    }

    # insert new relation
    my $Success = $DBObject->Do(
        SQL => 'INSERT INTO signature_user '
            . '(user_login, signature_id, create_time, create_by) '
            . 'VALUES (?, ?, current_timestamp, ?)',
        Bind => [ \$Param{UserLogin}, \$Param{SignatureID}, \$Param{UserID} ]
    );

    return $Success;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
