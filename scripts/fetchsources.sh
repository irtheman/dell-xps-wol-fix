#!/bin/sh

# Fetch and patch the sources defined in sources.txt
# First parameter is directory where sources are installed

install_tree="$1"

log_it()
{
	echo "$*"
}

fetch_sources="$(dirname "$0")/fetch_kernelparts.sh"
patch_sources="$(dirname "$0")/patch_sources.sh"
file_list="${PWD}/.fetched_files"

mf="$install_tree/$kernelver/build/Makefile"
if [ $(grep -c '^\s*VERSION\s*=' $mf) -eq 0 ]; then
	if [ $(grep -c '^\s*include\s\+' $mf) -ne 1 ]; then
		echo "Can not find makefile containing the kernel version" 1>&2
		exit 1
	fi

	mf="$(grep '^\s*include\s\+' $mf)"

	mf="$(echo "$mf" | sed -n 's|^\s*include\s\+||g;p')"
	if [ $(echo "$mf" | grep -c '^/') -ne 1 ]; then
		mf="$install_tree/$kernelver/build/$mf"
	fi

	if [ ! -f "$mf" ]; then
		echo "Bad Makefile, can't work" 1>&2
		exit 1
	fi
fi

version=$(grep '^\s*VERSION\s*=' $mf | sed -n 's|^.*[= ]\(\S\+\)$|\1|g;p')
patchlevel=$(grep '^\s*PATCHLEVEL\s*=' $mf | sed -n 's|^.*[= ]\(\S\+\)$|\1|g;p')
sublevel=$(grep '^\s*SUBLEVEL\s*=' $mf | sed -n 's|^.*[= ]\(\S\+\)$|\1|g;p')
if [ "$version" = "" ] || [ "$patchlevel" = "" ] || [ "$sublevel" = "" ]; then
	echo "Can not detect kernel version information, can't work" 1>&2
	exit 1
fi
kernel_version=$version.$patchlevel.$sublevel

truncate -s 0 "${file_list}"

"${fetch_sources}" "${kernel_version}" "${PWD}/sources.txt" "${PWD}" "${file_list}"
if [ $? -ne 0 ]; then
	log_it "$(basename "${fetch_sources}") failed"
	exit 1
fi

"${patch_sources}" "${kernel_version}" "${PWD}/sources.txt" "${PWD}" "${file_list}"
if [ $? -ne 0 ]; then
	log_it "$(basename "${patch_sources}") failed"
	exit 1
fi
