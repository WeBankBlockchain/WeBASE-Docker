
# 编译文档说明
## Changelog

1. 优化容器启动脚本 docker-start.sh 脚本；
2. 优化 Dockerfile, 合理使用缓存；
3. 修改编译镜像脚本，支持参数化，根据参数编译指定镜像；
4. 优化 WeBASE-Front 的启动脚本，可以指定 profile；

## 说明
1. 该镜像包含了 BCOS 和 WeBASE-Front 两个应用程序。启动时需要挂载 FISCO-BCOS 的配置文件和节点证书和密钥文件；
2. 镜像会额外创建一个 latest（国密版本时：latest-gm） 标签的镜像；


## 编译步骤
1. 执行 bash docker-build.sh -h 查看脚本帮助文件。

### 脚本指南

#### 脚本说明

```Bash 
Usage:
    ${__cmd}    [-t new_tag] [-c bcos_version] [-a git_account] [-b front_branch] [-r docker_repository] [-p] [-h]
    -t          Docker image new_tag, required.

    -c          BCOS docker image tag, default v2.4.0, equal to fiscoorg/fiscobcos:v2.4.0.
    -a          Git account, default WeBankFinTech.
    -b          Branch of WeBASE-Front, default master.
    -r          Which repository new image will be pushed to, default fiscoorg/front.
    -p          Execute docker push, default no.
    -h          Show help info.
```

##### 参数说明:

|   参数       | 必须          |描述 | 默认值     |
| ------------- |--------| -----| -----|
| -t     | 是 | 新的 FISCO-BCOS + WeBASE-Front 的镜像标签   | 需要输入|
| -r     | 否 | 编译后的镜像推送的 Docker registry 仓库 | 默认 fiscoorg/front|
| -c     | 否 | BCOS 基础 Docker 镜像的版本，如果镜像以 gm 结尾，将编译国密版本镜像| 默认使用 v2.4.0|
| -a     | 否 | 使用哪个版本的 WeBASE-Front(测试时使用)| 默认使用 WeBankFinTech |
| -b     | 否 | 使用 WeBASE-Front 的哪个分支 | 默认使用 master|
| -p     | 否 | 是否执行 docker push | no，不执行 |
| -h     | 否 | 帮助文档 | |

#### 示例

```Bash
# 1. 不使用国密
# 2. 新的 Docker 镜像版本为 fiscoorg/front:v2.3.0
# 3. 使用 fiscoorg/fiscobcos:v2.4.0 的 Docker 镜像版本
# 4. WeBASE-Front 的地址为 https://github.com/WeBankFinTech/WeBASE-Front.git
# 5. WeBASE-Front 的分支为 master 
bash docker-build.sh -t v2.3.0  


# 1. 使用 fiscoorg/fiscobcos:v2.3.0-gm 的 Docker 镜像版本，-gm 结尾，默认编译国密版本
# 2. 新的 Docker 镜像版本为 fiscoorg/front:v1.0-gm，由于是国密版本，默认会在版本后添加 -gm 后缀
# 3. WeBASE-Front 的地址为 https://github.com/yuanmomo/WeBASE-Front.git
# 4. WeBASE-Front 的分支为 add-condition-in-gradle
bash docker-build.sh -t v1.0 -c v2.3.0-gm -a yuanmomo -b add-condition-in-gradle


# 1. 使用 fiscoorg/fiscobcos:v2.4.0 的 Docker 镜像版本
# 2. 新的 Docker 镜像版本为 fiscoorg/front:v2.0，会推送到 Docker registry 的 yuanmomo/bcos-front 仓库
# 3. WeBASE-Front 的地址为 https://github.com/WeBankFinTech/WeBASE-Front.git
# 4. WeBASE-Front 的分支为 master
bash docker-build.sh -t v2.0 -p yuanmomo/bcos-front

```

## 镜像启动

成功编译镜像后，运行镜像时，需要使用 build_chain.sh 脚本生成相关的配置。

**注意：build_chain.sh 生成的配置，不支持在 MacOS 上运行，所以下面的配置，请在 Linux 中执行**

关于 build_chain.sh 的详细事情请参考 [build_chain.sh](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/build_chain.html)。

```Bash
# 下载 build_chain.sh 脚本
curl -LO https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/v2.4.0/build_chain.sh && chmod u+x build_chain.sh

# 生成 node 的配置文件

# 拷贝文件到机器

# 使用 docker run 启动

```





