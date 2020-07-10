# WeBASE-Front镜像使用说明

## 前提条件

|   环境    | 版本                   |
| :------: | :----------------------: |
| Docker |       建议17.03之后版本    |


## 1 镜像使用步骤

​	举例，如果要生成一个机构名为test，4个节点分别位于`172.17.0.1-172.17.0.4`这四台机器上，单群组模式的区块链网络，则操作如下。  

###  1.1 下载build_chain脚本（已在docker目录下）

  ```bash
curl -LO https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/v2.5.0/build_chain.sh && chmod u+x build_chain.sh
  ```

### 1.2 准备配置文件

```bash
# 172.17.0.1:1 表示172.17.0.1机器上1个节点
# test 机构名
# 1 群组id
cat  > nodeconf << EOF
    172.17.0.1:1 test 1 30300,20200,8545
    172.17.0.2:1 test 1 30300,20200,8545
    172.17.0.3:1 test 1 30300,20200,8545
    172.17.0.4:1 test 1 30300,20200,8545
EOF
```

### 1.3 生成节点配置文件

​	自签证书请参考cert目录结构， 执行后会生成nodes目录，nodes目录包含各节点配置。

```bash
# -d 使用docker模式
# -f 根据配置文件生成节点
# -S 资源统计
# -g 国密
# -G 节点与SDK连接使用国密SSL
# -Z 各节点下存放一份SDK证书
# -k 自签链证书，要求-k的目录里有ca.key/ca.crt，如果ca.crt是二级CA，则还需要root.crt(根证书) 
# -K 自签国密链证书，要求-K的目录中有gmca.key/gmca.crt，如果gmca.crt是二级CA，则还需要gmroot.crt(根证书)

bash build_chain.sh -d -f nodeconf -S -g -G -Z
```
### 1.4 启动镜像

 至此，区块链网络各节点的配置已生成，将nodes下各节点目录即nodes/{ip}拷贝到对应ip机器上。

 在各机器节点目录启动容器，指令如下：

```bash
# 节点目录
cd {ip}/node0/

# 其中网络模式，脚本使用了host模式，用户可自行选择网络模式
# 挂载节点和sdk连接需要的证书目录，支持国密ssl
# 挂载WeBASE-Front配置文件applicaiton.yml，参考docker目录下文件，国密时sdk.encryptType配置为1
# 自行替换需要的镜像名

docker run -d -v $PWD:/data -v $PWD/sdk/gm:/data/cert -v $PWD/application.yml:/dist/conf/application.yml --network=host -w=/data fiscoorg/front:v1.0.0
```
### 1.5 检查 

 - docker ps 查看进程   
 - docker exec -it {containerId} /bin/bash   进入容器
 - 容器里执行/usr/local/bin/fisco-bcos -v 检查节点版本是否正确
 - 容器里/data目录存放的是节点相关信息，/dist目录存放的是前置相关信息 
 - 前置日志在/dist/log下，执行 tail -f /dist/log/WeBASE-Front.log 查看日志

   如果需要将WeBASE-Front日志挂载出来，docker启动加上 **-v $PWD/frontlog:/dist/log**， 参考命令如下：
```bash
docker run -d -v $PWD:/data -v $PWD/sdk/gm:/data/cert -v $PWD/application.yml:/dist/conf/application.yml -v $PWD/frontlog:/dist/log --network=host -w=/data fiscoorg/front:v1.0.0
```

## 2 使用镜像进行扩容
### 2.1 为新节点生成私钥证书
**build_chain建链时使用自签ca，所有ca.key以及机构私钥位于nodes/cert目录**，请妥善保管**nodes/cert目录**中的文件。

如果某机构需要新增节点的话，需要为新节点签发证书，下面介绍签发证书所使用的脚本`gen_node_cert.sh`。  以使用agency签发新的证书为例。

1 下载gen_node_cert.sh（已在docker目录下）

