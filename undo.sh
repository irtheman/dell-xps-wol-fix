#!/bin/sh

script="$(basename "$0")"

user=$(whoami)
if [ "$user" != "root" ]; then
	echo "${script} has to be run as root!" 1>&2
	exit 1
fi

chk="$(which dkms)"
if [ -z $chk ]; then
	echo "${script} requires dkms!" 1>&2
	exit 1
fi

this_name="$(grep '^[^#]*PACKAGE_NAME=' dkms.conf | sed -n 's|.*PACKAGE_NAME=\"||g;s|\"$||g;p')"
this_version="$(grep '^[^#]*PACKAGE_VERSION=' dkms.conf | sed -n 's|.*PACKAGE_VERSION=\"||g;s|\"$||g;p')"
this_module_name="$(grep '^[^#]*BUILT_MODULE_NAME\[0\]=' dkms.conf | sed -n 's|.*BUILT_MODULE_NAME\[0\]=\"||g;s|\"$||g;p')"

installed="$(dkms status | grep "^${this_name}/")"
if [ "${installed}" != "" ]; then
	echo "Found versions of ${this_name} installed"
	echo -n "	shall they all be removed [y/N]? "
	doit="N"
	read doit
	if [ "${doit}" = "y" ] || [ "${doit}" = "Y" ]; then
		i=0
		last=$(echo "${installed}" | wc -l)
		while [ $i -lt $last ]; do
			i=$(expr $i + 1)
			line="$(echo "${installed}" | sed -n "${i}p")"
			remove_version="$(echo "${line}" | sed -n 's|^[^/]*/\([^,]*\),.*$|\1|p')"
			remove_kernel="$(echo "${line}" | sed -n 's|^[^,]*,[[:space:]]*\([^,]*\),.*$|\1|p')"
			remove_arch="$(echo "${line}" | sed -n 's|^[^,]*,[^,]*,[[:space:]]*\([^:]*\):.*$|\1|p')"

			echo "remove ${this_name} ${remove_version} ${remove_kernel} ${remove_arch} ..."
			dkms remove -m "${this_name}" -v "${remove_version}" -k "${remove_kernel}" -a "${remove_arch}"
		done

		rm -rf "/var/lib/dkms/${this_name}"
		echo "Uninstallation of ${this_name} completed."
	else
		echo "Please uninstall all ${this_name} versions manually"
		exit 1
	fi
fi

# remove the update-initramfs hook
if [ -d /etc/initramfs-tools/hooks ] && [ -f /etc/initramfs-tools/hooks/dkms-adder ]; then
	rm /etc/initramfs-tools/hooks/dkms-adder
fi

echo "Current DKMS Status:"
dkms status
