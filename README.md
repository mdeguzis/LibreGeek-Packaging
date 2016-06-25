# SteamOS-Tools-Packaging

Packaging scripts and files for SteamOS-Tools

# Links and resources
* [Unofficial packaging tutorial](https://packages.debian.org/jessie/packaging-tutorial)
* [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
* [Debian Developer's Reference](http://www.debian.org/doc/manuals/developers-reference/)
* [Debian Policy](http://www.debian.org/doc/debian-policy/)
* [Binary package How-To](http://tldp.org/HOWTO/html_single/Debian-Binary-Package-Building-HOWTO/)
* [libregeek package stats](http://steamos-tools-stats.libregeek.org)

# Packages built using simple-backport creation

See debian-bacports/ in this repository.

# Working with pbuilder and the SteamOS-Tools beta repo

If you wish to work with the SteamOS-Tools beta repo when building, please set the relevant hook(s) at the top of the build script.

```
STEAMOS_TOOLS_BETA_HOOK="true"
```

# Testing a build inside the temp dirs
This is useful if you want to retest already prepped package files and code

Example
```
sudo build_dir=results_temp STEAMOS_TOOLS_BETA_HOOK="true" DIST="brewmaster" pdebuild
```

Example (full output from pdebuild)
```
sudo build_dir=results_temp STEAMOS_TOOLS_BETA_HOOK="true" DIST="brewmaster" bash -x pdebuild
```

Example (login with options set so you can work inside the chroot)
```
sudo build_dir=results STEAMOS_TOOLS_BETA_HOOK="true" DIST="brewmaster" pbuilder login
bash /tmp/hooks/ tmp/hooks/D10steamos-tools-hook.sh 
```

The reason for this, and the intention, is to keep the chroot as clean as possible. You will also notice, that the [hook script](https://github.com/ProfessorKaos64/SteamOS-Tools-Packaging/blob/brewmaster/setup-files/hooks/D01steamos-tools-hook.sh) will always adds the standard SteamOS-Tools repository configuration, _if_ the pbuilder distribution is brewmaster.

# Other information
See docs/* for more
