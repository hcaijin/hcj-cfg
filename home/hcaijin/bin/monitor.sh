#!/bin/bash

MAILLIST="hcjonline@gmail.com"    #emailist

MEM_CORDON=100   #内存使用大于这个值报警
#SWAP_CORDON=50  #交换区使用值大于这个报警  
CPU_CORDON=5    #cpu空闲小于这个值报警
DISK_CORDON=85  #磁盘占用大于这个值报警
load_warn=0.70 #设置系统单个核心15分钟的平均负载的告警值为0.70(即使用超过70%的时候告警)。
HOSTNAME=`hostname`
DATA=`date`
IP=`ifconfig eth1 | grep "inet addr" | cut -f 2 -d ":" | cut -f 1 -d " "`  #提取本服务器的IP地址信息

send_warning()
{
    echo $MESSAGE | /bin/mail -s "$TITLE" "$MAILLIST" 
}

if [ $# -ne 0 ];then
    DISK_DIR=$1
else
    DISK_DIR="/dev/xvdb1"
fi

#LOAD_WARN check 
# 1、监控系统负载的变化情况，超出时发邮件告警：

#抓取cpu的总核数
cpu_num=`grep -c 'model name' /proc/cpuinfo`

#抓取当前系统15分钟的平均负载值
load_15=`uptime | awk '{print $12}'`

#计算当前系统单个核心15分钟的平均负载值，结果小于1.0时前面个位数补0。
average_load=`echo "scale=2;a=$load_15/$cpu_num;if(length(a)==scale(a)) print 0;print a" | bc`

#取上面平均负载值的个位整数
average_int=`echo $average_load | cut -f 1 -d "."`

#当单个核心15分钟的平均负载值大于等于1.0（即个位整数大于0） ，直接发邮件告警；如果小于1.0则进行二次比较
if (($average_int > 0)); then
#echo "$IP服务器15分钟的系统平均负载为$average_load，超过警戒值1.0，请立即处理！！！" | mutt -s "$IP 服务器系统负载严重告警！！！" test@126.com
    TITLE="[bad_girl]:$HOSTNAME@$IP sys_load usage"
    MESSAGE="Time:${DATA},average load:${average_int}"
    send_warning
else

#当前系统15分钟平均负载值与告警值进行比较（当大于告警值0.70时会返回1，小于时会返回0 ）
load_now=`expr $average_load \> $load_warn`

#如果系统单个核心15分钟的平均负载值大于告警值0.70（返回值为1），则发邮件给管理员
if (($load_now == 1)); then
#echo "$IP服务器15分钟的系统平均负载达到 $average_load，超过警戒值0.70，请及时处理。" | mutt -s "$IP 服务器系统负载告警" test@126.com
    TITLE="[bad_girl]:$HOSTNAME@$IP sys_load usage"
    MESSAGE="Time:${DATA},average_load:${average_load} > 0.70 warnning"
    send_warning
fi

fi

#MEM|SWAP check
MEMSTATUS=`free | grep "Mem" | awk '{printf("%d", $3*100/$2)}'`
#SWAPSTATUS=`free | grep "Swap" | awk '{printf("%d", $3*100/$2)}'`

if [ $MEMSTATUS -ge $MEM_CORDON ];then
    TITLE="[bad_girl]:$HOSTNAME@$IP mem usage"
    MESSAGE="Time:${DATA},Mem_used:${MEMSTATUS}%"
    send_warning
fi

#if [ $SWAPSTATUS -ge $SWAP_CORDON ];then
#    TITLE="[bad_girl]:$HOSTNAME@$IP Swap usage"
#    MESSAGE="Time:${DATA},Mem_used:${MEMSTATUS}%,Swap_used:${SWAPSTATUS}%"
#    send_warning
#fi    

#cpu

CPUSTATUS=`vmstat | awk '{print $15}' | tail -1`

if [ $CPUSTATUS -le $CPU_CORDON ];then
    TITLE="[bad_girl]:$HOSTNAME@$IP cpu usage"
    MESSAGE="Time:${DATA},MCpu_free:${CPUSTATUS}%"
fi

#disk use n%

DISKSTATUS=`df -h $DISK_DIR | awk '{print $5}' | tail -1 | tr -d %`

if [ $DISKSTATUS -ge $DISK_CORDON ];then
    TITLE="[bad_girl]:$HOSTNAME@$IP disk usage"
    MESSAGE="Time:${DATA},Disk_used:${DISKSTATUS}%"
    send_warning
fi
