#!/bin/bash
usage() {
    echo "Usage: $(basename $0) [options] [<access-point-name> [<passphrase>]]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help"
    echo "  -f <file>               Server Ip list "
    echo "  --scp <local> <server>  Batch do scp local to server"
    echo "  --bat <bash>            Batch do bash "
    echo "  --sci                   Batch do ssh-copy-id to server"        
    echo "  --list                  List file Ip list " 
    echo
    echo "Useful informations:"
    echo "  * If you're not using the --no-virt option, then you can create an AP with the same"
    echo "    interface you are getting your Internet connection."
    echo "  * You can pass your SSID and password through pipe or through arguments (see examples)."
    echo "  * On bridge method if the <interface-with-internet> is not a bridge interface, then"
    echo "    a bridge interface is created automatically."
    echo
    echo "Examples:"
    echo "  $(basename $0) -f <file> --scp <local file> <server dir>"
    echo "  $(basename $0) -f <file> --bat 'ls -al' "
    echo "  $(basename $0) -f <file> --sci "
    echo "  $(basename $0) -f <file> --list "
}

#$FILES文件里面ip和密码写法  
#192.168.0.2:admin2  
#192.168.0.3:admin3
scpdo() {
    for h in $(cat $FILES|cut -f1 -d":")  
    do 
    scp ${SCPFILE} root@$h:${SCPDIR}
    done 
}

batchdo() {
    for h in $(cat $FILES|cut -f1 -d":")  
    do 
    ssh root@$h ${DOBASH}
    #如果命令是多行的，请参照下面  
    #ssh root@$h '此处写要执行的命令1' 
    #ssh root@$h '此处写要执行的命令2' 
    done 
}

#批量ssh认证建立
ssh_copy_id() {
    for p in $(cat $FILES)  #注意ip.txt文件的绝对路径
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
}

list_ip() {
    cat $FILES
}

#通过ssh批量执行命令  
GETOPT_ARGS=$(getopt -o hf: -l "help","scp","bat","sci","list" -n $(basename $0) -- "$@")
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
        --scp)
            shift
            DOSCP=1
            ;;
        --bat)
            shift
            BATCHDO=1
            ;;
        --sci)
            shift
            SSHCOPYID=1
            ;;
        --list)
            shift
            LIST_IP=1
            ;;
        --)
            shift
            LIST_IP=1
            break
            ;;
    esac
done

if [[ ! -f "$FILES" ]]; then
    echo "文件：${FILES}不存在";
    exit 0
fi

if [[ $DOSCP -eq 1 ]]; then
    SCPFILE=$1
    SCPDIR=$2
    scpdo
    exit 1
fi

if [[ $BATCHDO -eq 1 ]]; then
    DOBASH=$1
    batchdo
    exit 1
fi

if [[ $LIST_IP -eq 1 ]]; then
    list_ip
    exit 1
fi

if [[ $SSHCOPYID -eq 1 ]]; then
    ssh_copy_id
    exit 1
fi

