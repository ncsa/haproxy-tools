#!/usr/bin/bash

# Get certs

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

TEST=$YES


## Add email to top config
set_email() {
  echo
  echo "Set email"
  /usr/bin/certbot \
    register \
    --email "${EMAIL}" \
    --no-eff-email \
    --agree-tos
  echo "OK"
}


## Make SAN (subject alternative name) names
mk_SANs() {
  if [[ -z "${SA_NAMES}" ]] ; then
    SA_NAMES="${KEEPALIVED_VIRTUAL_HOSTNAME}"
  fi
  echo "${SA_NAMES}"
}


## Test cert
test_cert() {
  local _rc
  TEST=$YES
  echo
  echo "Testing certbot ..."
  get_cert
  _rc=$?
  TEST=$NO
  return $_rc
}


get_cert() {
  local _test_opts _domains _sans
  _test_opts=()
  [[ $TEST -eq $YES ]] && _test_opts=( '--dry-run' '--test-cert' )
  _sans=$( mk_SANs )
  [[ -n "${_sans}" ]] && _sans=",${_sans}"
  _domains="${HOST}${_sans}"
  set -x
  /usr/bin/certbot \
    certonly \
    --non-interactive \
    --keep \
    --standalone \
    --verbose \
    --cert-name "${HOST}" \
    -d "${_domains}" \
    "${_test_opts[@]}" \
    "${_certbot_extra_opts[@]}" \
  ;
  set +x
}


show_certs() {
  /usr/bin/certbot certificates
}


enable_certbot_renewals() {
  systemctl start certbot-renew.timer
}

# Main

certbot_extra_options=()
[[ "$1" == "force" ]] && certbot_extra_options+='--force-renewal'
[[ "$1" == "expand" ]] && certbot_extra_options+='--expand'

set_email

test_cert && get_cert

show_certs

enable_certbot_renewals
