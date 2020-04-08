#!/bin/bash

# wget https://www.fisco.com.cn/cdn/webase/releases/download/v1.2.3/webase-front.zip

  git clone -b $1 https://github.com/WeBankFinTech/WeBASE-Front.git --depth=1 && cd  WeBASE-Front
  sh gradlew build -x test
  cp -r dist ../
  cd .. && rm -rf WeBASE-Front
  # 可以自动拷贝dist，注释上面部分代码即可。
#---------------------------------------------------------
  cp ./start.sh ./dist/
  cp -r ./dist/conf_template ./dist/conf

 echo "此次镜像tag: $2"
 docker build -t  front:$2 .
 docker tag  front:$2 fiscoorg/front:$2
 rm -rf dist
# docker push fiscoorg/front:$1