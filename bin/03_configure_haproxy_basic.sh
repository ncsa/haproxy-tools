#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh
CONF_ORIG=/etc/haproxy/haproxy.cfg
CONF_D=/etc/haproxy/conf.d

[[ ${DEBUG} -eq ${YES} ]] && set -x

mk_conf_d() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  mkdir -p "${CONF_D}"
}


mk_global_conf() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  local _global_path
  _global_path="${CONF_D}"/00-global.cfg
  # return immediately if this was already done
  [[ -f "${_global_path}" ]] && return

  # extract the "global" section from the default hsproxy.conf
  >"${_global_path}" \
  awk -v section=global -f "${BIN}"/get_haproxy_section.awk "${CONF_ORIG}"
  
  >>"${_global_path}" \
  cat <<ENDHERE
  ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11
ENDHERE

  # Backup original config
  mv "${CONF_ORIG}" "${CONF_ORIG}".orig."${TS}"
  echo "# See configs in /etc/haproxy/conf.d" > "${CONF_ORIG}"
}


install_local_config_files() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  install_files "${CONF_D}" '0444' '*.cfg'
  #exclude ldaps config for now, it will fail until the cert has been created
  find "${CONF_D}" -type f -name '*ldaps.cfg' -delete
}


validate_configs() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  "${BIN}"/haproxyctl check
}


restart_haproxy() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  "${BIN}"/haproxyctl restart
  sleep 2
  systemctl is-active --quiet haproxy || die 'haproxy service not running'
}


###
# MAIN
###

mk_conf_d

mk_global_conf

install_local_config_files

add_backend_servers

validate_configs

restart_haproxy
