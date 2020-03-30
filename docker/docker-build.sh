#!/bin/bash

# wget https://www.fisco.com.cn/cdn/webase/releases/download/v1.2.3/webase-front.zip

  git clone -b $1 https://github.com/WeBankFinTech/WeBASE-Front.git && cd  WeBASE-Front
  chmod +x ./gradlew
 ./gradlew build -x test

  cp -r dist ../
  cd .. && rm -rf WeBASE-Front
  cp ./start.sh ./dist/
  cp -r ./dist/conf_template ./dist/conf

 echo "此次镜像tag: $2"
 docker build -t  front:$2 .
 docker tag  front:$2 fiscoorg/front:$2
 rm -rf dist
# docker push fiscoorg/front:$1