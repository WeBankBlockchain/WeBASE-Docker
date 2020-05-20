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
# 新镜像的版本
new_tag=""
# 拉取哪个版本的 WeBASE-Front（开发调试使用）
git_account="WeBankFinTech"
# WeBASE-Front 的分支
front_branch=master
# 是否使用国密
guomi_model=no
# bcos 的 Docker 镜像版本
bcos_image_tag="v2.2.0"
# FISCO-BCOS 和 WeBASE-Front 镜像的 Docker Hub repository
docker_repository="fiscoorg/front"

# 解析参数
__cmd="$(basename $0)"
# usage help doc.
usage() {
    cat << USAGE  >&2
Usage:
    ${__cmd}    [-t new_tag] [-c bcos_version] [-a git_account] [-b front_branch] [-p docker_repository] [-g] [-h]
    -t          Docker image new_tag, required.
    
    -c          BCOS docker image tag, default v2.4.0, equal to fiscoorg/fiscobcos:v2.4.0.
    -a          Git account, default WeBankFinTech.
    -b          Branch of WeBASE-Front, default master.
    -p          Which repository new image will be pushed to, default fiscoorg/front.
    -g          Use guomi, default no.
    -h          Show help info.
USAGE
    exit 1
}
while getopts t:c:a:b:p:gh OPT;do
    case $OPT in
        t)
            new_tag=${OPTARG}
            ;;
        c)
            bcos_image_tag=${OPTARG}
            ;;
        a)
            git_account=${OPTARG}
            ;;
        g)
            guomi_model=yes
            ;;
        b)
            front_branch=${OPTARG}
            ;;
        p)
            docker_repository=${OPTARG}
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

if [[ "${guomi_model}"x == "yesx" ]] ; then
  # 如果是国密，检查 BCOS 的docker 镜像是否是 -结尾 gm
  if [[ ${bcos_image_tag} != *-gm ]] ; then
    LOG_WARN "BCOS docker image:[${bcos_image_tag}] should end with [-gm] when use guomi model."
    exit 1;
  fi
fi

# 拉取 WeBASE-Front
WEBASE_FRONT_GIT="https://github.com/${git_account}/${PROJECT_NAME}.git";
LOG_INFO "git pull WeBASE-Front's branch: [${front_branch}] from ${WEBASE_FRONT_GIT}"
git clone -b "${front_branch}" "${WEBASE_FRONT_GIT}" --depth=1

# 使用国密编译
cd "${PROJECT_NAME}" && chmod +x ./gradlew && ./gradlew clean build -x test && cd ..
rm -rfv ./dist &&  mv -fv ${PROJECT_NAME}/dist . && rm -rf ${PROJECT_NAME}
mv -fv dist/conf_template dist/conf

# 修改application.yml 配置
if [[ "${guomi_model}"x == "yesx" ]] ; then
  sed -i "s/encryptType.*#/encryptType: 1 #/g" dist/conf/application.yml
else
  sed -i "s/encryptType.*#/encryptType: 0 #/g" dist/conf/application.yml
fi

LOG_INFO "Docker image new_tag is [${new_tag}]"
docker build --build-arg BCOS_IMG_VERSION="${bcos_image_tag}" -t front:"${new_tag}" .
docker tag  front:"${new_tag}" fiscoorg/front:"${new_tag}"

rm -rf dist
docker push "${docker_repository}":"${new_tag}"