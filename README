Hack for logging into LTSP system from LightDM - or possibly any other DM - bypassing LDM.


Vanilla LDM login uses two ssh tunnels. The first one is created at login, which opens a control socket for connection sharing. The second tunnel is opened after setting up the environment via LDM rc.d scripts, and is used to connect the remote desktop to the thin client.

These hacks emulate this behaviour by hooking up the the login process from PAM, via pam_exec. The LDM package is required to be installed, as the rc.d scripts are run. The files within this hack require no modifications to the existing rc.d scripts.

Sound using pulseaudio is verified to be working. External USB drives using LTSPFS also work. LDM_DIRECTX does *NOT* work for reasons unknown.

To test these hacks, clone the repository on your LTSP master server, adjust the Makefile if necessary (default chroot is /opt/ltsp/i386) and run:

    $ make deploy

Remember to install both ldm and LightDM into the chroot. As this is a hack, *the login user account has to be created to BOTH into the chroot AND ALSO into the server*. PAM uses local accounts to authenticate, later the scripts use the same username to login to remote host. I repeat, *THIS IS A HACK*.

In your server's lts.conf, set this directive to launch LightDM instead of LDM:

	[default]
	SCREEN_07=lightdm
	LDM_SESSION="gnome-session --session=gnome-fallback"
	LDM_DIRECTX=False
	LOCALDEV=True
	SOUND=True
	SOUND_DAEMON=pulse

After these prequisites are valid, rebuild the client image and boot it up.

While hacking the scripts, it is possible to use the "hotdeploy" make target to copy changes to the client, and test them without rebuilding the image. Adjust the client IP in the Makefile and possibly restart affected services.

