# --
# Kernel/System/ContractType.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: ContractType.pm,v 1.4 2016/11/20 19:30:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ContractType;

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

Kernel::System::ContractType - ContractType lib

=head1 SYNOPSIS

All ContractType functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ContractTypeObject = $Kernel::OM->Get('Kernel::System::ContractType');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item ContractTypeList()

return a hash list of ContractType

    my %ContractTypeList = $ContractTypeObject->ContractTypeList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub ContractTypeList {
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
        $Param{Valid} = 1;
    }

    # ask database
    $DBObject->Prepare(
        SQL => 'SELECT id, name, valid_id FROM contracttype',
    );

    # fetch the result
    my %ContractTypeList;
    my %ContractTypeValidList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractTypeList{ $Row[0] }      = $Row[1];
        $ContractTypeValidList{ $Row[0] } = $Row[2];
    }

    return %ContractTypeList if !$Param{Valid};

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # duplicate RequestCategories list
    my %ContractTypeListTmp = %ContractTypeList;

    # add suffix for correct sorting
    for my $ContractTypeID ( keys %ContractTypeListTmp ) {
        $ContractTypeListTmp{$ContractTypeID} .= '::';
    }

    my %ContractTypeInvalidList;
    CHANGECATEGORIESID:
    for my $ContractTypeID (
        sort { $ContractTypeListTmp{$a} cmp $ContractTypeListTmp{$b} }
        keys %ContractTypeListTmp
        )
    {

        my $Valid = scalar grep { $_ eq $ContractTypeValidList{$ContractTypeID} } @ValidIDs;

        next CHANGECATEGORIESID if $Valid;

        $ContractTypeInvalidList{ $ContractTypeList{$ContractTypeID} } = 1;
        delete $ContractTypeList{$ContractTypeID};
    }

    # delete invalid ContractType and childs
    for my $ContractTypeID ( keys %ContractTypeList ) {

        INVALIDNAME:
        for my $InvalidName ( keys %ContractTypeInvalidList ) {

            if ( $ContractTypeList{$ContractTypeID} =~ m{ \A \Q$InvalidName\E :: }xms ) {
                delete $ContractTypeList{$ContractTypeID};
                last INVALIDNAME;
            }
        }
    }

    return %ContractTypeList;
}

=item ContractTypeGet()

return a ContractType as hash

Return
    $ContractTypeData{ContractTypeID}
    $ContractTypeData{ParentID}
    $ContractTypeData{Name}
    $ContractTypeData{NameShort}
    $ContractTypeData{ValidID}
    $ContractTypeData{Comment}
    $ContractTypeData{CreateTime}
    $ContractTypeData{CreateBy}
    $ContractTypeData{ChangeTime}
    $ContractTypeData{ChangeBy}

    my %ContractTypeData = $ContractTypeObject->ContractTypeGet(
        ContractTypeID => 123,
        UserID         => 1,
    );

    my %ContractTypeData = $ContractTypeObject->ContractTypeGet(
        Name    => 'ContractType::SubContractType',
        UserID  => 1,
    );

=cut

