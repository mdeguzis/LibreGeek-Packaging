#!/bin/bash

# This assumes we have a "qt5" directory under home that is initialized
# It is only meant for simple checks on configure options

####################################################

DEB_HOST_MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
DEB_HOST_ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)
DEB_HOST_ARCH_OS=$(dpkg-architecture -qDEB_HOST_ARCH_OS)
DEB_HOST_ARCH_BITS=$(dpkg-architecture -qDEB_HOST_ARCH_BITS)
DEB_HOST_ARCH_CPU=$(dpkg-architecture -qDEB_HOST_ARCH_CPU)

platform_arg="linux-g++-64"

# Checking a build log, there two are added at the end via $(extra_configure_opts)
# (normally determined via dh/shell checks)

#-plugin-sql-ibase \
#-opengl desktop

# Currently disabled options from upstream Debian experimental debian/rules:
#-plugin-sql-mysql \
#-plugin-sql-odbc \
#-plugin-sql-psql \
#-plugin-sql-sqlite \
#-no-sql-sqlite2 \
#-plugin-sql-tds \
#-system-sqlite \
#-plugin-sql-ibase \

qtdir="$HOME/qt5"
currdir="${PWD}"

if [[ -d "${qtdir}" ]]; then

	cd $HOME/qt5
	./init-repository
	
else

	echo "Error! - $qtdir not found!"
	exit 1
	
fi

./configure \
-confirm-license \
-prefix "/usr" \
-bindir "/usr/lib/$DEB_HOST_MULTIARCH/qt5/bin" \
-libdir "/usr/lib/$DEB_HOST_MULTIARCH" \
-docdir "/usr/share/qt5/doc" \
-headerdir "/usr/include/$DEB_HOST_MULTIARCH/qt5" \
-datadir "/usr/share/qt5" \
-archdatadir "/usr/lib/$DEB_HOST_MULTIARCH/qt5" \
-hostdatadir "/usr/share/qt5" \
-plugindir "/usr/lib/$DEB_HOST_MULTIARCH/qt5/plugins" \
-importdir "/usr/lib/$DEB_HOST_MULTIARCH/qt5/imports" \
-translationdir "/usr/share/qt5/translations" \
-hostdatadir "/usr/lib/$DEB_HOST_MULTIARCH/qt5" \
-sysconfdir "/etc/xdg" \
-examplesdir "/usr/lib/$DEB_HOST_MULTIARCH/qt5/examples" \
-opensource \
-platform $platform_arg \
-system-harfbuzz \
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
-nomake examples \
-nomake tests \
-qpa xcb \
-xcb \
-glib \
-icu \
-accessibility \
-compile-examples \
-no-directfb \
-gstreamer 1.0 \
-opengl desktop \
-no-sql-ibase

echo -e "\nReview log?"
read -erp "Choice [y/n]: " choice

if [[ "${choice}" == "y" ]]; then

	less qt-configure-test.log
	
fi

# clean up
rm -f qt-configure-test.log
cd "$currdir"
