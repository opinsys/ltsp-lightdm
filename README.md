Hack for logging into LTSP system from LightDM or GDM.


LDM is the login display manager in LTSP systems. This hack makes it possible to use LightDM and GDM instead of LDM as the display manager in LTSP-5 systems. This is not yet intended to be used by end-users, the primary audience are LTSP developers.

LDM login uses two ssh tunnels: one that is created at login, and is responsible for opening a control socket for connection sharing. The second tunnel brings the user's desktop session onto the client, using this shared connection. This hack lifts the main tasks from the LDM binary into a script that hooks up to the login process from pam_exec. During the auth phase the ssh control socket is opened, the open_session phase sets environment variables and runs the rc.d scripts. No modifications are needed in the rc.d or xinitrc.d scripts.

Sound using pulseaudio and external USB drives using LTSPFS are working. LDM_DIRECTX also works when the display manager is configured to allow TCP connections. The desktop session needs to be configured in lts.conf. Only thin clients are supported so far.


## User accounts

Currently you have two options with LightDM; one option with GDM. To get either one working, create the login accounts *both into chroot and onto the server*. This is extremely hackish, but most reliable, and required to login by GDM at the moment.

	chroot:# useradd -s /bin/bash -m -d /home/usr1 usr1
	chroot:# passwd usr1

	server:# useradd -s /bin/bash -m -d /home/usr1 usr1
	server:# passwd usr1

With LightDM there is an option to use libpam-sshauth with libnss-sshsock2, and the user account is required to exist only on the server. Depending on your choice of desktop, you may have to set `LOCAL_APPS=True`.


## Installation

To test the hack, install the required packages to chroot, along with the DM of your choice:

	chroot:# apt-get install ldm ltspfs daemon libpam-sshauth libnss-sshsock2

	chroot:# apt-get install lightdm lightdm-gtk-greeter
	# AND/OR
	chroot:# apt-get install gdm

Make sure to have the session package installed that is defined in lts.conf.

	server:# apt-get install gnome-fallback-session

Clone this repository to your LTSP master server, adjust the Makefile if necessary (default chroot is `/opt/ltsp/i386`) and run:

    server:# make deploy

Now you're ready to rebuild the client image.

	server:# ltsp-update-image --arch i386

Setup your lts.conf. Bump up the FAT_RAM_THRESHOLD high enough to disable switching to fat client mode.

	[default]
	SCREEN_07=lightdm
	# SCREEN_07=gdm
	LDM_SESSION="gnome-session --session=gnome-fallback"
	LOCALDEV=True
	LOCAL_APPS=True # required if the user does not exist in chroot
	SOUND=True
	SOUND_DAEMON=pulse
	FAT_RAM_THRESHOLD=99999

Keep an eye on `/var/log/syslog`, `/var/log/auth.log` and `~/.xsession-errors`.


## Debugging

While hacking the scripts, it is possible to use the "hotdeploy" make target to copy changes to the client, and test them without rebuilding the image. Adjust the client IP in the Makefile and possibly restart affected services.

The rspec test suite for ltsp-session script can by run by

	$ gem install bundler
	$ bundle install
	$ bundle exec rspec

