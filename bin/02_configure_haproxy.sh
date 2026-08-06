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
  >"${CONF_D}"/00_global.cfg \
  awk -v section=global -f "${BIN}"/get_haproxy_section.awk "${CONF_ORIG}"
  
  >>"${CONF_D}"/00_global.cfg \
  cat <<ENDHERE
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11
ENDHERE
}


install_local_config_files() {
  local _src_dir _tgt_dir
  _src_dir="${FILES}${CONF_D}"
  cp -t "${CONF_D}" "${_src_dir}"/*.cfg
}


# reconfigure_haproxy_service() {
#   # Reconfigure haproxy service to read files from conf.d
#   local _src_dir
#   _src_dir="${FILES}${SERVICE_DIR}"
#   mkdir -p "${SERVICE_DIR}"
#   cp -t "${SERVICE_DIR}" "${_src_dir}"/*.conf
#   systemctl daemon-reload
# }


backup_original_config() {
  mv "${CONF_ORIG}" "${CONF_ORIG}".orig
  echo "# See configs in /etc/haproxy/conf.d" > "${CONF_ORIG}"
}


validate_configs() {
  haproxy -c -f "${CONF_ORIG}" -f "${CONF_D}" || die 'Error validating config files'
}


restart_haproxy() {
  systemctl restart haproxy
  sleep 2
  systemctl is-active --quiet haproxy || die 'haproxy service not running'
}


###
# MAIN
###

mk_conf_d

mk_global_conf

install_local_config_files

validate_configs

backup_original_config

restart_haproxy
