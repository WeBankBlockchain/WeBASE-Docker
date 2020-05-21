# choose bcos image, standard or guomi
ARG BCOS_IMG_VERSION
FROM fiscoorg/fiscobcos:${BCOS_IMG_VERSION:-v2.4.0}
LABEL maintainer service@fisco.com.cn

# bcos config files
WORKDIR /bcos
# WeBASE-Front files
WORKDIR /front

# setup JDK
ADD jdk-8u211-linux-x64.tar.gz /usr/local/
ENV JAVA_HOME /usr/local/jdk1.8.0_211
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH $PATH:$JAVA_HOME/bin

# COPY start shell of bcos and front
COPY ["docker-start.sh", "/docker-start.sh"]

# COPY front files
# cache lib layer
COPY ["dist/*.sh", "/front/"]
COPY ["dist/lib/", "/front/lib/"]
COPY ["dist/conf/", "/front/conf/"]
COPY ["dist/apps/", "/front/apps/"]

# expose port
EXPOSE 30300 20200 8545 5002

# start
ENTRYPOINT ["bash","/docker-start.sh"]
