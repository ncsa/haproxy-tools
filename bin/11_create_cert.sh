#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x

ACME_DIR=/root/.acme.sh
ACME="${ACME_DIR}"/acme.sh
INSTALLER_URL=https://raw.githubusercontent.com/acmesh-official/acme.sh/refs/heads/master/acme.sh
TEST=$YES


## Make SAN (subject alternative name) names
mk_SANs() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  if [[ -z "${SA_NAMES}" ]] ; then
    SA_NAMES="${KEEPALIVED_VIRTUAL_HOSTNAME}"
  fi
  echo "${SA_NAMES}"
}


## Test cert
test_cert() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  local _rc
  TEST=$YES
  get_cert
  _rc=$?
  TEST=$NO
  return $_rc
}


get_cert() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  local _test_opts _domains _sans _msg
  _test_opts=()
  [[ $TEST -eq $YES ]] && _test_opts=( '--test' )
  _sans=$( mk_SANs )
  [[ -n "${_sans}" ]] && _sans=",${_sans}"
  _domains="${HOST}${_sans}"
  _msg='Attempting to get a'
  [[ $TEST -eq $YES ]] && _msg="${_msg} TEST"
  _msg="${_msg} cert"
  info "${_msg}"
  set -x
  "${ACME}" \
    --issue \
    -d "${_domains}" \
    "${_test_opts[@]}" \
  ;
  set +x
}


show_certs() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  "${ACME}" --list
}


###
# Main
###


test_cert && get_cert

show_certs
