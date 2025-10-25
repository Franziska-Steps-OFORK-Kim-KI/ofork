# --
# Kernel/System/TimeTrackingArticle.pm - the time tracking lib
# Copyright (C) 2010-2025 OFORK, https://o-fork.de/
# --
# $Id: TimeTrackingArticle.pm,v 1.3 2019/08/21 10:06:06 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TimeTrackingArticle;

use strict;
use warnings;

use MIME::Base64;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SysConfig',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::TimeTrackingArticle - TimeTrackingArticle lib

=head1 DESCRIPTION

All type functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $TimeTrackingArticleObject = $Kernel::OM->Get('Kernel::System::TimeTrackingArticle');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 TimeTrackingArticleAdd()

add a new ticket type

    my $ID = $TimeTrackingArticleObject->TimeTrackingArticleAdd(
        TicketID         => 123,
        CustomerID       => 123,
        TimeTrackingID   => 123,
        TimeTrackingTime => 10,
        Subject          => 'New Type',
        Body             => 'New Type',
        CreateTime       => '2019-08-08 12:12:00',
        UserID           => 123,
    );

=cut

sub TimeTrackingArticleAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(TicketID TimeTrackingID TimeTrackingTime UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    $Param{Seen} = '0';

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL =>
            'INSERT INTO time_tracking_article (ticket_id, customer_id, time_tracking_id, time_tracking_time, '
            . ' subject, create_time, create_by, change_time, change_by, seen)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, ?)',
        Bind => [
            \$Param{TicketID}, \$Param{CustomerID}, \$Param{TimeTrackingID},
            \$Param{TimeTrackingTime},
            \$Param{Subject}, \$Param{CreateTime}, \$Param{UserID}, \$Param{UserID}, \$Param{Seen},
        ],
    );

    return 1;
}

=head2 TimeTrackingArticleGet()

get attributes

    my %TimeTrackingArticle = $TimeTrackingArticleObject->TimeTrackingArticleGet(
        ID => 123,
    );

Returns:

    TimeTrackingArticle = (
        ID               => 123,
        TicketID         => 123,
        TimeTrackingID   => 123,
        CustomerID       => 123,
        TimeTrackingTime => 10,
        Subject          => 'New Type',
        CreateTime       => '2010-04-07 15:41:15',
        CreateBy         => '321',
        ChangeTime       => '2010-04-07 15:59:45',
        ChangeBy         => '223',
        Seen             => '1',
    );

=cut

sub TimeTrackingArticleGet {
    my ( $Self, %Param ) = @_;

    # either ID must be passed
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask the database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, ticket_id, customer_id, time_tracking_id, time_tracking_time, subject, '
            . 'create_time, create_by, change_time, change_by, seen, content_type, content, filename '
            . 'FROM time_tracking_article WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # fetch the result
    my %TimeTrackingArticle;
    while ( my @Data = $DBObject->FetchrowArray() ) {

        # decode attachment if it's a postgresql backend!!!
        if ( !$DBObject->GetDatabaseFunction('DirectBlob') ) {
            $Data[12] = decode_base64( $Data[12] );
        }

        $TimeTrackingArticle{ID}               = $Data[0];
        $TimeTrackingArticle{TicketID}         = $Data[1];
        $TimeTrackingArticle{CustomerID}       = $Data[2];
        $TimeTrackingArticle{TimeTrackingID}   = $Data[3];
        $TimeTrackingArticle{TimeTrackingTime} = $Data[4];
        $TimeTrackingArticle{Subject}          = $Data[5];
        $TimeTrackingArticle{CreateTime}       = $Data[6];
        $TimeTrackingArticle{CreateBy}         = $Data[7];
        $TimeTrackingArticle{ChangeTime}       = $Data[8];
        $TimeTrackingArticle{ChangeBy}         = $Data[9];
        $TimeTrackingArticle{Seen}             = $Data[10];
        $TimeTrackingArticle{ContentType}      = $Data[11];
        $TimeTrackingArticle{Content}          = $Data[12];
        $TimeTrackingArticle{Filename}         = $Data[13];
    }

    # no data found
    if ( !%TimeTrackingArticle ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "TimeTrackingArticle '$Param{ID}' not found!",
        );
        return;
    }

    return %TimeTrackingArticle;
}

=head2 TimeTrackingArticleUpdate()

update attributes

    $TimeTrackingArticleObject->TimeTrackingArticleUpdate(
        ID               => 123,
        TimeTrackingID   => 1,
        TimeTrackingTime => 10,
        Subject          => 'New Type',
        CreateTime       => '2010-04-07 15:41:15',
        UserID           => '223',
    );