```bash
curl -LO https://raw.githubusercontent.com/FISCO-BCOS/FISCO-BCOS/master/tools/gen_node_cert.sh && chmod u+x gen_node_cert.sh
```

2 生成新节点私钥证书

```bash
# -c 指定机构证书及私钥所在路径
# -o 输出到指定文件夹，其中newNode/conf中会存在机构agency新签发的证书和私钥

bash gen_node_cert.sh -c nodes/cert/agency -o newNode
```

**国密版本**请执行下面的指令生成证书：

```bash
bash gen_node_cert.sh -c nodes/cert/agency -o newNodeGm -g nodes/gmcert/agency/
```

### 2.2 准备配置文件

 1 拷贝群组已有节点（node0为例）的配置文件

```bash
cp nodes/172.17.0.1/node0/config.ini newNodeGm/config.ini
cp nodes/172.17.0.1/node0/conf/group.1.genesis newNodeGm/conf/group.1.genesis
cp nodes/172.17.0.1/node0/conf/group.1.ini newNodeGm/conf/group.1.ini
```

 2 拷贝证书到新的目录，sdk和节点连接需要，docker启动时挂载
```bash
mkdir newNode/sdk
# （ca.crt）ca证书
cp -r newNode/conf/ca.crt newNode/sdk
# （node.crt）节点证书
cp -r newNode/conf/node.crt newNode/sdk
# （node.key）节点证书私钥
cp -r newNode/conf/node.key newNode/sdk
```
 **国密版本注意证书命名（gmca.crt、gmensdk.crt、gmensdk.key、gmsdk.crt、gmsdk.key）**，操作如下：

```bash
mkdir newNodeGm/sdk
# （gmca.crt）ca证书
cp -r newNodeGm/conf/gmca.crt newNodeGm/sdk
# （gmensdk.crt）国密en证书
cp -r newNodeGm/conf/gmennode.crt newNodeGm/sdk/gmensdk.crt
# （gmensdk.key）国密en证书私钥
cp -r newNodeGm/conf/gmennode.key newNodeGm/sdk/gmensdk.key
# （gmsdk.crt）国密证书
cp -r newNodeGm/conf/gmnode.crt newNodeGm/sdk/gmsdk.crt
# （gmsdk.key）国密证书私钥
cp -r newNodeGm/conf/gmnode.key newNodeGm/sdk/gmsdk.key
```

 3 更新`newNodeGm/config.ini`中监听的IP和端口

 4 在newNodeGm目录使用docker启动新节点，参考1.4

 5 通过[链管理服务](<https://github.com/WeBankFinTech/WeBASE-Chain-Manager/tree/bsn>)将新节点加入群组，`nodeID`可以通过文件获取：

```bash
非国密：cat newNode/conf/node.nodeid
国 密：cat newNodeGm/conf/gmnode.nodeid
```

### 2.3 为新机构生成证书

1 下载gen_agency_cert.sh（已在docker目录下）

```bash
curl -LO https://raw.githubusercontent.com/FISCO-BCOS/FISCO-BCOS/master/tools/gen_agency_cert.sh && chmod u+x gen_agency_cert.sh
```

2 签发机构证书
  使用指定的根证书（链证书）签发 新机构的证书

```bash
# -c 指定链证书及私钥所在路径，目录下必须有ca.crt 和 ca.key， 如果ca.crt是二级CA，则还需要root.crt(根证书)
# -g 指定国密链证书及私钥所在路径，目录下必须有gmca.crt 和 gmca.key，如果gmca.crt是二级CA，则还需要gmroot.crt(根证书)
# -a 新机构的机构名

bash gen_agency_cert.sh -c nodes/cert/ -a newAgencyName
```
 **国密版本**请执行下面的指令生成证书：

```bash
bash gen_agency_cert.sh -c nodes/cert/ -a newAgencyName -g nodes/gmcert/
```

 生成的机构证书在nodes/cert/newAgencyName 以及 nodes/gmcert/newAgencyName-gm下。