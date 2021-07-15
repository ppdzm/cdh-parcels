#!/bin/bash
CYAN="\033[36;1m"
GREEN="\033[32;1m"
RED="\033[31;1m"
RESET="\033[0m"
#set -x
set -e
#set -v
usage(){
  echo -e "${GREEN}Usage: $0 < parcel | csd | csd_standalone >"
}
if [ -z "$1" ];then
  usage
fi

FLINK_URL=$(sed '/^FLINK_URL=/!d;s/.*=//' flink-parcel.properties)
FLINK_VERSION=$(sed '/^FLINK_VERSION=/!d;s/.*=//' flink-parcel.properties)
EXT_VERSION=$(sed '/^EXT_VERSION=/!d;s/.*=//' flink-parcel.properties)
OS_VERSION=$(sed '/^OS_VERSION=/!d;s/.*=//' flink-parcel.properties)
CDH_MIN_FULL=$(sed '/^CDH_MIN_FULL=/!d;s/.*=//' flink-parcel.properties)
CDH_MIN=$(sed '/^CDH_MIN=/!d;s/.*=//' flink-parcel.properties)
CDH_MAX_FULL=$(sed '/^CDH_MAX_FULL=/!d;s/.*=//' flink-parcel.properties)
CDH_MAX=$(sed '/^CDH_MAX=/!d;s/.*=//' flink-parcel.properties)

SERVICE_NAME="FLINK"
# flink
SERVICE_NAME_LOWER=$(echo $SERVICE_NAME | tr '[:upper:]' '[:lower:]')
# flink-1.13.1-bin-scala_2.11.tgz
ARCHIVE_NAME=$(basename "$FLINK_URL")
# flink-1.13.1
UNZIP_ARCHIVE_NAME="${SERVICE_NAME_LOWER}-${FLINK_VERSION}"
# flink-1.13.1-bin-scala_2.11
PARCEL_FOLDER_NAME_LOWER="$(basename "$ARCHIVE_NAME" .tgz)"
# FLINK-1.13.1-BIN-SCALA_2.11
PARCEL_FOLDER_NAME_UPPER="$(echo "$PARCEL_FOLDER_NAME_LOWER" | tr '[:lower:]' '[:upper:]')"
# FLINK-1.13.1-BIN-SCALA_2.11
PARCEL_BUILD_PATH="$PARCEL_FOLDER_NAME_UPPER"
# FLINK-1.13.1-BIN-SCALA_2.11-el7.parcel
PARCEL_NAME="$PARCEL_FOLDER_NAME_UPPER-el${OS_VERSION}.parcel"
PARCEL_PATH="${PARCEL_FOLDER_NAME_UPPER}_build"

function build_cm_ext() { #Checkout if dir does not exist
  if [ ! -d cm_ext ]; then
    # 拉取cm_ext
    git clone https://github.com/cloudera/cm_ext.git
  fi
  if [ ! -f cm_ext/validator/target/validator.jar ]; then
    cd cm_ext
    #git checkout "$CM_EXT_BRANCH"
    # 如果validator.jar不存在则打包
    mvn install -DskipTests
    cd ..
  fi
}

function get_flink() {
  if [ ! -f "$ARCHIVE_NAME" ]; then
    # 如果Flink安装包不存在则下载
    wget "$FLINK_URL"
  fi
  #flink_md5="$( md5sum $ARCHIVE_NAME | cut -d' ' -f1 )"
  #if [ "$flink_md5" != "$FLINK_MD5" ]; then
  # echo ERROR: md5 of $ARCHIVE_NAME is not correct
  #exit 1
  #fi
  if [ ! -d "$UNZIP_ARCHIVE_NAME" ]; then
    echo -e "${CYAN}tar -xvf $GREEN$ARCHIVE_NAME$RESET"
    # 解压Flink安装包
    tar -xf "$ARCHIVE_NAME"
  fi
}

