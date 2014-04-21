#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

# 开启sudo的自动补全
complete -cf sudo

# alias 配置
alias ls='ls --color=auto'
alias ll='ls --color=auto -al'
alias rm='rm -i'
alias sudo='sudo -E'

########### export HISTSIZE ####################
# 设置保存历史命令的文件大小
export HISTFILESIZE=1000000000
# 保存历史命令条数
export HISTSIZE=1000000
# 实时记录历史命令，默认只有在用户退出之后才会统一记录，很容易造成多个用户间的相互覆盖。
#export PROMPT_COMMAND="history -a"
# 记录每条历史命令的执行时间
export HISTTIMEFORMAT="%Y-%m-%d_%H:%M:%S "
