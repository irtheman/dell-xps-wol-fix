#!/bin/sh

# first parameter: architecture (e.g. x86_64)
# second parameter: temp folder
# third parameter: requested version
# fourth parameter (optional): file containing additional compilers

if [ $# -lt 3 ]; then
	echo "$(basename $0) requires at least 3 parameters" >&2
	exit 1
fi

arch="$1"
temp="$2"
req="$3"
add="$4"
list="${temp}/available_gcc"

mkdir -p "${temp}"
truncate -s 0 "${list}.unsort"

get_version ()
{
	echo "$1" | sed -n 's|^.* \([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\).*$|\1|p'
}

gccs="$(ls /usr/bin/${arch}*gcc* 2>&1)"
if [ $? -ne 0 ]; then
	gccs="$(ls /usr/bin/*gcc* 2>&1)"
fi

for exe in $gccs;
do
	if [ -f "${exe}" ] && [ ! -L "${exe}" ] && [ -x "${exe}" ]; then
		versionstring="$(${exe} --version | grep 'gcc.*[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}.*$')"
		if [ "${versionstring}" != "" ]; then
			version="$(get_version "${versionstring}" | sed -n 's|\.| |gp')"
			echo "$version ${exe}" >> "${list}.unsort"
		fi
	fi
done

if [ $# -gt 3 ] && [ -f "${add}" ]; then
	for exe in $(cat "${add}")
	do
		if [ -f "${exe}" ] && [ -x "${exe}" ]; then
			versionstring="$(${exe} --version | grep 'gcc.*[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}$')"
			if [ "${versionstring}" != "" ]; then
				version="$(get_version "${versionstring}" | sed -n 's|\.| |gp')"
				echo "$version ${exe}" >> "${list}.unsort"
			fi
		fi
	done
fi

sort -n "${list}.unsort" > "${list}"
rm "${list}.unsort"

i=$(echo "${req}" | grep -c '^[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$')
if [ $i -eq 0 ]; then
	echo "$(basename $0): requested version has to be number.number.number" >&2
	exit 1
fi

req_major=$(echo "${req}" | sed -n 's|^\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$|\1|p')
req_minor=$(echo "${req}" | sed -n 's|^[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}$|\1|p')
req_patch=$(echo "${req}" | sed -n 's|^[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)$|\1|p')

use=""
while read line;
do
	found_major=$(echo "${line}" | sed -n 's|^\([[:digit:]]\{1,\}\) .*|\1|p')
	found_minor=$(echo "${line}" | sed -n 's|^[[:digit:]]\{1,\} \([[:digit:]]\{1,\}\) .*|\1|p')
	found_patch=$(echo "${line}" | sed -n 's|^[[:digit:]]\{1,\} [[:digit:]]\{1,\} \([[:digit:]]\{1,\}\) .*|\1|p')
	use=$(echo "${line}" | sed -n 's|^[[:digit:]]\{1,\} [[:digit:]]\{1,\} [[:digit:]]\{1,\} ||p')
	if [ $found_major -eq $req_major ]; then
		if [ $found_minor -eq $req_minor ]; then
			if [ $found_patch -eq $req_patch ]; then
				break
			elif [ $found_patch -gt $req_patch ]; then
				break
			fi
		elif [ $found_minor -gt $req_minor ]; then
			break
		fi
	elif [ $found_major -gt $req_major ]; then
		break
	fi
done < "${list}"

rm "${list}"

echo "Using ${use} to compile module" >&2
echo "${use}"
