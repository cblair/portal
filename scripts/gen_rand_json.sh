#!/bin/bash

while (true); 
	DATE=`date`
	do echo "{\"date\" : \"$DATE\", \"1\" : $RANDOM}" > /var/www/test.json
	sleep 10
done
