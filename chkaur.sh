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

ver="0.2" # Version

# File from which to get list of packages
pfile="./lists/pkglist.txt"

# File from which to get repo packages
rfile="./lists/repolist.txt"

# File from which to get installed repo packages
ufile="./lists/instlist.txt"

# File from which to get arch repo packages
afile="./lists/archlist.txt"

# File from which to get aur packages
ofile="./lists/aurlist.txt"

# File from which to get list of ignored packages
ifile="./lists/ignlist.txt"

editor="/usr/bin/vim" # Editor for viewing/editing package lists.
#editor="/usr/bin/nano" # Alternate editor

# Function to check if dependencies are installed
check_dep () {
	if [ ! -e /usr/bin/package-query ]; then 
		echo "package-query not available. Please install it to run this application" && exit 1
	fi
}
check_net () {
	if [ ! "$(ping -c 1 google.com)" ]; then
		echo "Internet connection not available. Internet access is required to check the AUR" && exit 1
	fi
}

check-file () {
	if [ ! -e "$1" ]; then
		echo "File: $1 does not exist" && exit 1
	fi
}

edit-file () {
	if [ -e $editor ]; then
		$editor $1
	elif [ -e /usr/bin/nano ]; then
		nano $1
	elif [ -e /usr/bin/vim ]; then
		vim $1
	else
		echo "Unable to find editor to edit the $1 file" && exit 1
	fi
}

check-pkg-file () {
	file="$1" # file from which to read packages specified as first argument
	if [ ! -e "$file" ]; then
		echo "Could not find package file $file" && exit 1
	fi
}

query-installed-pkg () {
	pkg="$1" # package is first argument
	installed=$(/usr/bin/pacman -Qi $pkg | grep Version | cut -f 2 -d ":" | cut -c 2-)
}

query-repo-pkg () {
	pkg="$1" # package is first argument
	in_repo=$(/usr/bin/pacman -Si $pkg | grep Version | head -n 1  | cut -f 2 -d ":" | cut -c 2-)
}

query-aur-pkg () {
	pkg="$1" # package is first argument
	in_aur=$(/usr/bin/package-query -A $pkg | head -n 1 | cut -f 2 -d " ")
}

query-arch-repo-pkg () {
	pkg="$1" # package is first argument
	in_arch=$(/usr/bin/package-query -b ./pacman -S $pkg | head -n 1 | cut -f 2 -d " ")
}

# Parse the file specified and set left and right packages
parse-and-set () {
	# Check for empty lines and comments
	if [ -z "$p" ]; then
		return 1
	elif [ "$(echo $p | cut -c 1)" == "#" ]; then
		return 1
	else
		# Get first package in current line
		left=$(echo $p | cut -f 1 -d " ")
		# Get second package in current line
		right=$(echo $p | cut -f 2 -d " ")
		# Check if second package specified
		if [ "$left" == "$right" ]; then
			unset right
		fi
	fi
}

check-update () {
		# Assuming that $pkg1 and $pkg2 have already been set
		if [ "$pkg1" == "$pkg2" ]; then
			echo "$left, $right: no change ($pkg1)"
		else
			echo -e "\033[1m $left: \033[0m $pkg1 -> $pkg2 ($right)"
		fi
}

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
			# Check for blank and commented out lines
			if [ -z "$i" ] || [ "$(echo $i | cut -c 1)" == "#" ]; then
				continue  # skip this loop instance
			fi
			echo $i
		done	
	else
		echo "Could not find ignored file" && exit 1
	fi
	;;
-e)
	if [ -z "$2" ]; then
		echo "File name not entered" && exit 1
	fi
	if [ "$2" == "pkglist" ]; then
		check-file $pfile && edit-file $pfile
	elif [ "$2" == "ignlist" ]; then
		check-file $ifile && edit-file $ifile
	elif [ "$2" == "repolist" ]; then
		check-file $rfile && edit-file $rfile
	elif [ "$2" == "archlist" ]; then
		check-file $afile && edit-file $afile
	elif [ "$2" == "aurlist" ]; then
		check-file $ofile && edit-file $ofile
	else
		echo "Could not understand filename" && exit 1
	fi
	;;
-c)
	# Check specified packages only
	check_dep
	check_net
	# Parse command line arguments
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
	fakeroot pacman --noprogressbar -b ./pacman --config ./pacman/pacman-$(uname -m).conf -Sy
	# Check if package is specified
	if [ -n "$2" ]; then
		query-repo-pkg "$2"
		pkg1="$in_repo"
		# Check if additional "other" package is specified
		if [ -n "$3" ]; then
			query-arch-repo-pkg "$3"
		else
			query-arch-repo-pkg "$2"
		fi
		pkg2="$in_arch"
		check-update
	else
		check-pkg-file $afile
		# Check packages in package file for version changes
		while read p; do
			# Parse the line and get left (and right) package(s)
			parse-and-set || continue
			query-repo-pkg "$left"
			pkg1="$in_repo"
			# Check if additional "other" package is specified
			if [ -n "$right" ]; then
				query-arch-repo-pkg "$right"
			else
				query-arch-repo-pkg "$left"
			fi
			pkg2="$in_arch"
			check-update
			# Unset the variables so that they can be used correctly in the next loop instance
			unset left right pkg1 pkg2
		done < $file
	fi
	;;
