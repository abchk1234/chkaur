#!/bin/bash
# chkaur.sh: utility to check updates to repo packages from packages in the AUR
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
# dependencies: package-query (available in AUR)

ver="0.3" # Version

# File from which to get list of packages
pfile="./lists/pkglist.txt"

# File from which to get arch repo packages
afile="./lists/archlist.txt"

editor="/usr/bin/vim" # Editor for viewing/editing package lists.
#editor="/usr/bin/nano" # Alternate editor

#----------------------------------------------------------------#

# A note about the program architecture
# To allow code reusability, program is split into functions;
# however as strings cannot be returned from functions,
# so variables are set/unset.
# This can a little tricky to track.

# The common varibles that are set/unset in this way are:
# left, right, pkg1, pkg2, out_pkg

# Function to check if dependencies are installed
check_dep () {
	if [ ! -e /usr/bin/package-query ]; then 
		echo "package-query not available. Please install it to run this application" && exit 1
	fi
}

# Check for working internet connection
check_net () {
	if [ ! "$(ping -c 1 google.com)" ]; then
		echo "Internet connection not available. Internet access is required for it to function" && exit 1
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

query-pkg () {
	ptype="$1" # type (repo, aur, local) is first argument
	pkg="$2"   # package is second argument

	if   [ "$ptype" == "repo" ]; then
		out_pkg=$(pacman -Si $pkg | grep Version | head -n 1  | cut -f 2 -d ":" | cut -c 2-)
	elif [ "$ptype" == "aur" ]; then
		out_pkg=$(package-query -A $pkg | head -n 1 | cut -f 2 -d " ")
	elif [ "$ptype" == "local" ]; then
		out_pkg=$(package-query -b ./repo -S $pkg | head -n 1 | cut -f 2 -d " ")
	else
		echo "invalid search type" && exit 1
	fi
}

# Parse the file specified and set left and right package variables
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
			# right package not specified
			unset right
		fi
	fi
}

check-update () {
		# Assuming that $pkg1 and $pkg2 have already been set
		if [ "$pkg1" == "$pkg2" ]; then
			printf "%-25s \t no change \t (%s)\n" "$left" "$pkg1"
		else
			printf "\033[1m%-23s \033[0m %s -> %s \t (%s)\n" "$left" "$pkg1" "$pkg2" "$right"
		fi
}

case "$1" in
-h) 	
	cat << EOF
Usage:	chkaur [option] 

chkaur -f [<aur_pkgname> <repo_pkgname>]  # Check AUR pkg against repo package
chkaur -a [<repo_pkg_name>] [<arch_pkg_name>]  # Check from Arch repo 
chkaur -c <pkg1> <pkg2> ..  # Check specified packages for updates
chkaur -e pkglist  # View and edit lists/pkglist.txt
chkaur -e archlist  # View and edit lists/archlist.txt
chkaur -h  # Display help

Examples:
	
chkaur	# Equivalent to chkaur -f
chkaur -f  # Will take packages to check (repo to AUR) from pkglist file
chkaur -f octopi  # Compare version of package octopi in repo and AUR
chkaur -f i-nex-git i-nex  # Compare i-nex from repo to i-nex-git in AUR
chkaur -a  # Will take packages to check (repo to Arch repo) from archlist file
chkaur -a xorg-server  # Check xorg-server version in repo to Arch repo
chkaur -a eudev-systemdcompat systemd  # Compare pkg1 in repo to pkg2 in Arch
chkaur -c yaourt downgrade  # Check repo packages to those in AUR
EOF
	;;
-e)
	if [ -z "$2" ]; then
		echo "File name not entered" && exit 1
	fi
	if   [ "$2" == "pkglist" ]; then
		check-file $pfile && edit-file $pfile
	elif [ "$2" == "archlist" ]; then
		check-file $afile && edit-file $afile
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
		left="$i" # necessary to get name of package in output
		query-pkg 'repo' "$i"
		pkg1="$out_pkg"
		query-pkg 'aur' "$i"
		pkg2="$out_pkg"
		# Check if changed
		check-update
		# Unset the variables so that they can be used correctly in the next loop instance
		unset left right pkg1 pkg2
	done
	;;
-a)
	check_dep
	check_net
	# First sync arch repo to pacman folder in current directory
	fakeroot pacman --noprogressbar -b ./repo --config ./repo/pacman-$(uname -m).conf -Sy
	# Check if package is specified
	if [ -n "$2" ]; then
		left="$2" # Required for package name in output
		query-pkg 'repo' "$2"
		pkg1="$out_pkg"
		# Check if additional "other" package is specified
		if [ -n "$3" ]; then
			right="$3" # Required for package name in output
			query-pkg 'local' "$3"
		else
			query-pkg 'local' "$2"
		fi
		pkg2="$out_pkg"
		check-update
	else
		check-pkg-file $afile
		# Check packages in package file for version changes
		while read p; do
			# Parse the line and get left (and right) package(s)
			parse-and-set || continue
			query-pkg 'repo' "$left"
			pkg1="$out_pkg"
			# Check if additional "other" package is specified
			if [ -n "$right" ]; then
				query-pkg 'local' "$right"
			else
				query-pkg 'local' "$left"
			fi
			pkg2="$out_pkg"
			check-update
			# Unset the variables so that they can be used correctly in the next loop instance
			unset left right pkg1 pkg2
		done < $afile
	fi
	;;
*)
	# Check packages from file for updates from the AUR
	check_dep
	check_net
	# Check if package is specified
	if [ -n "$2" ]; then
		left="$2" # Required for package name in output
		query-pkg 'aur' "$2"
		pkg1="$out_pkg"
		# Check if additional "other" package is specified
		if [ -n "$3" ]; then
			right="$3" # Required for package name in output
			query-pkg 'repo' "$3"
		else
			query-pkg 'repo' "$2"
		fi
		pkg2="$out_pkg"
		# Check if changed
		check-update
	else
		check-pkg-file $pfile
		# Check packages in package file for version changes between repo and AUR
		while read p; do
			# Parse the line and get left (and right) package(s)
			parse-and-set || continue
			query-pkg 'aur' "$left"
			pkg1="$out_pkg"
			# Check if additional "other" package is specified
			if [ -n "$right" ]; then
				query-pkg 'repo' "$right"
			else
				query-pkg 'repo' "$left"
			fi
			pkg2="$out_pkg"
			check-update
			# Unset the variables so that they can be used correctly in the next loop instance
			unset left right pkg1 pkg2
		done < $pfile
	fi
	;;
esac

# Done
exit 0
