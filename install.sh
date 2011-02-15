#!/bin/bash

PREFIX=/usr/local

method="install"

name=encrypt-system-files

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
  rm -f "$PREFIX/lib/$name/home"*
  rmdir "$PREFIX/lib/$name/home"
# leave the config...
#  rm -f "$PREFIX/lib/$name/"*
#  rmdir "$PREFIX/lib/$name"
  set +x
  echo "Done"

else
  # install
  echo "This will install $name in $PREFIX[/bin|/lib]. Continue? (y/n)"
  read RESP
  if [ "$RESP" != "y" ] ; then
    echo "Nothing done"
    exit
  fi
  set -x
  $install -o root -g root -m 0700 "./$name" "$PREFIX/bin/$name"
  mkdir -p -m 0700 "$PREFIX/lib/$name"
  mkdir -p -m 0700 "$PREFIX/lib/$name/home"
  $install -o root -g root -m 0600 "./config" "$PREFIX/lib/$name/config"
  $gpg --homedir "$PREFIX/lib/$name/home" --import ./PublicKey_to_Encrypt
  set +x
  echo "Done. Be sure to check config and edit accordingly."
fi
