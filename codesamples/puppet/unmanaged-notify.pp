# Manually manage /tmp/original
# Each puppet run willy copy it to /tmp/flag if there's a change and notify
# the exec when it changes.
file {
  "/tmp/flag":
    source => "file:///tmp/original",
    notify => Exec["hello world"];
}

exec {
  "hello world":
    command => "/bin/echo hello world",
    refreshonly => true;
}

