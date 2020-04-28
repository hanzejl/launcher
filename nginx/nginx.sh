#!/bin/bash

check_non_empty() {
    # $1 is the content of the variable in quotes e.g. "$FROM_EMAIL"
    # $2 is the error message
    if [[ "$1" == "" ]]; then
        echo "ERROR: specify $2"
        exit -1
    fi
}

check_exec_success() {
    # $1 is the content of the variable in quotes e.g. "$FROM_EMAIL"
    # $2 is the error message
    if [[ "$1" != "0" ]]; then
        echo "ERROR: $2 failed"
        echo "$3"
        exit -1
    fi
}

CurDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -a ${CurDir}/envs.sh ]]; then
    source ${CurDir}/envs.sh
fi

# get config vars
if [[ -z "$NodeName" ]]; then
    NodeName="$(hostname)"
elif [[ -n "$XNN" ]]; then
    NodeName="$XNN"
fi
NodeDisk="${NodeDisk:-hdd}"
if [[ -n "$XND" ]]; then
    NodeDisk="$XND"
fi

check_non_empty "${NodeName}" "NodeName"
check_non_empty "${NodeDisk}" "NodeDisk"

# get host ip
HostIP="$(ip route get 1 | awk '{print $NF;exit}')"

start() {

    docker kill nginx 2>/dev/null
    docker rm -v nginx 2>/dev/null

    docker run -d --name nginx \
           -v ${CurDir}/conf/conf.d:/etc/nginx/conf.d \
           --net=host \
           --restart=always \
           --log-opt max-size=10m \
           --log-opt max-file=9 \
           registry.cn-hangzhou.aliyuncs.com/docker-ant/nginx:1.10

    check_exec_success "$?" "start nginx container"
}

stop() {
    docker stop nginx 2>/dev/null
    docker rm -v nginx 2>/dev/null
}

destroy() {
    stop
    rm -rf ${ESData}
    rm -rf ${ESLog}
}


##################
# Start of script
##################

case "$1" in
    start) start ;;
    stop) stop ;;
    restart)
        stop
        start
        ;;
    destroy) destroy ;;
    *)
        echo "Usage:"
        echo "./nginx.sh start|stop|restart"
        echo "./nginx.sh destroy"
        exit 1
        ;;
esac

exit 0
