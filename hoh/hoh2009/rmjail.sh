#!/bin/sh

if [ -z "$1" ] ; then
	echo "Usage: $0 jailname"
	exit 1
fi

if [ ! -d "$1" ] ; then
	echo "'$1' is not a directory"
	exit 1
fi

chflags noschg $1/var/empty
rm -r $1
