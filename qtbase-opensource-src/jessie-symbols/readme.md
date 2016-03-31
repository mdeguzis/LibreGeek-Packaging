# WARNING!

Please advise the below notes are "right" for doing a backport of this package. It is highly urged you read throughly through the "Working with symbols files" link below for complete information.

# Notes

* [Working with symbols files](http://pkg-kde.alioth.debian.org/symbolfiles.html)
* [Pool for qtbase](ftp://ftp.debian.org/debian/pool/main/q/qtbase-opensource-src/)
 * File: "qtbase-opensource-src_5.3.2+dfsg-4.debian.tar.xz"

# How-To:

1. Import the target (in this case Jessie for the backport) symbols into debian/
2. Attempt the build
3. Take the buildlog and run it thru the utility below (assuming log .build with pbuilder):

One libary
```
pkgkde-symbolshelper patch -p LIB_PKG_NAME -v 5.6.0 < $HOME/build-qtbase-opensource-src/qtbase*.build
```

A batch:
```
pkgkde-symbolshelper batchpatch -v 5.6.0 $HOME/build-qtbase-opensource-src/qtbase*.build
```

List of libs packages:

```
libqt5concurrent5
libqt5core5a
libqt5dbus5
libqt5gui5
libqt5network5
libqt5opengl5
libqt5printsupport5
libqt5sql5
libqt5test5
libqt5widgets5
libqt5xml5
```
