#!/bin/bash
CYAN="\033[36;1m"
GREEN="\033[32;1m"
RED="\033[31;1m"
RESET="\033[0m"
BASE_DIR=$(
  cd "$(dirname "$0")" || exit
  pwd
)
CM_EXT_URL="https://github.com/cloudera/cm_ext.git"
LIB_PATH="$BASE_DIR/lib"
if [ -f "$LIB_PATH/make_manifest.py" ] && [ -f "$LIB_PATH/validator.jar" ];then
  return
fi
if [ ! -d "$BASE_DIR/cm_ext" ]; then
  echo -e "${GREEN}Clone$CYAN cm_ext$RESET from$CYAN $CM_EXT_URL$RESET"
  # 拉取cm_ext
  git clone "${CM_EXT_URL}"
fi
if [ ! -f "$BASE_DIR/cm_ext/validator/target/validator.jar" ]; then
  cd "$BASE_DIR/cm_ext" || exit
  echo -e "${GREEN}Package$CYAN cm_ext"
  # 如果validator.jar不存在则打包
  mvn install -DskipTests
  cd ..
fi
cp -f "$BASE_DIR/cm_ext/validator/target/validator.jar" "$LIB_PATH"
cp -f "$BASE_DIR/cm_ext/make_manifest/make_manifest.py" "$LIB_PATH"