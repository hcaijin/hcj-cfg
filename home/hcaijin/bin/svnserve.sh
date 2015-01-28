#!/bin/bash
case "$1" in
start)
        svnserve -d -r /svndata
        svnport=`netstat -natp | grep svnserve | awk -F: '{print $4}' | awk 'NR==1'`
        if [ $svnport -eq 3690 ]
        then
                echo "SVN Server Already Runnning. Port:3690"
        else
                echo "SVN Server Does Not Start"
        fi

reload)
        svnport=`netstat -natp | grep svnserve | awk -F: '{print $4}' | awk 'NR==1'`
        if [ $svnport -eq 3690 ]
        then
                killall svnserve && svnserve -d -r /svndata
                echo "Reload OK"
        else
                echo "SVN Server Is Not Running"
        fi

stop)
        killall svnserve
        echo "SVN Server Has Been Stopped"

status)
        svnport=`netstat -natp | grep svnserve | awk -F: '{print $4}' | awk 'NR==1'`
        pid=`ps aux | grep svnserve | grep -v "grep" | awk '{print $2}'`
        if [ $svnport -eq 3690 ]
        then
                echo "SVN Server (pid:$pid) 正在运行..."
        else
                echo "SVN Server 停止运行..."
        fi

*)
        echo "$0: Usage: $0 {start|status|stop|reload}"
        exit 1

esac
