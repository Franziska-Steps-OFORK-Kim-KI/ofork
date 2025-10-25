# --
# Kernel/System/SelfServiceCategories.pm - all SelfService function
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: SelfServiceCategories.pm,v 1.4 2016/11/20 19:30:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SelfServiceCategories;

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

Kernel::System::SelfServiceCategories - SelfServiceCategories lib

=head1 SYNOPSIS

All SelfServiceCategories functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $SelfServiceCategoriesObject = $Kernel::OM->Get('Kernel::System::SelfServiceCategories');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item SelfServiceCategoriesList()

return a hash list of SelfServiceCategories

    my %SelfServiceCategoriesList = $SelfServiceCategoriesObject->SelfServiceCategoriesList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub SelfServiceCategoriesList {
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
        SQL => 'SELECT id, name, valid_id FROM selfservicecategories',
    );

    # fetch the result
    my %SelfServiceCategoriesList;
    my %SelfServiceCategoriesValidList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceCategoriesList{ $Row[0] }      = $Row[1];
        $SelfServiceCategoriesValidList{ $Row[0] } = $Row[2];
    }

    return %SelfServiceCategoriesList if !$Param{Valid};

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # duplicate SelfServiceCategories list
    my %SelfServiceCategoriesListTmp = %SelfServiceCategoriesList;

    # add suffix for correct sorting
    for my $SelfServiceCategoriesID ( keys %SelfServiceCategoriesListTmp ) {
        $SelfServiceCategoriesListTmp{$SelfServiceCategoriesID} .= '::';
    }

    my %SelfServiceCategoriesInvalidList;
    CHANGECATEGORIESID:
    for my $SelfServiceCategoriesID (
        sort { $SelfServiceCategoriesListTmp{$a} cmp $SelfServiceCategoriesListTmp{$b} }
        keys %SelfServiceCategoriesListTmp
        )
    {

        my $Valid = scalar grep { $_ eq $SelfServiceCategoriesValidList{$SelfServiceCategoriesID} } @ValidIDs;

        next CHANGECATEGORIESID if $Valid;

        $SelfServiceCategoriesInvalidList{ $SelfServiceCategoriesList{$SelfServiceCategoriesID} } = 1;
        delete $SelfServiceCategoriesList{$SelfServiceCategoriesID};
    }

    # delete invalid SelfServiceCategories and childs
    for my $SelfServiceCategoriesID ( keys %SelfServiceCategoriesList ) {

        INVALIDNAME:
        for my $InvalidName ( keys %SelfServiceCategoriesInvalidList ) {

            if ( $SelfServiceCategoriesList{$SelfServiceCategoriesID} =~ m{ \A \Q$InvalidName\E :: }xms ) {
                delete $SelfServiceCategoriesList{$SelfServiceCategoriesID};
                last INVALIDNAME;
            }
        }
    }

    return %SelfServiceCategoriesList;
}

=item SelfServiceCategoriesGet()

return a SelfServiceCategories as hash

Return
    $SelfServiceCategoriesData{SelfServiceCategoriesID}
    $SelfServiceCategoriesData{ParentID}
    $SelfServiceCategoriesData{Name}
    $SelfServiceCategoriesData{NameShort}
    $SelfServiceCategoriesData{SelfServiceColor}
    $SelfServiceCategoriesData{ValidID}
    $SelfServiceCategoriesData{Comment}
    $SelfServiceCategoriesData{ImageID}
    $SelfServiceCategoriesData{CreateTime}
    $SelfServiceCategoriesData{CreateBy}
    $SelfServiceCategoriesData{ChangeTime}
    $SelfServiceCategoriesData{ChangeBy}

    my %SelfServiceCategoriesData = $SelfServiceCategoriesObject->SelfServiceCategoriesGet(
        SelfServiceCategoriesID => 123,
        UserID             => 1,
    );

    my %SelfServiceCategoriesData = $SelfServiceCategoriesObject->SelfServiceCategoriesGet(
        Name    => 'SelfServiceCategories::SubSelfServiceCategories',
        UserID  => 1,
    );

=cut

