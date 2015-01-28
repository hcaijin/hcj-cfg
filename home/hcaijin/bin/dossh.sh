#!/bin/bash
#2013-04-08
#author myhoop
#blog [url]http://myhoop.blog.[/url]

#批量ssh认证建立

for p in $(cat /home/hcaijin/hcj-cfg/ip.txt)  #注意ip.txt文件的绝对路径
do
ip=$(echo "$p"|cut -f1 -d":")       #取ip.txt文件中的ip地址
password=$(echo "$p"|cut -f2 -d":") #取ip.txt文件中的密码

#expect自动交互开始
expect -c "
spawn ssh-copy-id -i /home/hcaijin/.ssh/id_rsa.pub root@$ip
        expect {
                \"*yes/no*\" {send \"yes\r\"; exp_continue}
                \"*password*\" {send \"$password\r\"; exp_continue}
                \"*Password*\" {send \"$password\r\";}
        }
"
done
