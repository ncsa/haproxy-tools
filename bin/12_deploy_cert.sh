#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x

mk_haproxy_cert_dir() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  mkdir -p "${HAPROXY_CERT_DIR}"
}


# Deploy the cert to haproxy
# ACME.sh will remember the deploy process and repeat it automatically at
# renewal
# https://github.com/haproxy/wiki/wiki/Letsencrypt-integration-with-HAProxy-and-acme.sh
install_cert() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  DEPLOY_HAPROXY_HOT_UPDATE=yes \
    DEPLOY_HAPROXY_STATS_SOCKET="UNIX:${HAPROXY_STATS_SOCKET}"
    DEPLOY_HAPROXY_PEM_PATH="${HAPROXY_CERT_DIR}" \
    "${ACME}" \
    --deploy \
    -d "${HOST}" \
    --deploy-hook haproxy
}


###
# Main
###

mk_haproxy_cert_dir

install_cert
