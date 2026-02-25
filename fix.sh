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

chk="$(which wget)"
if [ -z $chk ]; then
	echo "${script} requires wget!" 1>&2
	exit 1
fi

# Get the kernel and gcc versions from the running kernel
export kernelver=$(uname -r)

if [ ! -d /lib/modules/$kernelver ]; then
	echo "linux headers were not found." 1>&2
	exit 1
fi

if [ "$(which gcc)" = "" ]; then
	echo "gcc is required for building modules" >&2
	exit 1
fi

this_name="$(grep '^[^#]*PACKAGE_NAME=' dkms.conf | sed -n 's|.*PACKAGE_NAME=\"||g;s|\"$||g;p')"
this_version="$(grep '^[^#]*PACKAGE_VERSION=' dkms.conf | sed -n 's|.*PACKAGE_VERSION=\"||g;s|\"$||g;p')"
this_module_name="$(grep '^[^#]*BUILT_MODULE_NAME\[0\]=' dkms.conf | sed -n 's|.*BUILT_MODULE_NAME\[0\]=\"||g;s|\"$||g;p')"

installed="$(dkms status | grep "^${this_name}/")"
if [ "${installed}" != "" ]; then
	echo "Found other versions of ${this_name} installed."
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
		echo "Removal of ${this_name} completed"
	else
		echo "Please uninstall all ${this_name} versions manually"
		exit 1
	fi
fi

which update-initramfs > /dev/null 2>&1
if [ $? -eq 0 ]; then
	if [ -d /etc/initramfs-tools/hooks ]; then
		cp dkms-adder /etc/initramfs-tools/hooks
	else
		echo "/etc/initramfs-tools/hooks doesn't exist so initramfs may fail"
	fi
fi

# Remove the matching source directory
if [ -d "/usr/src/${this_name}-${this_version}" ]; then
	rm -rf "/usr/src/${this_name}-${this_version}"
fi

mkdir "/usr/src/${this_name}-${this_version}"

all_files="$(ls)"
i=0
last=$(echo "${all_files}" | wc -l)
while [ $i -lt $last ]; do
	i=$(expr $i + 1)
	file="$(echo "${all_files}" | sed -n "${i}p")"
	if [ "${file}" != "${script}" ] \
		&& [ "${file}" != "README.md" ] \
		&& [ "${file}" != "dkms-adder" ] \
		&& [ "${file}" != "undo.sh" ] \
		&& [ "${file}" != "kernelsources" ];
	then
		cp --preserve=mode,timestamps -r "${file}" "/usr/src/${this_name}-${this_version}/"
	fi
done

dkms install -m "${this_name}" -v "${this_version}"
if [ $? -eq 0 ]; then
	echo "Installation of ${this_name} version ${this_version} succeeded!"
else
	echo "Failed to install ${this_name} version ${this_version}!"
fi
