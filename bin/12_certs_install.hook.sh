#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x

BIN="${INSTALL_DIR}"/bin

mk_haproxy_cert_dir() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  mkdir -p "${HAPROXY_CERT_DIR}"
}


mk_haproxy_pem() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  cat "${CERT_FULL_CHAIN}" "${CERT_HOST_KEY}" >"${HAPROXY_PEM_PATH}"
}


conditional_restart() {
  [[ $DEBUG -eq $YES ]] && set -x
  # only need to restart when invoked by certbot
  # if invoked by certbot, RENEWED_LINEAGE and RENEWED_DOMAINS will be present
  [[ -n "${RENEWED_DOMAINS}" ]] \
  && "${BIN}"/haproxyctl reload
}


###
# MAIN
###

mk_haproxy_cert_dir

mk_haproxy_pem

conditional_restart
