
# WeBASE-Docker
 [FISCO BCOS](https://github.com/FISCO-BCOS/FISCO-BCOS) + [WeBASE-Front](https://github.com/WeBankFinTech/WeBASE-Front) 镜像和K8s部署。
 
  项目主要有三个部分：
  1. docker目录存放front镜像使用和打包相关文件。  
    - [front镜像使用文档.md](docker/front-install.md)   
    - [front镜像打包文档.md](docker/front-build.md)
  
  2. k8s目录主要存放front镜像k8s部署相关yaml文件。
  3. nodes-config主要存放相关buildchain和节点相关配置文件。
 
 ### 1. 镜像简要说明
 front镜像包含了底层镜像和WeBASE-Front的代码,将节点和节点前置放在一起。通过镜像搭建区块链网络需要通过[build_chain.sh](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/manual/build_chain.html) 生成各节点的配置信息。
 搭建区块链网络前建议阅读以下两部分内容并熟悉buildchain的使用。

 #### 1.1节点网络说明
 
 - 每个节点需要3个端口，详细请参考[FISCO BCOS网络端口讲解](https://mp.weixin.qq.com/s/IiHsPlxmvEEBTC84n27I9A)。
 - 节点之间需要保证P2P网络可达
 - 节点的channel端口供SDK访问，但默认监听127.0.0.1
 - 节点的RPC端口提供HTTP的JSON-RPC协议，但默认监听127.0.0.1
 
 ### 1.2 节点依赖说明
 
 **buildchain脚本会自动生成各节点相关配置文件，放置在节点目录下，启动容器时需挂载节点的配置文件**。
 
 - 每个节点启动依赖一些配置文件，详细请参考[FISCO BCOS配置说明](https://mp.weixin.qq.com/s/3RGTRvheSr5P1nXbmAjl2g)。
 - 主配置文件config.ini，其中会配置本节点监听的IP和端口。需要根据云环境定制。
 - 主配置文件config.ini，其中会配置需要链接的其他节点IP和端口，需要根据云环境定制。
 - ca.crt/node.crt/node.key是节点建立SSL链接是使用的证书相关文件。
 - 节点conf/目录下会有群组配置相关文件，节点启动时依赖。需要注意conf/group.1.genesis文件中会存放节点的nodeid，是节点node.key对应的公钥。
 

 ### 2 附录
 #### 2.1 安装
 
| 操作系统         |  版本最低要求     |  安装方式    |
| ------------- |:-------|:-----|
| CentOS(RHEL)| CentOS 7.3（kernel >= 3.10.0-514）      |curl -fsSL https://get.docker.com -o get-docker.sh && bash get-docker.sh|
|Debian|Stretch 9  |curl -fsSL https://get.docker.com -o get-docker.sh && bash get-docker.sh|
|Ubuntu|Xenial 16.04 (LTS)|curl -fsSL https://get.docker.com -o get-docker.sh && bash get-docker.sh|
|MacOS| 10.13 |参考: [https://docs.docker.com/docker-for-mac/install/](https://docs.docker.com/docker-for-mac/install/)|

关于其他系统的安装方法，请参考: https://docs.docker.com/install/linux/docker-ce/binaries/

因为 Docker 的存储驱动，建议使用 overlay2，所以需要 Linux kernel 4.0 以上的版本。如果是 RHEL 或者 CentOS 的话，需要 Linux kernel  3.10.0-51 以上。关于 overlay2 请参考: [https://docs.docker.com/storage/storagedriver/overlayfs-driver/](https://docs.docker.com/storage/storagedriver/overlayfs-driver/)

CentOS 版本对应的 kernel 版本请参考: [https://en.wikipedia.org/wiki/CentOS#CentOS_version_7](https://en.wikipedia.org/wiki/CentOS#CentOS_version_7)


 