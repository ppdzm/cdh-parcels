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
BUILD_CONFIG="${BASE_DIR}/source/presto/presto-parcel.properties"
PRESTO_VERSION=$(sed '/^PRESTO_VERSION=/!d;s/.*=//' "${BUILD_CONFIG}")
CDH_VERSION=$(sed '/^CDH_VERSION=/!d;s/.*=//' "${BUILD_CONFIG}")
OS_VERSION=$(sed '/^OS_VERSION=/!d;s/.*=//' "${BUILD_CONFIG}")
PRESTO_TAR_BALL_NAME="presto-server-${PRESTO_VERSION}.tar.gz"
PRESTO_UNZIP_DIR_NAME="presto-server-${PRESTO_VERSION}"
LIB_DIR="${BASE_DIR}/lib"
RESOURCES_DIR="${BASE_DIR}/resources"
SOURCE_DIR="${BASE_DIR}/source"
TARGET_DIR="${BASE_DIR}/target"
BUILD_DIR="${TARGET_DIR}/build"
PARCEL_BUILD_FOLDER_NAME="PRESTO-${PRESTO_VERSION}-${CDH_VERSION}"
PARCEL_BUILD_DIR="${BUILD_DIR}/${PARCEL_BUILD_FOLDER_NAME}"
PARCEL_NAME="PRESTO-${PRESTO_VERSION}-${CDH_VERSION}-${OS_VERSION}.parcel"
PARCEL_DIR="${TARGET_DIR}/parcels/presto"
CSD_BUILD_DIR="${TARGET_DIR}/build/presto-csd"
CSD_DIR="${TARGET_DIR}/csd"
CSD_NAME="PRESTO-csd-${PRESTO_VERSION}.jar"

function get_presto() {
  PRESTO_DOWNLOAD_URL="https://repo1.maven.org/maven2/com/facebook/presto/presto-server/${PRESTO_VERSION}/${PRESTO_TAR_BALL_NAME}"
  if [ ! -f "${RESOURCES_DIR}/${PRESTO_TAR_BALL_NAME}" ]; then
    echo -e "${GREEN}开始从 ${CYAN}${PRESTO_DOWNLOAD_URL}${GREEN} 下载 ${CYAN}${PRESTO_TAR_BALL_NAME}${RESET}"
    curl -L -O "${PRESTO_DOWNLOAD_URL}"
    mv "${PRESTO_TAR_BALL_NAME}" "${RESOURCES_DIR}/"
  fi
  PRESTO_CLI_JAR="presto-cli-${PRESTO_VERSION}-executable.jar"
  PRESTO_CLI_URL="https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/${PRESTO_VERSION}/${PRESTO_CLI_JAR}"
  if [ ! -f "${RESOURCES_DIR}/${PRESTO_CLI_JAR}" ]; then
    echo -e "${GREEN}开始从 ${CYAN}${PRESTO_CLI_URL}${GREEN} 下载 ${CYAN}${PRESTO_CLI_JAR}${RESET}"
    curl -L -O "${PRESTO_CLI_URL}"
    mv "${PRESTO_CLI_URL}" "${RESOURCES_DIR}/"
  fi
  PRESTO_JDBC_JAR="presto-jdbc-${PRESTO_VERSION}.jar"
  PRESTO_JDBC_URL="https://repo1.maven.org/maven2/com/facebook/presto/presto-jdbc/${PRESTO_VERSION}/${PRESTO_JDBC_JAR}"
  if [ ! -f "${RESOURCES_DIR}/${PRESTO_JDBC_JAR}" ]; then
    echo -e "${GREEN}开始从 ${CYAN}${PRESTO_JDBC_URL}${GREEN} 下载 ${CYAN}${PRESTO_JDBC_JAR}${RESET}"
    curl -L -O "${PRESTO_JDBC_URL}"
    mv "${PRESTO_JDBC_URL}" "${RESOURCES_DIR}/"
  fi
}

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

