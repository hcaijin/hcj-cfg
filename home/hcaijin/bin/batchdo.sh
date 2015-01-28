#!/bin/bash
#通过ssh批量执行命令  
  
for h in $(cat webip.txt|cut -f1 -d":")  
do 
ssh root@$h $1
#scp $2 root@$h:$3
#如果命令是多行的，请参照下面  
#ssh root@$h '此处写要执行的命令1' 
#ssh root@$h '此处写要执行的命令2' 
#ssh root@$h '此处写要执行的命令3' 
done 
  
  
#ip.txt文件里面ip和密码写法  
#192.168.0.2:admin2  
#192.168.0.3:admin3
