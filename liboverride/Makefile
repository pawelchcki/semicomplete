CFLAGS+=-fPIC -I/usr/local/include -g
PACKAGE=liboverride
FILES=Makefile funcdefs *.over

DYNFLAGS=-fPIC -shared

package: clean
	NAME="$(PACKAGE)-`date +%Y%m%d`"; \
	mkdir $${NAME}; \
	rsync --exclude '.*' -av `ls -d $(FILES)` $${NAME}/; \
	tar -zcf $${NAME}.tar.gz $${NAME}/; \
	rm -rf $${NAME}/

socket.so: socket.o
	@CFLAGS="$(CFLAGS)"; \
	[ "`uname`" = "Linux" ] && CFLAGS="$${CFLAGS} -ldl"; \
	set -x; \
	gcc $(DYNFLAGS) $$CFLAGS socket.o -o socket.so

socket.o: socket.c
	@CFLAGS="$(CFLAGS)"; \
	set -x; \
	gcc -c $$CFLAGS socket.c -o socket.o

%.so: %.o
	@CFLAGS="$(CFLAGS)"; \
	[ "`uname`" = "Linux" ] && CFLAGS="$${CFLAGS} -ldl"; \
	set -x; \
	gcc $(DYNFLAGS) $$CFLAGS $< -o $@

%.o: %.c
	@CFLAGS="$(CFLAGS)"; \
	set -x; \
	gcc -c $$CFLAGS $< -o $@

%.c-pre_sed: %.over
	m4 funcdefs $< > $@

%.c: %.c-pre_sed
	sed -re '' < /dev/null > /dev/null 2>&1 && sed="sed -re" || true; \
	sed -Ee '' < /dev/null > /dev/null 2>&1 && sed="sed -Ee" || true; \
	$$sed '/\/\/RETURNVARS/ { s,//RETURNVARS[^(]+,,; s/[[:alpha:]_*]+ //g; s/[/()*]//g; }' $< \
	> $@

clean:
	rm -f *.o *.so *.c
