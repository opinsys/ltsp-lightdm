FILES=`cd hack && find -type f -printf '%P\n'`
DESTROOT=/opt/ltsp/i386
CLIENT_IP=192.168.0.22

deploy:
	for file in $(FILES); do \
		cp hack/$$file $(DESTROOT)/$$file; \
		echo $$file; \
	done

hotdeploy:
	rsync -r hack/* root@$(CLIENT_IP):/

