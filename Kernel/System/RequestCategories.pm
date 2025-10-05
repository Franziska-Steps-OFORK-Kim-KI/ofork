# --
# Kernel/System/RequestCategories.pm - all service function
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: RequestCategories.pm,v 1.4 2016/11/20 19:30:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::RequestCategories;

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

Kernel::System::RequestCategories - RequestCategories lib

=head1 SYNOPSIS

All RequestCategories functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $RequestCategoriesObject = $Kernel::OM->Get('Kernel::System::RequestCategories');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item RequestCategoriesList()

return a hash list of RequestCategories

    my %RequestCategoriesList = $RequestCategoriesObject->RequestCategoriesList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub RequestCategoriesList {
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
        SQL => 'SELECT id, name, valid_id FROM requestcategories',
    );

    # fetch the result
    my %RequestCategoriesList;
    my %RequestCategoriesValidList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestCategoriesList{ $Row[0] }      = $Row[1];
        $RequestCategoriesValidList{ $Row[0] } = $Row[2];
    }

    return %RequestCategoriesList if !$Param{Valid};

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # duplicate RequestCategories list
    my %RequestCategoriesListTmp = %RequestCategoriesList;

    # add suffix for correct sorting
    for my $RequestCategoriesID ( keys %RequestCategoriesListTmp ) {
        $RequestCategoriesListTmp{$RequestCategoriesID} .= '::';
    }

    my %RequestCategoriesInvalidList;
    CHANGECATEGORIESID:
    for my $RequestCategoriesID (
        sort { $RequestCategoriesListTmp{$a} cmp $RequestCategoriesListTmp{$b} }
        keys %RequestCategoriesListTmp
        )
    {

        my $Valid = scalar grep { $_ eq $RequestCategoriesValidList{$RequestCategoriesID} } @ValidIDs;

        next CHANGECATEGORIESID if $Valid;

        $RequestCategoriesInvalidList{ $RequestCategoriesList{$RequestCategoriesID} } = 1;
        delete $RequestCategoriesList{$RequestCategoriesID};
    }

    # delete invalid RequestCategories and childs
    for my $RequestCategoriesID ( keys %RequestCategoriesList ) {

        INVALIDNAME:
        for my $InvalidName ( keys %RequestCategoriesInvalidList ) {

            if ( $RequestCategoriesList{$RequestCategoriesID} =~ m{ \A \Q$InvalidName\E :: }xms ) {
                delete $RequestCategoriesList{$RequestCategoriesID};
                last INVALIDNAME;
            }
        }
    }

    return %RequestCategoriesList;
}

=item RequestCategoriesGet()

return a RequestCategories as hash

Return
    $RequestCategoriesData{RequestCategoriesID}
    $RequestCategoriesData{ParentID}
    $RequestCategoriesData{Name}
    $RequestCategoriesData{NameShort}
    $RequestCategoriesData{ValidID}
    $RequestCategoriesData{Comment}
    $RequestCategoriesData{ImageID}
    $RequestCategoriesData{CreateTime}
    $RequestCategoriesData{CreateBy}
    $RequestCategoriesData{ChangeTime}
    $RequestCategoriesData{ChangeBy}

    my %RequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
        RequestCategoriesID => 123,
        UserID             => 1,
    );

    my %RequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
        Name    => 'RequestCategories::SubRequestCategories',
        UserID  => 1,
    );

=cut

