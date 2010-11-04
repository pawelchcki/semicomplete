notice("fqdn: $fqdn")

# All nodes should register and import other host info
node default {
  example::exported::expiringhost {
    $fqdn: ip => $ipaddress_eth0;
  }

  Example::Expiringhosts <<| |>>
}
