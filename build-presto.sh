#!/bin/bash
CYAN="\033[36;1m"
GREEN="\033[32;1m"
RED="\033[31;1m"
RESET="\033[0m"
set -e
PRESTO_VERSION="0.257"
CDH_VERSION="cdh-6.3.2"
PARCEL_RESOURCE_PATH="PRESTO-${PRESTO_VERSION}-${CDH_VERSION}"
PARCEL_NAME="PRESTO-${PRESTO_VERSION}-${CDH_VERSION}-el7.parcel"
PRESTO_TAR_BALL_NAME="presto-server-${PRESTO_VERSION}.tar.gz"
PRESTO_UNZIP_DIR_NAME="presto-server-${PRESTO_VERSION}"
PARCEL_BUILD_PATH="${PARCEL_RESOURCE_PATH}_build"
CSD_RESOURCE_PATH="presto-csd"
CSD_NAME="PRESTO-csd-${PRESTO_VERSION}.jar"
ETC_PATH="src/presto/parcel/etc"
META_PATH="src/presto/parcel/meta"

PRESTO_DOWNLOAD_URL="https://repo1.maven.org/maven2/com/facebook/presto/presto-server/${PRESTO_VERSION}/$PRESTO_TAR_BALL_NAME"
if [ ! -f "$PRESTO_TAR_BALL_NAME" ];then
  echo -e "${GREEN}开始从 $CYAN$PRESTO_DOWNLOAD_URL${GREEN} 下载 $CYAN$PRESTO_TAR_BALL_NAME$RESET"
  curl -L -o "$PRESTO_TAR_BALL_NAME" "$PRESTO_DOWNLOAD_URL"
fi
PRETO_CLI_JAR="presto-cli-${PRESTO_VERSION}-executable.jar"
PRESTO_CLI_URL="https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/${PRESTO_VERSION}/$PRETO_CLI_JAR"
if [ ! -f "$PRETO_CLI_JAR" ];then
  echo -e "${GREEN}开始从 $CYAN$PRESTO_CLI_URL${GREEN} 下载 $CYAN$PRETO_CLI_JAR$RESET"
  curl -L -O "$PRESTO_CLI_URL"
fi
PRETO_JDBC_JAR="presto-jdbc-${PRESTO_VERSION}.jar"
PRESTO_JDBC_URL="https://repo1.maven.org/maven2/com/facebook/presto/presto-jdbc/${PRESTO_VERSION}/PRETO_JDBC_JAR"
if [ ! -f "$PRETO_JDBC_JAR" ];then
  echo -e "${GREEN}开始从 $CYAN$PRESTO_JDBC_URL${GREEN} 下载 $CYAN$PRETO_JDBC_JAR$RESET"
  curl -L -O "$PRESTO_JDBC_URL"
fi

if [ -d "$PARCEL_RESOURCE_PATH" ];then
  echo -e "${GREEN}删除parcel资源目录 $CYAN$PARCEL_RESOURCE_PATH$RESET"
  rm -rf "$PARCEL_RESOURCE_PATH"
fi
if [ -d "$PARCEL_BUILD_PATH" ];then
  echo -e "${GREEN}删除parcel构建目录 $CYAN$PARCEL_BUILD_PATH$RESET"
  rm -rf "$PARCEL_BUILD_PATH"
fi
if [ -d "$CSD_RESOURCE_PATH" ];then
  echo -e "${GREEN}删除csd目录 $CYAN$CSD_RESOURCE_PATH$RESET"
  rm -rf "$CSD_RESOURCE_PATH"
fi
if [ ! -d "$PRESTO_UNZIP_DIR_NAME" ];then
  echo -e "${GREEN}解压 $CYAN$PRESTO_TAR_BALL_NAME${GREEN} 到 $CYAN$PRESTO_UNZIP_DIR_NAME$RESET"
  tar xzf "$PRESTO_TAR_BALL_NAME"
fi
# 重命名server到parcel
echo -e "${GREEN}移动 $CYAN$PRESTO_UNZIP_DIR_NAME${GREEN} 到 $CYAN$PARCEL_RESOURCE_PATH$RESET"
mv $PRESTO_UNZIP_DIR_NAME $PARCEL_RESOURCE_PATH
# 复制meta到parcel
echo -e "${GREEN}复制 $CYAN$META_PATH${GREEN} 到 $CYAN$PARCEL_RESOURCE_PATH$RESET"
cp -rf $META_PATH $PARCEL_RESOURCE_PATH
#cp -rf $ETC_PATH $PARCEL_RESOURCE_PATH
mkdir -p $PARCEL_RESOURCE_PATH/etc/catalog
# 复制cli jar到parcel bin
echo -e "${GREEN}复制 $CYAN$PRETO_CLI_JAR${GREEN} 到 $CYAN$PARCEL_RESOURCE_PATH$RESET"
cp -rf ${PRETO_CLI_JAR} $PARCEL_RESOURCE_PATH/bin/
# 复制jdbc jar到parcel lib
echo -e "${GREEN}复制 $CYAN$PRETO_JDBC_JAR${GREEN} 到 $CYAN$PARCEL_RESOURCE_PATH$RESET"
cp -rf ${PRETO_JDBC_JAR} $PARCEL_RESOURCE_PATH/lib/
echo -e "${GREEN}创建 $CYAN$PARCEL_RESOURCE_PATH/bin/presto$RESET"
# 复制launcher到 parcel bin
echo -e "${GREEN}复制 ${CYAN}src/presto/parcel/launcher${GREEN} 到 $CYAN$PARCEL_RESOURCE_PATH$RESET"
cp -rf src/presto/parcel/launcher $PARCEL_RESOURCE_PATH/bin/
chmod +x $PARCEL_RESOURCE_PATH/bin/launcher
# 创建PRESTO-0.257-cdh-6.3.2/bin/presto
cat <<"EOF" > "$PARCEL_RESOURCE_PATH/bin/presto"
#!/usr/bin/env python

