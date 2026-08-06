#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

SAMPLE_CONFIG="${INSTALL_DIR}"/conf/example
TMP_CONFIG="${INSTALL_DIR}"/conf/tmp
#CONFIG ... is defined in lib/base.sh


update_config() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _varname _value
  _varname="$1"
  _value="$2"
  sed -i -e "/^${_varname}/c ${_varname}=${_value}" "${TMP_CONFIG}"
}


###
# MAIN
###

# Quick exit if config already exists
[[ -f "${CONFIG}" ]] && {
  echo "Config file already exists ..." 1>&2
  ls -l "${CONFIG}"
  exit 0
}

# make temp config for work-in-progress edits
cp "${SAMPLE_CONFIG}" "${TMP_CONFIG}"

# # set DS_INSTANCE_NAME
# DS_INSTANCE_NAME=$( get_instance_name )
# update_config "DS_INSTANCE_NAME" "${DS_INSTANCE_NAME}"

# # set PAM_AUTH
# if ask_no_yes "Enable PAM auth? [No]"; then
#   update_config "PAM_AUTH" '$YES'
# fi

# # set DB type
# echo "What DB type? [mdb]" 1>&2
# db_type=$( ask_enum mdb bdb )
# update_config "DS_DB_LIB" "${db_type}"

# Save finalized config
REAL_CFG_DIR="${HOME}"/.config/"${TOOLS_PKG_NAME}"
REAL_CFG_PATH="${REAL_CFG_DIR}"/config
mkdir -p "${REAL_CFG_DIR}"
mv "${TMP_CONFIG}" "${REAL_CFG_PATH}"
ln -s "${REAL_CFG_PATH}" "${CONFIG}"
