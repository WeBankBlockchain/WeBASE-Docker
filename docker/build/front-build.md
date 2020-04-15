
## 脚本使用说明：

1 检查Dockerfile第一行，看是否需要修改底层镜像。  
2 打国密镜像时务必保证applicaiton.yml的encryptType为1。  
3 拷贝jdk-8u211-linux-x64.tar.gz到docker目录下。  
4  sh docker-build.sh bsn v1.0 （bsn 是分支， v1.0 是tag）。  
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
