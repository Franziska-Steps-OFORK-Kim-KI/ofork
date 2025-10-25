# --
# Kernel/System/RequestFields.pm - all service function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: RequestFields.pm,v 1.5 2016/11/20 19:30:55 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RequestFields;

use strict;
use warnings;

use base qw(Kernel::System::EventHandler);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SysConfig',
    'Kernel::System::Time',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::RequestFields - RequestFields lib

=head1 SYNOPSIS

All Antrag functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $RequestFieldsObject = $Kernel::OM->Get('Kernel::System::RequestFields');

    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item RequestFieldsList()

return a hash list of Antrag

    my %RequestFieldsList = $RequestFieldsObject->RequestFieldsList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub RequestFieldsList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 0;
    }

    if ( !$Param{Valid} ) {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, name, label, typ FROM request_fields ORDER BY typ ASC",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, name, label, typ FROM request_fields WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} ) ORDER BY typ ASC",
        );
    }

    # fetch the result
    my %RequestFieldsList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFieldsList{ $Row[0] } = $Row[3] . "-" . $Row[1];
    }

    return %RequestFieldsList;
}

=item RequestFieldsAdminList()

return a hash list of Antrag

    my %RequestFieldsList = $RequestFieldsObject->RequestFieldsAdminList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub RequestFieldsAdminList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 0;
    }

    if ( !$Param{Valid} ) {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, typ, label FROM request_fields ORDER BY typ",
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL => "SELECT id, typ, label FROM request_fields WHERE valid_id IN "
                . "( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} ) ORDER BY typ",
        );
    }

    # fetch the result
    my %RequestFieldsList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFieldsList{ $Row[0] } = "(" . $Row[1] . ") " . $Row[2];
    }

    return %RequestFieldsList;
}

=item RequestFieldsGet()

get Antrag attributes

    my %RequestFields = $RequestFieldsObject->RequestFieldsGet(
        RequestFieldsID => 123,
    );

=cut

sub RequestFieldsGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestFieldsID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need AntragID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, typ, name, label, defaultvalue, feld_rows, feld_cols, leer_wert, valid_id, create_time, create_by, change_time, change_by '
            . 'FROM request_fields WHERE id = ?',
        Bind => [ \$Param{RequestFieldsID} ],
    );
    my %RequestFields;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %RequestFields = (
            ID           => $Data[0],
            Typ          => $Data[1],
            Name         => $Data[2],
            Labeling     => $Data[3],
            Defaultvalue => $Data[4],
            Rows         => $Data[5],
            Cols         => $Data[6],
            LeerWert     => $Data[7],
            ValidID      => $Data[8],
            CreateTime   => $Data[9],
            CreateBy     => $Data[10],
            ChangeTime   => $Data[11],
            ChangeBy     => $Data[12],
        );
    }

    # return result
    return %RequestFields;
}

=item RequestFieldsUpdate()

update RequestFields

    my $AntragID = $RequestFieldsObject->RequestFieldsUpdate(
        ID           => 123,
        Name         => 'UserName',
        Labeling => 'Name',
        Defaultvalue => 'Herr',
        Rows         => 10,
        Cols         => 7,
        LeerWert     => 1,
        ValidID      => 1,
        UserID       => 123,
    );

=cut

sub RequestFieldsUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ID Name Labeling ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find existing service
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM request_fields WHERE name = ?',
        Bind  => [ \$Param{Name} ],
    );

    my $Exists;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{ID} ne $Row[0] ) {
            $Exists = 1;
        }
    }

    # add service to database
    if ($Exists) {
        return 'Exists';
    }

    if ( !$Param{Rows} ) {
        $Param{Rows} = 0;
    }
    if ( !$Param{Cols} ) {
        $Param{Cols} = 0;
    }
    if ( !$Param{LeerWert} ) {
        $Param{LeerWert} = 0;
    }

    # update
    return if !$DBObject->Do(
        SQL =>
            'UPDATE request_fields SET typ = ?, name = ?, label = ?, defaultvalue = ?, feld_rows = ?, feld_cols = ?, leer_wert = ?,'
            . ' valid_id = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Typ}, \$Param{Name}, \$Param{Labeling}, \$Param{Defaultvalue},
            \$Param{Rows},
            \$Param{Cols}, \$Param{LeerWert}, \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    return 1;
}

=item RequestFieldsAdd()

add RequestFields

    my $RequestFieldsID = $RequestFieldsObject->RequestFieldsAdd(
        Typ          => 'Text',
        Name         => 'UserName',
        Labeling     => 'Name',
        Defaultvalue => 'Herr',
        Rows         => 10,
        Cols         => 7,
        LeerWert     => 1,
        ValidID      => 1,
        UserID       => 123,
    );

