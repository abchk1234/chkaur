#!/bin/bash
# chkaur.sh: utility to check updates to repo packages from packages in the AUR
# dependencies: package-query (available in AUR)
##
# Copyright (C) 2014 Aaditya Bagga <aaditya_gnulinux@zoho.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed WITHOUT ANY WARRANTY;
# without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

# List of packages to check
list=('qbittorrent' 'i-nex' 'yaourt' 'pekwm-menu' 'wallpaperd' 'thermald' 'downgrade')

# File from which to get list of packages
pfile="./packagelist.txt"

# Packages which are ignored even if there is change in versions
ignore=('allservers' 'timeset' 'timeset-gui' 'fetter')

# File from which to get list of ignored packages
ifile="./ignoredlist.txt"


case "$1" in
-h) echo "Usage: 
	chkaur [-c,-i,-h]"
	;;
-i)
	# Display ignored packages
	echo -e "\033[1mIgnored: \033[0m"
	for ((i=0;i<${#ignore[@]};i++)); do
		echo ${ignore[$i]}
	done
	
	# Ignored packages in file
	if [ -e $ifile ]; then
		echo -e "\033[1mIgnored: \033[0m"
		for i in $(cat $ifile); do
			echo $i
		done	
	fi
	;;
-c)
	# Check specified packages only
	for ((i=1;i<$#;i++)); do
		in_repo=$(/usr/bin/pacman -Ss ${list[$i]} | head -n 1 | cut -f 2 -d " ")
		in_aur=$(/usr/bin/package-query -A ${list[$i]} | head -n 1 | cut -f 2 -d " ")
		if [ "$in_repo" == "$in_aur" ]; then
			echo "${list[$i]}: no change"
		else
			echo -e "${list[$i]}: \033[1m $in_repo -> $in_aur \033[0m"
		fi
	done
	;;
-a)
	# Check for package in Manjaro repo against Arch repo package

*)
	# Check packages in list for version changes between repo and AUR
	for ((i=0;i<${#list[@]};i++)); do
		in_repo=$(/usr/bin/pacman -Ss ${list[$i]} | head -n 1 | cut -f 2 -d " ")
		in_aur=$(/usr/bin/package-query -A ${list[$i]} | head -n 1 | cut -f 2 -d " ")
		if [ "$in_repo" == "$in_aur" ]; then
			echo "${list[$i]}: no change"
		else
			echo -e "${list[$i]}: \033[1m $in_repo -> $in_aur \033[0m"
		fi
	done
	# Check packages in package file
	if [ -e $pfile ]; then
		for i in $(cat $pfile); do
			# Check if additional "other" package is specified
			if [ $(echo $i) -eq 1 ]; then
				# Check repo package (on left) against AUR package (on right)
				# The packages are assumed to be tab separated
				left=$(echo $i | cut -f 1)
				right=$(echo $i | cut -f 2)
				in_repo=$(/usr/bin/pacman -Ss $left | head -n 1 | cut -f 2 -d " ")
				in_aur=$(/usr/bin/package-query -A $right | head -n 1 | cut -f 2 -d " ")
			else
				in_repo=$(/usr/bin/pacman -Ss $left | head -n 1 | cut -f 2 -d " ")
				in_aur=$(/usr/bin/package-query -A $right | head -n 1 | cut -f 2 -d " ")
			fi
			# Check if changed
			if [ "$in_repo" == "$in_aur" ]; then
				echo "$i: no change"
			else
				echo -e "$i: \033[1m $in_repo -> $in_aur \033[0m"
			fi
		done
	fi
	;;
esac
