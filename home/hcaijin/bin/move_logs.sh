#!/bin/bash

logpath=/data/logs

cd $logpath
logs=`find  -maxdepth 1  -name "*.log"`

for n in $logs
do
	prefix=`echo $n | egrep -o '[0-9\.]{7,15}'`
	
	if [ "$prefix" == "" ] ; then
		continue
	fi

	if [ ! -d "$logpath/$prefix" ] ; then
		mkdir "$logpath/$prefix"
	fi

	to=`echo $n | sed -e "s/${prefix}_//"`
	to=`basename $to`

	echo "$to"
	if [ "$to" == "" ] ; then
		continue
	fi

	mv "$n"  "$logpath/$prefix/$to"
done


find ./ -name "*.log" -mtime +10
