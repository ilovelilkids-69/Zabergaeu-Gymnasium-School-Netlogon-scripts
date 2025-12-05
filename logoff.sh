#!/bin/bash

logoff_common()
{
  [ -d "$homepath/Freigaben" ] || exit
  for d in "$homepath/Freigaben"/*; do
    [ -d "$d" ] || continue
    umount "$d"
    rmdir "$d"
  done
  rmdir "$homepath/Freigaben"/* 2>/dev/null
  rmdir "$homepath/Freigaben"
}
delete_profile()
{
  abspath=`cd "$homepath"; pwd`
  if ! grep -q ":$abspath:" /etc/passwd; then
    if echo "$abspath" | grep -q "^/home/"; then
      umount "$abspath/.gvfs" 2>/dev/null
      rm -rf "$abspath/.gvfs"
      rm -rf --one-file-system "$abspath"
    fi
  fi
}
logoff_user()
{
  logoff_common
  delete_profile
}

logoff_pgmadmin()
{
  logoff_common

  PGMADMIN_SYNC_TEMPLATE=/etc/skel.custom
  PGMADMIN_DELETE_HOME=no

  [ -f /etc/default/profiles ] && . /etc/default/profiles

  if echo "$PGMADMIN_SYNC_TEMPLATE" | grep -q ^/; then
    mkdir -p "$PGMADMIN_SYNC_TEMPLATE"
    rsync -rx --delete --delete-excluded \
      --exclude=".gvfs" \
      --exclude=".bash_history" \
      --exclude=".xsession-errors*" \
      --exclude=".cache/*" \
      --exclude=".ICEauthority" \
      --exclude=".pulse-cookie" \
      --exclude=".local/share/Trash/*" \
      --exclude="Freigaben" \
      "$homepath/" "$PGMADMIN_SYNC_TEMPLATE/"

    find "$PGMADMIN_SYNC_TEMPLATE/" -type f -exec grep -qi 'pgmadmin' '{}' \; -delete
  fi
  [ "$PGMADMIN_DELETE_HOME" = "yes" ] && delete_profile
}

if echo "$homepath" | grep -Eqi "/pgmadmin/?"; then
  logoff_pgmadmin
else
  logoff_user
fi