sub ContractTypeGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # either ContractTypeID or Name must be passed
    if ( !$Param{ContractTypeID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ContractTypeID or Name!',
        );
        return;
    }

    # check that not both ContractTypeID and Name are given
    if ( $Param{ContractTypeID} && $Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need either ContractTypeID OR Name - not both!',
        );
        return;
    }

    # lookup the ContractTypeID
    if ( $Param{Name} ) {
        $Param{ContractTypeID} = $Self->ContractTypeLookup(
            Name => $Param{Name},
        );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get RequestCategories from db
    $DBObject->Prepare(
        SQL =>
            'SELECT id, name, valid_id, comments, create_time, create_by, change_time, change_by '
            . 'FROM contracttype WHERE id = ?',
        Bind  => [ \$Param{ContractTypeID} ],
        Limit => 1,
    );

    # fetch the result
    my %ContractTypeData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractTypeData{ContractTypeID} = $Row[0];
        $ContractTypeData{Name}           = $Row[1];
        $ContractTypeData{ValidID}        = $Row[2];
        $ContractTypeData{Comment}        = $Row[3] || '';
        $ContractTypeData{CreateTime}     = $Row[4];
        $ContractTypeData{CreateBy}       = $Row[5];
        $ContractTypeData{ChangeTime}     = $Row[6];
        $ContractTypeData{ChangeBy}       = $Row[7];
    }

    # check ContractType
    if ( !$ContractTypeData{ContractTypeID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No such ContractTypeID ($Param{ContractTypeID})!",
        );
        return;
    }

    # create short name and parentid
    $ContractTypeData{NameShort} = $ContractTypeData{Name};
    if ( $ContractTypeData{Name} =~ m{ \A (.*) :: (.+?) \z }xms ) {
        $ContractTypeData{NameShort} = $2;

        # lookup parent
        my $ContractTypeID = $Self->ContractTypeLookup(
            Name => $1,
        );
        $ContractTypeData{ParentID} = $ContractTypeID;
    }

    return %ContractTypeData;
}

=item ContractTypeLookup()

return a ContractType name and id

    my $ContractTypeName = $ContractTypeObject->ContractTypeLookup(
        ContractTypeID => 123,
    );

    or

    my $ContractTypeID = $ContractTypeObject->ContractTypeLookup(
        Name => 'ContractType::SubContractType',
    );

=cut

sub ContractTypeLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ContractTypeID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ContractTypeID or Name!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{ContractTypeID} ) {

        # check cache
        my $CacheKey = 'Cache::ContractTypeLookup::ID::' . $Param{ContractTypeID};
        if ( defined $Self->{$CacheKey} ) {
            return $Self->{$CacheKey};
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT name FROM contracttype WHERE id = ?',
            Bind  => [ \$Param{ContractTypeID} ],
            Limit => 1,
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->{$CacheKey} = $Row[0];
        }

        return $Self->{$CacheKey};
    }
    else {

        # check cache
        my $CacheKey = 'Cache::ContractTypeLookup::Name::' . $Param{Name};
        if ( defined $Self->{$CacheKey} ) {
            return $Self->{$CacheKey};
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT id FROM contracttype WHERE name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->{$CacheKey} = $Row[0];
        }

        return $Self->{$CacheKey};
    }
}

=item ContractTypeAdd()

add a ContractType

    my $ContractTypeID = $ContractTypeObject->ContractTypeAdd(
        Name     => 'ContractType Name',
        ParentID => 1,           # (optional)
        ValidID  => 1,
        Comment  => 'Comment',    # (optional)
        UserID   => 1,
    );

=cut

sub ContractTypeAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # set comment
    $Param{Comment} ||= '';

    # get object
    my $DBObject        = $Kernel::OM->Get('Kernel::System::DB');
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    # cleanup given params
    for my $Argument (qw(Name Comment)) {
        $CheckItemObject->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }

    # check ContractType name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't add ContractType! Invalid ContractType name '$Param{Name}'!",
        );
        return;
    }

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {
        my $ParentName
            = $Self->ContractTypeLookup( ContractTypeID => $Param{ParentID}, );
        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }
    }

    # find existing ContractType
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM contracttype WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( $DBObject->FetchrowArray() ) {
        $Exists = 1;
    }

    # add ContractType to database
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                'Can\'t add ContractType! ContractType with same name and parent already exists.'
        );
        return;
    }

    return if !$DBObject->Do(
        SQL => 'INSERT INTO contracttype '
            . '(name, valid_id, comments, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{Comment}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get ContractType id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM contracttype WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $ContractTypeID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractTypeID = $Row[0];
    }

    return $ContractTypeID;
}

=item ContractTypeUpdate()

update a existing ContractType

    my $True = $ContractTypeObject->ContractTypeUpdate(
        ContractTypeID => 123,
        ParentID       => 1,           # (optional)
        Name           => 'ContractType Name',
        ValidID        => 1,
        Comment        => 'Comment',    # (optional)
        UserID         => 1,
    );

