Check repo packages for updates against packages in the AUR.

## Requires

* package-query
* Internet connection for checking AUR packages

## Files used

pkglist.txt: Contains list of packages to be checked for updates

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

archlist.txt: Contains list of packages to be checked for updates from a local copy of Arch repo (can be changed).

Like before, a single line can contain one or two packages, with repo pkg on the left and Arch repo (local repo)
package on the right..

-------------------------------------------------------------------------------

ignlist.txt: Contains list of packages that are ignored for updates

Some packages may be known to have different version in AUR, but are not required to be updated.
Such packages can be put in the ignored list, and may be taken out of it and into the pkglist if required.

This is only informational in nature.

