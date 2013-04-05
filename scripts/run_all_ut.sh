#!/bin/bash

echo "run_all_ut.sh ['db' - prepares the db]"

UTS="helpers/searches_helper_test.rb "
UTS+="helpers/documents_helper_test.rb "

if [ "$1" == "db" ]; then
	rake db:test:prepare
	rake environment RAILS_ENV=test db:migrate
fi

for UT in $UTS; do
	CMD="ruby -I test test/unit/$UT"
	echo $CMD
	ruby -I test test/unit/"$UT"
done