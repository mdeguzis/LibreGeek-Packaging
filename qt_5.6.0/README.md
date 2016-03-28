# About

Some info about the build work in progress to get Qt 5.6.0 into SteamOS brewmaster. This is mainly for building PlexMediaPlayer.
The debian/ files were sourced from the [Debian Stretch](https://packages.debian.org/sid/qt5-default) set of files. From there, 
these have been tweaked a little to allow building on SteamOS brewmaster (with Jessie/Jessie-Backports enabled).

# Build status

Status: **[[WIP]]**

# Disabled confiugre options

# Disabled installs

These installs are currently removed. Perhaps when the issues are resolved in building, they can be added back. This could maybe
occuren when a debian/ file set surfaces under Stretch for 5.6.0~.

## libqt5sql

* Error boils down to inability to find sqlcli.h. 
* TODO - upload failed build log to Gist.

libqt5sql5-ibase.install
libqt5sql5-mysql.install
libqt5sql5-odbc.install
libqt5sql5-psql.install
libqt5sql5-sqlite.install
libqt5sql5-tds.install
libqt5sql5.install
libqt5sql5.lintian-overrides
libqt5sql5.symbols
