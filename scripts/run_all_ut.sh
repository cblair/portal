#!/bin/bash

echo "run_all_ut.sh ['db' - prepares the db]"

if [ "$1" == "db" ]; then
	rake db:test:prepare
fi

ruby -I test test/unit/helpers/documents_helper_test.rb
