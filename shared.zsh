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

lock_create write
lock_create read
lock_lock write
lock_lock read

function ____shared()  {
    zpty -w testW "$@"
    lock_unlock write
    lock_lock read

    local line=""
    while zpty -r testR buffer; do
        line+="$buffer"
    done
    echo ${line//$'\015'} | sed \$d
}

function shared() {
    if [[ $# == 1 ]]; then
        ____get $1
    elif [[ $# == 2 ]]; then
        ____set $1 $2
    fi
}

function ____set() {
    ____shared "$1=${(qqq)2}"
}

function ____get() {
    ____shared "echo \$$1"
}

____shared_server &