=cut

sub RequestFieldsAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name Labeling ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find existing service
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM request_fields WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );
    my $Exists;
    while ( $DBObject->FetchrowArray() ) {
        $Exists = 1;
    }

    # add service to database
    if ($Exists) {
        return 'Exists';
    }

    if ( !$Param{Rows} ) {
        $Param{Rows} = 0;
    }
    if ( !$Param{Cols} ) {
        $Param{Cols} = 0;
    }
    if ( !$Param{LeerWert} ) {
        $Param{LeerWert} = 0;
    }

    return if !$DBObject->Do(
        SQL => 'INSERT INTO request_fields '
            . '(typ, name, label, defaultvalue, feld_rows, feld_cols, leer_wert, valid_id, create_time, create_by, '
            . 'change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Typ}, \$Param{Name}, \$Param{Labeling}, \$Param{Defaultvalue},
            \$Param{Rows},
            \$Param{Cols}, \$Param{LeerWert}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Antrag id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM request_fields WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );
    my $AntragID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $AntragID = $Row[0];
    }

    return $AntragID;
}

=item RequestFieldsWertAdd()

add RequestFieldsWertAdd

    my $RequestFieldsID = $RequestFieldsObject->RequestFieldsWertAdd(
        FeldID     => 123,
        Schluessel => 'Schluessel',
        Inhalt     => 'Inhalt',
        UserID     => 123,
    );

=cut

sub RequestFieldsWertAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(FeldID Schluessel Inhalt UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find existing service
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM request_fields_value WHERE schluessel = ? AND feld_id = ? ',
        Bind  => [ \$Param{Schluessel}, \$Param{FeldID}, ],
        Limit => 1,
    );
    my $Exists;
    while ( $DBObject->FetchrowArray() ) {
        $Exists = 1;
    }

    # add service to database
    if ($Exists) {
        return 'Exists';
    }

    return if !$DBObject->Do(
        SQL => 'INSERT INTO request_fields_value '
            . '(feld_id, schluessel, inhalt, create_time, create_by, '
            . 'change_time, change_by) '
            . 'VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{FeldID}, \$Param{Schluessel}, \$Param{Inhalt},
            \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get Antrag id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM request_fields_value WHERE schluessel = ?',
        Bind  => [ \$Param{Schluessel} ],
        Limit => 1,
    );
    my $AntragID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $AntragID = $Row[0];
    }

    return $AntragID;
}

=item RequestFieldsWerteList()

return a hash list of Antrag

    my %RequestFieldsList = $RequestFieldsObject->RequestFieldsWerteList(
        FeldID => 1,
    );

=cut

sub RequestFieldsWerteList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{FeldID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need FeldID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id, schluessel, inhalt FROM request_fields_value WHERE feld_id = ?',
        Bind => [ \$Param{FeldID} ],
    );

    # fetch the result
    my %RequestFieldsList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestFieldsList{ $Row[0] } = $Row[1];
    }

    return %RequestFieldsList;
}

=item RequestFieldsWerteGet()

get Antrag attributes

    my %RequestFields = $RequestFieldsObject->RequestFieldsWerteGet(
        ID => 123,
    );

=cut

sub RequestFieldsWerteGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log( Priority => 'error', Message => 'Need ID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, feld_id, schluessel, inhalt, create_time, create_by, change_time, change_by '
            . 'FROM request_fields_value WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );
    my %RequestFields;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %RequestFields = (
            ID         => $Data[0],
            FeldID     => $Data[1],
            Schluessel => $Data[2],
            Inhalt     => $Data[3],
            CreateTime => $Data[4],
            CreateBy   => $Data[5],
            ChangeTime => $Data[6],
            ChangeBy   => $Data[7],
        );
    }

    # return result
    return %RequestFields;
}

=item RequestFieldsWertRemove()

get Antrag attributes

    my $Remove = $RequestFieldsObject->RequestFieldsWertRemove(
        WertID => 123,
    );

=cut

sub RequestFieldsWertRemove {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{WertID} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Need WertID!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL  => 'DELETE FROM request_fields_value WHERE id = ? ',
        Bind => [ \$Param{WertID}, ],
    );

    return 1;
}

=item RequestFieldsWertLookup()

get RequestFieldsWertInhalt

    my $AntragFeldInhalt = $RequestFieldsObject->RequestFieldsWertLookup(
        RequestFieldKey => 'Schluessel',
    );

