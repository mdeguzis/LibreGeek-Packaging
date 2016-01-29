# SteamOS-Tools-Packaging

Packaging scripts and files for SteamOS-Tools

# Links and resources
* [Unofficial packaging tutorial](https://packages.debian.org/jessie/packaging-tutorial)
* [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
* [Debian Developer's Reference](http://www.debian.org/doc/manuals/developers-reference/)
* [Debian Policy](http://www.debian.org/doc/debian-policy/)
* [Binary package How-To](http://tldp.org/HOWTO/html_single/Debian-Binary-Package-Building-HOWTO/)
* [libregeek package stats](http://steamos-tools-stats.libregeek.org)

# Using reprepro
* [Setting up a signed repository (Debian)](https://wiki.debian.org/SettingUpSignedAptRepositoryWithReprepro)
* [Creating a Debian/Ubuntu mirror (What I used initially)](http://www.infrastructureanywhere.com/documentation/additional/mirrors.html)
* [Local corporate APT repositories (Vincent Bernat)](http://vincent.bernat.im/en/blog/2014-local-apt-repositories.html)
* [How to Use Reprepro for a Secure Package Repository (Digital Ocean)](https://www.digitalocean.com/community/tutorials/how-to-use-reprepro-for-a-secure-package-repository-on-ubuntu-14-04)

# How to create and use Makefiles
* [Using make and writing Makefiles (Sourceforge)](http://makepp.sourceforge.net/1.19/makepp_tutorial.html)
* [GNU make manual](https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents)
* [Using phony targets](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html)

# Examples of packages that merely install files
* [php-htmlpurifier](http://packages.debian.org/source/sid/php-htmlpurifier)

# Cmake
* [Cmake official Wiki](https://cmake.org/Wiki/CMake)
* [Getting started with cmake](http://mathnathan.com/2010/07/getting-started-with-cmake/)
* [Cmake - An introduction](http://www.cs.swarthmore.edu/~adanner/tips/cmake.php)
* [Useful variables](https://cmake.org/Wiki/CMake_Useful_Variables#Prefixes.2C_Suffixes_.28Postfixes.29.2C_and_Extensions)

# Cmake vs Make
* [Cmake vs Make (Perpetual Enigma)](http://prateekvjoshi.com/2014/02/01/cmake-vs-make/)

# Patches
* [Applying patches with quilt](https://raphaelhertzog.com/2012/08/08/how-to-use-quilt-to-manage-patches-in-debian-packages/)

# Python
[Debian Python packaging](https://wiki.debian.org/Python/Packaging)

# Unattended upgrades
* Checking for issues: `sudo unattended-upgrade -d`

# Git

Revert a commit:
```
git revert --no-commit 0766c053..HEAD
git commit
```

# Other notes
* Some folders here may be a [sub-module](https://git-scm.com/book/en/v2/Git-Tools-Submodules). If you clone this repository, ensure you add the --recursive option flag. You can also use

```
git pull --recurse-submodules
git submodule update --recursive
```
