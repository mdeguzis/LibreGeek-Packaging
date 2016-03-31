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

#ifneq (,$(filter libqt5sql5-ibase,$(shell dh_listpackages)))
#	extra_configure_opts += -plugin-sql-ibase
#else
extra_configure_opts=("-no-sql-ibase")
#endif

no_pch_architectures="arm64"
ifeq ($(DEB_HOST_ARCH),$(findstring $(DEB_HOST_ARCH), $(no_pch_architectures)))
	extra_configure_opts+=("-no-pch")
endif

gles2_architectures := armel armhf
ifeq ($(DEB_HOST_ARCH),$(findstring $(DEB_HOST_ARCH), $(gles2_architectures)))
	extra_configure_opts+=("-opengl es2")
else
	extra_configure_opts+=("-opengl desktop")
endif

ifneq ($(DEB_HOST_ARCH_OS),linux)
	extra_configure_opts+=("-no-eglfs")
endif

# Compile without sse2 support on i386
# Do not use pre compiled headers in order to be able to rebuild the gui
# submodule.
ifeq ($(DEB_HOST_ARCH_CPU),i386)
	cpu_opt="-no-sse2 -no-pch"
endif

ifeq ($(DEB_HOST_ARCH_OS),linux)
  ifneq (,$(filter $(DEB_HOST_ARCH),alpha ia64 mips64 mips64el arm64))
	platform_arg="linux-g++"
  else ifeq ($(DEB_HOST_ARCH_BITS),64)
	platform_arg="linux-g++-64"
  else
	platform_arg="linux-g++"
  endif
else ifeq ($(DEB_HOST_ARCH_OS),hurd)
	platform_arg="hurd-g++"
else ifeq ($(DEB_HOST_ARCH_OS),kfreebsd)
	platform_arg="gnukfreebsd-g++"
else
	$(error Unknown qmake mkspec for $(DEB_HOST_ARCH_OS))
endif

# Set number of jobs explicitly
NB_CORES=$(grep -c '^processor' /proc/cpuinfo)

%:
	dh $@ --parallel --with pkgkde_symbolshelper

override_dh_auto_configure:
	MAKEFLAGS="-j$((NB_CORES+1)) -l${NB_CORES}" ./configure \
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
			$(extra_configure_opts) \
			$(cpu_opt)
