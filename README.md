Hack for logging into LTSP system from LightDM or GDM.


LDM is the login display manager in LTSP systems. LDM login uses two ssh tunnels: one that is created at login, and is responsible for opening a control socket for connection sharing. The second tunnel brings the user's desktop session onto the client, using this shared connection.

These hacks emulate this behaviour by hooking up the the login process from PAM, via pam_exec. The LDM package is required to be installed, but this hack does no modifications to the existing rc.d scripts.

Sound using pulseaudio is working. External USB drives using LTSPFS also work. LDM_DIRECTX also works when the display manager is configured to allow TCP connections.

To test these hacks, install the required packages to chroot, along with the DM of your choice:

	chroot:# apt-get install ldm ltspfs daemon libpam-sshauth libnss-sshsock2

	chroot:# apt-get install lightdm lightdm-gtk-greeter
	# AND/OR
	chroot:# apt-get install gdm

Make sure to have the session package installed that is defined in lts.conf.

	server:# apt-get install gnome-fallback-session

Clone this repository to your LTSP master server, adjust the Makefile if necessary (default chroot is `/opt/ltsp/i386`) and run:

    server:# make deploy

As this is a hack, **the login user account has to be created BOTH into the chroot AND ALSO into the server**. PAM uses local accounts to authenticate, later the scripts use the same username to login to remote host. I repeat, **THIS IS A HACK**.

	chroot:# useradd -s /bin/bash -m -d /home/usr1 usr1
	chroot:# passwd usr1

	server:# useradd -s /bin/bash -m -d /home/usr1 usr1
	server:# passwd usr1

Now you're ready to rebuild the client image.

	server:# ltsp-update-image --arch i386

In your server's lts.conf, set this directive to launch LightDM or GDM instead of LDM. This hack is currently only available for thin clients, so bump up the FAT_RAM_TRESHOLD high enough.

	[default]
	SCREEN_07=lightdm
	# SCREEN_07=gdm
	LDM_SESSION="gnome-session --session=gnome-fallback"
	LOCALDEV=True
	SOUND=True
	SOUND_DAEMON=pulse
	FAT_RAM_THRESHOLD=99999

Keep an eye on `/var/log/syslog` and `/var/log/auth.log`.


*While hacking the scripts, it is possible to use the "hotdeploy" make target to copy changes to the client, and test them without rebuilding the image. Adjust the client IP in the Makefile and possibly restart affected services.*

