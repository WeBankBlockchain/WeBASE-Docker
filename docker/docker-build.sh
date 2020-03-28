#!/bin/bash

 cp ./start.sh ./dist/
 cp -r ./dist/conf_template ./dist/conf

 echo "此次镜像tag: $1"
 docker build -t  front:$1 .
 docker tag  front:$1 fiscoorg/front:$1
# docker push fiscoorg/front:$1