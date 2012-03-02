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
if [[ $? == 0 ]] ; then
	echo test
	git fetch
	git reset --hard origin/integration #reset to the integration branch
	if [[ $? == 0 ]] ; then
		UPDATED=1
		CONT_DATE=`date`
	fi
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
