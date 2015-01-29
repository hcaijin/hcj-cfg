#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#PS1='[\u@\h \W]\$ '  # To leave the default one
#DO NOT USE RAW ESCAPES, USE TPUT
reset=$(tput sgr0)
red=$(tput setaf 1)
blue=$(tput setaf 4)
green=$(tput setaf 2)

PS1='\[$red\]\u\[$reset\] \[$blue\]\w\[$reset\] \[$red\]\$ \[$reset\]\[$green\] '
PATH=$PATH:$HOME/bin

# 开启sudo,man的自动补全
complete -cf sudo
complete -cf man

# alias 配置
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

########### export HISTSIZE ####################
# 设置保存历史命令的文件大小
export HISTFILESIZE=1000000000
# 保存历史命令条数
export HISTSIZE=1000000
# 实时记录历史命令，默认只有在用户退出之后才会统一记录，很容易造成多个用户间的相互覆盖。
#export PROMPT_COMMAND="history -a"
# 记录每条历史命令的执行时间
export HISTTIMEFORMAT="%Y-%m-%d_%H:%M:%S "
export HISTCONTROL=ignoreboth
export HISTIGNORE='history*'
export PROMPT_COMMAND='history -a;echo -en "\e]2;";history 1|sed "s/^[ \t]*[0-9]\{1,\}  //g";echo -en "\e\\";'
export HISTCONTROL=erasedups
export HISTIGNORE="pwd:ls:ll:la:"
#export HISTCONTROL=ignorespace


shopt -s autocd
shopt -s checkwinsize


cl() {
    local dir="$1"
    local dir="${dir:=$HOME}"
    if [[ -d "$dir" ]]; then
        cd "$dir" >/dev/null; ls
    else
        echo "bash: cl: $dir: Directory not found"
    fi
}


calc() {
    echo "scale=3;$@" | bc -l
}

inote () {
    # if file doesn't exist, create it
    if [[ ! -f $HOME/.notes ]]; then
        touch "$HOME/.notes"
    fi

    if ! (($#)); then
        # no arguments, print file
        cat "$HOME/.notes"
    elif [[ "$1" == "-c" ]]; then
        # clear file
        > "$HOME/.notes"
    else
        # add all arguments to file
        printf "%s\n" "$*" >> "$HOME/.notes"
    fi
}

todo() {
    if [[ ! -f $HOME/.todo ]]; then
        touch "$HOME/.todo"
    fi

    if ! (($#)); then
        cat "$HOME/.todo"
    elif [[ "$1" == "-l" ]]; then
        nl -b a "$HOME/.todo"
    elif [[ "$1" == "-c" ]]; then
        > $HOME/.todo
    elif [[ "$1" == "-r" ]]; then
        nl -b a "$HOME/.todo"
        eval printf %.0s- '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
        read -p "Type a number to remove: " number
        sed -i ${number}d $HOME/.todo "$HOME/.todo"
    else
        printf "%s\n" "$*" >> "$HOME/.todo"
    fi
}

ipif() { 
    if grep -P "(([1-9]\d{0,2})\.){3}(?2)" <<< "$1"
    then
        curl ipinfo.io/"$1"
    else
        local ipadd=$(host "$1") &&
        local ipawk=$(awk '{ print $4 }' <<< "$ipadd")
        curl ipinfo.io/"$ipawk"
    fi
    echo
}

#Now open a terminal and just do:  
#secure_chromium
function secure_chromium {
    port=1080
    #使用以下两种配置都可以
    #export SOCKS_SERVER=localhost:$port
    #export SOCKS_VERSION=5
    #chromium &
    chromium --proxy-server="socks://localhost:$port" &
    exit
}

#help url https://wiki.archlinux.org/index.php/Pacman_tips#Shortcuts
pacman-size()
{
    CMD="pacman -Si"
    SEP=": "
    TOTAL_SIZE=0
    
    RESULT=$(eval "${CMD} $@ 2>/dev/null" | awk -F "$SEP" -v filter="Size" -v pkg="^Name" \
      '$0 ~ pkg {pkgname=$2} $0 ~ filter {gsub(/\..*/,"") ; printf("%6s KiB %s\n", $2, pkgname)}' | sort -u -k3)
    
    echo "$RESULT"
    
    ## Print total size.
    echo "$RESULT" | awk '{TOTAL=$1+TOTAL} END {printf("Total : %d KiB\n",TOTAL)}'
}

