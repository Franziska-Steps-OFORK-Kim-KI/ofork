# --
# Kernel/Config.pm - Config file for OTRS kernel
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: Config.pm.dist,v 1.23 2010/01/13 22:25:00 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
#  Note:
#
#  -->> OTRS does have a lot of config settings. For more settings
#       (Notifications, Ticket::ViewAccelerator, Ticket::NumberGenerator,
#       LDAP, PostMaster, Session, Preferences, ...) see
#       Kernel/Config/Defaults.pm and copy your wanted lines into "this"
#       config file. This file will not be changed on update!
#
# --

package Kernel::Config;

sub Load {
    my $Self = shift;
    # ---------------------------------------------------- #
    # ---------------------------------------------------- #
    #                                                      #
    #         Start of your own config options!!!          #
    #                                                      #
    # ---------------------------------------------------- #
    # ---------------------------------------------------- #

    # ---------------------------------------------------- #
    # database settings                                    #
    # ---------------------------------------------------- #
    # DatabaseHost
    # (The database host.)
    $Self->{'DatabaseHost'} = 'localhost';
    # Database
    # (The database name.)
    $Self->{'Database'} = "ofork";
    # DatabaseUser
    # (The database user.)
    $Self->{'DatabaseUser'} = "ofork";
    # DatabasePw
    # (The password of database user. You also can use bin/ofork.CryptPassword.pl
    # for crypted passwords.)
    $Self->{'DatabasePw'} = 'ofork';
    # DatabaseDSN
    # (The database DSN for MySQL ==> more: "man DBD::mysql")
    $Self->{'DatabaseDSN'} = "DBI:mysql:database=$Self->{Database};host=$Self->{DatabaseHost}";

    # (The database DSN for PostgreSQL ==> more: "man DBD::Pg")
    # if you want to use a local socket connection
    #    $Self->{DatabaseDSN} = "DBI:Pg:dbname=$Self->{Database};";
    # if you want to use a tcpip connection
    #    $Self->{DatabaseDSN} = "DBI:Pg:dbname=$Self->{Database};host=$Self->{DatabaseHost};";

    # ---------------------------------------------------- #
    # fs root directory
    # ---------------------------------------------------- #
    $Self->{Home} = '/opt/ofork';

    # ---------------------------------------------------- #
    # insert your own config settings "here"               #
    # config settings taken from Kernel/Config/Defaults.pm #
    # ---------------------------------------------------- #

    $Self->{'SystemID'}   = '11';

    $Self->{'SessionName'}         = 'ofork';
    $Self->{'ScriptAlias'}         = 'ofork/';
    $Self->{'Frontend::WebPath'}   = '/ofork-web/';

    $Self->{'OFORKTimeZone'}       = 'Europe/Berlin';
    $Self->{'UserDefaultTimeZone'} = 'Europe/Berlin';

    $Self->{CustomerUser}->{CustomerUserSearchFields}  =  [ 'login', 'first_name', 'last_name', 'customer_id', 'email' ];

    # ---------------------------------------------------- #

    # ---------------------------------------------------- #
    # data inserted by installer                           #
    # ---------------------------------------------------- #
    # $DIBI$


    # ---------------------------------------------------- #
    # ---------------------------------------------------- #
    #                                                      #
    #           End of your own config options!!!          #
    #                                                      #
    # ---------------------------------------------------- #
    # ---------------------------------------------------- #
}

# ---------------------------------------------------- #
# needed system stuff (don't edit this)                #
# ---------------------------------------------------- #

use Kernel::Config::Defaults; # import Translatable()
use parent qw(Kernel::Config::Defaults);

# -----------------------------------------------------#

1;

