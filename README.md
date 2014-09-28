Check repo packages for updates against packages in the AUR

## Files used

packagelist.txt: Contains list of packages to be checked for updates

A single line can contain one or 2 packages.

For example, if one wants to check package "downgrade" in repo and AUR, simply
<pre> downgrade </pre>
can be specified in the file.

If one wants to check package "i-nex" in the repo to package "i-nex" from AUR,
<pre> i-nex	i-nex-git </pre>
The above format can be used.

archlist.txt
