#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x

BIN="${INSTALL_DIR}"/bin
FILES="${INSTALL_DIR}"/files
CONF_ORIG=/etc/keepalived/keepalived.conf
CONF_D=/etc/keepalived/conf.d
KEEPALIVED_STATE=BACKUP #default, can get updated by mk_keepalived_state()
KEEPALIVED_PRIORITY=100 #default, can get updated by mk_keepalived_priority()
KEEPALIVED_PEER_IP="${KEEPALIVED_SERVERS[0]}" #default, if state=BACKUP


mk_conf_d() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  mkdir -p "${CONF_D}"
}


mk_keepalived_state() {
  # MASTER if local hostname is the first one in list of KEEPALIVED_SERVERS
  # BACKUP otherwise
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  if [[ "${HOST}" == "${KEEPALIVED_SERVERS[0]}" ]] ; then
    KEEPALIVED_STATE=MASTER
  fi
}


mk_keepalived_priority() {
  # 150 if state is MASTER
  # 100 otherwise
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  if [[ "${KEEPALIVED_STATE}" == 'MASTER' ]] ; then
    KEEPALIVED_PRIORITY=150
  fi
}


mk_keepalived_peer_ip() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
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


mk_keepalived_virtual_ip() {
  # get IP from KEEPALIVED_VIRTUAL_HOSTNAME (set in config)
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  KEEPALIVED_VIRTUAL_IP=$( hostname2ip "${KEEPALIVED_VIRTUAL_HOSTNAME}" )
}


replace_original_config() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
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


install_keepalived_configs() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  # local _src_dir
  # _src_dir="${FILES}${CONF_D}"
  # cp -t "${CONF_D}" "${_src_dir}"/*.conf
  install_files "${CONF_D}" '0444' '*.conf'
}


update_config_files() {
  # get list of ___-bounded varnames in conf filesi
  # (tunders is short for triple-underscore-strings)
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  # local _tunders _ref
  # _tunders=( $( grep -h -oP '\b(___\w+___)' "${CONF_D}"/*.conf | sort -u ) )
  # for tunder in "${_tunders[@]}" ; do
  #   # _varname="${v:3:$((${#v} - 6))}"
  #   declare -n _ref="${tunder:3:$((${#tunder} - 6))}"
  #   sed -i -e "s?$tunder?$_ref?" "${CONF_D}"/*.conf
  # done
  update_tunders "${CONF_D}"/'*.conf'
}


configure_notify() {
  ln -s "${BIN}"/notify.sh /etc/keepalived/notify.sh
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
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  keepalived -t -f "${CONF_ORIG}"
}

restart_keepalived() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
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
mk_keepalived_virtual_ip

replace_original_config

install_keepalived_configs

update_config_files

configure_notify

validate_configs
