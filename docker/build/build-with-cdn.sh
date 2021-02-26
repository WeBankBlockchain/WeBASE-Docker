#!/usr/bin/env bash

# 常量配置
PROJECT_NAME="WeBASE-Front"

LOG_WARN()
{
    local content=${1}
    echo -e "\033[31m[WARN] ${content}\033[0m"
}

LOG_INFO()
{
    local content=${1}
    echo -e "\033[32m[INFO] ${content}\033[0m"
}

# 命令返回非 0 时，就退出
set -o errexit
# 管道命令中任何一个失败，就退出
set -o pipefail
# 遇到不存在的变量就会报错，并停止执行
set -o nounset
# 在执行每一个命令之前把经过变量展开之后的命令打印出来，调试时很有用
#set -o xtrace

# 退出时，执行的命令，做一些收尾工作
trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; trap ERR;  exit 1' ERR

# Set magic variables for current file & dir
# 脚本所在的目录
#__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 脚本的全路径，包含脚本文件名
#__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
# 脚本的名称，不包含扩展名
#__base="$(basename ${__file} .sh)"
# 脚本所在的目录的父目录，一般脚本都会在父项目中的子目录，
#     比如: bin, script 等，需要根据场景修改
#__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app


###########################################
# 编译后镜像 FISCO-BCOS & WeBASE-Front 的版本，推送的 Docker registry 仓库
new_tag=""
latest_tag="latest"
docker_repository="fiscoorg/fisco-webase"
docker_push="no"

# 指定 WeBASE-Front 账号（开发调试使用）
git_account="WeBank"
# WeBASE-Front 的分支
front_branch=dev
# webase front默认版本
front_version="v1.4.2"

# 父镜像 FISCO-BCOS 的版本
bcos_image_tag="latest"

# 解析参数
__cmd="$(basename $0)"
# usage help doc.
usage() {
    cat << USAGE  >&2
Usage:
    ${__cmd}    [-t new_tag] [-c bcos_version] [-a git_account] [-b front_branch] [-r docker_repository] [-p] [-h]
    -t          Docker image new_tag, required.

    -c          BCOS docker image tag, default v2.4.0, equal to fiscoorg/fiscobcos:v2.4.0.
    -f          Front version to pull from cdn, default v1.4.2
    -a          Git account, default WeBankFinTech.
    -b          Branch of WeBASE-Front, default master.
    -r          Which repository new image will be pushed to, default fiscoorg/front.
    -p          Execute docker push, default no.
    -h          Show help info.
USAGE
    exit 1
}
while getopts t:c:f:a:b:r:ph OPT;do
    case $OPT in
        t)
            new_tag=${OPTARG}
            ;;
        c)
            bcos_image_tag=${OPTARG}
            ;;
        f)
            front_version=${OPTARG}
            ;;
        a)
            git_account=${OPTARG}
            ;;
        b)
            front_branch=${OPTARG}
            ;;
        r)
            docker_repository=${OPTARG}
            ;;
        p)
            docker_push=yes
            ;;
        h)
            usage
            exit 3
            ;;
        \?)
            usage
            exit 3
            ;;
    esac
done

# 必须设置新镜像的版本
if [[ "${new_tag}"x == "x" ]] ; then
  LOG_WARN "Need a new_tag for new docker image!! "
  usage
  exit 1
fi

# FISCO-BCSO 的 docker 镜像是 -gm 结尾, 使用国密
#encrypt_type="0"
#if [[ ${bcos_image_tag} == *-gm ]] ; then
  # update application.yml of WeBASE-Front
#  encrypt_type="1"

#  if [[ ${new_tag} != *-gm ]] ; then
#    new_tag="${new_tag}-gm"
#    latest_tag="${latest_tag}-gm"
#  fi

#  LOG_INFO "FISCO-BCOS docker image:[${bcos_image_tag}] ends with [-gm], use guomi model, new image tag:[${new_tag} and ${latest_tag}]"
#fi

# 拉取 WeBASE-Front
wget https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/WeBASE/releases/download/${front_version}/webase-front.zip
unzip webase-front.zip && mv webase-front dist && rm -f webase-front.zip
#WEBASE_FRONT_GIT="https://gitee.com/${git_account}/${PROJECT_NAME}.git";
#LOG_INFO "git pull WeBASE-Front's branch: [${front_branch}] from ${WEBASE_FRONT_GIT}"
#git clone -b "${front_branch}" "${WEBASE_FRONT_GIT}" --depth=1

# # 使用国密编译
#cd "${PROJECT_NAME}" && chmod +x ./gradlew && ./gradlew clean build -x test && cd ..
#rm -rfv ./dist &&  mv -fv ${PROJECT_NAME}/dist . && rm -rf ${PROJECT_NAME}
#mv -fv dist/conf_template dist/conf

# # conf里增加sol 0.6支持
#mkdir dist/conf/solcjs
#wget -P dist/conf/solcjs https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/WeBASE/download/solidity/v0.6.10.js
#wget -P dist/conf/solcjs https://osp-1257653870.cos.ap-guangzhou.myqcloud.com/WeBASE/download/solidity/v0.6.10-gm.js

# 修改application.yml 配置
#sed -i "s/encryptType.*#/encryptType: ${encrypt_type} #/g" dist/conf/application.yml

new_image="${docker_repository}":"${new_tag}"
sudo docker build -f Dockerfile --build-arg BCOS_IMG_VERSION="${bcos_image_tag}" -t "${new_image}" .
sudo docker tag "${new_image}" ${docker_repository}:"${latest_tag}"

rm -rf dist

if [[ "${docker_push}"x == "yesx" ]] ; then
    docker push "${docker_repository}":"${new_tag}"
    docker push "${docker_repository}":"${latest_tag}"
fi
