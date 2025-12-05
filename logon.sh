#!/bin/bash

error()
{
  [ -n "$@" ] && echo "$@"
  exit 1
}

[ -z "$user" ] && error "user-Variable nicht gesetzt!"

home=
eval "home=~$user"

echo "$home" | grep -q "^/" || error "Benutzer existiert nicht oder Homeverzeichnis nicht gefunden!"

if [ ! -d "$home" ]; then
  mkdir -p "$home"
fi
chmod 0750 "$home"

if [ -z "`ls -A \"$home\"`" ]; then
  for dir in /etc/skel /etc/skel.custom; do
    if [ -d "$dir" ]; then
      rsync -r --ignore-existing "$dir/" "$home"
    fi
  done
  #mkdir -p "$home/.mozilla/firefox"
  #echo -e "[General]\nStartWithLastProfile=1\n\n[Profile0]\nName=default\nIsRelative=0\nPath=$home/Freigaben/Eigene Dateien/Profile/Firefox" > "$home/.mozilla/firefox/profiles.ini"
  #mkdir -p "$home/.mozilla-thunderbird"
  #echo -e "[General]\nStartWithLastProfile=1\n\n[Profile0]\nName=default\nIsRelative=0\nPath=$home/Freigaben/Eigene Dateien/Profile/Thunderbird" > "$home/.mozilla-thunderbird/profiles.ini"
fi

export USER="$user"
export PASSWD="$pass"

shares="$home/Freigaben"
mkdir -p "$shares"

for text in homes="Eigene Dateien" pgm=Programme tausch=Tauschverzeichnisse; do
  share=`echo "$text" | cut -d= -f 1`
  name=`echo "$text" | cut -d= -f 2-`
  mntpt="$shares/$name"
  tag=`echo "$mntpt" | sed -r "s/[^a-z/]//gi"`
  if cut -d " " -f 2 /proc/mounts | sed -r "s/[^a-z/]//gi" | grep -qi "$tag"; then
    :
  else
    mkdir -p "$mntpt"
    uid=`id -u "$user"`
    [ -z "$uid" ] && uid="$user"
    mount -t cifs -o uid="$uid",iocharset=utf8,gid=0,dir_mode=0750,file_mode=0640 "//files/$share" "$mntpt"
  fi
done
find "$home" -xdev -print0 | xargs -0 chown "$user:0"