function build_parcel() {
  if [ -f "$PARCEL_PATH/$PARCEL_NAME" ] && [ -f "$PARCEL_PATH/manifest.json" ]; then
    rm -rf "$PARCEL_PATH"
  fi
  echo -e "${CYAN}Flink 解压文件夹为 $GREEN$UNZIP_ARCHIVE_NAME$RESET"
  if [ -d "$PARCEL_BUILD_PATH" ]; then
    echo -e "${CYAN}删除已存在的Parcel资源目录 $GREEN$PARCEL_BUILD_PATH$RESET"
    rm -rf "$PARCEL_BUILD_PATH"
  fi
  get_flink
  echo -e "${CYAN}创建Parcel资源目录 $GREEN$PARCEL_BUILD_PATH$RESET"
  mkdir -p "$PARCEL_BUILD_PATH"
  echo -e "${CYAN}拷贝Flink目录 $GREEN$UNZIP_ARCHIVE_NAME${CYAN} 下的文件到 $GREEN$PARCEL_BUILD_PATH$RESET"
  cp -r "$UNZIP_ARCHIVE_NAME"/* "$PARCEL_BUILD_PATH/"
  echo -e "${CYAN}拷贝 ${GREEN}src/flink/parcel/meta${CYAN} 到 $GREEN$PARCEL_BUILD_PATH$RESET"
  cp -r src/flink/parcel/meta "$PARCEL_BUILD_PATH/"
  chmod 755 src/flink/parcel/flink*
  echo -e "${CYAN}拷贝 ${GREEN}src/flink/parcel/config.sh${CYAN} 到 $GREEN$PARCEL_BUILD_PATH$RESET"
  cp -r src/flink/parcel/config.sh "$PARCEL_BUILD_PATH/bin/"
  echo -e "${CYAN}拷贝 ${GREEN}src/flink/parcel/flink-master.sh${CYAN} 到 $GREEN$PARCEL_BUILD_PATH$RESET"
  cp -r src/flink/parcel/flink-master.sh "$PARCEL_BUILD_PATH/bin/"
  echo -e "${CYAN}拷贝 ${GREEN}src/flink/parcel/flink-worker.sh${CYAN} 到 $GREEN$PARCEL_BUILD_PATH$RESET"
  cp -r src/flink/parcel/flink-worker.sh "$PARCEL_BUILD_PATH/bin/"
  echo -e "${CYAN}拷贝 ${GREEN}src/flink/parcel/flink-yarn.sh${CYAN} 到 $GREEN$PARCEL_BUILD_PATH$RESET"
  cp -r src/flink/parcel/flink-yarn.sh "$PARCEL_BUILD_PATH/bin/"
  sed -i -e "s/%flink_version%/$PARCEL_FOLDER_NAME_UPPER/" "$PARCEL_BUILD_PATH/meta/flink_env.sh"
  sed -i -e "s/%VERSION%/$FLINK_VERSION/" "$PARCEL_BUILD_PATH/meta/parcel.json"
  sed -i -e "s/%EXT_VERSION%/$EXT_VERSION/" "$PARCEL_BUILD_PATH/meta/parcel.json"
  sed -i -e "s/%CDH_MAX_FULL%/$CDH_MAX_FULL/" "$PARCEL_BUILD_PATH/meta/parcel.json"
  sed -i -e "s/%CDH_MIN_FULL%/$CDH_MIN_FULL/" "$PARCEL_BUILD_PATH/meta/parcel.json"
  sed -i -e "s/%SERVICE_NAME%/$SERVICE_NAME/" "$PARCEL_BUILD_PATH/meta/parcel.json"
  sed -i -e "s/%SERVICE_NAME_LOWER%/$SERVICE_NAME_LOWER/" "$PARCEL_BUILD_PATH/meta/parcel.json"
  java -jar cm_ext/validator/target/validator.jar -d "$PARCEL_BUILD_PATH"
  echo -e "${CYAN}创建Parcel构建目录 $GREEN$PARCEL_PATH$RESET"
  mkdir -p "$PARCEL_PATH"
  echo -e "${CYAN}构建Parcel $GREEN$PARCEL_PATH/$PARCEL_NAME$RESET"
  if [ "$(uname)" = "Linux" ]; then
    tar zchf "$PARCEL_PATH/$PARCEL_NAME" "$PARCEL_BUILD_PATH" --owner=root --group=root
  else
    tar zchf "$PARCEL_PATH/$PARCEL_NAME" "$PARCEL_BUILD_PATH"
  fi
  echo -e "${CYAN}校验Parcel $GREEN$PARCEL_PATH/$PARCEL_NAME$RESET"
  java -jar cm_ext/validator/target/validator.jar -f "$PARCEL_PATH/$PARCEL_NAME"
  echo -e "${CYAN}为Parcel $GREEN$PARCEL_PATH/${PARCEL_NAME}生成manifest.json$RESET"
  python cm_ext/make_manifest/make_manifest.py "$PARCEL_PATH"
  echo -e "${CYAN}为Parcel $GREEN$PARCEL_PATH/${PARCEL_NAME}生成sha$RESET"
  sha1sum "$PARCEL_PATH/$PARCEL_NAME" | awk '{print $1}' >"$PARCEL_PATH/${PARCEL_NAME}.sha"
}

function build_csd() {
  JARNAME=${SERVICE_NAME}-csd-${FLINK_VERSION}.jar
  if [ -f "$JARNAME" ]; then
    rm -f "$JARNAME"
  fi
  CSD_BUILD_PATH="flink-csd-build"
  rm -rf ${CSD_BUILD_PATH}
  cp -rf src/flink/csd ${CSD_BUILD_PATH}
  sed -i -e "s/%SERVICE_NAME%/$livy_service_name/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%SERVICE_NAME_LOWER%/$SERVICE_NAME_LOWER/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%VERSION%/$FLINK_VERSION/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%CDH_MIN%/$CDH_MIN/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%CDH_MAX%/$CDH_MAX/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%SERVICE_NAME_LOWER%/$SERVICE_NAME_LOWER/" ${CSD_BUILD_PATH}/scripts/control.sh
  java -jar cm_ext/validator/target/validator.jar -s ${CSD_BUILD_PATH}/descriptor/service.sdl -l "SPARK_ON_YARN SPARK2_ON_YARN"
  jar -cvf "csd-build/$JARNAME" -C ${CSD_BUILD_PATH} .
}

function build_csd_standalone() {
  JARNAME=${SERVICE_NAME}_STANDALONE-csd-${FLINK_VERSION}.jar
  if [ -f "$JARNAME" ]; then
    rm -f "$JARNAME"
  fi
  CSD_BUILD_PATH="flink-csd-standalone-build"
  rm -rf ${CSD_BUILD_PATH}
  cp -rf src/flink/csd-standalone ${CSD_BUILD_PATH}
  sed -i -e "s/%VERSION%/$FLINK_VERSION/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%CDH_MIN%/$CDH_MIN/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%CDH_MAX%/$CDH_MAX/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%SERVICE_NAME%/$livy_service_name/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%SERVICE_NAME_LOWER%/$SERVICE_NAME_LOWER/" ${CSD_BUILD_PATH}/descriptor/service.sdl
  sed -i -e "s/%SERVICE_NAME_LOWER%/$SERVICE_NAME_LOWER/" ${CSD_BUILD_PATH}/scripts/control.sh
  java -jar cm_ext/validator/target/validator.jar -s ${CSD_BUILD_PATH}/descriptor/service.sdl -l "SPARK_ON_YARN SPARK2_ON_YARN"
  echo "jar -cvf $JARNAME -C ${CSD_BUILD_PATH} ${CSD_PATH}"
  jar -cvf "csd-build/$JARNAME" -C ${CSD_BUILD_PATH} .
}

case $1 in
parcel)
  build_cm_ext
  build_parcel
  ;;
csd)
  build_csd
  ;;
csd_standalone)
  build_csd_standalone
  ;;
*)
  echo "Usage: $0 < parcel | csd | csd_standalone >"
  ;;
esac
echo -e "${GREEN}Done!!!${RESET}"