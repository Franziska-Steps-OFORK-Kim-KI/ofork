# --
# Kernel/Modules/AdminRequestFieldsContent.pm
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# --
# $Id: AdminRequestFieldsContent.pm,v 1.4 2016/09/20 12:33:58 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminRequestFieldsContent;

use strict;
use warnings;

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

    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RequestFieldsObject = $Kernel::OM->Get('Kernel::System::RequestFields');
    my $ValidObject        = $Kernel::OM->Get('Kernel::System::Valid');

    # get params
    my %GetParam = ();
    for (
        qw( FeldID Schluessel Inhalt WertID )
        )
    {
        $GetParam{$_} = $ParamObject->GetParam( Param => $_ );
    }

    my %RequestFieldsListe;

    if (
        $Self->{Subaction}    eq "Liste"
        || $Self->{Subaction} eq "Dropdown"
        || $Self->{Subaction} eq "Multiselect"
        )
    {

        #get list
        %RequestFieldsListe = $RequestFieldsObject->RequestFieldsWerteList(
            FeldID => $GetParam{FeldID},
        );

    }

    if ( $Self->{Subaction} eq "NeuerWert" ) {

        #generate new
        $RequestFieldsObject->RequestFieldsWertAdd(
            FeldID     => $GetParam{FeldID},
            Schluessel => $GetParam{Schluessel},
            Inhalt     => $GetParam{Inhalt},
            UserID     => $Self->{UserID},
        );

        #get list
        %RequestFieldsListe = $RequestFieldsObject->RequestFieldsWerteList(
            FeldID => $GetParam{FeldID},
        );
    }

    if ( $Self->{Subaction} eq "RemoveWert" ) {

        #update
        $RequestFieldsObject->RequestFieldsWertRemove(
            WertID => $GetParam{WertID},
        );

        #get list
        %RequestFieldsListe = $RequestFieldsObject->RequestFieldsWerteList(
            FeldID => $GetParam{FeldID},
        );
    }

    my $Output = '';

    my %AntragWerteDropdown = ();

    if (
        $Self->{Subaction}    eq "Liste"
        || $Self->{Subaction} eq "Dropdown"
        || $Self->{Subaction} eq "Multiselect"
        || $Self->{Subaction} eq "NeuerWert"
        || $Self->{Subaction} eq "RemoveWert"
        )
    {

        for my $RequestFieldsWerteID ( sort keys %RequestFieldsListe ) {

            #get RequestFieldsWerte
            my %RequestFieldsWerte = $RequestFieldsObject->RequestFieldsWerteGet(
                ID => $RequestFieldsWerteID,
            );

            $AntragWerteDropdown{ $RequestFieldsWerte{Schluessel} } = $RequestFieldsWerte{Inhalt};

            #generate output
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AdminRequestFieldsContentList',
                Data => {
                    Schluessel => $RequestFieldsWerte{Schluessel},
                    Inhalt     => $RequestFieldsWerte{Inhalt},
                    WerteID    => $RequestFieldsWerteID,
                },
            );
        }

        #generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminRequestFieldsContent',
            Data         => \%Param,
        );

    }


    if ( $Self->{Subaction} eq "Dropdown" ) {

        for my $RequestFieldsWerteID ( sort keys %RequestFieldsListe ) {

            #get RequestFieldsWerte
            my %RequestFieldsWerte = $RequestFieldsObject->RequestFieldsWerteGet(
                ID => $RequestFieldsWerteID,
            );

            $AntragWerteDropdown{ $RequestFieldsWerte{Schluessel} } = $RequestFieldsWerte{Inhalt};

        }

        # get data
        my %RequestFieldsData = $RequestFieldsObject->RequestFieldsGet(
            RequestFieldsID => $GetParam{FeldID},
            UserID          => $Self->{UserID},
        );

        if (
            $GetParam{Schluessel}
            && ( $RequestFieldsData{Defaultvalue} eq "$GetParam{Schluessel}" )
            )
        {
            $RequestFieldsData{Defaultvalue} = '';
        }

        my $IfLeerWert = '';
        if ( $RequestFieldsData{LeerWert} eq "1" ) {
            $IfLeerWert = 1;
        }
        else {
            $IfLeerWert = '';
        }

        #generate output
        $Output = $LayoutObject->BuildSelection(
            Data         => \%AntragWerteDropdown,
            Name         => 'Defaultvalue',
            PossibleNone => $IfLeerWert,
            SelectedID   => $RequestFieldsData{Defaultvalue},
            Translation  => 0,
            Max          => 200,
        );

    }
    elsif ( $Self->{Subaction} eq "Multiselect" ) {

        # get the sla data
        my %RequestFieldsData = $RequestFieldsObject->RequestFieldsGet(
            RequestFieldsID => $GetParam{FeldID},
            UserID         => $Self->{UserID},
        );

        if (
            $GetParam{Schluessel}
            && ( $RequestFieldsData{Defaultvalue} eq "$GetParam{Schluessel}" )
            )
        {
            $RequestFieldsData{Defaultvalue} = '';
        }
        my @DefaultvalueValue;
        if ( $RequestFieldsData{Defaultvalue} ) {
            @DefaultvalueValue = split( /,/, $RequestFieldsData{Defaultvalue} );
        }

        my $IfLeerWert = '';
        if ( $RequestFieldsData{LeerWert} eq "1" ) {
            $IfLeerWert = 1;
        }
        else {
            $IfLeerWert = '';
        }

        #generate output
        $Output = $LayoutObject->BuildSelection(
            Data         => \%AntragWerteDropdown,
            Name         => 'Defaultvalue',
            PossibleNone => $IfLeerWert,
            Multiple     => 1,
            Size         => 10,
            Class        => 'W50pc',
            SelectedID   => \@DefaultvalueValue,
            Translation  => 0,
            Max          => 200,
        );
    }

    # get output back
    return $LayoutObject->Attachment(
        ContentType => 'text/html; charset=' . $Self->{LayoutObject}->{Charset},
        Content     => $Output,
        Type        => 'inline',
        NoCache     => '1',
    );
}

1;
