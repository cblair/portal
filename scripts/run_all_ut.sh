#!/bin/bash

echo "run_all_ut.sh ['db' - prepares the db]"

if [ "$1" == "db" ]; then
	rake db:test:prepare
	ruby -I test test/unit/helpers/documents_helper_test.rb
else
	echo ruby -I test test/unit/helpers/documents_helper_test.rb $@
	ruby -I test test/unit/helpers/documents_helper_test.rb $@
fi
