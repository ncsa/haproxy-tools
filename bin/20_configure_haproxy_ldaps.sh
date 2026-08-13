#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh
BIN="${INSTALL_DIR}"/bin
FILES="${INSTALL_DIR}"/files
CONF_D=/etc/haproxy/conf.d
LDAPS_CONF="${CONF_D}"/30-ldaps.cfg
# SERVICE_DIR=/etc/systemd/system/haproxy.service.d


install_local_config_files() {
  # install the ldaps config
  local _src_dir
  _src_dir="${FILES}${CONF_D}"
  cp --no-clobber -t "${CONF_D}" "${_src_dir}"/*.cfg
}


set_cert_file() {
  sed -i "s/___HAPROXY_PEM_PATH___/${HAPROXY_PEM_PATH}/" "${LDAPS_CONF}"
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
    _server_line="  server ${_remote_name} ${_remote_ip}:636 weight ${_weight}"
    sed -i "/___HAPROXY_BACKEND_SERVERS___/a ${_server_line}" "${LDAPS_CONF}"
  done
}


# is_same_vlan() {
#   local _remomte_ip
#   _remote_ip=$1
#   # test if the other IP is reachable on the same broadcast domain
#   # (which implies same VLAN if no routing is involved) using ping or arp.

#   # # Ping the target IP
#   # ping -c 1 <target_ip>

#   # # Check ARP table for MAC address resolution (indicates Layer 2 connectivity)
#   # arp -n <target_ip>

#   # Note: If the target IP is on a different VLAN, the traffic will be routed, and the ARP table will only show the MAC address of the default gateway, not the target device. If no gateway is involved, a failure to resolve the MAC address via ARP indicates they are on different broadcast domains (VLANs).
# }


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

install_local_config_files

set_cert_file

add_backend_servers

validate_configs

restart_haproxy
