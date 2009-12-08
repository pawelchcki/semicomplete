#!/bin/bash
# cronhelper.sh
# usage: cronhelper.sh &lt;timeout&gt; &lt;startupdelay&gt; &lt;command ... &gt;

# You should set the following environment variables:
# SLEEPYSTART - sleeps at startup a random number from 0 to $SLEEPYSTART seconds
# TIMEOUT - sets expiration time for your command (requires alarm.rb)
# JOBNAME - sets the job name used for locking and syslog tag (should be unique)

if [ -z "$JOBNAME" ] ; then
  echo "No jobname given. Please set JOBNAME in environment."
  exit 1
fi

output=$(mktemp) # for output capture
lockfile="/tmp/cronhelper.lock.$JOBNAME"

# use a subshell to capture all command output
(
  # redirect stderr to stdout for everything in this subshell.
  exec 2>&1

  if [ ! -z "$SLEEPYSTART" ] ; then
    sleeptime=$(echo "scale=8; ($RANDOM / 32768) * $SLEEPYSTART" | bc | cut -d. -f1)
    echo "Sleeping for $sleeptime before starting $1."
    sleep $sleeptime
  fi

  if [ -z "$TIMEOUT" ] ; then
    exec "$@"
  else
    exec alarm.rb $TIMEOUT "$@"
  fi
) | tee $output | logger -t "$JOBNAME"

# bash has "pipestatus" so we can get the exit status of the first command in
# the pipe. Normal /bin/sh does not support this.
jobstatus=${PIPESTATUS[0]}

if [ "$jobstatus" -ne 0 ] ; then
  echo "exit code $jobstatus from $@"
  cat $output
  rm $output
  exit $jobstatus
fi

rm $output


