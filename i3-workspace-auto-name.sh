#!/usr/bin/env bash
# i3 workspace auto rename
# author: rains31@gmail.com
# github: https://github.com/rains31
DISPLAY=${DISPLAY:-":0"}
MAX_NAME_LENGTH=20
DEBUG=false

watch_wm_name() {
  if hash xtitle 2>/dev/null; then
    xtitle -sie
  else
    xprop -spy -root | grep '^_NET_DESKTOP_NAMES' | awk -F'"' '{print $2}'
  fi
}

rename_workspace() {
  local num=$1
  local oldname=$2
  local newname=$3
  newname=$(echo $newname | tr -d '<>"\\') # remove special chars
  newname=$([ ${#newname} -eq 0 ] && echo $num || echo $num:${newname:0:$MAX_NAME_LENGTH})
  [ "$oldname" = "$newname" ] || {
    msg='rename workspace "'$oldname'" to "'$newname'"'
    [ $DEBUG = 'true' ] && echo $msg
    i3-msg "$msg" >/dev/null
  }
}

update_workspaces() {
  local wname=$1
  i3-msg -t get_workspaces | jq '.[]' | jq '.focused,.num,.name' | xargs -n3 | while read focused num oldname; do {
    # echo focused=$focused num=$num name=$oldname
    if [ $focused = 'true' ]; then
      # in the current workspace, rename workspace to the active window name
      rename_workspace $num "$oldname" "$wname"
    else
      # new workspace
      [ ${#oldname} -eq 1 ] && {
        ws=$(i3-msg -t get_tree | jq '.nodes[].nodes[].nodes[] | select(.type=="workspace" and .num=='$num')')
        focus=$(echo $ws | jq '.focus[]' | head -n1)
        # in a new workspace with a forcus window, use the focus window name
        [ -z $focus ] || {
          focusname=$(echo $ws | jq -r '.nodes[] | select(.id=='$focus').name')
          rename_workspace $num "$oldname" "$focusname"
        }
      }
    fi
  }; done
}

watch_wm_name | while read wname; do {
  update_workspaces "${wname}"
}; done
