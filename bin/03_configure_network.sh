#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

set -x

BIN="${INSTALL_DIR}"/bin
FILES="${INSTALL_DIR}"/files
IPTABLES_RULE_NUM=$( \
  iptables -t filter -L INPUT -n --line-numbers \
  | awk '/^[0-9]/{num=$1}END{print num}'
)


assert_puppet_disabled() {
  local _puppet _lockfile
  _puppet=$( type puppet )
  [[ -z "${_puppet}" ]] && return 0
  _lockfile=$( "${_puppet}" agent --configprint agent_disabled_lockfile )
  [[ -f "${_lockfile}" ]] || die 'puppet is still enabled'
}


firewall_allow_ldaps() {
  # allow incoming from the world to tcp:636
  local _proto _source _dest _dport
  _proto=tcp
  _source=''
  _dest=''
  _dport=636
  firewall_add_allow_rule "${_proto}" "${_source}" "${_dest}" "${_dport}"
}


firewall_allow_keepalived() {
  # allow incoming vrrp protocol from other keepalived servers
  local _hostname _proto _source _dest _dport
  for _hostname in "${KEEPALIVED_SERVERS[@]}"; do
    _proto=vrrp
    _source="${_hostname}"
    _dest=''
    _dport=''
    firewall_add_allow_rule "${_proto}" "${_source}" "${_dest}" "${_dport}"
  done
}


firewall_allow_haproxy_stats() {
  # allow access to tcp:8404 only from trusted cidrs
  local _cidr _proto _source _dest _dport
  for _cidr in "${HAPROXY_STATS_ALLOWED_CIDRS[@]}"; do
    _proto=tcp
    _source="${_cidr}"
    _dest=''
    _dport=8404
    firewall_add_allow_rule "${_proto}" "${_source}" "${_dest}" "${_dport}"
  done
}


firewall_add_allow_rule() {
  local _proto _src _dest _dport _opt_p _opt_s _opt_d _opt_dport _all_opts
  _proto="${1}"
  _src="${2}"
  _dest="${3}"
  _dport="${4}"
  [[ -n "${_proto}" ]] && _opt_p=( '-p' "${_proto}" )
  [[ -n "${_src}" ]] && _opt_s=( '-s' "${_src}" )
  [[ -n "${_dest}" ]] && _opt_d=( '-d' "${_dest}" )
  [[ -z "${_dport}" ]] && _opt_dport=( '--dport' "${_dport}" )
  _all_opts=(
    "${_opt_p[@]}"
    "${_opt_s[@]}"
    "${_opt_d[@]}"
    "${_opt_dport[@]}" 
    '-j' ACCEPT
  )
  iptables -C INPUT "${_all_opts[@]}" 2>/dev/null \
  || iptables -I INPUT ${IPTABLES_RULE_NUM} "${_all_opts[@]}"
}


###
# MAIN
###

assert_pupppet_disabled

firewall_allow_ldaps
