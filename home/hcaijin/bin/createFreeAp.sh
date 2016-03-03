#!/bin/sh
sudo create_ap --daemon wlp3s0 enp9s0 'CMCC-CHINA' 2>&1 > /dev/null
#echo $(date +%F)
#tshark -s 512 -i wlp3s0 -n -f 'tcp dst port 80' -Y 'http.host and http.request.uri' -T fields -e http.host -e http.request.uri -l | tr -d '\t' > /home/hcaijin/hcj-cfg/tmp/scan.$(date +%F).tsk &
nohup tsk-http.sh > /home/hcaijin/hcj-cfg/tmp/scan.$(date +%F).tsk &
