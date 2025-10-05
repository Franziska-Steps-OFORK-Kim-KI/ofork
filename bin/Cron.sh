#!/bin/sh
# --
# bin/Cron.sh
# Modified version of the work:
# Copyright (C) 2010-2024 OFORK, https://o-fork.de
# based on the original work of:
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# --
# $Id: Cron.sh,v 1.1.1.1 2018/07/16 14:49:06 ud Exp $
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

CURRENTUSER=`whoami`
CRON_USER="$2"

# check if a common user try to use -u
if test -n "$CRON_USER"; then
    if test $CURRENTUSER != root; then
        echo "Run this script just as OFORK user! Or use 'Cron.sh {start|stop|restart} OFORK_USER' as root!"
        exit 5
    fi
fi

# check if the cron user is specified
if test -z "$CRON_USER"; then
    if test $CURRENTUSER = root; then
        echo "Run this script just as OFORK user! Or use 'Cron.sh {start|stop|restart} OFORK_USER' as root!"
        exit 5
    fi
fi

# find ofork root
cd "`dirname $0`/../"
OFORK_HOME="`pwd`"

#OFORK_ROOT=/opt/ofork
if test -e $OFORK_HOME/var/cron; then
    OFORK_ROOT=$OFORK_HOME
else
    echo "No cronjobs in $OFORK_HOME/var/cron found!";
    echo " * Check the \$HOME (/etc/passwd) of the OFORK user. It must be the root dir of your OFORK system (e. g. /opt/ofork). ";
    exit 5;
fi

CRON_DIR=$OFORK_ROOT/var/cron
CRON_TMP_FILE=$OFORK_ROOT/var/tmp/ofork-cron-tmp.$$

#
# main part
#
case "$1" in
    # ------------------------------------------------------
    # start
    # ------------------------------------------------------
    start)
        # add -u to cron user if user exists
        if test -n "$CRON_USER"; then
            CRON_USER=" -u $CRON_USER"
        fi

        if mkdir -p $CRON_DIR; cd $CRON_DIR && ls -d * | grep -Ev "(\.(dist|rpm|bak|backup|custom_backup|save|swp)|\~)$" | xargs cat > $CRON_TMP_FILE && crontab $CRON_USER $CRON_TMP_FILE; then

            rm -rf $CRON_TMP_FILE
            echo "(using $OFORK_ROOT) done";
            exit 0;
        else
            echo "failed";
            exit 1;
        fi
    ;;
    # ------------------------------------------------------
    # stop
    # ------------------------------------------------------
    stop)
        # add -u to cron user if user exists
        if test -n "$CRON_USER"; then
            CRON_USER=" -u $CRON_USER"
        fi

        if crontab $CRON_USER -r ; then
            echo "done";
            exit 0;
        else
            echo "failed";
            exit 1;
        fi
    ;;
    # ------------------------------------------------------
    # restart
    # ------------------------------------------------------
    restart)
        $0 stop "$CRON_USER"
        $0 start "$CRON_USER"
    ;;
    # ------------------------------------------------------
    # Usage
    # ------------------------------------------------------
    *)
    cat - <<HELP

Manage OFORK cron jobs.

Usage:
 Cron.sh [action]

Arguments:
 [action]                      - 'start', 'stop' or 'restart' - activate or deactivate OFORK cron jobs.
HELP

    exit 1
esac
