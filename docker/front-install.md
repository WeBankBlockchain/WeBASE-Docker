## front镜像模式使用说明

## 前提条件

|   环境    | 版本                   |
| :------: | :----------------------: |
| Docker |       建议17.03之后版本    |


### 1. 镜像使用步骤

 举例，如果要生成一个机构名为test，4个节点分别位于`172.17.0.1-172.17.0.4`这四台机器上，单群组模式的区块链网络，则操作如下。  
 
 1 下载build_chain脚本
 
  ```bash
   curl -LO https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/v2.3.0/build_chain.sh && chmod u+x build_chain.sh
   ```
 
 2 准备配置文件

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

 3 生成节点配置文件

```bash
# -p 指定节点所使用端口的起始值，同一机器上多节点端口递增。
# -d 使用docker模式
# -g 国密
# -S 资源统计
bash build_chain.sh -f nodeconf -p 30300,20200,8545 -o nodes -d
```
 执行后会生成nodes目录，nodes目录包含各节点配置。

 
 4  因为front需要sdk证书才能启动， 拷贝sdk目录内容到各个节点目录。 如下：
```bash
 cp -r nodes/{ip}/sdk/ nodes/{ip}/node0/
```

 5 启动 
 至此区块链网络各节点的配置已生成，将nodes下各节点目录即nodes/{ip}拷贝到对应ip机器上。
 
 然后在各自机器上启动容器，指令如下：

```bash
 # 其中网络模式，脚本使用了host模式，用户可自行选择网络模式，
 # 自行替换需要的镜像名。  

  cd {ip}/node0/
  docker run -d  -v ${PWD}:/data --network=host -w=/data fiscoorg/front:latest
```
 至此镜像启动成功。
 
 6 检查 
  
 - docker ps 查看进程   
 - docker exec -it {containerId} /bin/bash   进入容器
 - 容器里执行/usr/local/bin/fisco-bcos -v 检查节点版本是否正确。
 - 容器里/data目录存放的是节点相关信息，/dist目录主要存放的是前置的相关信息 
 - 前置日志在/dist/log下，
   执行 tail -f /dist/log/WeBASE-Front.log 可检查日志看是否启动报错。  
 
 7 修改application.yml （可跳过）
 
  如果需要修改front应用的applicaiton.yml配置,
  需要将本项目docker/application.yml拷贝到每个节点的目录下，
  参考命令如下：
   ```bash
    cp -r ./docker/application.yml nodes/{ip}/node0/
   ```
  然后在本地修改application.yml。
  front的数据存在h2数据库中，如果需要挂载出来，可以在application.yml中修改h2路径,如修改成"jdbc:h2:file:/data/h2/webasefront"。  

  启动镜像命令需要加上 **-v $PWD/application.yml:/dist/conf/application.yml**， 命令如下：
  ```bash
   docker run -d  -v $PWD:/data -v $PWD/application.yml:/dist/conf/application.yml --network=host -w=/data fiscoorg/front:latest
  ```
  
  
  
### 2. 使用镜像进行扩容

#### 2.1 签发合法证书给SDK使用
**build_chain建链时使用自签ca，所有ca.key以及机构私钥位于nodes/cert目录**，请妥善保管**nodes/cert目录**中的文件。

下面介绍签发证书所使用的脚本`gen_node_cert.sh`。  
以使用test机构签发新的证书为例。该证书既可以用于SDK与节点建立链接，又可以作为扩容时新节点的证书。

1 下载gen_node_cert.sh

```
curl -LO https://raw.githubusercontent.com/FISCO-BCOS/FISCO-BCOS/master/tools/gen_node_cert.sh && chmod u+x gen_node_cert.sh
```

2 签发证书

```bash
# -c指定机构证书及私钥所在路径
# -o输出到指定文件夹，其中newNode/conf中会存在机构test新签发的证书和私钥
# -g 国密
 
非国密
bash gen_node_cert.sh -c nodes/cert/test -o newNode

国密
bash gen_node_cert.sh -c nodes/cert/test -o newNodeGm -g nodes/gmcert/test/
```

#### 2.2 为群组1扩容节点

 1 根据步骤为新节点生成证书，拷贝下述文件到新节点文件夹。

```bash
非国密
nodes/172.17.0.1/node0/config.ini >> newNode/config.ini
nodes/172.17.0.1/node0/conf/group.1.genesis >> newNode/conf/group.1.genesis
nodes/172.17.0.1/node0/conf/group.1.ini >> newNode/conf/group.1.ini

国密
nodes/172.17.0.1/node0/config.ini >> newNodeGm/config.ini
nodes/172.17.0.1/node0/conf/group.1.genesis >> newNodeGm/conf/group.1.genesis
nodes/172.17.0.1/node0/conf/group.1.ini >> newNodeGm/conf/group.1.ini

```

 2 跟上述步骤3类似，拷贝sdk证书到新的节点目录，
```bash
  cp -r nodes/172.17.0.1/node0/sdk/ newNodeGm/ 
```
 3 修改新节点config.ini监听的IP和端口为正确的IP和端口。
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
```
 
 4 使用docker启动新节点
```bash
docker run -d  -v ${PWD}:/data --network=host -w=/data fiscoorg/front:latest
```
5 通过调用WeBASE-Front的addSealer接口将新节点加入区块链网络。
http://172.17.0.1:5002/WeBASE-Front/1/web3/addSealer