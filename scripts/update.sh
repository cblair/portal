#!/bin/bash

#This script checks the git server for updates, and if they exist,
# pull them down, and dumps the updated time to an html file.

ROOTDIR=/var/git/portal_continuous/scripts
CONT_UP_FILE=/var/www/portal/continuous_update.html
UPDATED=0

cd $ROOTDIR

git remote update
git status -uno 
git status -uno | grep 'behind'
STAT_BEHIND=$?
git status -uno | grep 'different'
STAT_DIFF=$?
if [[ $STAT_BEHIND == 0 || $STAT_DIFF == 0 ]] ; then
	echo test
	git pull
	if [[ $? == 0 ]] ; then
		UPDATED=1
		CONT_DATE=`date`
	fi

	#make sure we're on integration
	git checkout integration

	#do any new installs
	bundle install
	rake db:create
	rake db:schema:load
fi

HTML_TEXT="
<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.0//EN'>
<html>
<head>
<meta http-equiv='content-type' content='text/html;charset=utf-8'>
<meta name='robots' content='noindex,nofollow'>
<title>nwerp.org</title>
</head>
<body>

<h1>Portal Update</h1>
<ul>
	<li>Updated on "$CONT_DATE"</li>
</ul>

</body>
</html>
"

if [[ $UPDATED == 1 ]]; then
	echo "$HTML_TEXT" > $CONT_UP_FILE
	#echo "$HTML_TEXT"
	echo "Updated at $CONT_DATE"
fi
