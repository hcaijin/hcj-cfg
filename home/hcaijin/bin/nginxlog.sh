#!/bin/bash
usage() {
    echo "Usage: $(basename $0) [options] [<access-point-name> [<passphrase>]]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help"
    echo "  -f <file>               The nginx log file"
    echo "  --time                  Get most of the time"
    echo "  --status                Get most of the status"
    echo "  --page                  Get most of the page"
    echo "  --ip                    Get most of the ip"
    echo "  --tip                   Get most of the time/ip"
    echo "  --request               Get most of the request"
    echo "  --rip                   Get most of the request/ip"
    echo
    echo "Useful informations:"
    echo "  * If you're not using the --no-virt option, then you can create an AP with the same"
    echo "    interface you are getting your Internet connection."
    echo "  * You can pass your SSID and password through pipe or through arguments (see examples)."
    echo "  * On bridge method if the <interface-with-internet> is not a bridge interface, then"
    echo "    a bridge interface is created automatically."
    echo
    echo "Examples:"
    echo "  $(basename $0) -f <file> --time "
}

####################################
getStatus(){
    echo "Most of the status:"
    echo "---------------------------------------------------"
    awk '{print $9}' $LOG | sort | uniq -c | sort -nr 
    echo 
    echo
}
####################################
getIp(){
    echo "Most of the ip:"
    echo "---------------------------------------------------"
    awk '{print $1}' $LOG | sort | uniq -c | sort -nr | head -10
    echo 
    echo
}
#####################################
getTime(){
    echo "Most of the time:"
    echo "---------------------------------------------------"
    awk '{print $4}' $LOG | cut -c14-18 | sort | uniq -c | sort -nr | head -10
    echo
    echo
}
#####################################
getRequest(){
    echo "Most of the Request:"
    echo "---------------------------------------------------"
    awk '{print $7}' $LOG | sort | uniq -c | sort -nr | head -10
    echo
    echo
}
#####################################
getPage(){
    echo "Most of the page:"
    echo "---------------------------------------------------"
    awk '{print $11}' $LOG | sed 's/^.* \(.cn* \)\"/\1/g' | sort | uniq -c | sort -nr | head -10
    echo
    echo
}
#####################################
getTimeOnIp(){
    echo "Most of the time / Most of the ip:"
    echo "---------------------------------------------------"
    awk '{print $4}' $LOG | cut -c14-18 | sort -n | uniq -c | sort -nr | head -10 > timelog

    for i in `awk '{print $2}' timelog`
    do
        num=`grep $i timelog | awk '{print $1}'`
        echo " $i $num"
        ip=`grep $i $LOG | awk '{print $1}' | sort -n | uniq -c | sort -nr | head -10`
        echo "$ip"
        echo
    done
    rm -rf timelog
}
#####################################
getReOnIp(){
    echo "Most of the request / Most of the ip:"
    echo "---------------------------------------------------"
    awk '{print $7}' $LOG | sort | uniq -c | sort -nr | head -10 > pagelog

    for i in `awk '{print $2}' pagelog`
    do
        num=`grep $i pagelog | awk '{print $1}'`
        echo " $i $num"
        ip=`grep $i $LOG | awk '{print $1}' | sort -n | uniq -c | sort -nr | head -10`
        echo "$ip"
        echo
    done
    rm -rf pagelog
}

#通过ssh批量执行命令  
GETOPT_ARGS=$(getopt -o hf: -l "help","time","status","page","ip","tip","request","rip" -n $(basename $0) -- "$@")
[[ $? -ne 0 ]] && exit 1
eval set -- "$GETOPT_ARGS"
  
while :; do
    case "$1" in
        -h|--help)
            usage >&2
            exit 1
            ;;
        -f)
            shift
            FILES="$1"
            shift
            ;;
        --time)
            shift
            ISTIME=1
            ;;
        --status)
            shift
            ISSTATUS=1
            ;;
        --page)
            shift
            ISPAGE=1
            ;;
        --ip)
            shift
            ISIP=1
            ;;
        --tip)
            shift
            ISTIP=1
            ;;
        --rip)
            shift
            ISRIP=1
            ;;
        --request)
            shift
            ISREQUEST=1
            ;;
        --)
            shift
            ISALL=1
            break
            ;;
    esac
done

if [ ! -f $FILES ]; then
    echo "Sorry, sir, I can't find this log file, pls try again!"
    exit 0
fi

if [[ $ISTIME -eq 1 ]]; then
    LOG=$FILES
    getTime
    exit 0
fi

if [[ $ISSTATUS -eq 1 ]]; then
    LOG=$FILES
    getStatus
    exit 0
fi

if [[ $ISPAGE -eq 1 ]]; then
    LOG=$FILES
    getPage
    exit 0
fi

if [[ $ISIP -eq 1 ]]; then
    LOG=$FILES
    getIp
    exit 0
fi

if [[ $ISTIP -eq 1 ]]; then
    LOG=$FILES
    getTimeOnIp
    exit 0
fi

if [[ $ISRIP -eq 1 ]]; then
    LOG=$FILES
    getReOnIp
    exit 0
fi

if [[ $ISREQUEST -eq 1 ]]; then
    LOG=$FILES
    getRequest
    exit 0
fi

if [[ $ISALL -eq 1 ]]; then
    LOG=$FILES
    getTime
    getStatus
    getRequest
    getPage
    getIp
    getTimeOnIp
    getReOnIp
    exit 0
fi