import os
import sys
import subprocess
from os.path import realpath, dirname

path = dirname(realpath(sys.argv[0]))
arg = ' '.join(sys.argv[1:])
cmd = "env PATH=\"/usr/java/jdk1.8.0_181-cloudera/bin:$PATH\" %s/presto-cli-0.257-executable.jar %s" % (path, arg)

subprocess.call(cmd, shell=True)
EOF
echo -e "${GREEN}修改 $CYAN$PARCEL_RESOURCE_PATH/bin/presto$GREEN 为可执行$RESET"
chmod +x "$PARCEL_RESOURCE_PATH/bin/presto"
# 校验生成parcel前的路径：java -jar cm_ext/validator/target/validator.jar -d PRESTO-0.257-cdh-6.3.2
echo -e "${GREEN}校验 $CYAN$PARCEL_RESOURCE_PATH$RESET"
if [ ! -f cm_ext/validator/target/validator.jar ];then
  cd cm_ext
  mvn package -DskipTests
  cd ..
fi
java -jar cm_ext/validator/target/validator.jar -d $PARCEL_RESOURCE_PATH
# 创建PRESTO-0.257-cdh-6.3.2_build
echo -e "${GREEN}创建 $CYAN$PARCEL_BUILD_PATH$RESET"
mkdir -p $PARCEL_BUILD_PATH
# 打包parcel：tar chfz PRESTO-0.257-cdh-6.3.2_build/PRESTO-0.257-cdh-6.3.2-el7.parcel PRESTO-0.257-cdh-6.3.2
echo -e "${GREEN}打包 $CYAN$PARCEL_RESOURCE_PATH${GREEN} 到 $CYAN$PARCEL_BUILD_PATH/$PARCEL_NAME$RESET"
tar chfz $PARCEL_BUILD_PATH/$PARCEL_NAME $PARCEL_RESOURCE_PATH
# 校验parcel：java -jar cm_ext/validator/target/validator.jar -f PRESTO-0.257-cdh-6.3.2_build/PRESTO-0.257-cdh-6.3.2-el7.parcel
echo -e "${GREEN}校验 $CYAN$PARCEL_BUILD_PATH/$PARCEL_NAME$RESET"
java -jar cm_ext/validator/target/validator.jar -f $PARCEL_BUILD_PATH/$PARCEL_NAME
# 生成sha：sha1sum PRESTO-0.257-cdh-6.3.2_build/PRESTO-0.257-cdh-6.3.2-el7.parcel | awk '{print $1}' > PRESTO-0.257-cdh-6.3.2_build/PRESTO-0.257-cdh-6.3.2-el7.parcel.sha
echo -e "${GREEN}为 $CYAN$PARCEL_BUILD_PATH/$PARCEL_NAME${GREEN} 生成 $CYAN$PARCEL_BUILD_PATH/$PARCEL_NAME.sha$RESET"
sha1sum $PARCEL_BUILD_PATH/$PARCEL_NAME | awk '{print $1}' > $PARCEL_BUILD_PATH/$PARCEL_NAME.sha
echo -e "${GREEN}为 $CYAN$PARCEL_BUILD_PATH${GREEN} 生成$CYAN manifest.json$RESET"
# 生成manifest.json：python cm_ext/make_manifest/make_manifest.py $PARCEL_BUILD_PATH
python cm_ext/make_manifest/make_manifest.py $PARCEL_BUILD_PATH
if [ -d $CSD_RESOURCE_PATH ];then
  rm -rf CSD_RESOURCE_PATH
fi
echo -e "${GREEN}创建csd目录 $CYAN$CSD_RESOURCE_PATH$RESET"
mkdir -p $CSD_RESOURCE_PATH
cp -rf src/presto/csd/* $CSD_RESOURCE_PATH
# 打包csd：jar -cvf csd/PRESTO-csd-0.257.jar -C presto-csd-build .
echo -e "${GREEN}将 ${CYAN}$CSD_RESOURCE_PATH${GREEN} 打包为csd ${CYAN}csd/$CSD_NAME$RESET"
mkdir -p csd-build
jar -cvf csd-build/$CSD_NAME -C "$CSD_RESOURCE_PATH" .
echo -e "${GREEN}Done!!!!${RESET}"