#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

set -x 

BIN="${INSTALL_DIR}"/bin
FILES="${INSTALL_DIR}"/files
CONF_ORIG=/etc/keepalived/keepalived.conf
CONF_D=/etc/keepalived/conf.d
KEEPALIVED_STATE=BACKUP #default, can get updated by mk_keepalived_state()
KEEPALIVED_PRIORITY=100 #default, can get updated by mk_keepalived_priority()
KEEPALIVED_PEER_IP="${KEEPALIVED_SERVERS[0]}" #default, if state=BACKUP


mk_conf_d() {
  mkdir -p "${CONF_D}"
}


mk_keepalived_state() {
  # MASTER if local hostname is the first one in list of KEEPALIVED_SERVERS
  # BACKUP otherwise
  if [[ "${HOST}" == "${KEEPALIVED_SERVERS[0]}" ]] ; then
    KEEPALIVED_STATE=MASTER
  fi
}


mk_keepalived_priority() {
  # 150 if state is MASTER
  # 100 otherwise
  if [[ "${KEEPALIVED_STATE}" == 'MASTER' ]] ; then
    KEEPALIVED_PRIORITY=150
  fi
}


mk_keepalived_peer_ip() {
  # state was already determined based on comparing local ip to position in
  # ... KEEPALIVED_SERVERS
  # ... so if state=MASTER, peer IP is the second IP
  # ... likewise, if state=BACKUP, peer IP is the first IP
  # default setting already assumed state=BACKUP
  # so only need to check if state=MASTER and if so, update appropriately
  if [[ "${KEEPALIVED_STATE}" == 'MASTER' ]] ; then
    KEEPALIVED_PEER_IP=$( hostname2ip "${KEEPALIVED_SERVERS[1]}" )
  fi
}


replace_original_config() {
  local _pattern
  _pattern='___ CUSTOM CONFIG INCLUDE FROM conf.d ___'
  # skip if config already updated
  grep -F "${_pattern}" "${CONF_ORIG}" && return 0
  # backup old config
  mv "${CONF_ORIG}" "${CONF_ORIG}".orig.${TS}
  >"${CONF_ORIG}" cat << ENDHERE
! ${_pattern}
include ${CONF_D}/*.conf
ENDHERE
}


install_config_files() {
  local _src_dir
  _src_dir="${FILES}${CONF_D}"
  cp -t "${CONF_D}" "${_src_dir}"/*.conf
}


update_config_files() {
  local _tunders _ref
  # get list of ___-bounded varnames in conf filesi
  # (tunders is short for triple-underscore-strings)
  _tunders=( $( grep -h -oP '\b(___\w+___)' "${CONF_D}"/*.conf | sort -u ) )
  for tunder in "${_tunders[@]}" ; do
    # _varname="${v:3:$((${#v} - 6))}"
    declare -n _ref="${tunder:3:$((${#tunder} - 6))}"
    sed -i -e "s?$tunder?$_ref?" "${CONF_D}"/*.conf
  done
}


configure_notify() {
  ln -s "${BIN}"/notify.sh /etc/keepalived/notify.sh
}


# foreach backend server (defined in config)
# determine what weight to assign (if same VLAN, high weight, otherwise low)
add_backend_servers() {
  local _remote_name _remote_ip _weight _server_line
  for _remote_name in "${BACKEND_SERVERS[@]}"; do
    _remote_ip=$( hostname2ip "${_remote_name}" )
    [[ -z "${_remote_ip}" ]] && die "Couldn't get IP for '${_remote_name}'"
    _weight=1
    #TODO calculate weight by checking is_same_vlan()
    _server_line="    server ${_remote_name} ${_remote_ip}:636 check weight ${_weight}"
    sed -i "/___BACKEND_SERVERS___/a ${_server_line}" "${CONF_D}"/30-ldaps.cfg
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
mk_keepalived_state
mk_keepalived_priority
mk_keepalived_peer_ip

replace_original_config

install_config_files

update_config_files

configure_notify
