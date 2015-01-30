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
    old=$IFS
    IFS=$'\n';
    cd $nowdir
    for file in `  find . -maxdepth 1 -type f | awk -F/ '{print $NF}' `
    do
        if [ -f ${nowdir}"/"$file ]; then
            path=${nowdir}"/"$file  #得到文件的完整的目录
            name=$file        #得到文件的名字
            #做自己的工作.
            echo $path
            echo $name
        fi
    done
    IFS=$old
}

### 打印文件
function print_file(){
    cd $nowdir
    for file in `  find . -maxdepth 1 -type f -print0 `
    do
            path=${nowdir}"/"$file  #得到文件的完整的目录
            name=$file        #得到文件的名字
            #做自己的工作.
            echo $path
            echo $name
    done
}

### 检查文件的格式
function checkFile(){
    cd $nowdir
    for fileType in `find . -maxdepth 1 -type f -print0 | xargs -0 file |  cut -d ":" -f2- | sed 's/^ *//g'`
    do
        case "$fileType" in
            "*PNG*")
                if [ ! -d $PICTRUE ]; then
                    mkdir $PICTRUE
                fi
        esac
    done
}

checkFile $1
