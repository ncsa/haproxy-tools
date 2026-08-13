#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh
BIN="${INSTALL_DIR}"/bin
FILES="${INSTALL_DIR}"/files
CONF_ORIG=/etc/haproxy/haproxy.cfg
CONF_D=/etc/haproxy/conf.d
# SERVICE_DIR=/etc/systemd/system/haproxy.service.d

#TODO - Do we really only need to install conf.d/20-ldaps.cfg ??
#TODO - or maybe get global and defaults from RHEL original cfg, then install
#       20-ldaps.cfg (this way the basic config from RHEL assuming http doesn't
#       get setup

mk_conf_d() {
  mkdir -p "${CONF_D}"
}


mk_global_conf() {
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
  local _src_dir
  _src_dir="${FILES}${CONF_D}"
  cp --no-clobber -t "${CONF_D}" "${_src_dir}"/*.cfg
  #exclude ldaps config for now, it will fail until the cert has been created
  find "${CONF_D}" -type f -name '*ldaps*' -delete
}


validate_configs() {
  "${BIN}"/haproxyctl check
}


restart_haproxy() {
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
