#!/bin/sh

# this script handles the initrd creation
# $1: kernel version to handle
# $2: install or remove
# $3: complete path of original module
# $4: complete path of new module

kernelver="$1"
what="$2"
orig_location="$3"
new_location="$4"

i="$(grep '^[[:space:]]*BUILT_MODULE_NAME[[:space:]]*\[[0-9]\{1,\}\][[:space:]]*=' dkms.conf)"
all_names="$(echo "$i" | sed -n 's|^[^"]*"\([^"]*\).*$|\1|gp')"
running="$(uname -r)"

if [ "${running}" = "${kernelver}" ]; then
	cur=0
	end=$(echo "$all_names" | wc -l)
	while [ $cur -lt $end ];
	do
		cur=$(expr $cur + 1)
		name="$(echo "$all_names" | sed -n "${cur}p")"
		active=$(lsmod | grep -c "${name}")

		if [ $active -ne 0 ]; then
			rmmod "$name"

			if [ "${what}" = "install" ]; then
				module="$new_location"
			else
				module="$orig_location"
			fi

			module="$(find $module -name ${name}.*)"
			insmod "${module}"
		fi
	done
fi

depmod "${kernelver}"

which dracut > /dev/null 2>&1
if [ $? -eq 0 ]; then
	dracut --force ${kernelver}
else
	which update-initramfs > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		update-initramfs -u -k "${kernelver}"
	else
		mkinitcpio -P -k "${kernelver}"
	fi
fi

exit $?
