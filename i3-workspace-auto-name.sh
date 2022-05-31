#!/usr/bin/env bash
# i3 workspace auto rename
# author: rains31@gmail.com
# github: https://github.com/rains31
DISPLAY=${DISPLAY:-":0"}
MAX_NAME_LENGTH=20
# force update interval for inactive workspaces
UPDATE_INTERVAL=60
CACHE_FILE=/tmp/.i3-inactive-workspaces
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
  newname=$(echo $newname | tr -d '<>"\\')
  newname=$([ ${#newname} -eq 0 ] && echo $num || echo $num:${newname:0:$MAX_NAME_LENGTH})
  [ "$oldname" = "$newname" ] || {
    msg='rename workspace "'$oldname'" to "'$newname'"'
    [ $DEBUG = 'true' ] && echo $msg
    i3-msg "$msg" >/dev/null
  }
}

workspaces_not_changed() {
  oldsum=$(cat $CACHE_FILE | md5sum)
  newsum=$(i3-msg -t get_tree | jq '.nodes[].nodes[].nodes[] | select(.type=="workspace" and .focused!=true)' | tee $CACHE_FILE | md5sum)
  [ "$oldsum" = "$newsum" ]
  return $?
}

update_workspaces() {
  local wname=$1
  # do nothing if workspace tree not changed
  [ -z "$wname" ] && workspaces_not_changed && return
  i3-msg -t get_workspaces | jq '.[]' | jq '.focused,.num,.name' | xargs -n3 | while read focused num oldname; do {
    if [ $focused = 'true' ]; then
      # in the current workspace, rename workspace to the active window name
      [ -z "$wname" ] || rename_workspace $num "$oldname" "$wname"
    else
      # new workspace or force update
      [ ${#oldname} -lt 3 -o -z "$wname" ] && {
        ws=$(cat $CACHE_FILE | jq 'select(.num=='$num')')
        echo $ws | jq '.focus[]' | while read focus; do {
          focusname=$(echo $ws | jq -r '.nodes[] | select(.id=='$focus').name')
          # use the focus window name unless it's not null
          [ "$focusname" = 'null' ] || rename_workspace $num "$oldname" "$focusname"
        }; done
      }
    fi
  }; done
}

watch_wm_name | while read wname; do {
  update_workspaces "${wname}"
}; done &

while true; do
  update_workspaces
  sleep $UPDATE_INTERVAL
done
