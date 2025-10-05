#!/bin/bash
set -ev

if [ $DB = 'mysql' ]; then

    # Tweak some mysql settings for OFORK.
    sudo su - <<MODIFY_MYSQL_CONFIG
cat - <<MYSQL_CONFIG >> /etc/mysql/my.cnf
[mysqld]
max_allowed_packet   = 24M
innodb_log_file_size = 256M
MYSQL_CONFIG
MODIFY_MYSQL_CONFIG
    sudo service mysql restart
    mysql -e "SHOW VARIABLES LIKE 'max_allowed_packet';"
    mysql -e "SHOW VARIABLES LIKE 'innodb_log_file_size';"

    # Now create OFORK specific users and databases.
    cp -i $TRAVIS_BUILD_DIR/scripts/tools/travis/Config.mysql.pm $TRAVIS_BUILD_DIR/Kernel/Config.pm

    mysql -uroot -e "CREATE DATABASE ofork CHARACTER SET utf8";
    mysql -uroot -e "GRANT ALL PRIVILEGES ON ofork.* TO 'ofork'@'localhost' IDENTIFIED BY 'ofork'";
    mysql -uroot -e "CREATE DATABASE oforktest CHARACTER SET utf8";
    mysql -uroot -e "GRANT ALL PRIVILEGES ON oforktest.* TO 'oforktest'@'localhost' IDENTIFIED BY 'oforktest'";
    mysql -uroot -e "FLUSH PRIVILEGES";
    mysql -uroot ofork < $TRAVIS_BUILD_DIR/scripts/database/ofork-schema.mysql.sql
    mysql -uroot ofork < $TRAVIS_BUILD_DIR/scripts/database/ofork-initial_insert.mysql.sql
    mysql -uroot ofork < $TRAVIS_BUILD_DIR/scripts/database/ofork-schema-post.mysql.sql
fi

if [ $DB = 'postgresql' ]; then
    cp -i $TRAVIS_BUILD_DIR/scripts/tools/travis/Config.postgresql.pm $TRAVIS_BUILD_DIR/Kernel/Config.pm

    psql -U postgres -c "CREATE ROLE ofork LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE"
    psql -U postgres -c "CREATE DATABASE ofork OWNER ofork ENCODING 'UTF8'"
    psql -U postgres -c "CREATE ROLE oforktest LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE"
    psql -U postgres -c "CREATE DATABASE oforktest OWNER oforktest ENCODING 'UTF8'"
    psql -U ofork ofork < $TRAVIS_BUILD_DIR/scripts/database/ofork-schema.postgresql.sql > /dev/null
    psql -U ofork ofork < $TRAVIS_BUILD_DIR/scripts/database/ofork-initial_insert.postgresql.sql > /dev/null
    psql -U ofork ofork < $TRAVIS_BUILD_DIR/scripts/database/ofork-schema-post.postgresql.sql > /dev/null
    psql -U postgres -c "ALTER ROLE ofork PASSWORD 'ofork'"
    psql -U postgres -c "ALTER ROLE oforktest PASSWORD 'oforktest'"
fi
