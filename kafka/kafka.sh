#!/usr/bin/env bash


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

# get config vars
if [[ -z "$NodeName" ]]; then
  NodeName="$(hostname)"
elif [[ -n "$XNN" ]]; then
  NodeName="$XNN"
fi

check_non_empty "${NodeName}" "NodeName"

# set data dir
MyData=/data/kafka


# -v ${CurDir}/conf/kafka.conf:/usr/local/etc/kafka/kafka.conf \

start() {
  docker kill kafka 2>/dev/null
  docker rm -v kafka 2>/dev/null

  docker run -d --name kafka \
    --net=host\
    --env-file=envs.sh \
    -v ${MyData}:/bitnami/kafka \
    --log-opt max-size=10m \
    --log-opt max-file=9 \
    wurstmeister/kafka

  check_exec_success "$?" "start kafka container"
}

stop() {
  docker stop kafka 2>/dev/null
  docker rm -v kafka 2>/dev/null
}

destroy() {
  stop
  rm -rf ${MyData}
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
    echo "./kafka.sh start|stop|restart"
    echo "./kafka.sh destroy"
    exit 1
    ;;
esac

exit 0
