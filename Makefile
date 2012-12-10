NAME=ltsp-lightdm

all:

install:
	install -D -o root -g root -m 644 lightdm/lightdm.conf \
		$(DESTDIR)/etc/lightdm/lightdm.conf
	install -D -o root -g root -m 644 xsessions/ltsp-session.desktop \
		$(DESTDIR)/usr/share/xsessions/ltsp-session.desktop
	install -D -o root -g root -m 755 xsession-stub \
		$(DESTDIR)/usr/share/ltsp-lightdm/xsession-stub
	install -D -o root -g root -m 755 puavo-ltsp-session \
		$(DESTDIR)/usr/share/ltsp-lightdm/puavo-ltsp-session
	install -D -o root -g root -m 755 run-rc-scripts \
		$(DESTDIR)/usr/share/ltsp-lightdm/run-rc-scripts
	install -D -o root -g root -m 755 screen.d/lightdm \
		$(DESTDIR)/usr/share/ltsp/screen.d/lightdm
	cp -r rc.d $(DESTDIR)/usr/share/ltsp-lightdm/

clean:

