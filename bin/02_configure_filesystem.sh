#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq $YES ]] && set -x


install_autofs_configs() {
  [[ ${DEBUG} -eq $YES ]] && set -x
  local _conf_files
  _conf_files=(
    /etc/auto.nfs
    /etc/auto.master.d/nfs.autofs
  )
  # install the files
  install_files /etc '0444' 'auto.nfs'
  install_files /etc/auto.master.d '0444' 'nfs.autofs'
  # ACME_CHALLENGE_DIR needed in /etc/auto.nfs
  ACME_CHALLENGE_DIR=$( basename "${CHALLENGE_BASE}" )
  # update files with runtime values
  for fn in "${_conf_files}" ; do
    update_tunders "${fn}"
  done
}


enable_autofs() {
  [[ ${DEBUG} -eq $YES ]] && set -x
  systemctl enable --now autofs
}


validate_mountpoints() {
  [[ ${DEBUG} -eq $YES ]] && set -x
  local _testfn
  _testfn="${ACME_CHALLENGE_DIR}"/"${TS}"
  ls "${ACME_CHALLENGE_DIR}" || die "ACME_CHALLENGE_DIR '${ACME_CHALLENGE_DIR}' not mounted"
  touch "${_testfn}" || die "Failed to make testfile '${_testfn}'"
  ls "${_testfn}" || die "Can't find testfile '${_testfn}'"
  rm "${_testfn}" || die "Failed to remove testfile '${_testfn}'"
}


###
# MAIN
###
install_autofs_configs

enable_autofs

validate_mountpoints
