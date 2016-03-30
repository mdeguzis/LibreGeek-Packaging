# About

Some info about the build work in progress to get Qt 5.6.0 into SteamOS brewmaster. This is mainly for building PlexMediaPlayer.
The debian/ files were sourced from the [Debian Stretch](https://packages.debian.org/sid/qt5-default) set of files. From there, 
these have been tweaked a little to allow building on SteamOS brewmaster (with Jessie/Jessie-Backports enabled).

Please see [configure-test.sh](https://github.com/ProfessorKaos64/LibreGeek-Packaging/blob/brewmaster/qt_5.6.0/configure-test.sh)

The "debian_experimental" folder is for work on trying to build the individual packages of Qt 5.6.0+. The debian folder present installs everything made during the install. Once more is known about the build process, the experimental set can possibly be fixed up.

# Build status

Main package: **[WIP]**  
Experimental Status: **[WIP]**

# Configure options sourced in debian/rules via conditional statements

Checking a build log, there two are added at the end via $(extra_configure_opts) (normally determined via dh/shell checks).

```
-plugin-sql-ibase
-opengl desktop
```

# Configure options currently disabled

Currently disabled options from upstream Debian experimental debian/rules:

```
-plugin-sql-ibase
```
There are issues finding `sqlcli.h` for this piece.

Taken out because the jessie/jessie-backport version is too old

```
-system-harfbuzz
```

# Disabled installs

These installs are currently removed. Perhaps when the issues are resolved in building, they can be added back. This could maybe
occuren when a debian/ file set surfaces under Stretch for 5.6.0~.

# Build order notes (from README.source)

Bootstrapping the docs packages
-------------------------------

In Qt 5.6 the qdoc tool was moved to qttools source, so qtbase got a
Build-Depends-Indep on qttools5-dev-tools. Thus you need to do the following
steps if you want to rebuild the whole Qt stack from scratch:

* Build only arch-dependent packages from these sources:
  - qtbase-opensource-src
  - qtxmlpatterns-opensource-src
  - qtdeclarative-opensource-src
  - qtwebkit-opensource-src
  - qtdeclarative-opensource-src
* Build the arch-independent packages (-doc and -doc-html) of the above sources.
* Build the rest of the Qt stack in the usual way.

Note: the docs packages should not be a problem when bootstrapping a new
Debian architecture, because the arch-independent packages are already available
in Debian archive.
