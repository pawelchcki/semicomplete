#!/bin/sh

if [ "$#" -ne 2 ] ; then
  echo "Usage: $0 <hostname> <ip>"
  echo "This lets you fake a puppet run as the given host with the ip set as ipaddress_eth0"
  exit 1
fi

set -x
# I set FACTER_fqdn and FACTER_ipaddress_eth0 so we can easily pretend to be another
# host. This allows us to show this demo without requiring a run on different hosts.
export FACTER_fqdn=$1
export FACTER_ipaddress_eth0=$2

# Also set --certname here so we are really able to masquerade as another host
puppet --certname=$FACTER_fqdn --verbose --debug \
       --storeconfigs --dblocation ./storeconfigs.sqlite \
       --modulepath modules manifests/site.pp
