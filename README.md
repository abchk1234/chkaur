Check repo packages for updates against packages in the AUR.

# Requires

* package-query
* Internet connection for checking AUR packages

# Files used

```lists\pkglist.txt```: Contains list of packages to be checked for updates

A single line can contain one or two packages.

For example, if one wants to check package "downgrade" in AUR and repo, simply

~~~~
downgrade
~~~~

can be specified in the file.

If one wants to check package "i-nex-git" in AUR to "i-nex" in the repo,

~~~~
i-nex-git		i-nex
~~~~

The above format can be used.

Blank lines and lines starting with # (comments) are ignored.

-------------------------------------------------------------------------------

```lists\archlist.txt```: Contains list of packages to be checked for updates from a local copy of Arch repo (can be changed).

Like before, a single line can contain one or two packages, with repo pkg on the left and Arch repo (local repo)
package on the right..

# Syntax

~~~~
./chkaur.sh [option] [package(s)]
~~~~

# Examples

~~~~
./chkaur.sh  # Will check packages specified in lists/pkglist.txt (AUR vs repo)

./chkaur.sh -f  # Equivalent to above

./chkaur.sh -f qbittorrent  # Check qbittorrent (AUR vs repo)

./chkaur.sh -f i-nex-git i-nex  # Check i-nex-git in AUR vs i-nex in repo

./chkaur.sh -a  # Check packages in archlist.txt (Repo vs local Arch repo)

./chkaur.sh -a lxdm  # Check lxdm (repo vs local Arch repo)

./chkaur.sh -a lxdm-consolekit lxdm (lxdm-consolekit in repo vs lxdm in Arch)

./chkaur.sh -c yaourt downgrade  # Check multiple packages (AUR vs repo)

./chkaur.sh -e pkglist  # View and edit lists/pkglist.txt

./chkaur.sh -e archlist  # View and edit lists/archlist.txt
~~~~

