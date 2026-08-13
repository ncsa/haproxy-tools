#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh


set -x

get_cert() {
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

get_cert
