#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x


install_acme() {
  [[ -f "${ACME}" ]] && return
  curl https://get.acme.sh | sh -s email="${KEEPALIVED_NOTIFY_EMAIL_RECIPIENT}"
}


set_letsencrypt_ca() {
  "${ACME}" \
    --server letsencrypt \
    --set-default-ca
}


enable_logging() {
  "${ACME}" \
    --list \
    --log
}


###
# Main
###

install_acme

set_letsencrypt_ca

enable_logging
