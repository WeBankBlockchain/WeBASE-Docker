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
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 脚本的全路径，包含脚本文件名
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
# 脚本的名称，不包含扩展名
__base="$(basename ${__file} .sh)"
# 脚本所在的目录的父目录，一般脚本都会在父项目中的子目录，
#     比如: bin, script 等，需要根据场景修改
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app


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

# 解析参数
__cmd="$(basename $0)"
# usage help doc.
usage() {
    cat << USAGE  >&2
Usage:
    ${__cmd}    [-t new_tag] [-a git-account] [-c bcos_version] [-b front-branch] [-g] [-h]
    -t          Docker image new_tag, required.

    -c          BCOS docker image new_tag, default v2.2.0, equal to fiscoorg/fiscobcos:v2.2.0.
    -a          Git account, default WeBankFinTech.
    -g          Use guomi, default no.
    -b          Branch of WeBASE-Front, default master.
    -h          Show help info.
USAGE
    exit 1
}
while getopts t:c:a:b:gh OPT;do
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

# 拉取 WeBASE-Front
WEBASE_FRONT_GIT="https://github.com/${git_account}/${PROJECT_NAME}.git";
LOG_INFO "git pull WeBASE-Front's branch: [${front_branch}] from ${WEBASE_FRONT_GIT}"
git clone -b "${front_branch}" ${WEBASE_FRONT_GIT} --depth=1

# 使用国密编译
use_guomi=$([[ "${guomi_model}"x == "yesx" ]] && echo " -Pguomi " || echo "")

if [[ $(command -v gradle) ]]; then
  # install ufw
  cd "${PROJECT_NAME}" && gradle clean build -x test ${use_guomi} && cd ..
else
  cd "${PROJECT_NAME}" && chmod +x ./gradlew && ./gradlew clean build -x test ${use_guomi} && cd ..
fi

rm -rfv ./dist &&  mv -fv ${PROJECT_NAME}/dist . && rm -rf ${PROJECT_NAME}
mv -fv dist/conf_template dist/conf

if [[ "${guomi_model}"x == "yesx" ]] ; then
  sed -i "s/encryptType.*#/encryptType: 1 #/g" dist/conf/application.yml
else
  sed -i "s/encryptType.*#/encryptType: 0 #/g" dist/conf/application.yml
fi

LOG_INFO "Docker image new_tag is [${new_tag}]"
docker build --build-arg BCOS_IMG_VERSION=${bcos_image_tag} -t front:${new_tag} .
docker tag  front:${new_tag} fiscoorg/front:${new_tag}

rm -rf dist
docker push fiscoorg/front:${new_tag}