## front镜像K8S部署说明

## 前提条件

|   环境    | 版本                   |
| :------: | :----------------------: |
| Docker |       建议17.06之后版本    |
| Kubernetes |       建议1.12之后版本    |


### 1. 镜像部署使用步骤

  请先熟悉[front镜像使用文档.md](docker/front-install.md) ,
  1 生成各节点配置：
  请将**build.chain**脚本生成的配置在nodes-config目录下。生成配置拷贝到k8s集群的各个主机上。方便节点启动读取配置。
  
  2 k8s部署的yaml文件在bcos_kubernetes目录下，有相应的deployment.yaml和service.yaml。
   分别使用
  
    四个机构每个机构一个节点。
   
 在每个节点下执行：
 ```bash
 kubectl apply -f peer0.org1.deployment.yaml
 kubectl apply -f peer0.org1.svc.yaml
 ```