sub SelfServiceCategoriesGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # either SelfServiceCategoriesID or Name must be passed
    if ( !$Param{SelfServiceCategoriesID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need SelfServiceCategoriesID or Name!',
        );
        return;
    }

    # check that not both SelfServiceCategoriesID and Name are given
    if ( $Param{SelfServiceCategoriesID} && $Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need either SelfServiceCategoriesID OR Name - not both!',
        );
        return;
    }

    # lookup the SelfServiceCategoriesID
    if ( $Param{Name} ) {
        $Param{SelfServiceCategoriesID} = $Self->SelfServiceCategoriesLookup(
            Name => $Param{Name},
        );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get SelfServiceCategories from db
    $DBObject->Prepare(
        SQL =>
            'SELECT id, name, valid_id, color, comments, image_id, create_time, create_by, change_time, change_by '
            . 'FROM selfservicecategories WHERE id = ?',
        Bind  => [ \$Param{SelfServiceCategoriesID} ],
        Limit => 1,
    );

    # fetch the result
    my %SelfServiceCategoriesData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceCategoriesData{SelfServiceCategoriesID} = $Row[0];
        $SelfServiceCategoriesData{Name}                    = $Row[1];
        $SelfServiceCategoriesData{ValidID}                 = $Row[2];
        $SelfServiceCategoriesData{SelfServiceColor}        = $Row[3];
        $SelfServiceCategoriesData{Comment}                 = $Row[4] || '';
        $SelfServiceCategoriesData{ImageID}                 = $Row[5];
        $SelfServiceCategoriesData{CreateTime}              = $Row[6];
        $SelfServiceCategoriesData{CreateBy}                = $Row[7];
        $SelfServiceCategoriesData{ChangeTime}              = $Row[8];
        $SelfServiceCategoriesData{ChangeBy}                = $Row[9];
    }

    # check SelfServiceCategories
    if ( !$SelfServiceCategoriesData{SelfServiceCategoriesID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No such SelfServiceCategoriesID ($Param{SelfServiceCategoriesID})!",
        );
        return;
    }

    # create short name and parentid
    $SelfServiceCategoriesData{NameShort} = $SelfServiceCategoriesData{Name};
    if ( $SelfServiceCategoriesData{Name} =~ m{ \A (.*) :: (.+?) \z }xms ) {
        $SelfServiceCategoriesData{NameShort} = $2;

        # lookup parent
        my $SelfServiceCategoriesID = $Self->SelfServiceCategoriesLookup(
            Name => $1,
        );
        $SelfServiceCategoriesData{ParentID} = $SelfServiceCategoriesID;
    }

    return %SelfServiceCategoriesData;
}

=item SelfServiceCategoriesLookup()

return a SelfServiceCategories name and id

    my $SelfServiceCategoriesName = $SelfServiceCategoriesObject->SelfServiceCategoriesLookup(
        SelfServiceCategoriesID => 123,
    );

    or

    my $SelfServiceCategoriesID = $SelfServiceCategoriesObject->SelfServiceCategoriesLookup(
        Name => 'SelfServiceCategories::SubSelfServiceCategories',
    );

=cut

sub SelfServiceCategoriesLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{SelfServiceCategoriesID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need SelfServiceCategoriesID or Name!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{SelfServiceCategoriesID} ) {

        # check cache
        my $CacheKey = 'Cache::SelfServiceCategoriesLookup::ID::' . $Param{SelfServiceCategoriesID};
        if ( defined $Self->{$CacheKey} ) {
            return $Self->{$CacheKey};
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT name FROM requestcategories WHERE id = ?',
            Bind  => [ \$Param{SelfServiceCategoriesID} ],
            Limit => 1,
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->{$CacheKey} = $Row[0];
        }

        return $Self->{$CacheKey};
    }
    else {

        # check cache
        my $CacheKey = 'Cache::SelfServiceCategoriesLookup::Name::' . $Param{Name};
        if ( defined $Self->{$CacheKey} ) {
            return $Self->{$CacheKey};
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT id FROM selfservicecategories WHERE name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->{$CacheKey} = $Row[0];
        }

        return $Self->{$CacheKey};
    }
}

=item SelfServiceCategoriesAdd()

add a SelfServiceCategories

    my $SelfServiceCategoriesID = $SelfServiceCategoriesObject->SelfServiceCategoriesAdd(
        Name             => 'SelfServiceCategories Name',
        ParentID         => 1,           # (optional)
        SelfServiceColor => '#ffffff',
        ValidID          => 1,
        Comment          => 'Comment',    # (optional)
        ImageID          => 1,           # (optional)
        UserID           => 1,
    );

=cut

sub SelfServiceCategoriesAdd {
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

    # check SelfServiceCategories name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't add SelfServiceCategories! Invalid SelfServiceCategories name '$Param{Name}'!",
        );
        return;
    }

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {
        my $ParentName
            = $Self->SelfServiceCategoriesLookup( SelfServiceCategoriesID => $Param{ParentID}, );
        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }
    }

    # find existing SelfServiceCategories
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM selfservicecategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( $DBObject->FetchrowArray() ) {
        $Exists = 1;
    }

    # add SelfServiceCategories to database
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                'Can\'t add SelfServiceCategories! SelfServiceCategories with same name and parent already exists.'
        );
        return;
    }

    return if !$DBObject->Do(
        SQL => 'INSERT INTO selfservicecategories '
            . '(name, valid_id, color, comments, image_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{SelfServiceColor}, \$Param{Comment}, \$Param{ImageID},
            \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get SelfServiceCategories id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM selfservicecategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $SelfServiceCategoriesID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceCategoriesID = $Row[0];
    }

    return $SelfServiceCategoriesID;
}

