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

# File from which to get list of packages
pfile="./lists/pkglist.txt"

# File from which to get list of ignored packages
ifile="./lists/ignlist.txt"

# File from which to get arch repo packages
afile="./lists/archlist.txt"

case "$1" in
-h) 	
	cat << EOF
Usage:	chkaur [option] 

	chkaur -f  : Default option; takes packages to check from file(s)
	chkaur -o <repo_pkg_name> <aur_pkg_name>  : Check diff pkgname from AUR
	chkaur -a <repo_pkg_name> <arch_pkg_name>  : Check from Arch repo 
	chkaur -c <pkg1> <pkg2> ..  : Check specified packages for updates
	chkaur -i  : Display ignored packages
	chkaur -h  : Display help

Examples:
	
	chkaur -o i-nex i-nex-git
	chkaur -a eudev-systemdcompat systemd
	chkaur -c yaourt downgrade 

EOF
	;;
-i)
	# Display ignored packages from file
	if [ -e $ifile ]; then
		echo -e "\033[1mIgnored: \033[0m"
		for i in $(cat $ifile); do
			# Check for commented out line
			if [ $(echo $i | cut -c 1) == "#" ]; then
				continue  # skip this loop instance
			fi
			echo $i
		done	
	fi
	;;
-c)
	# Check specified packages only
	for ((i=1;i<$#;i++)); do
		in_repo=$(/usr/bin/pacman -Si $i} | grep Version | cut -f 2 -d ":" | cut -c 2-)
		in_aur=$(/usr/bin/package-query -A $i | head -n 1 | cut -f 2 -d " ")
		if [ "$in_repo" == "$in_aur" ]; then
			echo "$i: no change ($in_repo)"
		else
			echo -e "\033[1m $i: \033[0m $in_repo -> $in_aur"
		fi
	done
	;;
-a)
	# First sync arch repo to pacman folder in current directory
	sudo pacman -b ./pacman --config ./pacman/pacman-$(uname -m).conf -Sy
	left=$2
	# Check if additional "other" package is specified
	if [ -n "$3" ]; then
		right="$3"
		in_repo=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
		in_arch=$(/usr/bin/package-query -b ./pacman -S $right | head -n 1 | cut -f 2 -d " ")
	else
		# Check same package in repo and Arch
		in_repo=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
		in_arch=$(/usr/bin/package-query -b ./pacman -S $left | head -n 1 | cut -f 2 -d " ")
	fi
	# Check if changed
	if [ "$in_repo" == "$in_arch" ]; then
		echo "$left: no change ($in_repo)"
	else
		echo -e "\033[1m $left: \033[0m $in_repo -> $in_arch ($right)"
	fi
	;;
*)
	# Check packages in package file for version changes between repo and AUR
	if [ -e $pfile ]; then
		while read p; do
			# Get first (or only) package in current line
			left=$(echo $p | cut -f 1 -d " ")
			
			# Check for commented out line
			if [ $(echo $left | cut -c 1) == "#" ]; then
				continue  # skip this loop instance
			fi
			
			# Check if additional "other" package is specified
			if [ $(echo $p | wc -w) -eq 2 ]; then
				# Check repo package (on left) against AUR package (on right)
				right=$(echo $p | cut -f 2 -d " ")
				in_repo=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
				in_aur=$(/usr/bin/package-query -A $right | head -n 1 | cut -f 2 -d " ")
			else
				# Check same package in repo and AUR
				in_repo=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
				in_aur=$(/usr/bin/package-query -A $left | head -n 1 | cut -f 2 -d " ")
			fi
			
			# Check if changed
			if [ "$in_repo" == "$in_aur" ]; then
				echo "$left: no change ($in_repo)"
			else
				echo -e "\033[1m $left: \033[0m $in_repo -> $in_aur ($right)"
			fi
		
			# Unset the left and right variables so that they can be used correctly in the next loop instance
			unset left right
		done < $pfile
	fi
	
	# Check for package from file in manjaro repo against arch repo package
	if [ -e $afile ]; then
		# First sync Arch repo to pacman folder in current directory
		sudo pacman -b ./pacman --config ./pacman/pacman-$(uname -m).conf -Sy
	
		# Now query arch package from this repo	
		while read p; do
			# Get first (or only) package in current line
			left=$(echo $p | cut -f 1 -d " ")
			
			# Check for commented out line
			if [ $(echo $left | cut -c 1) == "#" ]; then
				continue  # skip this loop instance
			fi
			
			# Check if additional "other" package is specified
			if [ $(echo $p | wc -w) -eq 2 ]; then
				# Check repo package (on left) against Arch package (on right)
				right=$(echo $p | cut -f 2 -d " ")
				in_repo=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
				in_arch=$(/usr/bin/package-query -b ./pacman -S $right | head -n 1 | cut -f 2 -d " ")
			else
				# Check same package in repo and Arch
				in_repo=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
				in_arch=$(/usr/bin/package-query -b ./pacman -S $left | head -n 1 | cut -f 2 -d " ")
			fi
			
			# Check if changed
			if [ "$in_repo" == "$in_arch" ]; then
				echo "$left: no change ($in_repo)"
			else
				echo -e "\033[1m $left: \033[0m $in_repo -> $in_arch ($right)"
			fi
		
			# Unset the left and right variables so that they can be used correctly in the next loop instance
			unset left right
		done < $afile
	fi
	;;
esac
