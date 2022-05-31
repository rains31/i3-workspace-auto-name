# i3-workspace-auto-name

## requirements:

- bash
- jq
- xtitle or xorg-xprop

download this file, chmod, move/copy to your favorite location, eg: /usr/local/bin/

```shell
wget https://raw.githubusercontent.com/rains31/i3-workspace-auto-name/main/i3-workspace-auto-name.sh
chmod +x i3-workspace-auto-name.sh
sudo mv i3-workspace-auto-name.sh /usr/local/bin/
```

then, start it automatically or manually, make it start with i3wm anyway.

## method 1

add to i3 config & restart i3wm

```
exec --no-startup-id /usr/local/bin/i3-workspace-auto-name.sh
```

## method 2

add to i3blocks config & reload i3wm

```
[auto-wsname]
command=/usr/local/bin/i3-workspace-auto-name.sh
interval=persist
```

## method 3

manually run in terminal

```
( /usr/local/bin/i3-workspace-auto-name.sh & )
```