sub RequestCategoriesGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # either RequestCategoriesID or Name must be passed
    if ( !$Param{RequestCategoriesID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need RequestCategoriesID or Name!',
        );
        return;
    }

    # check that not both RequestCategoriesID and Name are given
    if ( $Param{RequestCategoriesID} && $Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need either RequestCategoriesID OR Name - not both!',
        );
        return;
    }

    # lookup the RequestCategoriesID
    if ( $Param{Name} ) {
        $Param{RequestCategoriesID} = $Self->RequestCategoriesLookup(
            Name => $Param{Name},
        );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get RequestCategories from db
    $DBObject->Prepare(
        SQL =>
            'SELECT id, name, valid_id, comments, image_id, create_time, create_by, change_time, change_by '
            . 'FROM requestcategories WHERE id = ?',
        Bind  => [ \$Param{RequestCategoriesID} ],
        Limit => 1,
    );

    # fetch the result
    my %RequestCategoriesData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestCategoriesData{RequestCategoriesID} = $Row[0];
        $RequestCategoriesData{Name}               = $Row[1];
        $RequestCategoriesData{ValidID}            = $Row[2];
        $RequestCategoriesData{Comment}            = $Row[3] || '';
        $RequestCategoriesData{ImageID}             = $Row[4];
        $RequestCategoriesData{CreateTime}          = $Row[5];
        $RequestCategoriesData{CreateBy}            = $Row[6];
        $RequestCategoriesData{ChangeTime}          = $Row[7];
        $RequestCategoriesData{ChangeBy}            = $Row[8];
    }

    # check RequestCategories
    if ( !$RequestCategoriesData{RequestCategoriesID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No such RequestCategoriesID ($Param{RequestCategoriesID})!",
        );
        return;
    }

    # create short name and parentid
    $RequestCategoriesData{NameShort} = $RequestCategoriesData{Name};
    if ( $RequestCategoriesData{Name} =~ m{ \A (.*) :: (.+?) \z }xms ) {
        $RequestCategoriesData{NameShort} = $2;

        # lookup parent
        my $RequestCategoriesID = $Self->RequestCategoriesLookup(
            Name => $1,
        );
        $RequestCategoriesData{ParentID} = $RequestCategoriesID;
    }

    return %RequestCategoriesData;
}

=item RequestCategoriesLookup()

return a RequestCategories name and id

    my $RequestCategoriesName = $RequestCategoriesObject->RequestCategoriesLookup(
        RequestCategoriesID => 123,
    );

    or

    my $RequestCategoriesID = $RequestCategoriesObject->RequestCategoriesLookup(
        Name => 'RequestCategories::SubRequestCategories',
    );

=cut

sub RequestCategoriesLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{RequestCategoriesID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need RequestCategoriesID or Name!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{RequestCategoriesID} ) {

        # check cache
        my $CacheKey = 'Cache::RequestCategoriesLookup::ID::' . $Param{RequestCategoriesID};
        if ( defined $Self->{$CacheKey} ) {
            return $Self->{$CacheKey};
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT name FROM requestcategories WHERE id = ?',
            Bind  => [ \$Param{RequestCategoriesID} ],
            Limit => 1,
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->{$CacheKey} = $Row[0];
        }

        return $Self->{$CacheKey};
    }
    else {

        # check cache
        my $CacheKey = 'Cache::RequestCategoriesLookup::Name::' . $Param{Name};
        if ( defined $Self->{$CacheKey} ) {
            return $Self->{$CacheKey};
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT id FROM requestcategories WHERE name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->{$CacheKey} = $Row[0];
        }

        return $Self->{$CacheKey};
    }
}

=item RequestCategoriesAdd()

add a RequestCategories

    my $RequestCategoriesID = $RequestCategoriesObject->RequestCategoriesAdd(
        Name     => 'RequestCategories Name',
        ParentID => 1,           # (optional)
        ValidID  => 1,
        Comment  => 'Comment',    # (optional)
        ImageID  => 1,           # (optional)
        UserID   => 1,
    );

=cut

sub RequestCategoriesAdd {
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

    # check RequestCategories name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't add RequestCategories! Invalid RequestCategories name '$Param{Name}'!",
        );
        return;
    }

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {
        my $ParentName
            = $Self->RequestCategoriesLookup( RequestCategoriesID => $Param{ParentID}, );
        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }
    }

    # find existing RequestCategories
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM requestcategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( $DBObject->FetchrowArray() ) {
        $Exists = 1;
    }

    # add RequestCategories to database
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                'Can\'t add RequestCategories! RequestCategories with same name and parent already exists.'
        );
        return;
    }

    return if !$DBObject->Do(
        SQL => 'INSERT INTO requestcategories '
            . '(name, valid_id, comments, image_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{Comment}, \$Param{ImageID},
            \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get RequestCategories id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM requestcategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $RequestCategoriesID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestCategoriesID = $Row[0];
    }

    return $RequestCategoriesID;
}

