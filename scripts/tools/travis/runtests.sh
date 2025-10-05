#!/bin/bash
set -ev

if [ $DB = 'postgresql' ]; then
    # PostgreSQL data is on a small ramdisk in Travis; make sure that it stays small by always performing VACUUM FULL.
    perl bin/ofork.Console.pl Dev::UnitTest::Run --post-test-script 'psql -U postgres ofork -c "VACUUM FULL"'
else
    perl bin/ofork.Console.pl Dev::UnitTest::Run
fi
