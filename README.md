Check repo packages for updates against packages in the AUR.

## Requires

* package-query
* Internet connection for checking AUR packages

## Files used

pkglist.txt: Contains list of packages to be checked for updates

A single line can contain one or two packages.

For example, if one wants to check package "downgrade" in repo and AUR, simply
<pre> downgrade </pre>
can be specified in the file.

If one wants to check package "i-nex" in the repo to package "i-nex-git" from AUR,
<pre> i-nex	i-nex-git </pre>
The above format can be used.

-------------------------------------------------------------------------------

archlist.txt: Contains list of packages to be checked for updates from Arch repo

Like before, a single line can contain one or two packages, with same syntax.

-------------------------------------------------------------------------------

ignlist.txt: Contains list of packages that are ignored for updates

Some packages may be known to have different version in AUR, but are not required to be updated.
Such packages can be put in the ignored list, and may be taken out of it and into the pkglist if required.

This is only informational in nature.
