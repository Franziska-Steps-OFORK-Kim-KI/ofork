# --
# Kernel/Modules/AgentCustomerRequest.pm - to handle customer messages
# Copyright (C) 2010-2025 OFORK, https://o-fork.de
# --
# $Id: AgentCustomerRequest.pm,v 1.21 2016/11/20 19:35:56 ud Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCustomerRequest;

use strict;
use warnings;

use MIME::Base64;

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

    my $ParamObject                = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                = $Kernel::OM->Get('Kernel::System::Valid');
    my $RequestObject              = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFormObject          = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $CustomerUserObject         = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $RequestCategoriesObject    = $Kernel::OM->Get('Kernel::System::RequestCategories');
    my $LinkObject                 = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $TicketObject               = $Kernel::OM->Get('Kernel::System::Ticket');

    # get params
    my %GetParam;
    for my $Key (qw( RequestID RequestCategoriesID SetRequestCategoriesID SetRequestCategoriesIDToRequest)) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    if ( !$Self->{Subaction} ) {

        # print form ...
        my $Output .= $LayoutObject->Header();
        $Output    .= $LayoutObject->NavigationBar();
        $Output    .= $Self->_MaskNew(
            %GetParam,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'StoreNew' ) {
        my %Error;

        if ( $GetParam{RequestCategoriesID} && !$GetParam{RequestID} ) {

            # print form ...
            my $Output .= $LayoutObject->Header();
            $Output    .= $LayoutObject->NavigationBar();
            $Output    .= $Self->_MaskNew(
                %GetParam,
                RequestCategoriesID => $GetParam{RequestCategoriesID},
            );
            $Output .= $LayoutObject->Footer();
            return $Output;

        }

        # check subject
        if ( !$GetParam{RequestID} ) {
            $Error{RequestID} = 'ServerError';
        }

        if (%Error) {

            # html output
            my $Output .= $LayoutObject->Header();
            $Output    .= $LayoutObject-rNavigationBar();
            $Output    .= $Self->_MaskNew(
                %GetParam,
                Errors => \%Error,
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        # redirect
        return $LayoutObject->Redirect(
            OP => "Action=AgentTicketRequest;RequestID=$GetParam{RequestID}",
        );
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $ParamObject                 = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject                = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject                 = $Kernel::OM->Get('Kernel::System::Valid');
    my $RequestObject               = $Kernel::OM->Get('Kernel::System::Request');
    my $RequestFormObject           = $Kernel::OM->Get('Kernel::System::RequestForm');
    my $CustomerUserObject          = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $RequestCategoriesObject     = $Kernel::OM->Get('Kernel::System::RequestCategories');
    my $LinkObject                  = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $TicketObject                = $Kernel::OM->Get('Kernel::System::Ticket');
    my $RequestCategoriesIconObject = $Kernel::OM->Get('Kernel::System::RequestCategoriesIcon');

    $Param{FormID} = $Self->{FormID};

    my %RequestCategoriesList = $RequestCategoriesObject->RequestCategoriesList(
        Valid  => 1,
        UserID => 1,
    );

    # get  list
    my %Requests = $RequestObject->RequestList(
        Valid  => 1,
        UserID => 1,
    );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    if ( %Requests ) {

        my %RequestsNew = ();
        if ( $Param{RequestCategoriesID} ) {
            my %RequestCategoriesTemplateList = $RequestCategoriesObject->RequestCategoriesTemplateList(
                RequestCategoriesID => $Param{RequestCategoriesID},
                UserID              => 1,
                );
            for my $CheckAntrag ( keys %Requests ) {
                for my $CheckKategorie ( keys %RequestCategoriesTemplateList ) {
                    if ( $CheckAntrag == $RequestCategoriesTemplateList{$CheckKategorie} ) {
                        $RequestsNew{ $RequestCategoriesTemplateList{$CheckKategorie} }
                            = $Requests{$CheckAntrag};
                    }
                }
            }
        }

        my $ShowRequestIcon = $ConfigObject->Get('Ticket::Frontend::RequestIcon');

        if ( $ShowRequestIcon && $ShowRequestIcon >= 1 ) {

            $LayoutObject->Block(
                Name => 'RequestImage',
                Data => \%Param,
            );

            my %List = $RequestCategoriesIconObject->RequestCategoriesIconList(
                UserID => 1,
                Valid  => 1,
            );

            if (%RequestCategoriesList) {

                my %KatData = ();
                for my $ID ( sort { $RequestCategoriesList{$a} cmp $RequestCategoriesList{$b} } keys %RequestCategoriesList ) {

                    my %RequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
                        RequestCategoriesID => $ID,
                        UserID              => 1,
                    );

                    if ( $RequestCategoriesData{Name} !~ /::/g ) {

                        if ( $RequestCategoriesData{ImageID} ) {

                            %KatData = $RequestCategoriesIconObject->RequestCategoriesIconGet(
                                ID => $RequestCategoriesData{ImageID},
                            );

                            $Param{RequestCategoriesID} = $ID;

                            if ( $Param{SetRequestCategoriesID} == $ID ) {
                                $Param{IfSetCategoriesID} = 'border: 1px solid #02a543;';
                            }
                            else {
                                $Param{IfSetCategoriesID} = '';
                            }

                            if ( $KatData{Content} && $KatData{Content} ne '' ) {
    
                                $KatData{Content} = encode_base64($KatData{Content});
                                $LayoutObject->Block(
                                    Name => 'CategoryIcons',
                                    Data => { %Param, %KatData, %RequestCategoriesData, },
                                );
                            }
                        }
                        else {

                            $Param{RequestCategoriesID} = $ID;

                            if ( $Param{SetRequestCategoriesID} == $ID ) {
                                $Param{IfSetCategoriesID} = 'border: 1px solid #02a543;';
                            }
                            else {
                                $Param{IfSetCategoriesID} = '';
                            }

                            $LayoutObject->Block(
                                Name => 'CategoryNoImageIcons',
                                Data => { %Param, %KatData, %RequestCategoriesData, },
                            );
                        }
                    }
                }

                if ( $Param{SetRequestCategoriesID} ) {

                    my %CheckRequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
                        RequestCategoriesID => $Param{SetRequestCategoriesID},
                        UserID              => 1,
                    );

                    my $CheckIfSubB = 0;
                    for my $ID ( sort { $RequestCategoriesList{$a} cmp $RequestCategoriesList{$b} } keys %RequestCategoriesList ) {

                        my %RequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
                            RequestCategoriesID => $ID,
                            UserID              => 1,
                        );

                        if ( $RequestCategoriesData{Name} =~ /$CheckRequestCategoriesData{Name}::/g ) {
                            $CheckIfSubB ++;
                        }
                    }

                    if ( $CheckIfSubB >= 1 )  {
                        $LayoutObject->Block(
                            Name => 'SubCategory',
                            Data => { %Param },
                        );
                    }

                    my %SubKatData = ();
                    my $CheckIfSub = 0;
                    for my $ID ( sort { $RequestCategoriesList{$a} cmp $RequestCategoriesList{$b} } keys %RequestCategoriesList ) {

                        my %RequestCategoriesData = $RequestCategoriesObject->RequestCategoriesGet(
                            RequestCategoriesID => $ID,
                            UserID              => 1,
                        );

                        if ( $RequestCategoriesData{Name} =~ /$CheckRequestCategoriesData{Name}::/g ) {

                            if ( $RequestCategoriesData{ImageID} ) {

                                %SubKatData = $RequestCategoriesIconObject->RequestCategoriesIconGet(
                                    ID => $RequestCategoriesData{ImageID},
                                );

                                $Param{RequestCategoriesID} = $ID;

                                $CheckIfSub ++;
                                $RequestCategoriesData{Name} =~ s/(.*)::(.*)/$2/g;
                                $RequestCategoriesData{RequestCategoriesIDOld} = $Param{SetRequestCategoriesID};

                                if ( $Param{SetRequestCategoriesIDToRequest} == $ID ) {
                                    $Param{IfSetCategoriesID} = 'border: 1px solid green; border-radius: 5px;';
                                }
                                else {
                                    $Param{IfSetCategoriesID} = '';
                                }

                                if ( $SubKatData{Content} ) {
    
                                    $SubKatData{Content} = encode_base64($SubKatData{Content});
                                    $LayoutObject->Block(
                                        Name => 'SubCategoryIcons',
                                        Data => { %Param, %SubKatData, %RequestCategoriesData, },
                                    );
                                }
                            }
                            else {

                                $Param{RequestCategoriesID} = $ID;

                                $CheckIfSub ++;
                                $RequestCategoriesData{Name} =~ s/(.*)::(.*)/$2/g;
                                $RequestCategoriesData{RequestCategoriesIDOld} = $Param{SetRequestCategoriesID};

                                if ( $Param{SetRequestCategoriesIDToRequest} == $ID ) {
                                    $Param{IfSetCategoriesID} = 'border: 1px solid green; border-radius: 5px';
                                }
                                else {
                                    $Param{IfSetCategoriesID} = '';
                                }

                                $LayoutObject->Block(
                                    Name => 'SubCategoryNoImageIcons',
                                    Data => { %Param, %SubKatData, %RequestCategoriesData, },
                                );
                            }
                        }
                    }
                }
            }

            if ( $Param{RequestCategoriesID} ) {

                $LayoutObject->Block(
                    Name => 'SetRequest',
                    Data => { %Param },
                );

                if ( %RequestsNew ) {

                    my $CheckIfGroup = 0;
                    for my $RequestID ( sort keys %RequestsNew ) {

                        my %Request = $RequestObject->RequestGet(
                            RequestID => $RequestID,
                        );

                        if ( $Request{ImageID} && $Request{ImageID} ne '0' ) {

                            my %Data = $RequestCategoriesIconObject->RequestCategoriesIconGet(
                                ID => $Request{ImageID},
                            );

                            $Data{Content} = encode_base64($Data{Content});
                            $LayoutObject->Block(
                                Name => 'SetRequestIcons',
                                Data => { %Param, %Data, %Request, },
                            );
                        }
                        else {

                            $LayoutObject->Block(
                                Name => 'SetRequestNoImageIcons',
                                Data => { %Param, %Request, },
                            );
                        }
                        $CheckIfGroup = 0;
                    }
                }
                else {

                    $LayoutObject->Block(
                        Name => 'SetRequestNoItems',
                        Data => { %Param, },
                    );
                }
            }
        }

        if ( !$ShowRequestIcon || $ShowRequestIcon == 0 ) {

            $Param{RequestCategoriesStrg} = $LayoutObject->BuildSelection(
                Data         => \%RequestCategoriesList,
                Name         => 'RequestCategoriesID',
                SelectedID   => $Param{RequestCategoriesID},
                PossibleNone => 1,
                Translation  => 0,
                Max          => 200,
            );

            $Param{RequestStrg} = $LayoutObject->BuildSelection(
                Data         => \%RequestsNew,
                Name         => 'RequestID',
                SelectedID   => $Param{RequestID},
                PossibleNone => 1,
                Translation  => 0,
                Max          => 200,
            );

            $LayoutObject->Block(
                Name => 'Request',
                Data => \%Param,
            );

            # prepare errors
            if ( $Param{Errors} ) {
                for ( keys %{ $Param{Errors} } ) {
                    $Param{$_} = $Param{Errors}->{$_};
                }
            }
        }

    }
    else {

        $LayoutObject->Block(
            Name => 'SetRequestNoItems',
            Data => { %Param, },
        );
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentCustomerRequest',
        Data         => \%Param,
    );
}

1;
