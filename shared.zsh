#/bin/zsh
source "${0:a:h}/lock.zsh"

function ____read_from_buffer() {
    local line="" pipe="$1"
    while zpty -r $pipe buffer; do
        line+="$buffer"
    done
    echo ${line//$'\015'} | sed \$d
}

function ____shared_server() {
    while true; do
        lock_lock write

        local line=$(____read_from_buffer writePipe)

        eval "function tmp() { $line }"
        result=$(tmp)
        eval "unset -f tmp"

        eval $line &>/dev/null

        zpty -w readPipe "$result"
        lock_unlock read
    done
}

zpty -d writePipe 2>/dev/null
zpty -b writePipe cat
zpty -d readPipe 2>/dev/null
zpty -b readPipe cat

lock_create server_access
lock_create write
lock_create read
lock_lock write
lock_lock read

function ____shared()  {
    lock_lock server_access
    zpty -w writePipe "$@"
    lock_unlock write
    lock_lock read

    ____read_from_buffer readPipe

    lock_unlock server_access
}

function shared() {
    option=$options[shwordsplit]

    unsetopt shwordsplit
    declare -f "shared_$1" &>/dev/null || return
    local command=$1
    shift

    shared_$command "$@"
    options[shwordsplit]=$option
}

function shared_var() {
  if [[ $# == 1 ]]; then
      ____shared "echo \$$1"
  elif [[ $# == 2 ]]; then
      ____shared "$1=${(qqq)2}"
  fi
}

function shared_map() {
    if [[ $# == 1 ]]; then
        ____shared "typeset -Ag $1"
    elif [[ $# == 2 ]]; then
        ____shared "echo \$$1[$2]"
    elif [[ $# == 3 ]]; then
        ____shared "$1[$2]=${(qqq)3}"
    fi
}

function shared_exe() {
  ____shared "$@"
}

function shared_start() {
    ____shared_server &!
    ____shared_pid=$!
    echo "Shared server created"
}

function shared_stop() {
    kill -9 $____shared_pid &>/dev/null
    echo "Shared server killed"
}

