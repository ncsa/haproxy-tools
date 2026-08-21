#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x

ACME_DIR=/root/.acme.sh
ACME="${ACME_DIR}"/acme.sh
HAPROXY_STATS_SOCKET=/var/lib/haproxy/stats


# Deploy the cert to haproxy
# ACME.sh will remember the deploy process and repeat it automatically at
# renewal
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


check_haproxy_cert() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  echo "show ssl cert ${HAPROXY_CERT_DIR}/*.pem" \
  | socat "${HAPROXY_STATS_SOCKET}"
}


###
# Main
###

install_cert

check_haproxy_cert
