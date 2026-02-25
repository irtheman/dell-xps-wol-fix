#!/bin/bash

for d in $(ls -d v* | grep -v '_patched$'); do
	diff -upr $d ${d}_patched > ../patches/alx-wol_$d.patch
	chmod 640 ../patches/alx-wol_$d.patch
done
