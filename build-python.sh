#!/bin/bash
CYAN="\033[36;1m"
GREEN="\033[32;1m"
RESET="\033[0m"
set -e
BASE_DIR=$(
  dirname "$0"
#    cd "$(dirname "$0")"
#    pwd || exit
)
BUILD_OS=$(uname)
PYTHON2_VERSION=2.7
PYTHON3_VERSION=3.7
PARCEL=${1:-CDH_PYTHON-0.0.1.p0}
PARCEL_SHORT_NAME=${PARCEL%%-*}
PARCEL_BUILD_VERSION=${PARCEL#*-}
CONDA_URI=https://repo.anaconda.com/archive/Anaconda3-5.3.1-MacOSX-x86_64.sh
if [ "${BUILD_OS}" = 'Linux' ]; then
  CONDA_URI=https://repo.anaconda.com/archive/Anaconda3-5.3.1-Linux-x86_64.sh
  yum install -y bzip2
fi
CONDA_VERSION=$(echo ${CONDA_URI} | cut -d - -f 2)
PARCEL_NAME="${PARCEL}-anaconda3_${CONDA_VERSION}-py2_${PYTHON2_VERSION}-py3_${PYTHON3_VERSION}"
LIB_DIR="${BASE_DIR}/lib"
RESOURCES_DIR="${BASE_DIR}/resources"
SOURCE_DIR="${BASE_DIR}/source"
TARGET_DIR="${BASE_DIR}/target"
BUILD_DIR="${TARGET_DIR}/build"
PARCEL_BUILD_DIR="${BUILD_DIR}/${PARCEL_NAME}"
PARCEL_DIR=${TARGET_DIR}/parcels/python
META_DIR=${SOURCE_DIR}/python/parcel/meta
OS_VERSION=el7
CDH_VERSION=6.3.2
PARCEL_FULL_NAME="${PARCEL_NAME}-${OS_VERSION}.parcel"
PARCEL_VERSION="${PARCEL_BUILD_VERSION}-anaconda3_${CONDA_VERSION}-py2_${PYTHON2_VERSION}-py3_${PYTHON3_VERSION}"

echo -e "${GREEN}Building ${CYAN}${PARCEL_SHORT_NAME}${RESET} \
${GREEN}with parcel build version ${CYAN}${PARCEL_BUILD_VERSION}${RESET} \
${GREEN}including python ${CYAN}${PYTHON2_VERSION}${RESET} and ${CYAN}${PYTHON3_VERSION}${RESET} \
${GREEN}using ${CYAN}${CONDA_URI}${RESET} \
${GREEN}with PREFIX ${CYAN}${PARCEL_BUILD_DIR}${RESET}"

echo -e "${GREEN}Delete parcel build directory ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
rm -rf "${PARCEL_BUILD_DIR}"

echo -e "${GREEN}Delete parcel directory ${CYAN}${PARCEL_DIR}${RESET}"
rm -rf "${PARCEL_DIR}"

echo -e "${GREEN}Create target directory ${CYAN}${PARCEL_DIR}${RESET}"
mkdir -p "${PARCEL_DIR}"

CONDA_EXECUTABLE=$(basename ${CONDA_URI})
if [ ! -f "${RESOURCES_DIR}/${CONDA_EXECUTABLE}" ]; then
  echo -e "${GREEN}Downloading ${CYAN}${CONDA_EXECUTABLE}${RESET}"
  curl -O ${CONDA_URI}
  mv "${CONDA_EXECUTABLE}" "${RESOURCES_DIR}/"
fi
echo -e "${GREEN}Create parcel build files in ${CYAN}${PARCEL_BUILD_DIR}${RESET}"
sh "${RESOURCES_DIR}/${CONDA_EXECUTABLE}" -b -p "${PARCEL_BUILD_DIR}"
export PATH=${PARCEL_BUILD_DIR}/bin:${PATH}
echo -e "${GREEN}Creating virtual-envs ${CYAN}${PYTHON2_VERSION}${RESET}"
conda create -y -q -n python2 python=${PYTHON2_VERSION}
echo -e "${GREEN}Creating virtual-envs ${CYAN}${PYTHON3_VERSION}${RESET}"
conda create -y -q -n python3 python=${PYTHON3_VERSION}

mkdir -p "${PARCEL_BUILD_DIR}"/{lib,meta}
echo -e "${GREEN}Create ${PARCEL_BUILD_DIR}/meta/parcel.json${RESET}"
cp -rf "${META_DIR}" "${PARCEL_BUILD_DIR}/"
sed -i -e "s/__OS_VERSION__/${OS_VERSION}/g" "${PARCEL_BUILD_DIR}/meta/parcel.json"
sed -i -e "s/__PARCEL_VERSION__/${PARCEL_VERSION}/g" "${PARCEL_BUILD_DIR}/meta/parcel.json"
sed -i -e "s/__PARCEL_NAME__/${PARCEL_SHORT_NAME}/g" "${PARCEL_BUILD_DIR}/meta/parcel.json"
sed -i -e "s/__CDH_VERSION__/${CDH_VERSION}/g" "${PARCEL_BUILD_DIR}/meta/parcel.json"

echo -e "${GREEN}Create ${PARCEL_BUILD_DIR}/meta/py_env.sh${RESET}"
sed -i -e "s/__OS_VERSION__/${OS_VERSION}/g" "${PARCEL_BUILD_DIR}/meta/py_env.sh"
sed -i -e "s/__PARCEL_VERSION__/${PARCEL_VERSION}/g" "${PARCEL_BUILD_DIR}/meta/py_env.sh"
sed -i -e "s/__PARCEL_NAME__/${PARCEL_SHORT_NAME}/g" "${PARCEL_BUILD_DIR}/meta/py_env.sh"
sed -i -e "s/__CDH_VERSION__/${CDH_VERSION}/g" "${PARCEL_BUILD_DIR}/meta/py_env.sh"

echo -e "${GREEN}Create ${PARCEL_DIR}/${PARCEL_FULL_NAME}${RESET}"
tar cfhz "${PARCEL_DIR}/${PARCEL_FULL_NAME}" -C"${BUILD_DIR}" "${PARCEL_NAME}"
# --owner=root --group=root

echo -e "${GREEN}Create manifest.json${RESET}"
python "${LIB_DIR}/make_manifest.py" "${PARCEL_DIR}"

echo -e "${GREEN}Validation parcel${RESET}"
java -jar "${LIB_DIR}/validator.jar" -f "${PARCEL_DIR}/${PARCEL_FULL_NAME}"
echo -e "${GREEN}Generate sha${RESET}"
sha1sum "${PARCEL_DIR}/${PARCEL_FULL_NAME}" | awk '{print $1}' >"${PARCEL_DIR}/${PARCEL_FULL_NAME}.sha"
rm -rf "${PARCEL_BUILD_DIR}"
echo -e "${GREEN}Successfully created ${CYAN}${PARCEL_FULL_NAME}${RESET}"
