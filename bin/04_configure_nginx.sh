#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq $YES ]] && set -x


install_nginx_configs() {
  [[ ${DEBUG} -eq $YES ]] && set -x
  # override default config from redhat
  install_files '/etc/nginx' '0444' 'nginx.conf'
  # install local files/servers
  install_files '/etc/nginx/conf.d' '0444' '*.conf'
  # update configs with runtime data
  update_tunders '/etc/nginx/conf.d/*.conf'
}


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
install_nginx_configs

validate_configs

restart_nginx
