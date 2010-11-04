define example::expiringhost($ip, $timestamp) {
  $age = inline_template("<%= require 'time'; Time.now - Time.parse(timestamp) %>")

  notice("$class[$name]: ip => $ip, timestamp => $timestamp")
  if $age > 60 {
    $expired = true
    notice("Expiring resource $class[$name] due to age > 60 ($age)")
  } else {
    $expired = false
    notice("Found recently-active $class[$name]")
  }

  host {
    $name:
      ip => $ip,
      ensure => $expired ? { true => absent, false => present };
  }
}