function prepare() {
  if [ ! -d "${BUILD_DIR}/${PRESTO_UNZIP_DIR_NAME}" ]; then
    echo -e "${GREEN}解压 ${CYAN}${RESOURCES_DIR}/${PRESTO_TAR_BALL_NAME}${GREEN} 到 ${CYAN}${BUILD_DIR}/${PRESTO_UNZIP_DIR_NAME}${RESET}"
    tar xzf "${RESOURCES_DIR}/${PRESTO_TAR_BALL_NAME}" -C "${BUILD_DIR}"
  fi
  # 重命名server到parcel
  echo -e "${GREEN}移动 ${CYAN}${BUILD_DIR}/${PRESTO_UNZIP_DIR_NAME}${GREEN} 到 ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  mv "${BUILD_DIR}/${PRESTO_UNZIP_DIR_NAME}" "${PARCEL_BUILD_DIR}"
  # 复制meta到parcel
  echo -e "${GREEN}复制 ${CYAN}${SOURCE_DIR}/presto/parcel/meta${GREEN} 到 ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  cp -rf "${SOURCE_DIR}/presto/parcel/meta" "${PARCEL_BUILD_DIR}"
  cp -rf "${SOURCE_DIR}/presto/parcel/etc" "${PARCEL_BUILD_DIR}"
  mkdir -p "${PARCEL_BUILD_DIR}/etc/catalog"
  # 复制cli jar到parcel bin
  echo -e "${GREEN}复制 ${CYAN}${RESOURCES_DIR}/${PRESTO_CLI_JAR}${GREEN} 到 ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  cp -rf "${RESOURCES_DIR}/${PRESTO_CLI_JAR}" "${PARCEL_BUILD_DIR}/bin"
  # 复制jdbc jar到parcel lib
  echo -e "${GREEN}复制 ${CYAN}${RESOURCES_DIR}/${PRESTO_JDBC_JAR}${GREEN} 到 ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  cp -rf "${RESOURCES_DIR}/${PRESTO_JDBC_JAR}" "${PARCEL_BUILD_DIR}/lib"
  echo -e "${GREEN}创建 ${CYAN}${PARCEL_BUILD_DIR}/bin/presto${RESET}"
  # 复制launcher到 parcel bin
  echo -e "${GREEN}复制 ${CYAN}${SOURCE_DIR}/presto/parcel/launcher${GREEN} 到 ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  cp -rf "${SOURCE_DIR}/presto/parcel/launcher" "${PARCEL_BUILD_DIR}/bin"
  chmod +x "${PARCEL_BUILD_DIR}/bin/launcher"
  # 创建PRESTO-0.263.1-cdh-6.3.2/bin/presto
  cp "${PARCEL_BUILD_DIR}"/bin/presto-cli-0.263.1-executable.jar "${PARCEL_BUILD_DIR}"/bin/presto
  echo -e "${GREEN}修改 ${CYAN}${PARCEL_BUILD_DIR}/bin/presto${GREEN} 为可执行${RESET}"
  chmod +x "${PARCEL_BUILD_DIR}/bin/presto"
  # 校验生成parcel前的路径：java -jar cm_ext/validator/target/validator.jar -d PRESTO-0.263.1-cdh-6.3.2
  echo -e "${GREEN}校验 ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  java -jar "${LIB_DIR}/validator.jar" -d "${PARCEL_BUILD_DIR}"
}

function build_parcel() {
  # 创建PRESTO-0.263.1-cdh-6.3.2_build
  echo -e "${GREEN}创建 ${CYAN}${PARCEL_DIR}${RESET}"
  mkdir -p "${PARCEL_DIR}"
  # 打包parcel
  echo -e "${GREEN}打包 ${CYAN}${PARCEL_BUILD_DIR}${GREEN} 到 ${CYAN}${PARCEL_DIR}/${PARCEL_NAME}${RESET}"
  tar cfhz "${PARCEL_DIR}/${PARCEL_NAME}" -C"${BUILD_DIR}" "${PARCEL_BUILD_FOLDER_NAME}"
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

function build_csd() {
  echo -e "${GREEN}创建csd构建目录 ${CYAN}${CSD_BUILD_DIR}${RESET}"
  mkdir -p "${CSD_BUILD_DIR}"
  cp -rf "${SOURCE_DIR}/presto/csd/"* "${CSD_BUILD_DIR}"
  # 打包csd
  echo -e "${GREEN}将 ${CYAN}${CSD_BUILD_DIR}${GREEN} 打包为csd ${CYAN}${CSD_DIR}/${CSD_NAME}${RESET}"
  mkdir -p "${CSD_DIR}"
  jar -cvf "${CSD_DIR}/${CSD_NAME}" -C "${CSD_BUILD_DIR}" .
}

get_presto
clean
#prepare
#build_parcel
build_csd
echo -e "${GREEN}Done!!!!${RESET}"
