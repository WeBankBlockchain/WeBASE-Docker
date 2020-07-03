
## 脚本使用说明：

1、检查Dockerfile第一行，看是否需要修改底层镜像

2、打国密镜像时务必保证applicaiton.yml的encryptType为1

3、拷贝jdk-8u211-linux-x64.tar.gz到docker目录下

4、sh docker-build.sh bsn v1.0.0 （bsn 是分支， v1.0.0 是tag）

5、如果拉代码过慢，自行注释掉docker-build.sh中虚线之前的代码



-----------------------------------------------------
## 镜像制作流程介绍：
1、手动拷贝jdk-8u211-linux-x64.tar.gz到docker目录

2、下载WeBASE-Front代码编译dist

3、拷贝start.sh脚本到dist目录

4、拷贝dist下的conf_template目录到conf目录

5、打镜像

​	docker build -t fiscoorg/front:v1.0.0 .

​	docker tag  fiscoorg/front:v1.0.0

​	docker push fiscoorg/front:v1.0.0