=item SelfServiceCategoriesUpdate()

update a existing SelfServiceCategories

    my $True = $SelfServiceCategoriesObject->SelfServiceCategoriesUpdate(
        SelfServiceCategoriesID => 123,
        ParentID         => 1,           # (optional)
        Name             => 'SelfServiceCategories Name',
        SelfServiceColor => '#ffffff',
        ValidID          => 1,
        Comment          => 'Comment',    # (optional)
        ImageID          => 1,           # (optional)
        UserID           => 1,
    );

=cut

sub SelfServiceCategoriesUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(SelfServiceCategoriesID Name ValidID UserID)) {
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

    # check SelfServiceCategories name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Can't update SelfServiceCategories! Invalid SelfServiceCategories name '$Param{Name}'!",
        );
        return;
    }

    # get old name of SelfServiceCategories
    my $OldSelfServiceCategoriesName
        = $Self->SelfServiceCategoriesLookup( SelfServiceCategoriesID => $Param{SelfServiceCategoriesID}, );

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {

        # lookup SelfServiceCategories
        my $ParentName = $Self->SelfServiceCategoriesLookup(
            SelfServiceCategoriesID => $Param{ParentID},
        );

        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }

        # check, if selected parent was a child of this SelfServiceCategories
        if ( $Param{FullName} =~ m{ \A ( \Q$OldSelfServiceCategoriesName\E ) :: }xms ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Can\'t update SelfServiceCategories! Invalid parent was selected.'
            );
            return;
        }
    }

    # find exists SelfServiceCategories
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM selfservicecategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{SelfServiceCategoriesID} ne $Row[0] ) {
            $Exists = 1;
        }
    }

    # update SelfServiceCategories
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                'Can\'t update SelfServiceCategories! SelfServiceCategories with same name and parent already exists.'
        );
        return;

    }

    # update SelfServiceCategories
    return if !$DBObject->Do(
        SQL => 'UPDATE selfservicecategories SET name = ?, valid_id = ?, color = ?, comments = ?, image_id = ?,'
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{SelfServiceColor}, \$Param{Comment}, \$Param{ImageID},
            \$Param{UserID}, \$Param{SelfServiceCategoriesID},
        ],
    );

    # find all childs
    $DBObject->Prepare(
        SQL => "SELECT id, name FROM selfservicecategories WHERE name LIKE '"
            . $DBObject->Quote( $OldSelfServiceCategoriesName, 'Like' )
            . "::%'",
    );
    my @Childs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Child;
        $Child{SelfServiceCategoriesID} = $Row[0];
        $Child{Name}               = $Row[1];
        push @Childs, \%Child;
    }

    # update childs
    for my $Child (@Childs) {
        $Child->{Name} =~ s{ \A ( \Q$OldSelfServiceCategoriesName\E ) :: }{$Param{FullName}::}xms;
        $DBObject->Do(
            SQL => 'UPDATE selfservicecategories SET name = ? WHERE id = ?',
            Bind => [ \$Child->{Name}, \$Child->{SelfServiceCategoriesID} ],
        );
    }
    return 1;
}

=item SelfServiceCategoriesSearch()

return SelfServiceCategories ids as an array

    my @SelfServiceCategoriesList = $SelfServiceCategoriesObject->SelfServiceCategoriesSearch(
        Name   => 'SelfServiceCategories Name', # (optional)
        Limit  => 122,            # (optional) default 1000
        UserID => 1,
    );

=cut

sub SelfServiceCategoriesSearch {
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
        = "SELECT id FROM selfservicecategories WHERE valid_id IN ( ${\(join ', ', $Self->{ValidObject}->ValidIDsGet())} )";

    if ( $Param{Name} ) {

        # quote
        $Param{Name} = $DBObject->Quote( $Param{Name}, 'Like' );

        # replace * with % and clean the string
        $Param{Name} =~ s{ \*+ }{%}xmsg;
        $Param{Name} =~ s{ %+ }{%}xmsg;

        $SQL .= " AND name LIKE '$Param{Name}' ";
    }

    $SQL .= ' ORDER BY name';

    # search SelfServiceCategories in db
    $DBObject->Prepare( SQL => $SQL );

    my @SelfServiceCategoriesList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @SelfServiceCategoriesList, $Row[0];
    }

    return @SelfServiceCategoriesList;
}

=item SelfServiceCategoriesTemplateAdd()

