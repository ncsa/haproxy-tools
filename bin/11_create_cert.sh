#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x

TEST=$NO


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
  [[ $_rc -eq 0 ]] && remove_cert
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
  "${ACME}" \
    --issue \
    --webroot "${CHALLENGE_BASE}" \
    -d "${_domains}" \
    "${_test_opts[@]}" \
  ;
}


show_certs() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  "${ACME}" --list
}


remove_cert() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  local _conf_path _cert_dir
  "${ACME}" \
    --remove \
    -d "${HOST}"
  _conf_path=$(
    "${ACME}" \
      --info \
      -d "${HOST}" \
      | grep '^DOMAIN_CONF' \
      | cut -d= -f2 )
  _cert_dir=$( dirname "${_conf_path}" )
  rm -rf "${_cert_dir}"
}


###
# Main
###

get_cert

show_certs
