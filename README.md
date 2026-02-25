# ALX-WOL

On my Dell XPS running Ubuntu 24.04, the Wake On Lan (WOL) would not work. The NIC would not stay on. Apparently, few have bothered thinking about drivers outside of Microsoft. The driver for the Qualcomm Atheros Killer E2400 Gigabit Ethernet Controller is incomplete so I have tried to fix it on my 4 computers.

If someone is thinking of using this then please be cautious as my computers are all Dell XPS running Ubuntu 24.04 so there are no guarantees that this will help you at all.

## Reminder of how to use this...
- Verify sources.txt
- Verify dkms.conf
- Use apt to update and upgrade
- Install dkms just in case it might not be there though unlikely
- Use sudo to run **./fix.sh**
- This can be undone by using sudo to run **./undo.sh**

## Notes
If the end result of running **./undo.sh** shows any alx-wol packages then run this...
```bash
sudo rm -rf /var/lib/dkms/alx-wol/3.1
sudo rm -rf /usr/src/alx-wol-3.1
```

### dkms.conf configuration

- **PACKAGE_NAME** has to be filled with the name to use in dkms.
- **PACKAGE_VERSION** is the version number of the dkms package.
- **BUILT_MODULE_NAME[0]** is the name of the module to build.
- **BUILT_MODULE_LOCATION[0]** is the path where the module is located after being compiled.
- **DEST_MODULE_NAME[0]** should be the same as BUILT_MODULE_NAME[0].
- **DEST_MODULE_LOCATION[0]** is the location where the original module is located.

### sources.txt

For every new kernel version, add the newest at the end based on the previous entries.
