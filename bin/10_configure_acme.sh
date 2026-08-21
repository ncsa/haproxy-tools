#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x

ACME_DIR=/root/.acme.sh
ACME="${ACME_DIR}"/acme.sh
INSTALLER_URL=https://raw.githubusercontent.com/acmesh-official/acme.sh/refs/heads/master/acme.sh


install_acme() {
  [[ -f "${ACME}" ]] && return
  local _installer
  _installer=$( mktemp )
  curl -O "${_installer}" "${INSTALLER_URL}"
  sh "${_installer}" \
    -s "${KEEPALIVED_NOTIFY_EMAIL_RECIPIENT}" \
    --log
  rm "${_installer}"
}


###
# Main
###

install_acme