=cut

sub ContractTypeUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ContractTypeID Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get object
    my $DBObject        = $Kernel::OM->Get('Kernel::System::DB');
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    # set default comment
    $Param{Comment} ||= '';

    # cleanup given params
    for my $Argument (qw(Name Comment)) {
        $CheckItemObject->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }

    # check ContractType name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Can't update ContractType! Invalid ContractType name '$Param{Name}'!",
        );
        return;
    }

    # get old name of ContractType
    my $OldContractTypeName
        = $Self->ContractTypeLookup( ContractTypeID => $Param{ContractTypeID}, );

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {

        # lookup ContractType
        my $ParentName = $Self->ContractTypeLookup(
            ContractTypeID => $Param{ParentID},
        );

        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }

        # check, if selected parent was a child of this ContractType
        if ( $Param{FullName} =~ m{ \A ( \Q$OldContractTypeName\E ) :: }xms ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Can\'t update ContractType! Invalid parent was selected.'
            );
            return;
        }
    }

    # find exists ContractType
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM contracttype WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{ContractTypeID} ne $Row[0] ) {
            $Exists = 1;
        }
    }

    # update ContractType
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                'Can\'t update ContractType! ContractType with same name and parent already exists.'
        );
        return;

    }

    # update ContractType
    return if !$DBObject->Do(
        SQL => 'UPDATE contracttype SET name = ?, valid_id = ?, comments = ?,'
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{Comment},
            \$Param{UserID}, \$Param{ContractTypeID},
        ],
    );

    # find all childs
    $DBObject->Prepare(
        SQL => "SELECT id, name FROM contracttype WHERE name LIKE '"
            . $DBObject->Quote( $OldContractTypeName, 'Like' )
            . "::%'",
    );
    my @Childs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Child;
        $Child{ContractTypeID} = $Row[0];
        $Child{Name}           = $Row[1];
        push @Childs, \%Child;
    }

    # update childs
    for my $Child (@Childs) {
        $Child->{Name} =~ s{ \A ( \Q$OldContractTypeName\E ) :: }{$Param{FullName}::}xms;
        $DBObject->Do(
            SQL => 'UPDATE contracttype SET name = ? WHERE id = ?',
            Bind => [ \$Child->{Name}, \$Child->{ContractTypeID} ],
        );
    }
    return 1;
}

=item ContractTypeSearch()

return ContractType ids as an array

    my @ContractTypeList = $ContractTypeObject->ContractTypeSearch(
        Name   => 'ContractType Name', # (optional)
        Limit  => 122,            # (optional) default 1000
        UserID => 1,
    );

=cut

sub ContractTypeSearch {
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

    # set default limit
    $Param{Limit} ||= 1000;

    # create sql query
    my $SQL
        = "SELECT id FROM contracttype WHERE valid_id IN ( ${\(join ', ', $Self->{ValidObject}->ValidIDsGet())} )";

    if ( $Param{Name} ) {

        # quote
        $Param{Name} = $DBObject->Quote( $Param{Name}, 'Like' );

        # replace * with % and clean the string
        $Param{Name} =~ s{ \*+ }{%}xmsg;
        $Param{Name} =~ s{ %+ }{%}xmsg;

        $SQL .= " AND name LIKE '$Param{Name}' ";
    }

    $SQL .= ' ORDER BY name';

    # search ContractType in db
    $DBObject->Prepare( SQL => $SQL );

    my @ContractTypeList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ContractTypeList, $Row[0];
    }

    return @ContractTypeList;
}

=item ContractTypeTemplateAdd()

add a ContractTypeTemplate

    my $ContractTypeTemplateID = $ContractTypeObject->ContractTypeTemplateAdd(
        TemplateID     => 2,
        ContractTypeID => 1,
        UserID         => 1,
    );

=cut

