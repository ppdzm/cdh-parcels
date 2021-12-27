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
usage() {
  echo -e "${GREEN}Usage: $0 < parcel | csd | csd_standalone >"
}
if [ -z "$1" ]; then
  usage
  exit 1
fi
SERVICE_NAME="FLINK"
FLINK_URL=$(sed '/^FLINK_URL=/!d;s/.*=//' "${BASE_DIR}/source/flink/flink-parcel.properties")
FLINK_VERSION=$(sed '/^FLINK_VERSION=/!d;s/.*=//' "${BASE_DIR}/source/flink/flink-parcel.properties")
EXT_VERSION=$(sed '/^EXT_VERSION=/!d;s/.*=//' "${BASE_DIR}/source/flink/flink-parcel.properties")
OS_VERSION=$(sed '/^OS_VERSION=/!d;s/.*=//' "${BASE_DIR}/source/flink/flink-parcel.properties")
# flink
SERVICE_NAME_LOWER=$(echo ${SERVICE_NAME} | tr '[:upper:]' '[:lower:]')
# flink-1.14.0-bin-scala_2.11.tgz
ARCHIVE_NAME=$(basename "${FLINK_URL}")
# flink-1.14.0
UNZIP_ARCHIVE_NAME="${SERVICE_NAME_LOWER}-${FLINK_VERSION}"
# flink-1.14.0-bin-scala_2.11
PARCEL_FOLDER_NAME_LOWER="$(basename "${ARCHIVE_NAME}" .tgz)"
# FLINK-1.14.0-BIN-SCALA_2.11
PARCEL_FOLDER_NAME_UPPER="$(echo "${PARCEL_FOLDER_NAME_LOWER}" | tr '[:lower:]' '[:upper:]')"
# FLINK-1.14.0-BIN-SCALA_2.11-el7.parcel
PARCEL_NAME="${PARCEL_FOLDER_NAME_UPPER}-${OS_VERSION}.parcel"
LIB_DIR="${BASE_DIR}/lib"
RESOURCES_DIR="${BASE_DIR}/resources"
SOURCE_LIR="${BASE_DIR}/source"
TARGET_DIR="${BASE_DIR}/target"
BUILD_DIR="${TARGET_DIR}/build"
PARCEL_BUILD_DIR="${BUILD_DIR}/${PARCEL_FOLDER_NAME_UPPER}"
PARCEL_DIR="${TARGET_DIR}/parcels/flink"
CSD_DIR="${TARGET_DIR}/csd"

function get_flink() {
  if [ ! -f "${RESOURCES_DIR}/${ARCHIVE_NAME}" ]; then
    echo -e "${GREEN}Downloading Flink archive ${CYAN}${ARCHIVE_NAME}${GREEN} from ${CYAN}${FLINK_URL}${GREEN} to ${CYAN}${RESOURCES_DIR}${RESET}"
    # 如果Flink安装包不存在则下载
    wget -P "${RESOURCES_DIR}" "${FLINK_URL}"
  fi
  if [ ! -d "${BUILD_DIR}/${UNZIP_ARCHIVE_NAME}" ]; then
    mkdir -p "${BUILD_DIR}"
    echo -e "${GREEN}Un-zip flink archive ${CYAN}${RESOURCES_DIR}/${ARCHIVE_NAME}${RESET} to ${GREEN}${BUILD_DIR}/${UNZIP_ARCHIVE_NAME}${RESET}"
    # 解压Flink安装包
    tar -xf "${RESOURCES_DIR}/${ARCHIVE_NAME}" -C "${BUILD_DIR}"
  fi
}

function clean() {
  if [ -d "${PARCEL_DIR}" ]; then
    # 删除上次的构建
    echo -e "${GREEN}Delete flink parcel directory ${CYAN}${PARCEL_DIR}${RESET}"
    rm -rf "${PARCEL_DIR}"
  fi
  if [ -d "${PARCEL_BUILD_DIR}" ]; then
    # 删除构建资源目录
    echo -e "${GREEN}Delete parcel build directory ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
    rm -rf "${PARCEL_BUILD_DIR}"
  fi
}

