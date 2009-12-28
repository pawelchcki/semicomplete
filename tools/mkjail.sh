
if [ $1 = "make" ]; then
	xapply 'cp -v /bin/%1 /misc/bin' cat chmod cp  df echo hostname kill ln ls mkdir mv ps pwd           rm rmdir sh sync test date dd stty expr

	xapply 'cp -v /sbin/%1 /misc/sbin' devfs dmesg rcorder sysctl

	xapply 'cp -v /usr/bin/%1 /misc/usr/bin' basename awk false killall less passwd pkill su touch true sed cmp find logger uname mktemp login

	xapply 'cp -v /usr/sbin/%1 /misc/usr/sbin' chown inetd pw pwd_mkdb syslogd

	xapply 'cp -v %1 /misc/%1' /usr/bin/ssh /usr/bin/ssh-keygen /usr/bin/scp /usr/sbin/sshd

	cp -v /libexec/* /misc/libexec
else
  if [ $1 = "link" ]; then
    cd /misc
    ldd -f "%p\n" bin/* sbin/* usr/sbin/* usr/bin/* | sort | uniq | xapply -f 'cp -v %1 /misc/%1' -
  fi
fi