-r)
	# Check package in repo against another package in the repo
	if [ -n "$2" ]; then
		left="$2"
		# Check if other package is specified
		if [ -n "$3" ]; then
			right="$3"
		else
			echo "second package not specified" && exit 1	
		fi
		in_repo_p1=$(/usr/bin/pacman -Si $left | grep Version | head -n 1 | cut -f 2 -d ":" | cut -c 2-)
		in_repo_p2=$(/usr/bin/pacman -Si $right | grep Version | head -n 1 | cut -f 2 -d ":" | cut -c 2-)
		# Check if changed
		if [ "$in_repo_p1" == "$in_repo_p2" ]; then
			echo "$left, $right: no change ($in_repo_p1)"
		else
			echo -e "\033[1m $left: \033[0m $in_repo_p1 -> $in_repo_p2 ($right)"
		fi
	else
		check-pkg-file $rfile
		# Check packages in package file for version changes
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
			in_repo_p1=$(/usr/bin/pacman -Si $left | grep Version | head -n 1 | cut -f 2 -d ":" | cut -c 2-)
			in_repo_p2=$(/usr/bin/pacman -Si $right | grep Version | head -n 1 | cut -f 2 -d ":" | cut -c 2-)
			# Check if changed
			if [ "$in_repo_p1" == "$in_repo_p2" ]; then
				echo "$left, $right: no change ($in_repo_p1)"
			else
				echo -e "\033[1m $left: \033[0m $in_repo_p1 -> $in_repo_p2 ($right)"
			fi
			# Unset the left and right variables so that they can be used correctly in the next loop instance
			unset left right
		done < $rfile
	fi
	;;
-o)
	# Check package in AUR against another package in the AUR
	if [ -n "$2" ]; then
		left="$2"
		# Check if other package is specified
		if [ -n "$3" ]; then
			right="$3"
		else
			echo "second package not specified" && exit 1
		fi
		in_aur_p1=$(/usr/bin/package-query -A $left | head -n 1 | cut -f 2 -d " ")
		in_aur_p2=$(/usr/bin/package-query -A $right | head -n 1 | cut -f 2 -d " ")
		# Check if changed
		if [ "$in_aur_p1" == "$in_aur_p2" ]; then
			echo "$left, $right: no change ($in_aur_p1)"
		else
			echo -e "\033[1m $left: \033[0m $in_aur_p1 -> $in_aur_p2 ($right)"
		fi
	else
		check-pkg-file $ofile
		# Check packages in package file for version changes
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
			# Check aur package (on left) against another aur package (on right)
			in_aur_p1=$(/usr/bin/package-query -A $left | head -n 1 | cut -f 2 -d " ")
			in_aur_p2=$(/usr/bin/package-query -A $right | head -n 1 | cut -f 2 -d " ")
			# Check if changed
			if [ "$in_aur_p1" == "$in_aur_p2" ]; then
				echo "$left, $right: no change ($in_aur_p1)"
			else
				echo -e "\033[1m $left: \033[0m $in_aur_p1 -> $in_aur_p2 ($right)"
			fi
			# Unset the left and right variables so that they can be used correctly in the next loop instance
			unset left right
		done < $ofile
	fi
	;;
-u)
	# Check if installed package is specified
	check_dep
	check_net
	if [ -n "$2" ]; then
		# Parse command line arguments
		for i in "$@"; do
			# Skip -u option
			if [ "$i" == "-u" ]; then
				continue
			fi
			# Check package version installed and in AUR
			installed=$(/usr/bin/pacman -Qi $i | grep Version | cut -f 2 -d ":" | cut -c 2-)
			in_aur=$(/usr/bin/package-query -A $i | head -n 1 | cut -f 2 -d " ")
			# Check if changed
			if [ "$installed" == "$in_aur" ]; then
				echo "$i: no change ($installed)"
			else
				echo -e "\033[1m $i: \033[0m $installed -> $in_aur"
			fi
		done
	else
		check-pkg-file $ufile
		# Check packages in package file for version changes between repo and AUR
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
				installed=$(/usr/bin/pacman -Qi $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
				in_aur=$(/usr/bin/package-query -A $right | head -n 1 | cut -f 2 -d " ")
			else
				# Check same package in repo and AUR
				installed=$(/usr/bin/pacman -Qi $left | grep Version | cut -f 2 -d ":" | cut -c 2-)
				in_aur=$(/usr/bin/package-query -A $left | head -n 1 | cut -f 2 -d " ")
			fi
			# Check if changed
				if [ "$installed" == "$in_aur" ]; then
				echo "$left: no change ($installed)"
			else
				echo -e "\033[1m $left: \033[0m $installed -> $in_aur ($right)"
			fi
			# Unset the left and right variables so that they can be used correctly in the next loop instance
			unset left right
		done < $ufile
	fi
	;;
*)
	# Check packages from file for updates from the AUR
	check_dep
	check_net
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
		check-pkg-file $pfile
		# Check packages in package file for version changes between repo and AUR
		while read p; do
			# Get first (or only) package in current line
			left=$(echo $p | cut -f 1 -d " ")
			# Check for commented out line
			if [ "$(echo $left | cut -c 1)" == "#" ]; then
				continue  # skip this loop instance
			fi
			# Check for blank line
			if [ -z "$left" ]; then
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
	;;
esac