function build_parcel() {
  clean
  get_flink
  echo -e "${GREEN}Create parcel build directory ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  mkdir -p "${PARCEL_BUILD_DIR}"
  echo -e "${GREEN}Copy parcel build resources from ${CYAN}${BUILD_DIR}/${UNZIP_ARCHIVE_NAME}${GREEN} to ${GREEN}${PARCEL_BUILD_DIR}${RESET}"
  cp -r "${BUILD_DIR}/${UNZIP_ARCHIVE_NAME}"/* "${PARCEL_BUILD_DIR}"
  rm -rf "${BUILD_DIR:?}/${UNZIP_ARCHIVE_NAME}"
  META_DIR="${SOURCE_LIR}/flink/parcel/meta"
  echo -e "${GREEN}Copy meta from ${CYAN}${META_DIR}${GREEN} to ${GREEN}${PARCEL_BUILD_DIR}${RESET}"
  cp -r "${META_DIR}" "${PARCEL_BUILD_DIR}"
  chmod 755 "${SOURCE_LIR}"/flink/parcel/*.sh
  echo -e "${GREEN}Copy ${CYAN}${SOURCE_LIR}/flink/parcel/config.sh${GREEN} to ${CYAN}${PARCEL_BUILD_DIR}/bin${RESET}"
  cp -r "${SOURCE_LIR}/flink/parcel/config.sh" "${PARCEL_BUILD_DIR}/bin"
  echo -e "${GREEN}Copy ${CYAN}${SOURCE_LIR}/flink/parcel/flink-master.sh${GREEN} to ${CYAN}${PARCEL_BUILD_DIR}/bin${RESET}"
  cp -r "${SOURCE_LIR}/flink/parcel/flink-master.sh" "${PARCEL_BUILD_DIR}/bin"
  echo -e "${GREEN}Copy ${CYAN}${SOURCE_LIR}/flink/parcel/flink-worker.sh${GREEN} to ${CYAN}${PARCEL_BUILD_DIR}/bin${RESET}"
  cp -r "${SOURCE_LIR}/flink/parcel/flink-worker.sh" "${PARCEL_BUILD_DIR}/bin"
  echo -e "${GREEN}Copy ${CYAN}${SOURCE_LIR}/flink/parcel/flink-yarn.sh${GREEN} to ${CYAN}${PARCEL_BUILD_DIR}/bin${RESET}"
  cp -r "${SOURCE_LIR}/flink/parcel/flink-yarn.sh" "${PARCEL_BUILD_DIR}/bin"
  sed -i -e "s/%flink_version%/${PARCEL_FOLDER_NAME_UPPER}/" "${PARCEL_BUILD_DIR}/meta/flink_env.sh"
  sed -i -e "s/%VERSION%/${FLINK_VERSION}/" "${PARCEL_BUILD_DIR}/meta/parcel.json"
  sed -i -e "s/%EXT_VERSION%/${EXT_VERSION}/" "${PARCEL_BUILD_DIR}/meta/parcel.json"
  sed -i -e "s/%SERVICE_NAME%/${SERVICE_NAME}/" "${PARCEL_BUILD_DIR}/meta/parcel.json"
  sed -i -e "s/%SERVICE_NAME_LOWER%/flink/" "${PARCEL_BUILD_DIR}/meta/parcel.json"
  echo -e "${GREEN}Validate parcel build path ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  java -jar "${LIB_DIR}"/validator.jar -d "${PARCEL_BUILD_DIR}"
  echo -e "${GREEN}Create parcel directory ${CYAN}${PARCEL_DIR}${RESET}"
  mkdir -p "${PARCEL_DIR}"
  echo -e "${GREEN}Build parcel ${CYAN}${PARCEL_DIR}/${PARCEL_NAME}${GREEN} from ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
  if [ "$(uname)" = "Linux" ]; then
    tar cfhz "${PARCEL_DIR}/${PARCEL_NAME}" -C"${BUILD_DIR}" "${PARCEL_FOLDER_NAME_UPPER}" --owner=root --group=root
  else
    tar cfhz "${PARCEL_DIR}/${PARCEL_NAME}" -C"${BUILD_DIR}" "${PARCEL_FOLDER_NAME_UPPER}"
  fi
  echo -e "${GREEN}Validate parcel ${GREEN}${PARCEL_DIR}/${PARCEL_NAME}${RESET}"
  java -jar "${LIB_DIR}"/validator.jar -f "${PARCEL_DIR}/${PARCEL_NAME}"
  echo -e "${GREEN}Generate${CYAN} manifest.json${GREEN} for parcel ${GREEN}${PARCEL_DIR}/${PARCEL_NAME}${RESET}"
  python cm_ext/make_manifest/make_manifest.py "${PARCEL_DIR}"
  echo -e "${GREEN}Generate${CYAN} sha${GREEN} for parcel ${GREEN}${PARCEL_DIR}/${PARCEL_NAME}${RESET}"
  sha1sum "${PARCEL_DIR}/${PARCEL_NAME}" | awk '{print $1}' >"${PARCEL_DIR}/${PARCEL_NAME}.sha"
}

function build_csd() {
  JAR_NAME=${SERVICE_NAME}-csd-${FLINK_VERSION}.jar
  if [ -f "${JAR_NAME}" ]; then
    rm -f "${JAR_NAME}"
  fi
  CSD_BUILD_DIR="${BUILD_DIR}/flink-csd"
  rm -rf "${CSD_BUILD_DIR}"
  cp -rf "${SOURCE_LIR}/flink/csd" "${CSD_BUILD_DIR}"
  sed -i -e "s/%VERSION%/${FLINK_VERSION}/" "${CSD_BUILD_DIR}/descriptor/service.sdl"
  sed -i -e "s/%SERVICE_NAME_LOWER%/flink/" "${CSD_BUILD_DIR}/descriptor/service.sdl"
  sed -i -e "s/%SERVICE_NAME_LOWER%/flink/" "${CSD_BUILD_DIR}/scripts/control.sh"
  java -jar "${LIB_DIR}"/validator.jar -s "${CSD_BUILD_DIR}/descriptor/service.sdl" -l "SPARK_ON_YARN SPARK2_ON_YARN"
  mkdir -p "${CSD_DIR}"
  jar -cvf "${CSD_DIR}/${JAR_NAME}" -C "${CSD_BUILD_DIR}" .
}

function build_csd_standalone() {
  JAR_NAME=${SERVICE_NAME}-STANDALONE-csd-${FLINK_VERSION}.jar
  if [ -f "${JAR_NAME}" ]; then
    rm -f "${JAR_NAME}"
  fi
  CSD_BUILD_DIR="${BUILD_DIR}/flink-csd-standalone"
  rm -rf "${CSD_BUILD_DIR}"
  cp -rf "${SOURCE_LIR}/flink/csd-standalone" "${CSD_BUILD_DIR}"
  sed -i -e "s/%VERSION%/${FLINK_VERSION}/" "${CSD_BUILD_DIR}/descriptor/service.sdl"
  sed -i -e "s/%SERVICE_NAME_LOWER%/flink/" "${CSD_BUILD_DIR}/descriptor/service.sdl"
  sed -i -e "s/%SERVICE_NAME_LOWER%/flink/" "${CSD_BUILD_DIR}/scripts/control.sh"
  java -jar "${LIB_DIR}"/validator.jar -s "${CSD_BUILD_DIR}/descriptor/service.sdl" -l "SPARK_ON_YARN SPARK2_ON_YARN"
  mkdir -p "${CSD_DIR}"
  jar -cvf "${CSD_DIR}/${JAR_NAME}" -C "${CSD_BUILD_DIR}" .
}

case $1 in
parcel)
  "${BASE_DIR}"/check.sh
  build_parcel
  ;;
csd)
  build_csd
  ;;
csd-standalone)
  build_csd_standalone
  ;;
all)
#  build_parcel
  build_csd
  build_csd_standalone
  ;;
*)
  echo "${GREEN}Usage: $0 < all | parcel | csd | csd-standalone >${RESET}"
  ;;
esac
echo -e "${GREEN}Done!!!${RESET}"
