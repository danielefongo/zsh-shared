#/bin/zsh
source lock.zsh

function ____shared_server() {
    while true; do
        lock_lock write
        local line=""
        while zpty -r testW buffer; do
            line+="$buffer"
        done
        
        eval "function tmp() { ${line//$'\015'} }" 
        result=$(tmp)
        eval ${line//$'\015'} &>/dev/null

        zpty -w testR "$result"
        lock_unlock read
    done    
}

zpty -d testW 2>/dev/null
zpty -b testW cat
zpty -d testR 2>/dev/null
zpty -b testR cat

lock_create server_access
lock_create write
lock_create read
lock_lock write
lock_lock read

function ____shared()  {
    lock_lock server_access
    zpty -w testW "$@"
    lock_unlock write
    lock_lock read

    local line=""
    while zpty -r testR buffer; do
        line+="$buffer"
    done
    echo ${line//$'\015'} | sed \$d
    lock_unlock server_access
}

function shared() {
    if [[ $# == 1 ]]; then
        ____get $1
    elif [[ $# == 2 ]]; then
        ____set $1 $2
    fi
}

function shared_map() {
    if [[ $# == 1 ]]; then
        ____map_create $1
    elif [[ $# == 2 ]]; then
        ____map_get $1 $2
    elif [[ $# == 3 ]]; then
        ____map_set $1 $2 $3
    fi
}

function ____set() {
    ____shared "$1=${(qqq)2}"
}

function ____get() {
    ____shared "echo \$$1"
}

function ____map_create() {
    ____shared "typeset -Ag $1"
}

function ____map_set() {
    ____shared "$1[$2]=${(qqq)3}"
}

function ____map_get() {
    ____shared "echo \$$1[$2]"
}

function shared_start() {
    ____shared_server &
    ____shared_pid=$!
    echo "Shared server created"
}

function shared_stop() {
    kill -9 $____shared_pid &>/dev/null
    echo "Shared server killed"
}

