#!/bin/bash

# Usage: notify.sh MASTER|BACKUP|FAULT

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

STATE=$1
LOGFILE=/var/log/keepalived-notify.log
echo "$(date) - Node transitioned to $STATE" >> $LOGFILE

# Example: send an email or push to a monitoring webhook here
mail \
  -s "Keepalived state change: $STATE on $(hostname)" \
  "${KEEPALIVED_NOTIFY_EMAIL_RECIPIENT}" \
  <<< "State: $STATE"

