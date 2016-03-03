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

PRE_FIX='<plugin><groupId>org.eclipse.jetty</groupId><artifactId>jetty-maven-plugin</artifactId><version>8.1.16.v20140903</version><!--支持java1.7--><configuration><scanIntervalSeconds>10</scanIntervalSeconds><webApp><contextPath>/</contextPath></webApp></configuration></plugin>' 

PRE_FIX2=<<EOF
             <plugin>
                <groupId>org.eclipse.jetty</groupId>
                <artifactId>jetty-maven-plugin</artifactId>
                <version>8.1.16.v20140903</version> <!-- 支持 java1.7 -->
                <configuration>
                    <scanIntervalSeconds>10</scanIntervalSeconds>
                    <webApp>
                        <contextPath>/</contextPath>
                    </webApp>
                </configuration>
            </plugin>
EOF


NOWDIR=$(pwd)
POM_FILE=${NOWDIR}/pom.xml

if [[ ! -f "$POM_FILE" ]]; then
    echo "当前文件夹下无 pom.xml 文件！"
    exit 1
fi

# grep $PRE_FIX `cat ${POM_FILE} | sed 's/[[:space:]]//g' | tr -d '\n'`
grep $PRE_FIX2 `cat ${POM_FILE}` 

if [[ $? == 0 ]]; then
    echo "Success!"
    exit 0
else
    echo "Error!"
    exit 1
fi


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
    terminfo=$( ssh root@$ip 'ls .terminfo/r/rxvt-unicode-256color')
    #判断是否有terminfo
    if [[ ! -f "$terminfo" ]]; then
        ssh root@$ip 'mkdir -p ~/.terminfo/r/'; scp /usr/share/terminfo/r/rxvt-unicode-256color root@$ip:~/.terminfo/r/
    fi
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
        -p)
            shift
            PORT="$1"
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

if [[ $PORT < 1000 || $PORT > 65555 ]]; then
    echo "端口号：${PORT}至少大于1000,小于65555";
    exit 1
fi

if [[ $DOSCP -eq 1 ]]; then
    SCPFILE=$1
    SCPDIR=$2
    scpdo
    exit 1
fi

if [[ $BATCHDO -eq 1 ]]; then
    DOBASH='echo "==============================>>"; hostname ;ip a | grep "inet " | grep -v "127.0.0.1" | awk "{print \"#######\"\$NF\"::\"\$2}" | cut -d \/ -f1; '$1' ;echo "<<=============================";'
    batchdo
    exit 1
fi

if [[ $SSHCOPYID -eq 1 ]]; then
    ssh_copy_id
    exit 1
fi

if [[ $LIST_IP -eq 1 ]]; then
    list_ip
    exit 1
fi
