#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x


check_haproxy_cert() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  echo "show ssl cert ${HAPROXY_PEM_PATH}" \
  | socat "${HAPROXY_STATS_SOCKET}" -
}


###
# Main
###

check_haproxy_cert
