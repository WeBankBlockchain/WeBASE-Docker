#!/bin/bash
SHELL_FOLDER=$(cd $(dirname $0);pwd)

fisco_bcos=${SHELL_FOLDER}/../fisco-bcos
node=$(basename ${SHELL_FOLDER})
node_pid=$(docker ps |grep ${SHELL_FOLDER//\//} | grep -v grep|awk '{print $1}')
try_times=10
i=0
if [ -z ${node_pid} ];then
    echo " ${node} isn't running."
    exit 0
fi
[ ! -z ${node_pid} ] && docker kill ${node_pid} 2>/dev/null > /dev/null
while [ $i -lt ${try_times} ]
do
    sleep 0.6
    node_pid=$(docker ps |grep ${SHELL_FOLDER//\//} | grep -v grep|awk '{print $1}')
    if [ -z ${node_pid} ];then
        echo -e "\033[32m stop ${node} success.\033[0m"
        exit 0
    fi
    ((i=i+1))
done
echo "  Exceed maximum number of retries. Please try again to stop ${node}"
exit 1
