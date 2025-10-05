# --
# scripts/DBUpdateTo11/CreateRequestFormTables.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: CreateRequestFormTables.pm,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --

package scripts::DBUpdateTo11::CreateRequestFormTables;

use strict;
use warnings;

use parent qw(scripts::DBUpdateTo11::Base);

our @ObjectDependencies = ();

=head1 NAME

scripts::DBUpdateTo11::CreateRequestFormTables - Create request form tables.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $Verbose = $Param{CommandlineOptions}->{Verbose} || 0;

    # Define the XML data for the form draft table.
    my @XMLStrings = (
        '<TableCreate Name="request">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="comment" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="queue_id" Required="true" Type="INTEGER" />
            <Column Name="type_id" Required="true" Type="INTEGER" />
            <Column Name="image_id" Required="false" Type="INTEGER" />
            <Column Name="show_configitem" Required="false" Type="INTEGER" />
            <Column Name="ticket_owner" Required="false" Type="INTEGER" />
            <Column Name="ticket_responsible" Required="false" Type="INTEGER" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="subject" Required="false" Size="2000" Type="VARCHAR" />
            <Column Name="subject_changeable" Required="false" Type="SMALLINT" />
            <Column Name="show_configitems" Required="false" Size="200" Type="VARCHAR" />
            <Column Name="show_attachment" Required="false" Type="INTEGER" />
            <Column Name="request_group" Required="false" Type="INTEGER" />
            <Column Name="process_id" Required="false" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="requestcategories">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="comments" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="image_id" Required="false" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="request_categories_icon">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="content_type" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="content" Required="true" Size="1000" Type="LONGBLOB" />
            <Column Name="filename" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="comments " Required="false" Size="250" Type="VARCHAR" />
            <Column Name="valid_id" Required="false" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="requestcategories_request">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="template_id" Required="true" Type="INTEGER" />
            <Column Name="requestcategories_id" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="request_fields">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="typ" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="name" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="label" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="defaultvalue" Required="false" Size="1000" Type="VARCHAR" />
            <Column Name="feld_rows" Required="false" Type="SMALLINT" />
            <Column Name="feld_cols" Required="false" Type="SMALLINT" />
            <Column Name="leer_wert" Required="false" Type="SMALLINT" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="request_fields_value">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="feld_id" Required="true" Type="INTEGER" />
            <Column Name="inhalt" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="schluessel" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="request_form">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="request_id" Required="true" Type="INTEGER" />
            <Column Name="feld_id" Required="false" Type="INTEGER" />
            <Column Name="requiredfield" Required="false" Type="SMALLINT" />
            <Column Name="orders" Required="true" Type="INTEGER" />
            <Column Name="move_over" Required="false" Size="3800" Type="VARCHAR" />
            <Column Name="tool_tip" Required="false" Type="SMALLINT" />
            <Column Name="headline" Required="false" Size="1000" Type="VARCHAR" />
            <Column Name="beschreibung" Required="false" Size="3800" Type="VARCHAR" />
            <Column Name="valid_id" Required="false" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="article_flag_customer">
            <Column Name="article_id" Required="true" Type="BIGINT"/>
            <Column Name="article_key" Required="true" Size="50" Type="VARCHAR"/>
            <Column Name="article_value" Required="false" Size="50" Type="VARCHAR"/>
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="user_id" Required="true" Size="250" Type="VARCHAR"/>
        </TableCreate>',
        '<TableCreate Name="ticket_flag_customer">
            <Column Name="ticket_id" Required="true" Type="BIGINT"/>
            <Column Name="ticket_key" Required="true" Size="50" Type="VARCHAR"/>
            <Column Name="ticket_value" Required="false" Size="50" Type="VARCHAR"/>
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="user_id" Required="true" Size="250" Type="VARCHAR"/>
        </TableCreate>',
        '<TableCreate Name="request_form_block">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="request_form_id" Required="true" Type="INTEGER" />
            <Column Name="request_form_value" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="request_id" Required="true" Type="INTEGER" />
            <Column Name="feld_id" Required="false" Type="INTEGER" />
            <Column Name="requiredfield" Required="false" Type="SMALLINT" />
            <Column Name="orders" Required="true" Type="INTEGER" />
            <Column Name="move_over" Required="false" Size="3800" Type="VARCHAR" />
            <Column Name="headline" Required="false" Size="1000" Type="VARCHAR" />
            <Column Name="beschreibung" Required="false" Size="3800" Type="VARCHAR" />
            <Column Name="valid_id" Required="false" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="ticket_id_request">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="request_id" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="ticket_request">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="antrag_id" Required="true" Type="INTEGER" />
            <Column Name="feld_key" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="feld_value" Required="false" Size="3800" Type="VARCHAR" />
            <Column Name="feld_beschriftung" Required="false" Size="1000" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="request_groups">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="comments " Required="false" Size="250" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="request_group_customer_user">
            <Column Name="user_id" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="group_id" Required="true" Type="INTEGER" />
            <Column Name="permission_key" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="permission_value" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableAlter Name="queue">
            <ColumnAdd Name="sw_id" Required="false" Type="INTEGER"/>
        </TableAlter>',
        '<TableAlter Name="request_form">
            <ColumnAdd Name="tool_tip" Required="false" Type="SMALLINT"/>
        </TableAlter>',
        '<TableAlter Name="requestcategories">
            <ColumnAdd Name="image_id" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="ticket_owner" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="ticket_responsible" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="image_id" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="show_configitem" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="subject" Required="false" Size="2000" Type="VARCHAR" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="show_configitems" Required="false" Size="200" Type="VARCHAR" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="show_attachment" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="request_group" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="request">
            <ColumnAdd Name="subject_changeable" Required="false" Type="SMALLINT" />
        </TableAlter>',
        '<TableCreate Name="roomcategories">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="2000" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="comments " Required="false" Size="2000" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="rooms">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="categories_id" Required="true" Type="INTEGER" />
            <Column Name="categories" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="room" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="building" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="floor" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="street" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="post_code" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="city" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="calendar" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="setup_time" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="persons" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="price" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="price_for" Required="false" Type="SMALLINT" />
            <Column Name="currency" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="equipment_bookable" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="equipment" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="description" Required="false" Size="2000" Type="VARCHAR" />
            <Column Name="queue_booking" Required="false" Type="INTEGER" />
            <Column Name="queue_device" Required="false" Type="INTEGER" />
            <Column Name="queue_catering" Required="false" Type="INTEGER" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="comment " Required="false" Size="250" Type="VARCHAR" />
            <Column Name="image_id" Required="false" Type="INTEGER" />
            <Column Name="room_color " Required="false" Size="250" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="room_booking">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="room_id" Required="true" Type="INTEGER" />
            <Column Name="participant" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="subject" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="body" Required="false" Size="10000" Type="VARCHAR"/>
            <Column Name="from_time" Required="true" Type="DATE" />
            <Column Name="to_time" Required="true" Type="DATE" />
            <Column Name="toend_time" Required="true" Type="DATE" />
            <Column Name="email_list" Required="false" Size="2000" Type="VARCHAR"/>
            <Column Name="equipment_order" Required="false" Size="2000" Type="VARCHAR"/>
            <Column Name="cal_uid" Required="true" Size="2000" Type="VARCHAR"/>
            <Column Name="sequence" Required="true" Type="SMALLINT" />
            <Column Name="qb_tid" Required="false" Type="INTEGER" />
            <Column Name="qd_tid" Required="false" Type="INTEGER" />
            <Column Name="qc_tid" Required="false" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Size="250" Type="VARCHAR" />
        </TableCreate>',
        '<TableCreate Name="room_equipments">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="quantity" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="equipment_type" Required="false" Type="SMALLINT" />
            <Column Name="price" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="price_for" Required="false" Type="SMALLINT" />
            <Column Name="currency" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="model" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="bookable" Required="true" Type="SMALLINT" />
            <Column Name="comments" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="room_icon">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="content_type" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="content" Required="true" Size="1000" Type="LONGBLOB" />
            <Column Name="filename" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="comments" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="valid_id" Required="false" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="checklist">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="queue_id" Required="false" Type="INTEGER" />
            <Column Name="type_id" Required="false" Type="INTEGER" />
            <Column Name="service_id" Required="false" Type="INTEGER" />
            <Column Name="queue_ids" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="type_ids" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="service_ids" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="set_article" Required="true" Type="SMALLINT" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="comment" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="checklist_field">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="checklist_id" Required="true" Type="INTEGER" />
            <Column Name="task" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="fieldorder" Required="true" Type="INTEGER" />
            <Column Name="field_type" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="checklist_field_value">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="checklist_id" Required="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="task" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="field_type" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="fieldorder" Required="true" Type="INTEGER" />
            <Column Name="if_set" Required="false" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableAlter Name="checklist">
            <ColumnAdd Name="queue_ids" Required="false" Size="250" Type="VARCHAR" />
        </TableAlter>',
        '<TableAlter Name="checklist">
            <ColumnAdd Name="type_ids" Required="false" Size="250" Type="VARCHAR" />
        </TableAlter>',
        '<TableAlter Name="checklist">
            <ColumnAdd Name="service_ids" Required="false" Size="250" Type="VARCHAR" />
        </TableAlter>',
        '<TableCreate Name="calendar_team">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="group_id" Required="true" Type="INTEGER" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="comments" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="calendar_team_user">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="team_id" Required="true" Type="INTEGER" />
            <Column Name="user_id" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="tracking_category">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="time_tracking_article">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="customer_id" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="time_tracking_id" Required="true" Type="SMALLINT" />
            <Column Name="time_tracking_time" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="subject" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="seen" Required="false" Type="INTEGER" />
            <Column Name="content_type" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="content" Required="false" Size="1000" Type="LONGBLOB" />
            <Column Name="filename" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableAlter Name="time_tracking_article">
            <ColumnAdd Name="seen" Required="false" Type="INTEGER" />
            <ColumnAdd Name="content_type" Required="false" Size="250" Type="VARCHAR" />
            <ColumnAdd Name="content" Required="false" Size="1000" Type="LONGBLOB" />
            <ColumnAdd Name="filename" Required="false" Size="250" Type="VARCHAR" />
        </TableAlter>',
        '<Table Name="dynamicprocess_fields">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="dynamicfield_id" Required="true" Type="INTEGER" />
            <Column Name="required" Required="false" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="process_conditions">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_no" Required="true" Type="INTEGER" />
            <Column Name="title" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="type" Required="false" Type="INTEGER" />
            <Column Name="queue" Required="false" Type="INTEGER" />
            <Column Name="state" Required="false" Type="INTEGER" />
            <Column Name="service" Required="false" Type="INTEGER" />
            <Column Name="sla" Required="false" Type="INTEGER" />
            <Column Name="customer_user" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="owner" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="process_d_conditions">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="dynamicfield_id" Required="true" Type="INTEGER" />
            <Column Name="dynamicfield_value" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="process_fields">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="field_id" Required="true" Type="INTEGER" />
            <Column Name="required" Required="true" Type="SMALLINT" />
            <Column Name="sequence" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="process_list">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="description" Required="true" Size="5000" Type="VARCHAR" />
            <Column Name="queue_id" Required="true" Type="INTEGER" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="process_step">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="process_step" Required="true" Type="INTEGER" />
            <Column Name="step_no" Required="true" Type="INTEGER" />
            <Column Name="step_no_from" Required="true" Type="INTEGER" />
            <Column Name="to_id_from_one" Required="false" Type="INTEGER" />
            <Column Name="to_id_from_two" Required="false" Type="INTEGER" />
            <Column Name="step_no_to" Required="false" Type="INTEGER" />
            <Column Name="process_color" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="description" Required="false" Size="5000" Type="VARCHAR" />
            <Column Name="group_id" Required="true" Type="INTEGER" />
            <Column Name="stepart_id" Required="true" Type="INTEGER" />
            <Column Name="step_end" Required="false" Type="SMALLINT" />
            <Column Name="with_conditions_end" Required="false" Type="SMALLINT" />
            <Column Name="without_conditions_end" Required="false" Type="SMALLINT" />
            <Column Name="not_approved" Required="false" Type="SMALLINT" />
            <Column Name="approver_id" Required="false" Type="INTEGER" />
            <Column Name="approver_email" Required="false" Size="5000" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
            <Column Name="with_conditions" Required="false" Type="SMALLINT" />
            <Column Name="parallel_step" Required="false" Type="INTEGER" />
            <Column Name="set_parallel" Required="false" Type="INTEGER" />
            <Column Name="parallel_se" Required="false" Type="INTEGER" />
            <Column Name="notify_agent" Required="false" Size="250" Type="VARCHAR" />
        </Table>',
        '<Table Name="process_transition">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_no" Required="true" Type="INTEGER" />
            <Column Name="step_no" Required="true" Type="INTEGER" />
            <Column Name="type_id" Required="false" Type="INTEGER" />
            <Column Name="state_id" Required="false" Type="INTEGER" />
            <Column Name="queue_id" Required="false" Type="INTEGER" />
            <Column Name="service_id" Required="false" Type="INTEGER" />
            <Column Name="sla_id" Required="false" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="t_dynamicprocess_fields">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="dynamicfield_id" Required="true" Type="INTEGER" />
            <Column Name="required" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="t_dynamicprocess_fields_value">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="process_step_id" Required="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="dynamicfield_id" Required="true" Type="INTEGER" />
            <Column Name="field_value" Required="true" Size="5000" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="t_process_conditions">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_no" Required="true" Type="INTEGER" />
            <Column Name="title" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="type" Required="false" Type="INTEGER" />
            <Column Name="queue" Required="false" Type="INTEGER" />
            <Column Name="state" Required="false" Type="INTEGER" />
            <Column Name="service" Required="false" Type="INTEGER" />
            <Column Name="sla" Required="false" Type="INTEGER" />
            <Column Name="customer_user" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="owner" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="t_process_d_conditions">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="dynamicfield_id" Required="true" Type="INTEGER" />
            <Column Name="dynamicfield_value" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="t_process_fields">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="field_id" Required="true" Type="INTEGER" />
            <Column Name="required" Required="true" Type="SMALLINT" />
            <Column Name="sequence" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="t_process_fields_value">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="process_step_id" Required="true" Type="INTEGER" />
            <Column Name="report" Required="true" Size="5000" Type="VARCHAR" />
            <Column Name="title" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="type_id" Required="false" Type="INTEGER" />
            <Column Name="queue_id" Required="false" Type="INTEGER" />
            <Column Name="state_id" Required="false" Type="INTEGER" />
            <Column Name="from_customer" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="user_id" Required="false" Type="INTEGER" />
            <Column Name="approval" Required="false" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="t_process_list">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="description" Required="true" Size="5000" Type="VARCHAR" />
            <Column Name="queue_id" Required="true" Type="INTEGER" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="ready" Required="false" Type="SMALLINT" />
        </Table>',
        '<Table Name="t_process_merge">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="old_id" Required="true" Type="INTEGER" />
            <Column Name="new_id" Required="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="t_process_step">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="process_step" Required="true" Type="INTEGER" />
            <Column Name="step_no" Required="true" Type="INTEGER" />
            <Column Name="step_no_from" Required="true" Type="INTEGER" />
            <Column Name="to_id_from_one" Required="false" Type="INTEGER" />
            <Column Name="to_id_from_two" Required="false" Type="INTEGER" />
            <Column Name="step_no_to" Required="false" Type="INTEGER" />
            <Column Name="process_color" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="description" Required="false" Size="5000" Type="VARCHAR" />
            <Column Name="group_id" Required="true" Type="INTEGER" />
            <Column Name="stepart_id" Required="true" Type="INTEGER" />
            <Column Name="step_end" Required="false" Type="SMALLINT" />
            <Column Name="with_conditions_end" Required="false" Type="SMALLINT" />
            <Column Name="without_conditions_end" Required="false" Type="SMALLINT" />
            <Column Name="not_approved" Required="false" Type="SMALLINT" />
            <Column Name="approver_id" Required="false" Type="INTEGER" />
            <Column Name="approver_email" Required="false" Size="5000" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
            <Column Name="with_conditions" Required="false" Type="SMALLINT" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
            <Column Name="ready" Required="false" Type="SMALLINT" />
            <Column Name="step_active" Required="false" Type="SMALLINT" />
            <Column Name="parallel_step" Required="false" Type="INTEGER" />
            <Column Name="set_parallel" Required="false" Type="INTEGER" />
            <Column Name="notify_agent" Required="false" Size="250" Type="VARCHAR" />
        </Table>',
        '<Table Name="t_process_transition">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="process_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_id" Required="true" Type="INTEGER" />
            <Column Name="processstep_no" Required="true" Type="INTEGER" />
            <Column Name="step_no" Required="true" Type="INTEGER" />
            <Column Name="type_id" Required="false" Type="INTEGER" />
            <Column Name="state_id" Required="false" Type="INTEGER" />
            <Column Name="queue_id" Required="false" Type="INTEGER" />
            <Column Name="service_id" Required="false" Type="INTEGER" />
            <Column Name="sla_id" Required="false" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
            <Column Name="ticket_id" Required="true" Type="INTEGER" />
        </Table>',
        '<TableAlter Name="ticket">
            <ColumnAdd Name="process_id" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="t_process_list">
            <ColumnAdd Name="setarticle_id" Required="true" Type="SMALLINT" />
        </TableAlter>',
        '<TableAlter Name="t_process_step">
            <ColumnAdd Name="setarticle_id" Required="true" Type="SMALLINT" />
        </TableAlter>',
        '<TableAlter Name="t_process_step">
            <ColumnAdd Name="set_parallel" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="process_list">
            <ColumnAdd Name="setarticle_id" Required="true" Type="SMALLINT" />
        </TableAlter>',
        '<TableAlter Name="process_step">
            <ColumnAdd Name="setarticle_id" Required="true" Type="SMALLINT" />
        </TableAlter>',
        '<TableAlter Name="process_step">
            <ColumnAdd Name="set_parallel" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="process_step">
            <ColumnAdd Name="parallel_se" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="t_process_fields_value">
            <ColumnChange NameOld="user" NameNew="user_id" Type="INTEGER" Required="false" />
        </TableAlter>',
        '<TableAlter Name="calendar_appointment">
            <ColumnAdd Name="queue_id" Required="false" Type="INTEGER" />
            <ColumnAdd Name="ticket_user_id" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<Table Name="signature_user">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="user_login" Required="true" Type="INTEGER" />
            <Column Name="signature_id" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="standard_templ_request_field">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="standard_request_field_id" Required="true" Type="INTEGER" />
            <Column Name="standard_template_id" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="contractualpartner">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="company" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="street" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="postcode" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="city" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="country" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="phone" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="contactperson" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="e_mail" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="description" Required="false" Size="2000" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="contracttype">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="comments" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="contractdevice">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="contract_id" Required="true" Type="INTEGER" />
            <Column Name="device_name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="device_number" Required="false" Type="INTEGER" />
            <Column Name="ticket_create" Required="false" Type="INTEGER" />
            <Column Name="queue_id" Required="false" Type="INTEGER" />
            <Column Name="notification" Required="false" Type="DATE" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="contract">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="cp_id" Required="false" Type="INTEGER" />
            <Column Name="customer_id" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="customeruser_id" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="direction" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="contracttype_id" Required="true" Type="INTEGER" />
            <Column Name="contractnumber" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="description" Required="false" Size="20000" Type="VARCHAR" />
            <Column Name="contractstart" Required="false" Type="DATE" />
            <Column Name="contractend" Required="false" Type="DATE" />
            <Column Name="service_id" Required="false" Type="INTEGER" />
            <Column Name="sla_id" Required="false" Type="INTEGER" />
            <Column Name="price" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="paymentmethod" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="noticeperiod" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="ticket_create" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="memory" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="memory_time" Required="false" Type="DATE" />
            <Column Name="notification" Required="false" Type="DATE" />
            <Column Name="queue_id" Required="false" Type="INTEGER" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<Table Name="handover">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="contract_id" Required="true" Type="INTEGER" />
            <Column Name="handover" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="handoverdate" Required="true" Type="DATE" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </Table>',
        '<TableAlter Name="request">
            <ColumnAdd Name="process_id" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="process_step">
            <ColumnAdd Name="parallel_step" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="t_process_step">
            <ColumnAdd Name="parallel_step" Required="false" Type="INTEGER" />
        </TableAlter>',
        '<TableAlter Name="process_step">
            <ColumnAdd Name="notify_agent" Required="false" Size="250" Type="VARCHAR" />
        </TableAlter>',
        '<TableAlter Name="t_process_step">
            <ColumnAdd Name="notify_agent" Required="false" Size="250" Type="VARCHAR" />
        </TableAlter>',
        '<TableCreate Name="selfservicecategories">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="color" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="comments" Required="true" Size="1000" Type="VARCHAR" />
            <Column Name="valid_id" Required="true" Type="SMALLINT" />
            <Column Name="image_id" Required="false" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="selfservice_categories_icon">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="name" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="content_type" Required="true" Size="250" Type="VARCHAR" />
            <Column Name="content" Required="true" Size="1000" Type="LONGBLOB" />
            <Column Name="filename" Required="false" Size="250" Type="VARCHAR" />
            <Column Name="comments " Required="false" Size="250" Type="VARCHAR" />
            <Column Name="valid_id" Required="false" Type="SMALLINT" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
        '<TableCreate Name="selfservicecat_selfservice">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER" />
            <Column Name="template_id" Required="true" Type="INTEGER" />
            <Column Name="selfservicecategories_id" Required="true" Type="INTEGER" />
            <Column Name="create_time" Required="true" Type="DATE" />
            <Column Name="create_by" Required="true" Type="INTEGER" />
            <Column Name="change_time" Required="true" Type="DATE" />
            <Column Name="change_by" Required="true" Type="INTEGER" />
        </TableCreate>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OFORK project (L<https://o-fork.de/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
