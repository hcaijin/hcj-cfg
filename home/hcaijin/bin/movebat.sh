#!/bin/bash
if [[ -z "$1" ]] || [[ ! -d "$1" ]]; then
    echo "The directory is empty or not exist!"
    echo "It will use the current directory."
    nowdir=$(pwd)
else
    nowdir=$(cd $1; pwd)
fi

## debug: echo $nowdir;

function searchfile(){
    cd $nowdir
    cfilelist=$(ls -l | grep "^-" | awk '{print $9}')
    for cfilename in $cfilelist
    do
        echo $cfilename
    done
}

function ergodic(){
    for file in `  find ${nowdir} -maxdepth 1 -type f | awk -F. '{print $NF}' `
    do
        if [ -f ${nowdir}"/"$file ]; then
            path=${nowdir}"/"$file  #得到文件的完整的目录
            name=$file        #得到文件的名字
            #做自己的工作.
            echo $path
            echo $name
        fi
    done
}

ergodic $1
