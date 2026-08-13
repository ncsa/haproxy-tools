#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

[[ ${DEBUG} -eq ${YES} ]] && set -x

# Is Code Ready Builder actually needed?
# Doesn't seem like it, everything working fine without it so far
# from output of
# + dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
# ...
# > Many EPEL packages require the CodeReady Builder (CRB) repository.
# > It is recommended that you run /usr/bin/crb enable to enable the CRB
# > repository.
install_pkgs() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  local _repos _pkgs
  _repos=(
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  )
  _pkgs=(
    certbot
    haproxy
    keepalived
    nginx
  )

  #install repos
  dnf -y install "${_repos[@]}"

  #install packages
  dnf -y install "${_pkgs[@]}"
}


validate_haproxy() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  haproxy -v
}

validate_keepalived() {
  [[ ${DEBUG} -eq ${YES} ]] && set -x
  keepalived --version
}


###
# MAIN
###

install_pkgs

validate_haproxy

validate_keepalived
