# SteamOS-Tools-Packaging

Packaging scripts and files for SteamOS-Tools

# Links and resources
* [Unofficial packaging tutorial](https://packages.debian.org/jessie/packaging-tutorial)
* [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
* [Debian Developer's Reference](http://www.debian.org/doc/manuals/developers-reference/)
* [Debian Policy](http://www.debian.org/doc/debian-policy/)
* [Binary package How-To](http://tldp.org/HOWTO/html_single/Debian-Binary-Package-Building-HOWTO/)
* [libregeek package stats](http://steamos-tools-stats.libregeek.org)

# Working with pbuilder and the SteamOS-Tools beta repo

If you wish to work with the SteamOS-Tools beta repo when building, please set the relevant hook(s) at the top of the build script.

```
STEAMOS_TOOLS_BETA_HOOK="true"
```

The reason for this, and the intention, is to keep the chroot as clean as possible. You will also notice, that the [hook script](https://github.com/ProfessorKaos64/SteamOS-Tools-Packaging/blob/brewmaster/setup-files/hooks/D01steamos-tools-hook.sh) will always adds the standard SteamOS-Tools repository configuration, _if_ the pbuilder distribution is brewmaster.

# Other information
See docs/* for more
