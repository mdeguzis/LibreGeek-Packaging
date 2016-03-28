# About

Some info about the build work in progress to get Qt 5.6.0 into SteamOS brewmaster. This is mainly for building PlexMediaPlayer.
The debian/ files were sourced from the [Debian Stretch](https://packages.debian.org/sid/qt5-default) set of files. From there, 
these have been tweaked a little to allow building on SteamOS brewmaster (with Jessie/Jessie-Backports enabled).

# Build status

Status: **[WIP]**

# Disabled configure options

Checking a build log, there two are added at the end via $(extra_configure_opts) (normally determined via dh/shell checks).

```
-plugin-sql-ibase
-opengl desktop
```

Currently disabled options from upstream Debian experimental debian/rules:

```
-plugin-sql-mysql
-plugin-sql-odbc
-plugin-sql-psql
-plugin-sql-sqlite
-no-sql-sqlite2
-plugin-sql-tds
-system-sqlite
-plugin-sql-ibase
```

Taken out because the jessie/jessie-backport version is too old

```
-system-harfbuzz
```

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
