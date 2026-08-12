#!/usr/bin/bash

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh


# Is Code Ready Builder actually needed?
# Doesn't seem like it, everything working fine without it so far
# from output of
# + dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
# ...
# > Many EPEL packages require the CodeReady Builder (CRB) repository.
# > It is recommended that you run /usr/bin/crb enable to enable the CRB
# > repository.
install_pkgs() {
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
  haproxy -v
}

validate_keepalived() {
  keepalived --version
}


###
# MAIN
###

install_pkgs

validate_haproxy

validate_keepalived
