#!/bin/sh
if [ $# -ne 0 ];then
    DEV_LOCAL=$1
else
    DEV_LOCAL="wlp3s0"
fi

tshark -s 512 -i $DEV_LOCAL -n -f 'tcp dst port 80' -Y 'http.host and http.request.uri' -T fields -e http.host -e http.request.uri -l | tr -d '\t'
