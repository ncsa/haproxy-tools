#!/usr/bin/bash

#TODO - update to check local file for each setting in 'example'
#       allow to change, add/remove (if an array)

INSTALL_DIR='___INSTALL_DIR___'
. "${INSTALL_DIR}"/lib/base.sh

SAMPLE_CONFIG="${INSTALL_DIR}"/conf/example
declare -A CONFIG_NAMES
TMP_CONFIG="${INSTALL_DIR}"/conf/tmp
#CONFIG ... is defined in lib/base.sh


mk_config() {
  if [[ -f "${CONFIG}" ]] ; then
    echo 'Found existing config file.'
    ask_no_yes 'Want to review it?' || exit 0
  else
    cp "${SAMPLE_CONFIG}" "${CONFIG}"
  fi
}


get_config_varnames() {
  # get variable names from config file
  local _config_parts _varname _context _vartype
  _config_parts=( $( awk -F= 'NF>1' "${CONFIG}" ) )
  for part in "${_config_parts[@]}" ; do
    _varname=$( echo "${part}" | cut -d= -f1 )
    _context=$( echo "${part}" | cut -d= -f2 )
    _vartype=string
    # if context starts with an open-parenthesis, then type is array
    [[ "${_context}" =~ ^'(' ]] && _vartype=array
    CONFIG_NAMES["${_varname}"]="${_vartype}"
  done
}


print_live_config() {
  # Print the current state of all the CONFIG_VARS
  local _vartype _var_names
  _var_names=( $( echo "${!CONFIG_NAMES[@]}" | sort ) )
  for k in "${_var_names[@]}" ; do
    local -n _ref="$k"
    _vartype="${CONFIG_NAMES[$k]}"
    if [[ "${_vartype}" == 'array' ]] ; then
      echo "${k}=("
      for item in "${_ref[@]}" ; do
        echo "  $item"
      done
      echo ')'
    else
      echo "${k}=$_ref"
    fi
    echo
  done
}


edit_vars() {
  # start a loop to allow VARs to be edited
  local _next_action _keep_going _new_value _vartype
  _keep_going=$YES
  while [[ $_keep_going -eq $YES ]] ; do
    print_live_config
    PS3='Choose a variable to edit, or quit: '
    select opt in "${!CONFIG_NAMES[@]}" 'quit'; do
      _next_action="${opt}"
      break
    done
    case "${_next_action}" in
      quit)
        _keep_going=$NO
        ;;
      *)
        _vartype="${CONFIG_NAMES[$_next_action]}"
        if [[ "${_vartype}" == 'array' ]] ; then
          edit_array "${_next_action}"
        else
          read -p 'New value: ' _new_value
          local -n _ref="${_next_action}"
          _ref="${_new_value}"
        fi
        ;;
    esac
  done
}


edit_array() {
  local -n list_ref="$1"
  local _varname _main_menu _continue _action _new_item _new_items _del_item _del_index
  _varname="$1"
  _main_menu=( 'Add One' 'Add Multiple' Delete Show Done )
  _continue=$YES
  while [[ ${_continue} == $YES ]] ; do
    echo "Contents of ${_varname}:"
    echo "${list_ref[@]}"
    echo
    PS3='Choose an option for editing this config setting: '
    select opt in "${_main_menu[@]}" ; do
      _action="${opt}"
      break
    done
    case "${_action}" in
      'Add One')
        read -p 'New item: ' _new_item
        list_ref+=( "${_new_item}" )
        ;;
      'Add Multiple')
        read -a _new_items -p 'New items (space separated list): '
        list_ref=( "${list_ref[@]}" "${_new_items[@]}" )
        ;;
      Delete)
        PS3='Which item to delete: '
        select elem in "${list_ref[@]}"; do
          _del_item="${elem}"
          _del_index=$((REPLY - 1)) #use 0-based index for bash array
          break
        done
        if [[ "${list_ref[$_del_index]}" == "${_del_item}" ]] ; then
          unset list_ref[$_del_index]
        else
          die "Value at index '$_del_index' is '${list_ref[$_del_index]}' does not match selected value '${_del_item}'"
        fi
        ;;
      Show)
        echo "Contents of ${_varname}:"
        echo "${list_ref[@]}"
        echo
        ;;
      Done)
        _continue=$NO
        ;;
    esac
  done
}


save_config() {
  # Save the current state of all the CONFIG_VARS to temp file
  print_live_config >"${TMP_CONFIG}"

  #( declare -p ) >"${TMP_CONFIG}"
  
  # If temp is different, copy over the real config
  diff -q "${TMP_CONFIG}" "${CONFIG}" || {
    # copy so it respects a symlink (move would overwrite a symlink and make
      # a regular file)
    cp "${TMP_CONFIG}" "${CONFIG}"
    rm "${TMP_CONFIG}"
  }

}


backup_config() {
  local _real_cfg_dir _real_cfg_path
  if ! [[ -L "${CONFIG}" ]] ; then
    _real_cfg_dir="${HOME}"/.config/"${TOOLS_PKG_NAME}"
    mkdir -p "${_real_cfg_dir}"
    _real_cfg_path="${_real_cfg_dir}"/config
    mv "${CONFIG}" "${_real_cfg_path}"
    ln -s "${_real_cfg_path}" "${CONFIG}"
  fi
}


print_config() {
  echo 'CURRENT CONFIG'
  echo '=============='
  cat "${CONFIG}"
  echo '=============='
}


###
# MAIN
###

mk_config

get_config_varnames

edit_vars

save_config

backup_config

print_config