=cut

sub TimeTrackingArticleUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ID TimeTrackingID TimeTrackingTime UserID)) {
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
        SQL =>
            'UPDATE time_tracking_article SET time_tracking_id = ?, time_tracking_time = ?, subject = ?, create_time = ?, '
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{TimeTrackingID}, \$Param{TimeTrackingTime}, \$Param{Subject},
            \$Param{CreateTime},
            \$Param{UserID}, \$Param{ID},
        ],
    );

    return 1;
}

=head2 TimeTrackingArticleUpdateSeen()

update attributes

    $TimeTrackingArticleObject->TimeTrackingArticleUpdateSeen(
        ID => 123,
    );

=cut

sub TimeTrackingArticleUpdateSeen {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    $Param{Seen} = 1;

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL =>
            'UPDATE time_tracking_article SET seen = ? WHERE id = ?',
        Bind => [
            \$Param{Seen}, \$Param{ID},
        ],
    );

    return 1;
}

=head2 TimeTrackingArticleList()

get list

    my %TimeTrackingArticleList = $TimeTrackingArticleObject->TimeTrackingArticleList(
        TicketID => 1,
    );

=cut

sub TimeTrackingArticleList {
    my ( $Self, %Param ) = @_;

    # either ID must be passed
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask the database
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id, ticket_id FROM time_tracking_article WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    # fetch the result
    my %TimeTrackingArticleList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $TimeTrackingArticleList{ $Row[0] } = $Row[1];
    }

    return %TimeTrackingArticleList;
}

=item TimeTrackingArticleStats()

return a hash list of Request

    my TimeTrackingArticleSearch = $TimeTrackingArticleObject->TimeTrackingArticleStats(
        CustomerID => 'CustomerID',
        Start      => 123456789,
        End        => 123456789,
    );

=cut

sub TimeTrackingArticleStats {
    my ( $Self, %Param ) = @_;

    my $SQLSearch = "ORDER BY ticket_id ASC";

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( !$Param{CustomerID} || $Param{CustomerID} eq '' ) {

        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, ticket_id FROM time_tracking_article WHERE create_time >= ? AND create_time <= ? AND ( customer_id LIKE '%@%' OR customer_id IS NULL OR customer_id = '') $SQLSearch",
            Bind => [ \$Param{Start}, \$Param{End}, ],
        );
    }
    else {

        return if !$DBObject->Prepare(
            SQL =>
                "SELECT id, ticket_id FROM time_tracking_article WHERE create_time >= ? AND create_time <= ? AND customer_id LIKE '%"
                . $Param{CustomerID}
                . "%' $SQLSearch",
            Bind => [ \$Param{Start}, \$Param{End}, ],
        );
    }

    # fetch the result
    my @TimeTrackingList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @TimeTrackingList, $Row[0];
    }

    return @TimeTrackingList;
}

=head2 TimeTrackingArticleUnterschrift()

update attributes

    $TimeTrackingArticleObject->TimeTrackingArticleUnterschrift(
        TicketID    => 123,
        ID          => 1,
        Content     => $Content,
        ContentType => 'text/xml',
        Filename    => 'SomeFile.xml',
        UserID      => '223',
    );

=cut

sub TimeTrackingArticleUnterschrift {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(TicketID ID UserID)) {
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

    # encode attachment if it's a postgresql backend!!!
    if ( !$DBObject->GetDatabaseFunction('DirectBlob') ) {
        $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput( \$Param{Content} );
        $Param{Content} = encode_base64( $Param{Content} );
    }

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL =>
            'UPDATE time_tracking_article SET content_type = ?, content = ?, filename = ?  WHERE ticket_id = ? AND id = ?',
        Bind => [
            \$Param{ContentType}, \$Param{Content}, \$Param{Filename}, \$Param{TicketID}, \$Param{ID},
        ],
    );

    return 1;
}

=head2 TimeTrackingArticleUnterschriftDelete()

update attributes

    $TimeTrackingArticleObject->TimeTrackingArticleUnterschriftDelete(
        ID       => 123,
        TicketID => 123,
    );

=cut

sub TimeTrackingArticleUnterschriftDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw( ID )) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    $Param{ContentType} = '';
    $Param{Content}     = '';
    $Param{Filename}    = '';

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL =>
            'UPDATE time_tracking_article SET content_type = ?, content = ?, filename = ?  WHERE id = ?',
        Bind => [
            \$Param{ContentType}, \$Param{Content}, \$Param{Filename}, \$Param{ID},
        ],
    );

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