add a SelfServiceCategoriesTemplate

    my $SelfServiceCategoriesTemplateID = $SelfServiceCategoriesObject->SelfServiceCategoriesTemplateAdd(
        TemplateID         => 2,
        SelfServiceCategoriesID => 1,
        UserID             => 1,
    );

=cut

sub SelfServiceCategoriesTemplateAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID SelfServiceCategoriesID UserID)) {
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
        SQL => 'INSERT INTO selfservicecat_selfservice '
            . '(template_id, selfservicecategories_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TemplateID}, \$Param{SelfServiceCategoriesID},
            \$Param{UserID},     \$Param{UserID},
        ],
    );

    # get SelfServiceCategories id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM selfservicecat_selfservice WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );
    my $SelfServiceCategoriesTemplateID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceCategoriesTemplateID = $Row[0];
    }

    return $SelfServiceCategoriesTemplateID;
}

=item SelfServiceCategoriesTemplateList()

return a hash list of Antrag

    my %SelfServiceCategoriesTemplateList = $SelfServiceCategoriesObject->SelfServiceCategoriesTemplateList(
        SelfServiceCategoriesID  => 1,
        UserID              => 1,
    );

=cut

sub SelfServiceCategoriesTemplateList {
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
    if ( !$Param{SelfServiceCategoriesID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need SelfServiceCategoriesID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL =>
            "SELECT id, template_id FROM selfservicecat_selfservice WHERE selfservicecategories_id = $Param{SelfServiceCategoriesID}",
    );

    # fetch the result
    my %SelfServiceCategoriesTemplateList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceCategoriesTemplateList{ $Row[0] } = $Row[1];
    }

    return %SelfServiceCategoriesTemplateList;
}

=item SelfServiceCategoriesTemplateUpdate()

update a SelfServiceCategoriesTemplate

    my $SelfServiceCategoriesTemplateID = $SelfServiceCategoriesObject->SelfServiceCategoriesTemplateUpdate(
        TemplateID         => 2,
        SelfServiceCategoriesID => 1,
        UserID             => 1,
    );

=cut

sub SelfServiceCategoriesTemplateUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID SelfServiceCategoriesID UserID)) {
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

    # get SelfServiceCategories from db
    $DBObject->Prepare(
        SQL =>
            'SELECT id FROM selfservicecat_selfservice WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );

    # fetch the result
    my $CheckTemplate;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $CheckTemplate = $Row[0];
    }

    if ($CheckTemplate) {

        # update SelfServiceCategories
        return if !$DBObject->Do(
            SQL => 'UPDATE selfservicecat_selfservice SET template_id = ?, selfservicecategories_id = ?, '
                . ' change_time = current_timestamp, change_by = ? WHERE template_id = ?',
            Bind => [
                \$Param{TemplateID}, \$Param{SelfServiceCategoriesID},
                \$Param{UserID},     \$Param{TemplateID},
            ],
        );
    }
    else {

        return if !$DBObject->Do(
            SQL => 'INSERT INTO selfservicecategories_request '
                . '(template_id, selfservicecategories_id, create_time, create_by, change_time, change_by) '
                . 'VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$Param{TemplateID}, \$Param{SelfServiceCategoriesID},
                \$Param{UserID},     \$Param{UserID},
            ],
        );

    }

    # get SelfServiceCategories id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM selfservicecategories_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );
    my $SelfServiceCategoriesTemplateID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceCategoriesTemplateID = $Row[0];
    }

    return $SelfServiceCategoriesTemplateID;
}

=item SelfServiceCategoriesTemplateGet()

return a SelfServiceCategoriesID

Return
    $SelfServiceCategoriesID

    my $SelfServiceCategoriesID = $SelfServiceCategoriesObject->SelfServiceCategoriesTemplateGet(
        TemplateID => 123,
        UserID     => 1,
    );

=cut

sub SelfServiceCategoriesTemplateGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # either SelfServiceCategoriesID or Name must be passed
    if ( !$Param{TemplateID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TemplateID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get SelfServiceCategories from db
    $DBObject->Prepare(
        SQL =>
            'SELECT selfservicecategories_id '
            . 'FROM selfservicecat_selfservice WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );

    # fetch the result
    my $SelfServiceCategoriesID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SelfServiceCategoriesID = $Row[0];

    }

    # check SelfServiceCategories
    if ( !$SelfServiceCategoriesID ) {
        return;
    }

    return $SelfServiceCategoriesID;
}

=item SelfServiceCategoriesTemplateDelete()

    my $Success = $SelfServiceCategoriesObject->SelfServiceCategoriesTemplateDelete(
        TemplateID => 123,
        UserID     => 123,
    );

Events:
    SelfServiceCategoriesTemplateDelete

=cut

sub SelfServiceCategoriesTemplateDelete {
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
        SQL  => 'DELETE FROM selfservicecat_selfservice WHERE template_id = ?',
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
