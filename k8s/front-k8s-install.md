## front镜像K8S部署说明

## 前提条件

|   环境    | 版本                   |
| :------: | :----------------------: |
| Docker |       建议17.06之后版本    |
| Kubernetes |       建议1.12之后版本    |


### 1. 镜像部署使用步骤

 举例，如果要生成有四个机构，机构名分别为org1~org4，并且每个机构一个节点，单群组模式的区块链网络，则操作如下。  
 
 1 下载build_chain脚本
 
  ```bash
   curl -LO https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/v2.3.0/build_chain.sh && chmod u+x build_chain.sh
   ```
 
 2 准备配置文件
  k8s部署各Service暴露IP方式建议采用ClusterIP,并且service的clusterIP用指定值。
  如下，clusterIP我们采用**172.18.255.20～172.18.255.23**

```bash
# 此IP根据service的IP范围确定
# test 机构名
# 1 群组id
cat  > nodeconf << EOF
     172.18.255.20:1 org1 1
     172.18.255.21:1 org2 1
     172.18.255.22:1 org3 1
     172.18.255.23:1 org4 1
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
 请将生成的区块链配置nodes目录拷贝到k8s集群的各个主机上。方便节点启动读取配置。
  ```bash       
    cp -r nodes/ /root
 ```
  
 4 k8s部署的yaml文件在bcos_kubernetes目录下，有相应的deployment.yaml和service.yaml，这里合并在一个文件里。
   在k8s 主机上根据yaml启动镜像，参考命令如下：
    
 ```bash       
   kubectl apply -f peer0.org1.yaml   
```


### 2.k8s部署yaml解析

####2.1 delpoyment解析：

1 如下 需要将pod内 /data ，/dist/log以及/dist/conf/application.yml挂载出来。挂载主机目录在hostPath属性下，可自行修改。  
2 需要将pod的 8545(rpc)，20200(channel)，30300(p2p)，5002（front端口）暴露出来。
```
    spec:
      containers:
      - name: peer0-org1
        image: fiscoorg/front:bsn-0.2.0-gm
        ports:
        - containerPort: 8545
        - containerPort: 20200
        - containerPort: 30300
        - containerPort: 5002
        resources: {}
        volumeMounts:
        - mountPath: /data
          name: peer0-org1-conf
        - mountPath: /dist/log
          name: peer0-org1-frontlog
        - mountPath: /dist/conf/application.yml
          name: peer0-org1-appconf
        workingDir: /data
      restartPolicy: Always
      volumes:
      - name: peer0-org1-conf
        hostPath:
          path: /root/nodes/172.18.255.20/node0
      - name: peer0-org1-frontlog
        hostPath:
          path: /root/nodes/172.18.255.20/frontlog
      - name: peer0-org1-appconf
        hostPath:
          path: /root/nodes/application.yml
```
####2.2 service解析
1 service在集群中采用ClusterIP方式暴露服务，并指定clusterIP值。   
2 外网访问服务用户可以自行选择方案。

```
spec:
  clusterIP: 172.18.255.20
  ports:
  - name: rpc
    port: 8545
    targetPort: 8545
  - name: channel
    port: 20200
    targetPort: 20200
  - name: p2p
    port: 30300
    targetPort: 30300
  - name: front
    port: 5002
    targetPort: 5002
``` 