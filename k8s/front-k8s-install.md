## front镜像K8S部署说明

## 前提条件

|   环境    | 版本                   |
| :------: | :----------------------: |
| Docker |       建议17.06之后版本    |
| Kubernetes |       建议1.12之后版本    |


### 1. 镜像部署使用步骤

 举例，如果要生成一个机构名为test，单群组模式的区块链网络，则操作如下。  
 
 1 下载build_chain脚本
 
  ```bash
   curl -LO https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/v2.7.2/build_chain.sh && chmod u+x build_chain.sh
   ```
 
 2 准备配置文件

```bash
# 172.17.0.1:1 表示172.17.0.1机器上1个节点
# test 机构名
# 1 群组id
cat  > nodeconf << EOF
    fisco-0:1 org1 1
    fisco-1:1 org2 1
    fisco-2:1 org3 1
    fisco-3:1 org4 1
EOF
```

 3 生成节点配置文件

```bash
# -p 指定节点所使用端口的起始值，同一机器上多节点端口递增。
# -d 使用docker模式
# -g 国密
# -S 资源统计
bash build_chain.sh -f nodeconf -p 30300,20200,8545 -o nodes -d -g
```
 执行后会生成nodes目录，nodes目录包含各节点配置。

  1 生成各节点配置：
  请将**build.chain**脚本生成的配置在nodes-config目录下。生成配置拷贝到k8s集群的各个主机上。方便节点启动读取配置。
  - 本项目中的node-config仅作目录参考，需要自行生成新的配置
  
  2 k8s部署的yaml文件在bcos_kubernetes目录下，有相应的deployment.yaml和service.yaml。
   分别使用
  
    四个机构每个机构一个节点。
   
 在每个节点下执行：
 ```bash
 kubectl apply -f peer0.org1.yaml
 ```