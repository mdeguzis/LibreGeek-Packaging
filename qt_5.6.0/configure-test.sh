#!/bin/bash

# This assumes we have a "qt5" directory under home that is initialized
# It is only meant for simple checks on configure options

####################################################

DEB_HOST_MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
DEB_HOST_ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)
DEB_HOST_ARCH_OS=$(dpkg-architecture -qDEB_HOST_ARCH_OS)
DEB_HOST_ARCH_BITS=$(dpkg-architecture -qDEB_HOST_ARCH_BITS)
DEB_HOST_ARCH_CPU=$(dpkg-architecture -qDEB_HOST_ARCH_CPU)

export PATH := $(PATH):$(shell pwd)/bin
export CFLAGS := $(shell dpkg-buildflags --get CFLAGS) $(shell dpkg-buildflags --get CPPFLAGS)
export CXXFLAGS := $(shell dpkg-buildflags --get CXXFLAGS) $(shell dpkg-buildflags --get CPPFLAGS)
export LDFLAGS := $(shell dpkg-buildflags --get LDFLAGS) -Wl,--as-needed

# Upstream changelog
upstream_changes := dist/changes-$(shell dpkg-parsechangelog | sed -n 's/^Version: //p' | cut -f1 -d '-' | sed -e 's/+dfsg//' | sed -e 's/+git.*//')
# Distribution vendor
vendor := $(shell dpkg-vendor --query Vendor)

# To easier the files installation according OSes and archs, we create three
# kinds of install files: foo.install-common, foo.install-$DEB_HOST_ARCH and
# foo.install-$DEB_HOST_ARCH_OS. In this case we can fine-tune what we install.
#
# Note that if any foo.install-* file exists and foo.install exist too, the
# later will get overwritten.
#
# I've opened a bug in debhelper to allow this:
# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=703201

# Retrieve packages that have a .install-common file
pkgs_with_common = $(patsubst debian/%.install-common,%,$(wildcard debian/*.install-common))
# Retrieve packages that have a .install-$DEB_HOST_ARCH file
pkgs_with_arch = $(patsubst debian/%.install-$(DEB_HOST_ARCH),%,$(wildcard debian/*.install-$(DEB_HOST_ARCH)))
# Retrieve packages that have a .install-$DEB_HOST_ARCH_OS file
pkgs_with_os = $(patsubst debian/%.install-$(DEB_HOST_ARCH_OS),%,$(wildcard debian/*.install-$(DEB_HOST_ARCH_OS)))


ifneq (,$(filter libqt5sql5-ibase,$(shell dh_listpackages)))
	extra_configure_opts += -plugin-sql-ibase
else
	extra_configure_opts += -no-sql-ibase
endif

no_pch_architectures := arm64
ifeq ($(DEB_HOST_ARCH),$(findstring $(DEB_HOST_ARCH), $(no_pch_architectures)))
	extra_configure_opts += -no-pch
endif

gles2_architectures := armel armhf
ifeq ($(DEB_HOST_ARCH),$(findstring $(DEB_HOST_ARCH), $(gles2_architectures)))
	extra_configure_opts += -opengl es2
else
	extra_configure_opts += -opengl desktop
endif

ifneq ($(DEB_HOST_ARCH_OS),linux)
	extra_configure_opts += -no-eglfs
endif

# Compile without sse2 support on i386
# Do not use pre compiled headers in order to be able to rebuild the gui
# submodule.
ifeq ($(DEB_HOST_ARCH_CPU),i386)
	cpu_opt = -no-sse2 -no-pch
endif

ifeq ($(DEB_HOST_ARCH_OS),linux)
  ifneq (,$(filter $(DEB_HOST_ARCH),alpha ia64 mips64 mips64el arm64))
	platform_arg = linux-g++
  else ifeq ($(DEB_HOST_ARCH_BITS),64)
	platform_arg = linux-g++-64
  else
	platform_arg = linux-g++
  endif
else ifeq ($(DEB_HOST_ARCH_OS),hurd)
	platform_arg = hurd-g++
else ifeq ($(DEB_HOST_ARCH_OS),kfreebsd)
	platform_arg = gnukfreebsd-g++
else
	$(error Unknown qmake mkspec for $(DEB_HOST_ARCH_OS))
endif

ifneq (,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
	NUMJOBS = $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
else
	NUMJOBS = 1
endif

####################################################

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
-plugin-sql-mysql \
-plugin-sql-odbc \
-plugin-sql-psql \
-plugin-sql-sqlite \
-no-sql-sqlite2 \
-plugin-sql-tds \
-system-sqlite \
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
$(extra_configure_opts) \
$(cpu_opt) &> qt-configure-test.log

echo -e "\nReview log?"
read -erp "Choice [y/n]: " choice

if [[ "${choice}" == "y" ]]; then

	less qt-configure-test.log
	
fi

# clean up
rm -f qt-configure-test.log
cd "$currdir"
