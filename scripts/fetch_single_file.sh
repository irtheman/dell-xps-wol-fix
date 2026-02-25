#!/bin/sh

# Fetch a single kernel source file
# first parameter:  file to fetch, path in kernel sources
# second parameter: store the file here
# third parameter:  log the fetch in this file
# environment kernver has to be set with the digits of the kernel version as 'x.y' or 'x.y.z'

file="$1"
store="$2"
got_files="$3"

dir=$(dirname "${store}")
if [ ! -d "${dir}" ]; then
	mkdir -p "${dir}"
	if [ $? -ne 0 ]; then
		exit 1
	fi
fi

if [ -d "${store}" ]; then
	rm -rf "${store}"
fi

ldv="v$(echo ${kernver} | sed -n 's|^\([0-9]\{1,\}\.[0-9]\{1,\}\)\.0$|\1|;p')"

wget -nv -O "${store}" https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/${file}?h=${ldv}
if [ $? -ne 0 ]; then
	rm "${store}"
	exit 1
fi

echo "${file}" | sed -n "s|^${kerneldir}/||p" >> "${got_files}"

exit 0
