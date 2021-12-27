#!/bin/bash
CYAN="\033[36;1m"
GREEN="\033[32;1m"
RESET="\033[0m"
set -e
BASE_DIR=$(
  dirname "$0"
#  cd "$(dirname "$0")"
#  pwd || exit
)
"${BASE_DIR}"/check.sh
BUILD_CONFIG="${BASE_DIR}/source/elasticsearch/elasticsearch-parcel.properties"
ES_VERSION=$(sed '/^ES_VERSION=/!d;s/.*=//' "${BUILD_CONFIG}")
CDH_VERSION=$(sed '/^CDH_VERSION=/!d;s/.*=//' "${BUILD_CONFIG}")
OS_VERSION=$(sed '/^OS_VERSION=/!d;s/.*=//' "${BUILD_CONFIG}")
ES_TAR_BALL_NAME="elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz"
ES_UNZIP_DIR_NAME="elasticsearch-${ES_VERSION}"
LIB_DIR="${BASE_DIR}/lib"
RESOURCES_DIR="${BASE_DIR}/resources"
SOURCE_DIR="${BASE_DIR}/source"
TARGET_DIR="${BASE_DIR}/target"
BUILD_DIR="${TARGET_DIR}/build"
PARCEL_BUILD_FOLDER_NAME="ELASTICSEARCH-${ES_VERSION}-${CDH_VERSION}"
PARCEL_BUILD_DIR="${BUILD_DIR}/${PARCEL_BUILD_FOLDER_NAME}"
PARCEL_NAME="ELASTICSEARCH-${ES_VERSION}-${CDH_VERSION}-${OS_VERSION}.parcel"
PARCEL_DIR="${TARGET_DIR}/parcels/elasticsearch"
CSD_BUILD_DIR="${TARGET_DIR}/build/elasticsearch-csd"
CSD_DIR="${TARGET_DIR}/csd"
CSD_NAME="ELASTICSEARCH-csd-${ES_VERSION}.jar"

function clean() {
  if [ -d "${PARCEL_BUILD_DIR}" ]; then
    echo -e "${GREEN}删除parcel构建目录 ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
    rm -rf "${PARCEL_BUILD_DIR}"
  fi
  if [ -d "${PARCEL_DIR}" ]; then
    echo -e "${GREEN}删除parcel目录 ${CYAN}${PARCEL_DIR}${RESET}"
    rm -rf "${PARCEL_DIR}"
  fi
  if [ -d "${CSD_BUILD_DIR}" ]; then
    echo -e "${GREEN}删除csd资源目录 ${CYAN}${CSD_BUILD_DIR}${RESET}"
    rm -rf "${CSD_BUILD_DIR}"
  fi
  if [ -f "${CSD_DIR}/${CSD_NAME}" ]; then
    echo -e "${GREEN}删除csd文件 ${CYAN}${CSD_DIR}/${CSD_NAME}${RESET}"
    rm -rf "${CSD_DIR:?}/${CSD_NAME}"
  fi
}

function build_parcel() {
  if [ ! -f "${RESOURCES_DIR}/${ES_TAR_BALL_NAME}" ]; then
    ES_URL=$(sed '/^ES_URL=/!d;s/.*=//' "${BUILD_CONFIG}")
    echo -e "${GREEN}开始从 ${CYAN}${ES_URL}${GREEN} 下载 ${CYAN}${ES_TAR_BALL_NAME}${RESET}"
    # 如果 ElasticSearch 安装包不存在则下载
    wget -P "${RESOURCES_DIR}" "${ES_URL}"
  fi
  if [ ! -d "${BUILD_DIR}/${ES_UNZIP_DIR_NAME}" ]; then
    mkdir -p "${BUILD_DIR}"
    echo -e "${GREEN}解压 ${CYAN}${RESOURCES_DIR}/${ES_TAR_BALL_NAME}${GREEN} 到 ${CYAN}${BUILD_DIR}/${ES_UNZIP_DIR_NAME}${RESET}"
    # 解压 ElasticSearch 安装包
    tar -xf "${RESOURCES_DIR}/${ES_TAR_BALL_NAME}" -C "${BUILD_DIR}"
    echo -e "${GREEN}重命名 ${CYAN}${BUILD_DIR}/${ES_UNZIP_DIR_NAME}${GREEN} 到 ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
    mv "${BUILD_DIR}/${ES_UNZIP_DIR_NAME}" "${PARCEL_BUILD_DIR}"
  fi
  cp -r "${SOURCE_DIR}/elasticsearch/parcel/config" "${PARCEL_BUILD_DIR}/"
  cp -r "${SOURCE_DIR}/elasticsearch/parcel/meta" "${PARCEL_BUILD_DIR}/"
  echo -e "${GREEN}创建 ${CYAN}${PARCEL_DIR}${RESET}"
  mkdir -p "${PARCEL_DIR}"
  # 打包parcel
  echo -e "${GREEN}打包 ${CYAN}${PARCEL_BUILD_DIR}${GREEN} 到 ${CYAN}${PARCEL_DIR}/${PARCEL_NAME}${RESET}"
  if [ "$(uname)" = "Linux" ]; then
    tar cfhz "${PARCEL_DIR}/${PARCEL_NAME}" -C"${BUILD_DIR}" "${PARCEL_BUILD_FOLDER_NAME}" --owner=root --group=root
  else
    tar cfhz "${PARCEL_DIR}/${PARCEL_NAME}" -C"${BUILD_DIR}" "${PARCEL_BUILD_FOLDER_NAME}"
  fi
  # 校验parcel
  echo -e "${GREEN}校验 ${CYAN}${PARCEL_DIR}/${PARCEL_NAME}${RESET}"
  java -jar "${LIB_DIR}/validator.jar" -f "${PARCEL_DIR}/${PARCEL_NAME}"
  # 生成sha
  echo -e "${GREEN}为 ${CYAN}${PARCEL_DIR}/${PARCEL_NAME}${GREEN} 生成 ${CYAN}${PARCEL_DIR}/${PARCEL_NAME}.sha${RESET}"
  sha1sum "${PARCEL_DIR}/${PARCEL_NAME}" | awk '{print $1}' >"${PARCEL_DIR}/${PARCEL_NAME}.sha"
  echo -e "${GREEN}为 ${CYAN}${PARCEL_BUILD_DIR}${GREEN} 生成${CYAN} manifest.json${RESET}"
  # 生成manifest.json
  python "${LIB_DIR}/make_manifest.py" "${PARCEL_DIR}"
}

build_csd() {
  echo -e "${GREEN}创建csd构建目录 ${CYAN}${CSD_BUILD_DIR}${RESET}"
  mkdir -p "${CSD_BUILD_DIR}"
  cp -rf "${SOURCE_DIR}/elasticsearch/csd/"* "${CSD_BUILD_DIR}"
  # 打包csd
  echo -e "${GREEN}将 ${CYAN}${CSD_BUILD_DIR}${GREEN} 打包为csd ${CYAN}${CSD_DIR}/${CSD_NAME}${RESET}"
  mkdir -p "${CSD_DIR}"
  jar -cvf "${CSD_DIR}/${CSD_NAME}" -C "${CSD_BUILD_DIR}" .
}
clean
build_parcel
build_csd
echo -e "${GREEN}Done !!!${RESET}"
