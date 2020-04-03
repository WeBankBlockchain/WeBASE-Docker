## FISCO 2.0 docker模式使用说明

### 1. 节点网络说明

- 每个节点需要3个端口，详细请参考[FISCO BCOS网络端口讲解](https://mp.weixin.qq.com/s/IiHsPlxmvEEBTC84n27I9A)。
- 节点之间需要保证P2P网络可达
- 节点的channel端口供SDK访问，但默认监听127.0.0.1
- 节点的RPC端口提供HTTP的JSON-RPC协议，但默认监听127.0.0.1

### 2. 节点依赖说明

**下述配置文件，脚本会自动生成，放置在节点目录下，启动容器时挂载即可**。

- 每个节点启动依赖一些配置文件，详细请参考[FISCO BCOS配置说明](https://mp.weixin.qq.com/s/3RGTRvheSr5P1nXbmAjl2g)。
- 主配置文件config.ini，其中会配置本节点监听的IP和端口。需要根据云环境定制。
- 主配置文件config.ini，其中会配置需要链接的其他节点IP和端口，需要根据云环境定制。
- ca.crt/node.crt/node.key是节点建立SSL链接是使用的证书相关文件。
- 节点conf/目录下会有群组配置相关文件，节点启动时依赖。需要注意conf/group.1.genesis文件中会存放节点的nodeid，是节点node.key对应的公钥

### 1. build_chain说明
`build_chain.sh`用于生成节点，本环境下建议使用配置文件模式。详细指令可以参考[这里](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/build_chain.html)

举例，如果要生成一个机构名为test，4个节点分别位于`172.17.0.1-172.17.0.4`，单群组模式，则操作如下。

 1 准备配置文件

```bash
# 1表示群组1
cat  > nodeconf << EOF
172.17.0.1:1 test 1
172.17.0.2:1 test 1
172.17.0.3:1 test 1
172.17.0.4:1 test 1
EOF
```

 2 生成配置文件

```bash
# -p 指定节点所使用端口的起始值，同一机器上多节点端口递增。
# -d 使用docker模式
# -g 国密
bash build_chain.sh -f nodeconf -p 30300,20200,8545 -o nodes -d -g
```

 3  因为front需要sdk证书才能启动， 拷贝sdk目录内容到各个节点目录。 如下：
```bash
cp -r sdk/ node*/
```

 4 启动 
 
 启动容器的指令如下，请参考此指令，修改k8s所使用的yaml文件。其中网络模式，脚本是为了简单使用了host模式，云这边使用端口映射即可。mac不支持host模式 用-P代替。 可自行替换自己需要的镜像名。

```bash
docker run -d  -v ${PWD}:/data --network=host -w=/data fiscoorg/front:bsn-0.2.0-gm
```

 5 检查 
  
 docker ps 查看进程
 docker exec -it {containerId} /bin/bash
 容器里执行/usr/local/bin/fisco-bcos -v 检查节点版本是否正确。
 front相关文件在容器的/dist目录下，日志在/dist/log下，可检查日志看是否启动报错。
 
 6 修改application.yml 和log配置
 
  如果需要修改applicaiton的配置或日志文件配置
  需要将frontconf目录下内容（即application.yml在目录）拷贝到node的frontconf目录（需要自己新建）下，这样可以在本地修改application.yml,log4j2.xml,修改好后。
 ```bash
   cp -r frontconf node0/
  ```
  启动镜像命令如下
  ```bash
   docker run -d  -v $PWD:/data -v $PWD/frontconf:/dist/conf --network=host -w=/data fiscoorg/front:bsn-0.2.0-gm
  ```


### 2. 签发合法证书给SDK使用

**build_chain建链时使用自签ca，所有ca.key以及机构私钥位于nodes/cert目录**，请妥善保管**nodes/cert目录**中的文件。

下面介绍签发证书所使用的脚本`gen_node_cert.sh`。以使用test机构签发新的证书为例。该证书既可以用于SDK与节点建立链接，又可以作为扩容时新节点的证书。

```bash
# -c指定机构证书及私钥所在路径
# -o输出到指定文件夹，其中newNode/conf中会存在机构test新签发的证书和私钥
非国密
bash gen_node_cert.sh -c nodes/cert/test -o newNode

国密
bash gen_node_cert.sh -c nodes/cert/agency -o newNodeGm -g nodes/gmcert/agency/
```

### 3. 为群组1扩容节点

1. 根据步骤5为新节点生成证书，拷贝下述文件到新节点文件夹。

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

2. 修改新节点config.ini监听的IP和端口为正确的IP和端口
3. 使用docker启动新节点
4. 通过console将新节点加入群组1，请参考[这里](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/console.html#addsealer)和[这里](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/node_management.html#id7)
5. 将新节点的P2P配置中的IP和Port加入原有节点的config.ini中的[p2p]字段。假设新节点IP:Port为172.17.0.5:30300则，修改后的[P2P]配置为
```bash
[p2p]
    listen_ip=0.0.0.0
    listen_port=30300
    ;enable_compress=true
    ; nodes to connect
    node.0=172.17.0.1:30300
    node.1=172.17.0.2:30300
    node.2=172.17.0.3:30300
    node.3=172.17.0.4:30300
    node.3=172.17.0.5:30300
```

### 4. 增加群组

**generateGroup**

生成群组所需的所有文件，放到conf目录下

请求

* method：generateGroup
* params：[groupid, timestamp, ["xxxxxxxxxxxxx0","xxxxxxxxxxxxx1","xxxxxxxxxxxxx2","xxxxxxxxxxxxx3"]]   groupID和nodeid的列表

``` shell
curl -X POST --data '{"jsonrpc":"2.0","method":"generateGroup","params":[3, 1575876929000, ["xxxxxxxxxxxxx0","xxxxxxxxxxxxx1","xxxxxxxxxxxxx2","xxxxxxxxxxxxx3"]] ,"id":1}' http://127.0.0.1:8545 |jq
```

返回

* error：字符串
  * "0x0"：成功
  * "0x1"：群组已存在
  * "0x2"：群组创世块文件存在
  * "0x3"：群组配置文件存在
  * "0x4"：传参错误
  * "0x5"：内部错误
  * "0x6"：此未与相应节点建立连接
* message：字符串，描述

``` json
{
    "id": 1, 
    "jsonrpc": "2.0", 
    "result": {
        "code": "0x0",
        "message": "success"       
    }
}
```

**startGroup**

检查群组依赖的文件，发送启动群组请求，是否启动成功需通过getGroupList来查

请求

- method：startGroup
- params：[groupid]   

```shell
curl -X POST --data '{"jsonrpc":"2.0","method":"startGroup","params":[3] ,"id":1}' http://127.0.0.1:8545 |jq
```

返回

- error：字符串
  - "0x0"：请求成功（不代表群组启动，是否启动需要用`getGroupList`来查）
  - "0x1"： group已经启动
  - "0x2"：创世块文件不存在
  - "0x3"：群组配置文件不存在
  - "0x4"：创世块文件配置错误
  - "0x5"：群组配置文件配置错误
  - "0x6"：传参错误
  - "0x7"：内部错误
- message：字符串，错误描述

```json
{
    "id": 1, 
    "jsonrpc": "2.0", 
    "result": {
        "code": "0x0",
        "message": "success"       
    }
}
```
