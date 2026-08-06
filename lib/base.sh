
INSTALL_DIR='___INSTALL_DIR___'

# load config if it exists
CONFIG="${INSTALL_DIR}"/conf/config
[[ -f "${CONFIG}" ]] && . "${CONFIG}"

# general settings
YES=0
NO=1
# ANSI escape codes for colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# General useful vars
TOOLS_PKG_NAME='haproxy-tools'
HOST=$( hostname -f )
TODAY=$( date +%Y%m%d )

# certificate related
LETSENCRYPT_BASE=/etc/letsencrypt
CERT_DIR="${LETSENCRYPT_BASE}"/live/"${HOST}"
HOST_KEY="${CERT_DIR}"/privkey.pem
HOST_CERT="${CERT_DIR}"/cert.pem
CA_CERT="${CERT_DIR}"/chain.pem
CA_NAME="LetsEncrypt CA"


### FUNCTIONS

err() {
  echo -e "${RED}✗ ERROR: $*${NC}" #| tee /dev/stderr
}


info() {
  [[ $VERBOSE -eq $YES ]] && {
    echo -e "${RED}INFO: ${NC}$*" 1>&2
  }
}

 
success() {
  echo -e "${GREEN}✓ $*${NC}" #| tee /dev/stderr
}
 
 
die() {
  err "$*"
  echo "from (${BASH_SOURCE[1]} [${BASH_LINENO[0]}] ${FUNCNAME[1]})"
  kill 0
  exit 99
}


ask_yes_no() {
  # Ask Yes or No
  # First option is Yes
  # Use this when the most common answer is yes,
  # ... enables the user to respond "1" for most installs
  local rv msg
  rv=1
  msg="Is this ok?"
  [[ -n "$1" ]] && msg="$1"
  echo "$msg"
  select yn in "Yes" "No"; do
    case $yn in
      Yes) rv=0;;
      No ) rv=1;;
    esac
    break
  done
  return $rv
}


ask_no_yes() {
  # Ask No or Yes
  # First option is No
  # Use this when the most common answer is no,
  # ... enables the user to respond "1" for most installs
  [[ $DEBUG -eq $YES ]] && set -x
  local rv msg ny
  rv=1
  msg="Is this ok?"
  [[ -n "$1" ]] && msg="$1"
  echo "$msg" 1>&2
  ny=$( ask_enum "No" "Yes" )
  case $ny in
    Yes) rv=0;;
    No ) rv=1;;
  esac
  return $rv
}


continue_or_exit() {
    local msg="Continue?"
    [[ -n "$1" ]] && msg="$1"
    echo "$msg"
    select yn in "Yes" "No"; do
        case $yn in
            Yes) return 0;;
            No ) exit 1;;
        esac
    done
}


ask_enum() {
  # Ask the user to choose from a custom list of choices
  # Caller should make the first option in the list the most common
  # First option is also the default, which will be chosen
  # ... if the user responds to the select-prompt with a 0 (or other non-valid
  # ... response)
  [[ $DEBUG -eq $YES ]] && set -x
  local _default _choice
  _default="$1"
  select result ; do
    if [[ "${#result}" -gt 0 ]] ; then
      _choice="$result"
    else
      _choice="$_default"
    fi
    break
  done
  echo "${_choice}"
}


mk_passwd() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 50
}


hostname2ip() {
  dig +short "${1}"
}


validate_file() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _fn="${1}"
  [[ -f "${_fn}" ]] || {
    LAST_ERR_MSG="File not found: '${_fn}'"
    return ${NO}
  }
  [[ -r "${_fn}" ]] || {
    LAST_ERR_MSG="File not readable: '${_fn}'"
    return ${NO}
  }
  [[ -s "${_fn}" ]] || {
    LAST_ERR_MSG="File is 0 size: '${_fn}'"
    return ${NO}
  }
  return ${YES}
}


validate_dir() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _dir="${1}"
  [[ -d "${_dir}" ]] || {
    LAST_ERR_MSG="Directory not found: '${_dir}'"
    return ${NO}
  }
  return ${YES}
}


