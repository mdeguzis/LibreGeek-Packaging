#!/bin/sh

# This assumes we have a "qt5" directory under home that is initialized
# It is only meant for simple checks on configure options

TOP="${PWD}"

cd $HOME/build-qtbase-opensource-src-temp/qtbase-opensource-src-* || exit 1

####################################################
# Passes as of 20160328 commit 26bb70d
####################################################

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

DEB_HOST_MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
DEB_HOST_ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)
DEB_HOST_ARCH_OS=$(dpkg-architecture -qDEB_HOST_ARCH_OS)
DEB_HOST_ARCH_BITS=$(dpkg-architecture -qDEB_HOST_ARCH_BITS)
DEB_HOST_ARCH_CPU=$(dpkg-architecture -qDEB_HOST_ARCH_CPU)

platform_arg="linux-g++-64"

# Set number of jobs explicitly
NB_CORES=$(grep -c '^processor' /proc/cpuinfo)


./configure \
	-confirm-license \
	-prefix "/usr" \
	-bindir "/usr/lib/$(DEB_HOST_MULTIARCH)/qt5/bin" \
	-libdir "/usr/lib/$(DEB_HOST_MULTIARCH)" \
	-docdir "/usr/share/qt5/doc" \
	-headerdir "/usr/include/$(DEB_HOST_MULTIARCH)/qt5" \
	-datadir "/usr/share/qt5" \
	-archdatadir "/usr/lib/$(DEB_HOST_MULTIARCH)/qt5" \
	-hostdatadir "/usr/share/qt5" \
	-plugindir "/usr/lib/$(DEB_HOST_MULTIARCH)/qt5/plugins" \
	-importdir "/usr/lib/$(DEB_HOST_MULTIARCH)/qt5/imports" \
	-translationdir "/usr/share/qt5/translations" \
	-hostdatadir "/usr/lib/$(DEB_HOST_MULTIARCH)/qt5" \
	-sysconfdir "/etc/xdg" \
	-examplesdir "/usr/lib/$(DEB_HOST_MULTIARCH)/qt5/examples" \
	-opensource \
	-system-sqlite \
	-platform $(platform_arg) \
	-plugin-sql-mysql
	-plugin-sql-odbc
	-plugin-sql-psql
	-plugin-sql-sqlite
	-no-sql-sqlite2
	-plugin-sql-tds
	-system-zlib \
	-system-libpng \
	-system-libjpeg \
	-openssl \
	-no-rpath \
	-verbose \
	-optimized-qmake \
	-dbus-linked \
	-no-strip \
	-no-separate-debug-info \
	-qpa xcb \
	-xcb \
	-glib \
	-icu \
	-accessibility \
	-compile-examples \
	-no-directfb \
	-gstreamer 1.0 \
	-no-sql-ibase -no-eglfs -opengl desktop \
	$(cpu_opt)

# Retrun to top dir
cd "${TOP}"
