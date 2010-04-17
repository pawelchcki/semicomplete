#!/bin/sh

. /etc/rc.subr
name="jail"
rcvar=`set_rcvar`
. /etc/rc.conf

corpzone="/etc/namedb/master/corp.db"
tenzone="/etc/namedb/master/corp-rev.db"

for _j in $jail_list; do
  # Copied from /etc/rc.d/jail
  eval _hostname=\"\$jail_${_j}_hostname\"
  eval _ip=\"\$jail_${_j}_ip\"

  echo "$_hostname -> $_ip"

  raddr=`echo "$_ip" | awk -F. '{printf "%d.%d.%d.%d.in-addr.arpa.\n", $4,$3,$2,$1}'`

  A="$_hostname. IN A $_ip"
  PTR="$raddr IN PTR $_hostname."
  if grep -q $_hostname $corpzone; then
    sed -i.bak -e "s/^.*$_hostname.*$/$A/" $corpzone
  else
    echo "$A" >> $corpzone
  fi

  if grep -q $_hostname $tenzone; then
    sed -i.bak -e "s/^.*PTR *$_hostname.*$/$PTR/" $tenzone
  else
    echo "$PTR" >> $tenzone
  fi
done

SERIAL=`date +%s`
sed -E -i.bak -e "s/[0-9]+ ; serial/$SERIAL ; serial/" $corpzone $tenzone
rndc reload || /etc/rc.d/named restart

