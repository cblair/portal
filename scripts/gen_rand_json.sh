#!/bin/bash

while (true); 
	do echo "{\"1\" : $RANDOM}" > /var/www/test.json
	sleep 10
done
