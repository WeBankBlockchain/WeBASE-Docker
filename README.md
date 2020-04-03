
# WeBASE-Docker
 [FISCO BCOS](https://github.com/FISCO-BCOS/FISCO-BCOS) + [WeBASE-Front](https://github.com/WeBankFinTech/WeBASE-Front) 镜像和K8s部署。
 
  项目主要有三个部分：
  1. docker目录存放front镜像打包相关文件。
    - [front镜像使用文档.md](docker/front.md) 
  
  2. k8s目录主要存放front镜像k8s部署相关yaml文件。
  3. nodes-config主要存放相关buildchain和节点相关配置文件。
 
 ### 1. 镜像简要说明
 front镜像包含了底层镜像和WeBASE-Front的代码。通过镜像搭建区块链网络需要通过[build_chain.sh](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/build_chain.html) 生成各节点的配置信息。
 搭建区块链网络前建议阅读以下两部分内容。

 #### 1.1节点网络说明
 
 - 每个节点需要3个端口，详细请参考[FISCO BCOS网络端口讲解](https://mp.weixin.qq.com/s/IiHsPlxmvEEBTC84n27I9A)。
 - 节点之间需要保证P2P网络可达
 - 节点的channel端口供SDK访问，但默认监听127.0.0.1
 - 节点的RPC端口提供HTTP的JSON-RPC协议，但默认监听127.0.0.1
 
 ### 1.2 节点依赖说明
 
 **下述配置文件，脚本会自动生成，放置在节点目录下，启动容器时挂载即可**。
 
 - 每个节点启动依赖一些配置文件，详细请参考[FISCO BCOS配置说明](https://mp.weixin.qq.com/s/3RGTRvheSr5P1nXbmAjl2g)。
 - 主配置文件config.ini，其中会配置本节点监听的IP和端口。需要根据云环境定制。
 - 主配置文件config.ini，其中会配置需要链接的其他节点IP和端口，需要根据云环境定制。
 - ca.crt/node.crt/node.key是节点建立SSL链接是使用的证书相关文件。
 - 节点conf/目录下会有群组配置相关文件，节点启动时依赖。需要注意conf/group.1.genesis文件中会存放节点的nodeid，是节点node.key对应的公钥。
 

 ### 2 附录
  docker安装，推荐使用centos系统。安装请参考官方文档：https://docs.docker.com/install/linux/docker-ce/centos/
 


