
# 编译文档说明
## Changelog

1. 优化start.sh 脚本
2. 优化 Dockerfile, 合理使用缓存
3. 修改编译镜像脚本，支持参数化，根据参数编译指定镜像。

## 说明
1. 该镜像包含了 BCOS 和 WeBASE-Front 两个应用程序。启动时需要挂载 BCOS 的配置文件和节点证书和密钥文件。
2. 编译镜像时需要依赖 jdk-8u211-linux-x64.tar.gz jdk 文件，该文件没有包含在仓库内，需要手动下载。
3. 因为需要编译 WeBASE-Front，所以 WeBASE-Front 需要使用 gracle build -P 指定参数的方式来选择编译标密还是国密版本。当前需要使用 [https://github.com/yuanmomo/WeBASE-Front.git](https://github.com/yuanmomo/WeBASE-Front.git) 仓库的 add-condition-in-gradle 分支。


## 编译步骤
1. 下载 jdk-8u211-linux-x64.tar.gz 文件，[点击此处跳转到 Oracle 下载](https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html)
2. 把下载好的 jdk-8u211-linux-x64.tar.gz 文件放入 [WeBASE-Docker/docker/build] 目录下。
3. 执行 bash docker-build.sh -h 查看脚本帮助文件。
4. 编译脚本会创建两个版本的 Docker 镜像，front:tag 和 fiscoorg/front:tag。

### 脚本指南

#### 脚本说明

```Bash 
Usage:
    docker-build.sh    [-t new_tag] [-a git-account] [-c bcos_version] [-b front-branch] [-g] [-h]
    -t          Docker image new_tag, required.

    -c          BCOS docker image new_tag, default v2.2.0, equal to fiscoorg/fiscobcos:v2.2.0.
    -a          Git account, default WeBankFinTech.
    -g          Use guomi, default no.
    -b          Branch of WeBASE-Front, default master.
    -h          Show help info.
```

##### 参数说明:

|   参数       | 必须          |描述 | 默认值     |
| ------------- |--------| -----| -----|
| -t     | 是  | 新的 BCOS + Front 的镜像标签   | 需要输入|
| -c     | 否 | BCOS 基础 Docker 镜像的版本| 默认使用 v2.2.0|
| -g     | 否 | 是否使用国密| 默认不是用|
| -a     | 否 | 使用哪个版本的 WeBASE-Front(测试时使用)| 默认使用 WeBankFinTech |
| -b     | 否 | 使用 WeBASE-Front 的哪个分支 | 默认使用 master|
| -h     | 否 | 帮助文档 | |

备注：

    1. 当使用 -g 参数，表示使用国密时，脚本会检查 -c 的 BCOS 镜像是否以 [-gm] 结束。
    2. 当使用 -g 参数，表示使用国密时，脚本会自动修改 Front 中的 application.yml 文件中的 encryptType 为 1.

#### 示例

```Bash
# 1. 不使用国密
# 2. 新的 Docker 镜像版本为 fiscoorg/front:v2.3.0
# 3. 使用 fiscoorg/fiscobcos:v2.2.0 的 Docker 镜像版本
# 4. WeBASE-Front 的地址为 https://github.com/WeBankFinTech/WeBASE-Front.git
# 5. WeBASE-Front 的分支为 master 
bash docker-build.sh -t v2.3.0  


# 1. 使用国密
# 2. 新的 Docker 镜像版本为 fiscoorg/front:v1.0
# 3. 使用 fiscoorg/fiscobcos:v2.3.0-gm 的 Docker 镜像版本
# 4. WeBASE-Front 的地址为 https://github.com/yuanmomo/WeBASE-Front.git
# 5. WeBASE-Front 的分支为 add-condition-in-gradle 
bash docker-build.sh -g -t v1.0 -c v2.3.0-gm -a yuanmomo -b add-condition-in-gradle 

```

## 镜像启动

成功编译镜像后，运行镜像时，需要使用 build_chain.sh 脚本生成相关的配置。

**注意：build_chain.sh 生成的配置，不支持在 MacOS 上运行，所以下面的配置，请在 Linux 中执行**

关于 build_chain.sh 的详细事情请参考 [build_chain.sh](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/build_chain.html)。

```Bash
# 下载 build_chain.sh 脚本
curl -LO https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/v2.3.0/build_chain.sh && chmod u+x build_chain.sh

# 生成 node 的配置文件

# 拷贝文件到机器

# 使用 docker run 启动

```



## 脚本使用说明：

1 检查Dockerfile第一行，看是否需要修改底层镜像。
2 打国密镜像时务必保证applicaiton.yml的encryptType为1
3 拷贝jdk-8u211-linux-x64.tar.gz到docker目录下。
4  sh docker-build.sh bsn v1.0 （bsn 是分支， v1.0 是tag）
5 如果拉代码过慢，自行注释掉docker-build.sh中虚线之前的代码。



-----------------------------------------------------
## 镜像制作流程注意事项：
1 jdk版本为1.8.0.211  使用jdk-8u211-linux-x64.tar.gz


2 拷贝dist下的conf_template 目录到conf目录

3 替换dist/start脚本（拷贝证书， 并且java启动时候去掉&）

cp -r /data/sdk/* /dist/conf/
CLASSPATH='conf/:apps/*:lib/*'
cd /dist

4 docker build -t  front:v0.9 .
  docker tag  front:v0.9 fiscoorg/front:v0.9
  docker save -o front.tar fiscoorg/front:v0.9
  
5 验证，buildchain脚本 在节点目录下执行  mac 不支持host模式
 docker run -d -P -v $PWD:/data -w=/data fiscoorg/front:v0.9 检查docker ps -l是否正常 

6 国密需要修改build.gradle 引入国密包， 增加lib下的solcJ-all-0.4.25-gm.jar， 并修改applicaiton.yml的encryptType

7 curl ip:5002/WeBASE-Front/1/web3/blockNumber 检查是否能获取块高






