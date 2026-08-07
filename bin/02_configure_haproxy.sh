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
  local _src_dir
  _src_dir="${FILES}${CONF_D}"
  cp -t "${CONF_D}" "${_src_dir}"/*.cfg
}


# foreach backend server (defined in config)
# determine what weight to assign (if same VLAN, high weight, otherwise low)
add_backend_servers() {
  local _remote_name _remote_ip _weight _server_line
  for _remote_name in "${HAPROXY_BACKEND_SERVERS[@]}"; do
    _remote_ip=$( hostname2ip "${_remote_name}" )
    [[ -z "${_remote_ip}" ]] && die "Couldn't get IP for '${_remote_name}'"
    _weight=1
    #TODO calculate weight by checking is_same_vlan()
    _server_line="    server ${_remote_name} ${_remote_ip}:636 check weight ${_weight}"
    sed -i "/___HAPROXY_BACKEND_SERVERS___/a ${_server_line}" "${CONF_D}"/30-ldaps.cfg
  done
}


is_same_vlan() {
  local _remomte_ip
  _remote_ip=$1
  # test if the other IP is reachable on the same broadcast domain
  # (which implies same VLAN if no routing is involved) using ping or arp.

  # # Ping the target IP
  # ping -c 1 <target_ip>

  # # Check ARP table for MAC address resolution (indicates Layer 2 connectivity)
  # arp -n <target_ip>

  # Note: If the target IP is on a different VLAN, the traffic will be routed, and the ARP table will only show the MAC address of the default gateway, not the target device. If no gateway is involved, a failure to resolve the MAC address via ARP indicates they are on different broadcast domains (VLANs).
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

add_backend_servers

backup_original_config

validate_configs

restart_haproxy