=item RequestCategoriesUpdate()

update a existing RequestCategories

    my $True = $RequestCategoriesObject->RequestCategoriesUpdate(
        RequestCategoriesID => 123,
        ParentID  => 1,           # (optional)
        Name      => 'RequestCategories Name',
        ValidID   => 1,
        Comment   => 'Comment',    # (optional)
        ImageID   => 1,           # (optional)
        UserID    => 1,
    );

=cut

sub RequestCategoriesUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(RequestCategoriesID Name ValidID UserID)) {
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

    # check RequestCategories name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Can't update RequestCategories! Invalid RequestCategories name '$Param{Name}'!",
        );
        return;
    }

    # get old name of RequestCategories
    my $OldRequestCategoriesName
        = $Self->RequestCategoriesLookup( RequestCategoriesID => $Param{RequestCategoriesID}, );

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {

        # lookup RequestCategories
        my $ParentName = $Self->RequestCategoriesLookup(
            RequestCategoriesID => $Param{ParentID},
        );

        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }

        # check, if selected parent was a child of this RequestCategories
        if ( $Param{FullName} =~ m{ \A ( \Q$OldRequestCategoriesName\E ) :: }xms ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Can\'t update RequestCategories! Invalid parent was selected.'
            );
            return;
        }
    }

    # find exists RequestCategories
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM requestcategories WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{RequestCategoriesID} ne $Row[0] ) {
            $Exists = 1;
        }
    }

    # update RequestCategories
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                'Can\'t update RequestCategories! RequestCategories with same name and parent already exists.'
        );
        return;

    }

    # update RequestCategories
    return if !$DBObject->Do(
        SQL => 'UPDATE requestcategories SET name = ?, valid_id = ?, comments = ?, image_id = ?,'
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{Comment}, \$Param{ImageID},
            \$Param{UserID}, \$Param{RequestCategoriesID},
        ],
    );

    # find all childs
    $DBObject->Prepare(
        SQL => "SELECT id, name FROM requestcategories WHERE name LIKE '"
            . $DBObject->Quote( $OldRequestCategoriesName, 'Like' )
            . "::%'",
    );
    my @Childs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Child;
        $Child{RequestCategoriesID} = $Row[0];
        $Child{Name}               = $Row[1];
        push @Childs, \%Child;
    }

    # update childs
    for my $Child (@Childs) {
        $Child->{Name} =~ s{ \A ( \Q$OldRequestCategoriesName\E ) :: }{$Param{FullName}::}xms;
        $DBObject->Do(
            SQL => 'UPDATE requestcategories SET name = ? WHERE id = ?',
            Bind => [ \$Child->{Name}, \$Child->{RequestCategoriesID} ],
        );
    }
    return 1;
}

=item RequestCategoriesSearch()

return RequestCategories ids as an array

    my @RequestCategoriesList = $RequestCategoriesObject->RequestCategoriesSearch(
        Name   => 'RequestCategories Name', # (optional)
        Limit  => 122,            # (optional) default 1000
        UserID => 1,
    );

=cut

sub RequestCategoriesSearch {
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
        = "SELECT id FROM requestcategories WHERE valid_id IN ( ${\(join ', ', $Self->{ValidObject}->ValidIDsGet())} )";

    if ( $Param{Name} ) {

        # quote
        $Param{Name} = $DBObject->Quote( $Param{Name}, 'Like' );

        # replace * with % and clean the string
        $Param{Name} =~ s{ \*+ }{%}xmsg;
        $Param{Name} =~ s{ %+ }{%}xmsg;

        $SQL .= " AND name LIKE '$Param{Name}' ";
    }

    $SQL .= ' ORDER BY name';

    # search RequestCategories in db
    $DBObject->Prepare( SQL => $SQL );

    my @RequestCategoriesList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @RequestCategoriesList, $Row[0];
    }

    return @RequestCategoriesList;
}

=item RequestCategoriesTemplateAdd()

add a RequestCategoriesTemplate

    my $RequestCategoriesTemplateID = $RequestCategoriesObject->RequestCategoriesTemplateAdd(
        TemplateID         => 2,
        RequestCategoriesID => 1,
        UserID             => 1,
    );

