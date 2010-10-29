exec {
  "/bin/mkdir /tmp/foo":
    creates => "/tmp/foo";
}

file {
  "/tmp/foo/bar":
    ensure => file,
    content => "Hello";
}
