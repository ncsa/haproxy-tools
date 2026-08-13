#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq $YES ]] && set -x

validate_configs() {
  [[ ${DEBUG} -eq $YES ]] && set -x
  nginx -t
}


restart_nginx() {
  [[ ${DEBUG} -eq $YES ]] && set -x
  systemctl restart nginx
  sleep 2
  systemctl is-active --quiet nginx || die 'nginx not running'
}


###
# MAIN
###

install_files '/etc/nginx/conf.d' '0444' '*.conf'

validate_configs

restart_nginx
