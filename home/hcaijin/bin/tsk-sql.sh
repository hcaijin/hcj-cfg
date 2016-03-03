#!/bin/sh
if [ $# -ne 0 ];then
    DEV_LOCAL=$1
else
    DEV_LOCAL="wlp3s0"
fi

tshark -s 512 -i $DEV_LOCAL -n -f 'tcp dst port 3306' -Y 'mysql.query' -T fields -e mysql.query