=cut

sub RequestFieldsWertLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestFieldKey} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Got no RequestFieldKey!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get data
    return if !$DBObject->Prepare(
        SQL  => 'SELECT inhalt FROM request_fields_value WHERE schluessel = ?',
        Bind => [ \$Param{RequestFieldKey} ],
    );

    my $AntragFeldInhalt;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $AntragFeldInhalt = $Row[0];
    }

    # return result
    return $AntragFeldInhalt;
}

=item RequestFieldsSchluesselLookup()

get RequestFieldsSchluessel

    my $AntragFeldSchluessel = $RequestFieldsObject->RequestFieldsSchluesselLookup(
        RequestFieldValue => 'inhalt',
    );

=cut

sub RequestFieldsSchluesselLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestFieldValue} ) {
        $Kernel::OM->Get('Kernel::System::Log')
            ->Log( Priority => 'error', Message => 'Got no RequestFieldValue!' );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get data
    return if !$DBObject->Prepare(
        SQL  => 'SELECT schluessel FROM request_fields_value WHERE inhalt = ?',
        Bind => [ \$Param{RequestFieldValue} ],
    );

    my $AntragFeldSchluessel;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $AntragFeldSchluessel = $Row[0];
    }

    # return result
    return $AntragFeldSchluessel;
}

=head2 RequestFieldsStandardTemplateMemberAdd()

to add an attachment to a template

    my $Success = $RequestFieldsObject->RequestFieldsStandardTemplateMemberAdd(
        RequestFieldID     => 123,
        StandardTemplateID => 123,
        Active             => 1,        # optional
        UserID             => 123,
    );

=cut

sub RequestFieldsStandardTemplateMemberAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(RequestFieldID StandardTemplateID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete existing relation
    return if !$DBObject->Do(
        SQL => 'DELETE FROM standard_templ_request_field
            WHERE standard_request_field_id = ?
            AND standard_template_id = ?',
        Bind => [ \$Param{RequestFieldID}, \$Param{StandardTemplateID} ],
    );

    my $Success = 0;
    if ( $Param{Active} && $Param{Active} == 1 ) {

        # insert new relation
        $Success = $DBObject->Do(
            SQL => '
                INSERT INTO standard_templ_request_field (standard_request_field_id, standard_template_id,
                    create_time, create_by, change_time, change_by)
                VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$Param{RequestFieldID}, \$Param{StandardTemplateID}, \$Param{UserID},
                \$Param{UserID},
            ],
        );
    }

    return $Success;
}

=head2 RequestFieldsStandardTemplateMemberList()

returns a list of Standard RequestFields / Standard Template members

    my %List = $RequestFieldsObject->RequestFieldsStandardTemplateMemberList(
        RequestFieldID => 123,
    );

    or
    my %List = $RequestFieldsObject->RequestFieldsStandardTemplateMemberList(
        StandardTemplateID => 123,
    );

Returns:
    %List = (
        1 => 'Some Name',
        2 => 'Some Name',
    );

=cut

sub RequestFieldsStandardTemplateMemberList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestFieldID} && !$Param{StandardTemplateID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need RequestFieldID or StandardTemplateID!',
        );
        return;
    }

    if ( $Param{RequestFieldID} && $Param{StandardTemplateID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need RequestFieldID or StandardTemplateID, but not both!',
        );
        return;
    }

    # sql
    my %Data;
    my @Bind;
    my $SQL = '
        SELECT str.standard_request_field_id, sr.name, str.standard_template_id, st.name
        FROM standard_templ_request_field str, request_fields sr, standard_template st
        WHERE';

    if ( $Param{RequestFieldID} ) {
        $SQL .= ' st.valid_id IN (' . join ', ',
            $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet() . ')';
    }
    elsif ( $Param{StandardTemplateID} ) {
        $SQL .= ' st.valid_id IN (' . join ', ',
            $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet() . ')';
    }

    $SQL .= '
            AND str.standard_request_field_id = sr.id
            AND str.standard_template_id = st.id';

    if ( $Param{RequestFieldID} ) {
        $SQL .= ' AND str.standard_request_field_id = ?';
        push @Bind, \$Param{RequestFieldID};
    }
    elsif ( $Param{StandardTemplateID} ) {
        $SQL .= ' AND str.standard_template_id = ?';
        push @Bind, \$Param{StandardTemplateID};
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{StandardTemplateID} ) {
            $Data{ $Row[0] } = $Row[1];
        }
        else {
            $Data{ $Row[2] } = $Row[3];
        }
    }

    return %Data;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
