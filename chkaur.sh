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

# File from which to get repo packages
rfile="./lists/repolist.txt"

# File from which to get arch repo packages
afile="./lists/archlist.txt"

# File from which to get list of ignored packages
ifile="./lists/ignlist.txt"

case "$1" in
-h) 	
	cat << EOF
Usage:	chkaur [option] 

chkaur -f [<repo_pkgname> <aur_pkgname>]  : Check repo package against AUR
chkaur -r [<repo_pkg1> <repo_pkg2>]  : Check one repo package against another
chkaur -a [<repo_pkg_name>] [<arch_pkg_name>]  : Check from Arch repo 
chkaur -c <pkg1> <pkg2> ..  : Check specified packages for updates
chkaur -i  : Display ignored packages
chkaur -h  : Display help

Examples:
	
chkaur	# Equivalent to chkaur -f
chkaur -f  # Will take packages to check (repo to AUR) from pkglist file
chkaur -f octopi  # Compare version of package octopi in repo and AUR
chkaur -f i-nex i-nex-git  # Compare i-nex from repo to i-nex-git in AUR
chkaur -r  # Take repo packages to check against each other from file 
chkaur -r eudev-systemdcompat systemd  # Compare both repo packages
chkaur -a  # Will take packages to check (repo to Arch repo) from archlist file
chkaur -a xorg-server  # Check xorg-server version in repo to Arch repo
chkaur -a eudev-systemdcompat systemd  # Compare pkg1 in repo to pkg2 in Arch
chkaur -c yaourt downgrade  # Check repo packages to those in AUR

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
	else
		echo "Could not find ignored file" && exit 1
	fi
	;;
-c)
	# Check specified packages only
	for i in "$@"; do
		# Skip -c option
		if [ "$i" == "-c" ]; then
			continue
		fi
		# Check package version in repo and AUR
		in_repo=$(/usr/bin/pacman -Si $i | grep Version | cut -f 2 -d ":" | cut -c 2-)
		in_aur=$(/usr/bin/package-query -A $i | head -n 1 | cut -f 2 -d " ")
		# Check if changed
		if [ "$in_repo" == "$in_aur" ]; then
			echo "$i: no change ($in_repo)"
		else
			echo -e "\033[1m $i: \033[0m $in_repo -> $in_aur"
		fi
	done
	;;
-a)
	# First sync arch repo to pacman folder in current directory
	fakeroot pacman -b ./pacman --config ./pacman/pacman-$(uname -m).conf -Sy
	# Check if package is specified
	if [ -n "$2" ]; then
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
	else
		# Check for package from file in manjaro repo against arch repo package
		if [ -e $afile ]; then
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
		else
			echo "Could not find package file" && exit 1
		fi
	fi
	;;
-r)
	if [ -n "$2" ]; then
		left="$2"
		# Check if other package is specified
		if [ -n "$3" ]; then
			right="$3"
		else
			echo "second package not specified" && exit 1	
		fi
		in_repo_p1=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
		in_repo_p2=$(/usr/bin/pacman -Si $right | grep Version | cut -f 2 -d ":" | cut -c 2-)
		# Check if changed
		if [ "$in_repo_p1" == "$in_repo_p2" ]; then
			echo "$left, $right: no change ($in_repo_p1)"
		else
			echo -e "\033[1m $left: \033[0m $in_repo_p1 -> $in_repo_p2 ($right)"
		fi
	else
		# Check packages in package file for version changes
		if [ -e $rfile ]; then
			while read p; do
				# Get first package in current line
				left=$(echo $p | cut -f 1 -d " ")
				# Check for commented out line
				if [ $(echo $left | cut -c 1) == "#" ]; then
					continue  # skip this loop instance
				fi
				# Get second package in current line
				right=$(echo $p | cut -f 2 -d " ")
				# Check if second package specified
				if [ "$left" == "$right" ]; then
					echo "$left: second package not specified" && continue
				fi		
				# Check repo package (on left) against repo package (on right)
				in_repo_p1=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
				in_repo_p2=$(/usr/bin/pacman -Si $right | grep Version | cut -f 2 -d ":" | cut -c 2-)
				# Check if changed
				if [ "$in_repo_p1" == "$in_repo_p2" ]; then
					echo "$left, $right: no change ($in_repo_p1)"
				else
					echo -e "\033[1m $left: \033[0m $in_repo_p1 -> $in_repo_p2 ($right)"
				fi
				# Unset the left and right variables so that they can be used correctly in the next loop instance
				unset left right
			done < $rfile
		else
			echo "Could not find package file" && exit 1
		fi
	fi
	;;
*)
	# Check if package is specified
	if [ -n "$2" ]; then
		left="$2"
		# Check if other package is specified
		if [ -n "$3" ]; then
			right="$3"
			in_repo=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
			in_aur=$(/usr/bin/package-query -A $right | head -n 1 | cut -f 2 -d " ")
		else
			# Check same package in repo and Arch
			in_repo=$(/usr/bin/pacman -Si $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
			in_arch=$(/usr/bin/package-query -b ./pacman -S $left | head -n 1 | cut -f 2 -d " ")
		fi
		# Check if changed
		if [ "$in_repo" == "$in_aur" ]; then
			echo "$left: no change ($in_repo)"
		else
			echo -e "\033[1m $left: \033[0m $in_repo -> $in_aur ($right)"
		fi
	else
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
		else
			echo "Could not find package file" && exit 1
		fi
	fi
	;;
esac