=cut

sub RequestCategoriesTemplateAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID RequestCategoriesID UserID)) {
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
        SQL => 'INSERT INTO requestcategories_request '
            . '(template_id, requestcategories_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TemplateID}, \$Param{RequestCategoriesID},
            \$Param{UserID},     \$Param{UserID},
        ],
    );

    # get RequestCategories id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM requestcategories_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );
    my $RequestCategoriesTemplateID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestCategoriesTemplateID = $Row[0];
    }

    return $RequestCategoriesTemplateID;
}

=item RequestCategoriesTemplateList()

return a hash list of Antrag

    my %RequestCategoriesTemplateList = $RequestCategoriesObject->RequestCategoriesTemplateList(
        RequestCategoriesID  => 1,
        UserID              => 1,
    );

=cut

sub RequestCategoriesTemplateList {
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
    if ( !$Param{RequestCategoriesID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need RequestCategoriesID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL =>
            "SELECT id, template_id FROM requestcategories_request WHERE requestcategories_id = $Param{RequestCategoriesID}",
    );

    # fetch the result
    my %RequestCategoriesTemplateList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestCategoriesTemplateList{ $Row[0] } = $Row[1];
    }

    return %RequestCategoriesTemplateList;
}

=item RequestCategoriesTemplateUpdate()

update a RequestCategoriesTemplate

    my $RequestCategoriesTemplateID = $RequestCategoriesObject->RequestCategoriesTemplateUpdate(
        TemplateID         => 2,
        RequestCategoriesID => 1,
        UserID             => 1,
    );

=cut

sub RequestCategoriesTemplateUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(TemplateID RequestCategoriesID UserID)) {
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

    # get RequestCategories from db
    $DBObject->Prepare(
        SQL =>
            'SELECT id FROM requestcategories_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );

    # fetch the result
    my $CheckTemplate;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $CheckTemplate = $Row[0];
    }

    if ($CheckTemplate) {

        # update RequestCategories
        return if !$DBObject->Do(
            SQL => 'UPDATE requestcategories_request SET template_id = ?, requestcategories_id = ?, '
                . ' change_time = current_timestamp, change_by = ? WHERE template_id = ?',
            Bind => [
                \$Param{TemplateID}, \$Param{RequestCategoriesID},
                \$Param{UserID},     \$Param{TemplateID},
            ],
        );
    }
    else {

        return if !$DBObject->Do(
            SQL => 'INSERT INTO requestcategories_request '
                . '(template_id, requestcategories_id, create_time, create_by, change_time, change_by) '
                . 'VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$Param{TemplateID}, \$Param{RequestCategoriesID},
                \$Param{UserID},     \$Param{UserID},
            ],
        );

    }

    # get RequestCategories id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM requestcategories_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );
    my $RequestCategoriesTemplateID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestCategoriesTemplateID = $Row[0];
    }

    return $RequestCategoriesTemplateID;
}

=item RequestCategoriesTemplateGet()

return a RequestCategoriesID

Return
    $RequestCategoriesID

    my $RequestCategoriesID = $RequestCategoriesObject->RequestCategoriesTemplateGet(
        TemplateID => 123,
        UserID     => 1,
    );

=cut

sub RequestCategoriesTemplateGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # either RequestCategoriesID or Name must be passed
    if ( !$Param{TemplateID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TemplateID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get RequestCategories from db
    $DBObject->Prepare(
        SQL =>
            'SELECT requestcategories_id '
            . 'FROM requestcategories_request WHERE template_id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );

    # fetch the result
    my $RequestCategoriesID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $RequestCategoriesID = $Row[0];

    }

    # check RequestCategories
    if ( !$RequestCategoriesID ) {
        return;
    }

    return $RequestCategoriesID;
}

=item RequestCategoriesTemplateDelete()

    my $Success = $RequestCategoriesObject->RequestCategoriesTemplateDelete(
        TemplateID => 123,
        UserID     => 123,
    );

Events:
    RequestCategoriesTemplateDelete

=cut

sub RequestCategoriesTemplateDelete {
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
        SQL  => 'DELETE FROM requestcategories_request WHERE template_id = ?',
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
