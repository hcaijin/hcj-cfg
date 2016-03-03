#!/bin/bash
# archive linux command history files
# written by vpsee.com

umask 077
maxlines=2000

lines=$(wc -l < ~/.bash_history)

if (($lines > $maxlines)); then
    cut=$(($lines - $maxlines))
    head -$cut ~/.bash_history >> ~/.bash_history.sav
    sed -e "1,${cut}d"  ~/.bash_history > ~/.bash_history.tmp
    mv ~/.bash_history.tmp ~/.bash_history
fi
