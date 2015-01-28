#!/bin/bash

# transfer system/application logs  to tftp server
# crontab : 0 6 * * * /root/tools/sync_logs.sh
# author : zhangxugg@163.com

fpm_log=/usr/local/php5.3.6/var/log/php-fpm.log
fpm_slowlog=/usr/local/php5.3.6/var/log/php-slow.log
fpm_pid=/usr/local/php5.3.6/var/run/php-fpm.pid

mysql_log=/data/front/mysql.log
mysql_slowlog=/data/front/mysqlslow.log
mysql_pid=/data/front/my.pid

nginx_log=/usr/local/nginx/logs/error.log
nginx_pid=/usr/local/nginx/logs/nginx.pid

#TFTP Server
server=172.169.10.1


syslogs='messages secure vsftpd.log lastlog cron dmesg'

function debug() {
	if [ ! "$TERM" == "" ] ; then
		echo "$1"
	fi
}

function send_log () {
	if [ -f "$1" -a  -s "$1" ] ; then
		cd `/usr/bin/dirname $1`
		if [ ! "$TERM" == "" ] ; then
			debug "sending $1 .."
		fi

		remote="${client_ip}_`/bin/basename $1 .log`_${name}"

		/usr/bin/tftp $server -c put "`basename $1`"  "$remote"

		if [ "$?" == 0 ] ; then
			rm -f "$1"
			return 0
		else
			debug "failed"
			return 3
		fi
	fi

	#delete empty file
	if [ -f "$1" ] ; then
		rm -f "$1"	
	else
		debug "$1 not exists , skip"
	fi
}

function send_fpmlog() {

	if [ -z "$fpm_pid" ] ; then
		return 0
	fi
	
	if [ ! -f "$fpm_pid" ] ; then
		debug "fpm_pid : $fpm_pid is not exists"
		return 1
	fi

	if [ ! -f "$fpm_log" ] ; then
		debug "fpm-log : ${fpm_log} is not exists"
	else
		send_log "$fpm_log"
	fi

	if [ ! -f "$fpm_slowlog" ] ; then
		debug "fpm_slowlog : $fpm_slowlog is not exists"
	else
		send_log "$fpm_slowlog"
	fi


	/usr/bin/find $logpath -name "*20*.log" -size -1  -exec /bin/rm -rf {} \;
	/bin/kill -SIGUSR2 `cat $fpm_pid` 2> /dev/null
}


function send_syslog () {
	for n in $syslogs
	do
		f="/var/log/$n"
		if [ -f "$f" -a ! "$n" == "lastlog" ] ; then
			send_log "$f"
			
		fi

		if [ "$n" == "lastlog" ] ; then
			to=/tmp/lastlog
			/usr/bin/lastlog > $to
			send_log "$to"
		fi
	done

	/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
	/bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
}

function send_mysql_log () {
	
	if [ -z "$mysql_pid" ] ; then
		return 0
	fi

	if [ ! -f "$mysql_pid" ] ; then
		debug "$mysql_pid is not exists"
		return 1
	fi

	if [ -f "$mysql_log" ] ; then
		send_log "$mysql_log"
	else
		debug "$mysql_log is not exists"
	fi

	if [ -f "$mysql_slowlog" ] ; then
		send_log "$mysql_slowlog"
	else
		debug "$mysql_log is not exists"
	fi

	/bin/kill -HUP `cat $mysql_pid`
}

function send_nginx_log () {

	if [ -z "$nginx_pid" ] ; then
		return 0
	fi

	if [ ! -f "$nginx_pid" ] ; then
		debug "$nginx_pid is not exists"
		return 1
	fi

	if [ -f "$nginx_log" ] ; then
		send_log "$nginx_log"
	else
		debug "nginx_log is not exists"
	fi

	/bin/kill -USR1 `cat $nginx_pid`
}

name=`/bin/date +%F`.log

if [ "`echo $server|egrep '^[0-9\.]{7,15}$'`" == "" ] ; then
	debug "lookup IP Address of $server ..."
	server=`nslookup $server | grep -v '#'|grep Address|head -1|awk '{print $2}'`
	if [ "$server" == "" ] ; then
		debug "can not find Address of $server"
		exit 2
	else
		debug "$server"
	fi
fi

gateway_prefix=`/sbin/route -n|/bin/grep '^0.0.0.0' | /bin/awk '{print $2}' | /bin/awk -F '.' '{print $1 "." $2}'`
client_ip=`/sbin/ifconfig | /bin/egrep -o 'inet addr:[0-9\.]{7,15}' | /bin/egrep -o "$gateway_prefix.+"`

if [ "$client_ip" == "" ] ; then
	client_ip='0.0.0.0'
fi


send_fpmlog
send_syslog
send_mysql_log
send_nginx_log


exit $?
