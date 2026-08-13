#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x


check_cert() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  echo \
  | openssl s_client \
      -servername "${HOST}" \
      -connect "${HOST}":636 2>/dev/null \
  | tee \
    >(openssl x509 -noout -subject -issuer -dates) \
    >(openssl x509 -noout -ext subjectAltName) \
    >/dev/null \
  | cat

}


###
# MAIN
###

check_cert