sub ContractTypeTemplateAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID ContractTypeID UserID)) {
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

    return if !$DBObject->Do(
        SQL => 'INSERT INTO contracttype_request '
            . '(template_id, contracttype_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TemplateID}, \$Param{ContractTypeID},
            \$Param{UserID},     \$Param{UserID},
        ],
    );

    # get ContractType id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM contracttype_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );
    my $ContractTypeTemplateID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractTypeTemplateID = $Row[0];
    }

    return $ContractTypeTemplateID;
}

=item ContractTypeTemplateList()

return a hash list of Antrag

    my %ContractTypeTemplateList = $ContractTypeObject->ContractTypeTemplateList(
        ContractTypeID  => 1,
        UserID          => 1,
    );

=cut

sub ContractTypeTemplateList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # check needed stuff
    if ( !$Param{ContractTypeID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ContractTypeID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL =>
            "SELECT id, template_id FROM contracttype_request WHERE contracttype_id = $Param{ContractTypeID}",
    );

    # fetch the result
    my %ContractTypeTemplateList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractTypeTemplateList{ $Row[0] } = $Row[1];
    }

    return %ContractTypeTemplateList;
}

=item ContractTypeTemplateUpdate()

update a ContractTypeTemplate

    my $ContractTypeTemplateID = $ContractTypeObject->ContractTypeTemplateUpdate(
        TemplateID     => 2,
        ContractTypeID => 1,
        UserID         => 1,
    );

=cut

sub ContractTypeTemplateUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID ContractTypeID UserID)) {
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

    # get ContractType from db
    $DBObject->Prepare(
        SQL =>
            'SELECT id FROM contracttype_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );

    # fetch the result
    my $CheckTemplate;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $CheckTemplate = $Row[0];
    }

    if ($CheckTemplate) {

        # update ContractType
        return if !$DBObject->Do(
            SQL => 'UPDATE contracttype_request SET template_id = ?, contracttype_id = ?, '
                . ' change_time = current_timestamp, change_by = ? WHERE template_id = ?',
            Bind => [
                \$Param{TemplateID}, \$Param{ContractTypeID},
                \$Param{UserID},     \$Param{TemplateID},
            ],
        );
    }
    else {

        return if !$DBObject->Do(
            SQL => 'INSERT INTO contracttype_request '
                . '(template_id, contracttype_id, create_time, create_by, change_time, change_by) '
                . 'VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$Param{TemplateID}, \$Param{ContractTypeID},
                \$Param{UserID},     \$Param{UserID},
            ],
        );

    }

    # get ContractType id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM contracttype_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );
    my $ContractTypeTemplateID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractTypeTemplateID = $Row[0];
    }

    return $ContractTypeTemplateID;
}

=item ContractTypeTemplateGet()

return a ContractTypeID

Return
    $ContractTypeID

    my $ContractTypeID = $ContractTypeObject->ContractTypeTemplateGet(
        TemplateID => 123,
        UserID     => 1,
    );

=cut

sub ContractTypeTemplateGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # either ContractTypeID or Name must be passed
    if ( !$Param{TemplateID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TemplateID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get ContractType from db
    $DBObject->Prepare(
        SQL =>
            'SELECT contracttype_id '
            . 'FROM contracttype_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );

    # fetch the result
    my $ContractTypeID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ContractTypeID = $Row[0];

    }

    # check ContractType
    if ( !$ContractTypeID ) {
        return;
    }

    return $ContractTypeID;
}

=item ContractTypeTemplateDelete()

    my $Success = $ContractTypeObject->ContractTypeTemplateDelete(
        TemplateID => 123,
        UserID     => 123,
    );

Events:
    ContractTypeTemplateDelete

=cut

sub ContractTypeTemplateDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TemplateID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')
                ->Log( Priority => 'error', Message => "Need $Needed!" );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL  => 'DELETE FROM contracttype_request WHERE template_id = ?',
        Bind => [ \$Param{TemplateID} ],
    );

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
