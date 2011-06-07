#!/bin/bash

PREFIX=/usr/local

method="install"

name=encrypt-system-files
if [ -z "$name" ] ; then
 echo "name was blank"
 exit
fi

if [ $# -gt 0 ] ; then
 case $@ in
  '--prefix=.*')  PREFIX=$(echo $EACH | cut -f2- -d'=') ;;
  
  '--uninstall')  method="uninstall" ;;
  
  *) echo "Usage: $0 [--prefix=/...] [--uninstall]" ; exit 1 ;;

 esac
fi

if ! [ -d "$PREFIX" ] ; then
  echo "Prefix does not exist: $PREFIX"
  exit 1
fi

check_exec() {
  for each in $@ ; do
    exe=$(which $each 2>/dev/null)
    if [ -x "$exe" ] ; then
      break
    fi
  done
  if ! [ -x "$exe" ] ; then
    echo "Cannot find $exe"
    exit 1
  fi
}

check_exec gpg gpg2
gpg=$exe
check_exec install
install=$exe


if [ "$method" == "uninstall" ] ; then
  echo "Are you sure you want to uninstall $name? (n/y)"
  read RESP
  if [ "$RESP" != "y" ] ; then
    echo "Nothing done"
    exit
  fi
  # uninstall
  set -x
  rm -f "$PREFIX/bin/$name"
  rm -f "$PREFIX/share/$name/home/"*
  rmdir "$PREFIX/share/$name/home" 2>/dev/null
# leave the config...
#  rm -f "$PREFIX/share/$name/"*
#  rmdir "$PREFIX/share/$name"
  # for old method of install
  if [ -d "$PREFIX/lib/$name" ] ; then
    rm -f "$PREFIX/lib/$name/home/"*
    rmdir "$PREFIX/lib/$name/home" 2>/dev/null
    [ -f "$PREFIX/lib/$name/config" ] && oldconfig=1
    # and move config to share, unless it already exists
    #if ! [ -f "$PREFIX/share/$name/config" ] && [ -f "$PREFIX/lib/$name/config" ] ; then
    #  mkdir -p -m 0700 "$PREFIX/share/$name"
    #  mv "$PREFIX/lib/$name/config" "$PREFIX/share/$name/"
    #  rmdir --ignore-fail-on-non-empty "$PREFIX/share/$name"
    #fi
  fi
  set +x
  echo
  if [ -n "$oldconfig" ] ; then
    echo "Old config was left at $PREFIX/lib/$name/config"
  fi
  echo "Config was left at $PREFIX/share/$name/config"
  echo "Done"

else
  # install
  echo "This will install $name in $PREFIX[/bin|/share]. Continue? (y/n)"
  read RESP
  if [ "$RESP" != "y" ] ; then
    echo "Nothing done"
    exit
  fi
  if [ -f  "$PREFIX/share/$name/config" ] ; then
    echo
    echo "Config file already exists. If you want to overwrite it, please run the following command:"
    echo "cp ./config \"$PREFIX/share/$name/config\""
    echo
  else
    CPCONFIG="install config"
  fi
  set -x
  $install -o root -g root -m 0700 "./$name" "$PREFIX/bin/$name"
  mkdir -p -m 0700 "$PREFIX/share/$name"
  mkdir -p -m 0700 "$PREFIX/share/$name/home"
  # do not install config file if it is already there
  [ -n "$CPCONFIG" ] && $install -o root -g root -m 0600 "./config" "$PREFIX/share/$name/config"
  $gpg --homedir "$PREFIX/share/$name/home" --import ./PublicKey_to_Encrypt
  set +x
  echo "Done. Be sure to check config and edit accordingly."
fi
