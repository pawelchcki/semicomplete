#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)
AC_INIT(proxy, 1.6, psionic@csh.rit.edu)
AM_INIT_AUTOMAKE(proxy, 1.6)
#AC_CONFIG_SRCDIR([src/main.c])

# Checks for programs.
AC_PROG_CC

# Checks for libraries.
LIBNET_LDFLAGS="`libnet-config --libs`"
LIBNET_CFLAGS="`libnet-config --defines` -D__GLIBC__"

# Checks for header files.

AC_HEADER_STDC
AC_CHECK_HEADERS([arpa/inet.h limits.h netdb.h netinet/in.h stddef.h stdlib.h string.h sys/socket.h sys/time.h unistd.h])

AC_CHECK_HEADERS([netinet/if_ether.h net/ethernet.h], , , [#include <sys/types.h>
#include <sys/socket.h>
#include <net/if.h>])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_HEADER_TIME

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_MEMCMP
AC_FUNC_REALLOC
AC_FUNC_SELECT_ARGTYPES
#AC_CHECK_FUNCS([gethostbyname inet_ntoa select socket strerror])

AC_CANONICAL_HOST

# pthreads...
echo "Host: $host"
case $host in
*solaris*)
	CFLAGS="$CFLAGS -D_POSIX_PTHREAD_SEMANTICS"
	LDFLAGS="$LDFLAGS -lpthread -lnsl -lsocket" ;;
*freebsd*)
	LDFLAGS="-pthread" ;;
*)
	AC_CHECK_LIB(pthread,pthread_create,
					 [LDFLAGS="$LDFLAGS -lpthread"],
					 [AC_MSG_ERROR([pthread library not found... perhaps you should fix that?])]
					)
esac

AC_ARG_WITH([debug], 
            AC_HELP_STRING([--with-debug], [enable debug symbols]),
				[ CFLAGS="$CFLAGS -g" ])

# Check for pcap
AC_ARG_WITH([pcap],
            AC_HELP_STRING([--with-pcap=DIR], 
									[search for pcap in DIR/include and DIR/lib]),
				[ PCAP_PREFIX=$withval ],
				[ PCAP_PREFIX=/usr/local ])

PCAP_FOUND=0

# Checking for paths for pcap
AC_CHECK_PATHS([/usr /usr/local], 
					[
					AC_CHECK_FILE([${dirname}/lib/libpcap.a], [AC_PATH_FOUND])
					],
					[
					LDFLAGS="$LDFLAGS -L${dirname}/lib"
					CFLAGS="$CFLAGS -I${dirname}/include"
					PCAP_PREFIX=$dirname
					],
					[ AC_MSG_ERROR([Unable to find libpcap.a. Specify path wth --with-pcap ]) ]
				  )

AC_CHECK_HEADERS(pcap.h,,AC_MSG_ERROR([pcap.h not found]))
AC_CHECK_LIB(pcap, pcap_lib_version, [LIBS="$LIBS -lpcap"], 
				 [AC_MSG_ERROR([libpcap was not found])])

# Check for libnet
AC_ARG_WITH([libnet],
            AC_HELP_STRING([--with-libnet=DIR], 
									[search for libnet in DIR/include and DIR/lib]),
				[ LIBNET_PREFIX=$withval ],
				[ LIBNET_PREFIX=/usr/local ])

LIBNET_FOUND=0
LIBS="$LIBS -lnet"

AC_CHECK_PATHS([/usr /usr/local], 
					[
					AC_CHECK_FILE([${dirname}/lib/libnet.a], [AC_PATH_FOUND])
					],
					[
					LDFLAGS="$LDFLAGS -L${dirname}/lib"
					CFLAGS="$CFLAGS -I${dirname}/include"
					LIBNET_PREFIX=$dirname
					LIBS="$LIBS -lnet"
					],
					[ AC_MSG_ERROR([Unable to find libnet.a. Specify path wth --with-libnet ]) ]
				  )

AC_CHECK_LIB(net, libnet_write_link_layer, 
				 AC_DEFINE([HAVE_LIBNET_1_0], [], [libnet 1.0.x]),
				 AC_CHECK_LIB(net, libnet_adv_write_link,
								  AC_DEFINE([HAVE_LIBNET_1_1], [], [libnet 1.1.x]),
								  AC_MSG_ERROR([Libnet library not found in $LIBNET_PREFIX])))

AC_CHECK_TYPE(u_char, unsigned char)

AC_SUBST(PCAP_PREFIX)
AC_SUBST(LIBNET_PREFIX)
AC_SUBST(LIBNET_LDFLAGS)
AC_SUBST(LIBNET_CFLAGS)

AM_CONFIG_HEADER([config.h])
AC_OUTPUT([Makefile
           src/Makefile])
