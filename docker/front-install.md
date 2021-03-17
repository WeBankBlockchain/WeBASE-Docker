# front镜像模式使用说明

## 前提条件

|   环境    | 版本                   |
| :------: | :----------------------: |
| Docker |       建议17.03之后版本    |


## 1. 使用镜像建链

通过build_chain脚本生成建链所需的证书、配置文件等。

举例，如果要生成一个机构名为test，4个节点分别位于`172.17.0.1-172.17.0.4`这四台机器上，单群组模式的区块链网络，则操作如下。  
 
### 下载build_chain脚本
 
  ```bash
    curl -LO https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/v2.7.2/build_chain.sh && chmod u+x build_chain.sh
  ```
 
如果因为网络问题导致长时间无法下载build_chain.sh脚本，请尝试` curl -#LO https://gitee.com/FISCO-BCOS/FISCO-BCOS/raw/master/tools/build_chain.sh && chmod u+x build_chain.sh`

更详细的build_chain脚本使用方法，请参考[FISCO BCOS开发部署工具](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/build_chain.html#id1)

### 准备配置文件

```bash
# 172.17.0.1:1 表示172.17.0.1机器上1个节点
# test 机构名
# 1 群组id
cat  > nodeconf << EOF
    172.17.0.1:1 test 1
    172.17.0.2:1 test 1
    172.17.0.3:1 test 1
    172.17.0.4:1 test 1
EOF
```

### 生成节点配置文件

```bash
bash build_chain.sh -f nodeconf -p 30300,20200,8545 -o nodes -d -g
### 
# -f 指定生成节点的节点数等相关配置
# -p 指定节点所使用端口的起始值，同一机器上多节点端口递增。
# -o 指定输出目录
# -d 使用docker模式，使用该选项时不再拉取二进制
### 如果生成国密链，加上-g
# -g 国密，加上-g则搭建国密链，去除则搭建默认ECDSA链
```
执行后会生成nodes目录，nodes目录包含各节点配置。

执行成功后的输出：
```bash
# 非国密时
bash build_chain.sh -f nodeconf -p 30300,20200,8545 -o nodes -d
# 国密时，以国密为例
bash build_chain.sh -f nodeconf -p 30300,20200,8545 -o nodes -d -g
## 国密示例
==============================================================
Generating CA key...
Generating Guomi CA key...
==============================================================
Generating keys and certificates ...
Processing IP=172.17.0.1 Total=1 Agency=test Groups=1
Processing IP=172.17.0.2 Total=1 Agency=test Groups=1
Processing IP=172.17.0.3 Total=1 Agency=test Groups=1
Processing IP=172.17.0.4 Total=1 Agency=test Groups=1
==============================================================
Generating configuration files ...
Processing IP=172.17.0.1 Total=1 Agency=test Groups=1
Processing IP=172.17.0.2 Total=1 Agency=test Groups=1
Processing IP=172.17.0.3 Total=1 Agency=test Groups=1
Processing IP=172.17.0.4 Total=1 Agency=test Groups=1
==============================================================
Group:1 has 4 nodes
==============================================================
[INFO] Docker tag      : latest
[INFO] IP List File    : nodeconf
[INFO] Start Port      : 30300 20200 8545
[INFO] Server IP       : 172.17.0.1:1 172.17.0.2:1 172.17.0.3:1 172.17.0.4:1
[INFO] Output Dir      : /root/mars/docker/nodes
[INFO] CA Path         : /root/mars/docker/nodes/cert/
[INFO] Guomi CA Path   : /root/mars/docker/nodes/gmcert/
[INFO] Guomi mode      : true
==============================================================
[INFO] Execute the download_console.sh script in directory named by IP to get FISCO-BCOS console.
e.g.  bash /root/mars/docker/nodes/172.17.0.1/download_console.sh -f
==============================================================
[INFO] All completed. Files in /root/mars/docker/nodes
```

其中生成的`nodes/cert`目录中包含了该链的ca证书与私钥，机构test的证书与私钥；
- 国密时，会额外生成包含国密证书的`nodes/gmcert`；由于国密链是采用双证书体系，因此包含了两种证书；非国密时只有`nodes/cert`目录
- 为机构test**扩容节点**时，需要用到`test`目录下的机构证书生成新节点的证书；
  - 具体的扩容方法可以参考下文的**扩容**章节

以`nodes/172.17.0.1`中的节点为例，生成的内容包含
- `node0`目录
  - 节点的配置目录`conf`，包含节点的证书与群组配置文件
  - 节点的配置文件`config.ini`
  - `start.sh/stop.sh`docker模式的启停脚本（非必须）；具体的启停方式参考下文的**启动**章节的docker run命令
- `sdk`目录
  - 包含通过javasdk连接节点所需的ssl证书；sdk目录包含了sdk证书，国密时还额外包含国密sdk证书的`sdk/gm`目录

## 4. 镜像说明（fisco-webase）

本小结介绍构建 FISCO + Front 镜像时，自动加载到镜像中的内容；

镜像构建后的名字为`fiscoorg/fisco-webase`，版本号以FISCO BCOS节点镜像的版本号为准

构建镜像的`Dockerfile`如下

```yaml
# choose bcos image, standard or guomi
ARG BCOS_IMG_VERSION
FROM fiscoorg/fiscobcos:${BCOS_IMG_VERSION:-v2.7.2}
LABEL maintainer service@fisco.com.cn

# bcos config files
WORKDIR /bcos
# WeBASE-Front files
WORKDIR /front

# setup JDK
RUN apt-get update \
    && apt-get -y install openjdk-8-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH $JAVA_HOME/bin:$PATH

# COPY start shell of bcos and front
COPY ["docker-start.sh", "/docker-start.sh"]

# COPY front files
# cache lib layer
# replace start.sh of front(use active profile)
COPY ["dist/*.sh", "/front/"]
COPY ["dist/lib/", "/front/lib/"]
COPY ["dist/conf/", "/front/conf/"]
COPY ["dist/apps/", "/front/apps/"]

# expose port
EXPOSE 30300 20200 8545 5002

# start
ENTRYPOINT ["bash","/docker-start.sh"]
```

Dockerfile的操作如下：
- 在Dockerfile中指定依赖`fiscoorg/fiscobcos`进行构建，默认版本为`v2.7.2`
- 在镜像中配置`openjdk-8-jdk`，并配置`JAVA_HOME`环境变量
- 将`docker-start.sh`复制到镜像内的根目录，即`/docker-start.sh`
- 将FISCO BCOS节点镜像的基础上，将`WeBASE-Front`的安装包复制到镜像内的`/front`目录中
- 暴露节点的默认P2P, RPC, CHANNEL端口以及Front的5002端口；
- 默认工作目录为/bcos和/front

#### 获取镜像

可以通过front-build文档构建自己的镜像，在Dockerhub上的镜像默认为最新的节点前置版本，如v2.7.2的镜像是由v2.7.2的节点结合最新的v1.5.0前置镜像，所以镜像版本为v2.7.2

拉取镜像：
```
docker pull fiscoorg/fisco-webase:v2.7.2
```

### 启动
至此区块链网络各节点的配置已生成，将nodes下各节点目录（即`nodes/{ip}`）拷贝到对应ip机器上。
 
#### 修改节点前置的application.yml （可跳过）

如果需要修改front应用的applicaiton.yml配置，需要将本项目docker/application.yml拷贝到每个节点的目录下

参考命令如下：
```bash
cp -r ./docker/application.yml nodes/{ip}/node0/
```

然后在本地修改application.yml
- 其中`keyServer`签名任务的地址,`sdk.ip`和`sdk.channelPort`根据实际节点的配置进行修改
- front的数据存在h2数据库中，如果需要挂载出来，可以在application.yml中修改h2路径，如 将默认的`jdbc:h2:file:../h2/webasefront`修改成`jdbc:h2:file:/data/h2/webasefront`（因为容器内的/data目录会在启动的时候挂载到宿主机）

启动镜像的命令需要加上 `-v $PWD/application.yml:/front/conf/application.yml`，可以参考下文的完整docker容器启动命令

#### 启动容器
然后在各自机器上启动容器，指令如下：
- 其中`--network`指定网络模式为host模式
- `-w=/data`指定容器的工作目录
- `-v`指定加载宿主机指定目录的文件到容器内的指定目录，如加载了`/data/node0`目录到容器内的`/data`目录，并把`/data/sdk`目录加载到容器内的`/data/sdk`目录
- 需要启动不同的镜像或镜像版本，自行替换即可

```bash
  cd {ip}/node0/
  docker run -d -v /data/node0:/data -v /data/node0/application.yml:/front/conf/application.yml -v /data/sdk:/data/sdk -v /data/node0/front-log:/front/log --network=host -w=/data fiscoorg/fisco-webase:v2.7.2
```

### 检查 
  
执行启动命令后，可通过以下操作检查容器运行状况
- `docker ps` 查看进程   
- `docker exec -it {containerId} /bin/bash`   进入容器
- 容器里执行`/usr/local/bin/fisco-bcos -v` 检查节点版本是否正确。
- 容器里`/data`目录存放的是节点相关信息(包括节点日志)，`/front`目录主要存放的是前置的相关信息 
- 前置日志在`/front/log`下
  - 执行 `cat /front/log/WeBASE-Front.log` 可检查日志看是否启动报错。  
 
  
## 2. 使用镜像进行扩容

### 2.1 签发新的机构证书

使用build_chain建链时生成的自签CA来生成新的机构证书；若使用已有机构进行节点扩容，可跳过本小节

获取gen_agency_cert机构证书生成脚本
```
curl -#LO https://raw.githubusercontent.com/FISCO-BCOS/FISCO-BCOS/master/tools/gen_agency_cert.sh && chmod u+x gen_node_cert.sh
# 下载过慢时可以使用国内镜像
curl -#LO https://gitee.com/FISCO-BCOS/FISCO-BCOS/raw/master/tools/gen_agency_cert.sh&& chmod u+x gen_node_cert.sh
```

执行生成的参数
- `-c` 指定链证书及私钥所在路径，目录下必须有ca.crt 和 ca.key， 如果ca.crt是二级CA，则还需要root.crt(根证书)
- `-a` 新机构的机构名
- `-g` 指定国密链证书及私钥所在路径，目录下必须有gmca.crt 和 gmca.key，如果gmca.crt是二级CA，则还需要gmroot.crt(根证书)

```Bash
## 非国密时
bash gen_agency_cert.sh -c nodes/cert/ -a newAgencyName
## 国密时，以国密为例
bash gen_agency_cert.sh -c nodes/cert/ -a newAgencyName -g nodes/gmcert/
## 国密示例
==============================================================
[INFO] Cert Path   : nodes/cert//newAgencyName
[INFO] GM Cert Path: nodes/gmcert//newAgencyName-gm
[INFO] All completed.
```

### 2.2 签发新的节点证书

build_chain建链时使用自签ca，**所有链证书与私钥、机构证书及私钥位于nodes/cert目录**，请妥善保管**nodes/cert目录**中的文件。
- 国密时，将同时生成`gmcert`目录存放国密的链证书与私钥、机构证书及私钥

下面介绍签发证书所使用的脚本`gen_node_cert.sh`，以使用test机构签发新的节点证书私钥（国密）为例。

1 下载gen_node_cert.sh

```Bash
curl -LO https://raw.githubusercontent.com/FISCO-BCOS/FISCO-BCOS/master/tools/gen_node_cert.sh && chmod u+x gen_node_cert.sh
# 下载过慢时可以使用国内镜像
curl -#LO https://gitee.com/FISCO-BCOS/FISCO-BCOS/raw/master/tools/gen_node_cert.sh&& chmod u+x gen_node_cert.sh
```

2 签发节点证书

- `-c` 指定机构证书及私钥所在路径
- `-o` 输出到指定文件夹，其中newNode/conf中会存在机构test新签发的证书和私钥
- `-g` 国密
- `-s` 生成SDK证书（SDK证书也是节点证书），**生成新机构时，需要生成新机构对应的SDK证书**
```Bash
## 非国密
bash gen_node_cert.sh -c nodes/cert/test -o newNode
## 国密
bash gen_node_cert.sh -c nodes/cert/test -o newNodeGm -g nodes/gmcert/test/
## 国密示例
==============================================================
[INFO] Cert Path   : nodes/cert/test
[INFO] GM Cert Path: nodes/gmcert/test/
[INFO] Output Dir  : newNodeGm
==============================================================
[INFO] All completed. Files in newNodeGm
### -s 生成国密sdk证书
bash gen_node_cert.sh -c nodes/cert/test -o newNodeGmSDK -g nodes/gmcert/test/ -s
==============================================================
[INFO] Cert Path   : nodes/cert/test
[INFO] GM Cert Path: nodes/gmcert/test/
[INFO] Output Dir  : newNodeGmSDK
==============================================================
[INFO] All completed. Files in newNodeGmSDK
```

### 2.3 为群组1扩容节点

上文中新生成的节点目录中为`newNodeGm/conf`，其中conf包含了生成的证书，目录如下
```
--newNodeGm
  --conf
    --gmca.crt
    --gmnode.crt
    ...
```

为群组1扩容新节点，还需要将节点的配置文件拷贝到`newNodeGm/conf`目录中，包含：
- 拷贝节点与群组配置文件
- sdk证书
- 修改节点的.ini配置文件
- 修改front的.yml配置文件

#### 1 节点配置文件：

以`newNodeGm`为例，需要将下述**节点配置文件**到新节点文件夹
- 已有节点的`config.ini`复制到`newNodeGm`目录中，与节点证书同级目录
- 已有节点的`conf`目录下的`group.x.genesis`和`group.x.ini`复制到`newNodeGm/conf`中
  - 已有群组的.genesis文件不可修改，新群组可以修改其中的`consensus.node.x`中修改默认共识节点列表

```bash
# 已有节点的配置文件 ->> 新节点所需的配置文件
nodes/172.17.0.1/node0/config.ini ->> newNodeGm/config.ini
nodes/172.17.0.1/node0/conf/group.1.genesis ->> newNodeGm/conf/group.1.genesis
nodes/172.17.0.1/node0/conf/group.1.ini ->> newNodeGm/conf/group.1.ini
```

#### 2 SDK证书
跟上述步骤类似，拷贝sdk证书到新的节点目录
- 若**生成了新机构的新节点，则需要使用新的SDK证书**；否则直接复制已有的节点的SDK证书即可

```bash
# 使用旧机构
cp -r nodes/172.17.0.1/node0/sdk newNodeGm/ 
# 使用新机构，直接将生成的newNodeGmSdk重命名为sdk
cp -r newNodeGm/newNodeGmSdk newNodeGm/sdk
```

docker容器启动时，容器启动脚本，会**自动**拷贝节点目录中的sdk目录`/data/sdk`到前置的配置目录`/front/conf`，用于节点前置的javasdk连接节点使用

#### 3 修改新节点config.ini

- 修改`rpc`与`p2p`模块监听的IP和端口
- 将已有节点的IP端口添加到`p2p`的`node.0, node.1`列表中，保证新节点可连上已有节点
- **国密时**
  - 确保`network_security`的节点证书和节点私钥要由`node开头`改为`gmnode开头`，同理`ca.crt`改为`gmca.crt`
  - 确保`chain.sm_crypto`要与节点的国密类型匹配，国密时`sm_crypto=true`
``` 
 $ vim newNodeGm/config.ini
 [rpc]
     ;rpc listen ip
     listen_ip=127.0.0.1
     ;channelserver listen port
     channel_listen_port=20302
     ;jsonrpc listen port
     jsonrpc_listen_port=8647
 [p2p]
     ;p2p listen ip
     listen_ip=0.0.0.0
     ;p2p listen port
     listen_port=30402
     ;nodes to connect
     node.0=127.0.0.1:30400
     node.1=127.0.0.1:30401
     node.2=127.0.0.1:30402  
  [network_security]
    ; directory the certificates located in
    data_path=conf/
    ; the node private key file
    key=gmnode.key
    ; the node certificate file
    cert=gmnode.crt
    ; the ca certificate file
    ca_cert=gmca.crt
  [chain]
    id=1
    ; use SM crypto or not, should nerver be changed
    sm_crypto=true
    sm_crypto_channel=false
  [compatibility]
    ; supported_version should nerver be changed
    supported_version=2.7.2
```

#### 4 修改front的application.yml

除了以上的节点配置文件外，还需要**拷贝节点前置的application.yml**到新节点的目录下

参考命令如下：
```bash
cp nodes/172.17.0.1/node0/application.yml newNodeGm/
```

修改application.yml
- 其中`keyServer`签名服务的IP端口（不能是127.0.0.1）,`sdk.ip`和`sdk.channelPort`根据实际节点的配置进行修改
- front的数据存在h2数据库中，如果需要挂载出来，可以在application.yml中修改h2路径，如 将默认的`jdbc:h2:file:../h2/webasefront`修改成`jdbc:h2:file:/data/h2/webasefront`（因为容器内的/data目录会在启动的时候挂载到宿主机）
- 如需修改前置的默认服务端口，则需要修改`server.port`配置，并在启动容器时加上新的端口映射`docker run -p {newFrontPort}`
```
sdk:
  ip: 127.0.0.1
  channelPort: 20200
...
...
constant:
  keyServer: 127.0.0.1:5004 # webase-sign服务的IP:Port
  ...
```


#### 5 使用docker启动新节点

将新节点传输到指定机器后，进入新节点的目录，指定docker run命令启动即可
```bash
  cd /data/newNodeGm/
  docker run -d -v /data/newNodeGm:/data -v /data/newNodeGm/application.yml:/front/conf/application.yml -v /data/newNodeGm/sdk:/data/sdk -v /data/newNodeGm/front-log:/front/log --network=host -w=/data fiscoorg/fisco-webase:v2.7.2
```
#### 6 检查 
  
执行启动命令后，可通过以下操作检查容器运行状况
- `docker ps` 查看进程   
- `docker exec -it {containerId} /bin/bash`   进入容器
- 容器里执行`/usr/local/bin/fisco-bcos -v` 检查节点版本是否正确。
- 容器里`/data`目录存放的是节点相关信息(包括节点日志)，`/front`目录主要存放的是前置的相关信息 
- 前置日志在`/front/log`下
  - 执行 `cat /front/log/WeBASE-Front.log` 可检查日志看是否启动报错。  
 
#### 7 新节点加入共识

通过**console控制台**将新节点设为共识节点或观察节点，加入区块里网络的共识；具体操作可以参考[FISCO BCOS console](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/console/index.html)文档


