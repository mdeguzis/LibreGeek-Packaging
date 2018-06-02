# SteamOS-Tools-Packaging
Packaging scripts and files for SteamOS-Tools

# Launchpad

## uploading

See process-packages.sh in `/mnt/server_media_y/packaging/ubuntu/` 
It is important to only generate the changes file with -sa so that the binary is not included:

For pbuilder:
```
--debbuildopts -sa
```

Howerver, it seem like this can have issues at times:
https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=867822

See also:
 * https://www.debian.org/doc/manuals/maint-guide/build.en.html#pbuilder
 * https://wiki.debian.org/SourceOnlyUpload

See: http://packaging.ubuntu.com/html/packaging-new-software.html

# Branches
Note that each branch corresponds to a codename of a GNU/Linux distribution. For instance, the main branch, "brewmaster," is for SteamOS "brewmaster."

# Flatpak TODO wishlist

* lgogdownloader
* Plex Media Player
