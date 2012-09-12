NAME=ltsp-lightdm
INSTALLFILES ?= \
	usr/share/xsessions/ltsp-session.desktop \
	usr/share/ltsp/ltsp-session \
	usr/share/ltsp/screen.d/gdm \
	usr/share/ltsp/screen.d/lightdm \
	usr/share/ltsp/xsession-stub

EXAMPLEFILES ?= \
	etc/lightdm/lightdm.conf \
	etc/nsswitch.conf \
	etc/pam.d/lightdm

all:

install:
	for file in $(INSTALLFILES); do \
		install -D -o root -g root -m 644 hack/$$file \
			$(DESTDIR)/$$file || exit 1; \
	done
	chmod +x -R $(DESTDIR)/usr/share/ltsp/*

	for file in $(EXAMPLEFILES); do \
		install -D -o root -g root -m 644 hack/$$file \
			$(DESTDIR)/usr/share/doc/$(NAME)/examples/$$file || exit 1; \
	done
	install -D -o root -g root -m 644 README.md \
		$(DESTDIR)/usr/share/doc/$(NAME)/README.md || exit 1; \

clean:

deb:
	-rm -rf debian/$(NAME) deb_dist
	mkdir -p deb_dist/$(NAME)
	cp -r debian README* Makefile hack deb_dist/$(NAME) && \
	cd deb_dist/$(NAME) && \
	dpkg-buildpackage -rfakeroot -uc -us || \
	echo "ERROR"

	@echo "\n *** PACKAGE CONTENTS\n"
	@dpkg-deb -c deb_dist/*.deb
	@echo "\n *** DEBIAN FILES\n"
	@ls -1 deb_dist/$(NAME)_*


# # # DEBUG # # #

DESTROOT=/opt/ltsp/i386
CLIENT_IP=192.168.0.22

directories:
	for dir in `cd hack && find -type d -printf '%P\n'`; do \
		mkdir -p $(DESTROOT)/$$dir; \
	done

deploy: directories
	for file in `cd hack && find -type f -printf '%P\n'`; do \
		cp hack/$$file $(DESTROOT)/$$file; \
		echo $$file; \
	done

hotdeploy:
	rsync -r hack/* root@$(CLIENT_IP):/

