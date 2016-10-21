# Imported from Fedora
# Slight modifications made to allow installation on RHEL 7 / CentOS 7+
# https://apps.fedoraproject.org/packages/SDL2-devel

# Note:  SDL_config.h can be found at /usr/include/SDL/SDL_config.h"
#        Package: SDL or SDL-devel

Name:           SDL2
Version:        2.0.3
Release:        7%{?dist}
Summary:        A cross-platform multimedia library
Group:          System Environment/Libraries
URL:            http://www.libsdl.org/
License:        zlib and MIT
Source0:        http://www.libsdl.org/release/%{name}-%{version}.tar.gz
Source1:        SDL_config.h

BuildRequires:  alsa-lib-devel
BuildRequires:  audiofile-devel
BuildRequires:  mesa-libGL-devel
BuildRequires:  mesa-libGLU-devel
BuildRequires:  mesa-libEGL-devel
BuildRequires:  mesa-libGLES-devel
BuildRequires:  libXext-devel
BuildRequires:  libX11-devel
BuildRequires:  libXi-devel
BuildRequires:  libXrandr-devel
BuildRequires:  libXrender-devel
BuildRequires:  dbus-devel
BuildRequires:  libXScrnSaver-devel
BuildRequires:  libusb-devel
BuildRequires:  pulseaudio-libs-devel
BuildRequires:  libXinerama-devel
BuildRequires:  libXcursor-devel
BuildRequires:  systemd-devel

%description
Simple DirectMedia Layer (SDL) is a cross-platform multimedia library designed
to provide fast access to the graphics frame buffer and audio device.

%package devel
Summary:    Files needed to develop Simple DirectMedia Layer applications
Group:      Development/Libraries
Requires:   %{name}%{?_isa} = %{version}-%{release}
Requires:   alsa-lib-devel
Requires:   mesa-libGL-devel
Requires:   mesa-libGLU-devel
Requires:   mesa-libEGL-devel
Requires:   mesa-libGLES-devel
Requires:   libX11-devel
Requires:   libXi-devel
Requires:   libXext-devel
Requires:   libXrandr-devel
Requires:   libXrender-devel
Requires:   libXScrnSaver-devel
Requires:   libXinerama-devel
Requires:   libXcursor-devel
Requires:   systemd-devel

%description devel
Simple DirectMedia Layer (SDL) is a cross-platform multimedia library designed
to provide fast access to the graphics frame buffer and audio device. This
package provides the libraries, include files, and other resources needed for
developing SDL applications.

%prep
%setup -q
# Compilation without ESD
sed -i -e 's/.*AM_PATH_ESD.*//' configure.in
sed -i -e 's/\r//g' TODO.txt README.txt WhatsNew.txt BUGS.txt COPYING.txt CREDITS.txt README-SDL.txt

%build
%configure \
    --enable-sdl-dlopen \
    --disable-arts \
    --disable-esd \
    --disable-nas \
    --enable-pulseaudio-shared \
    --enable-alsa \
    --disable-video-wayland \
    --disable-rpath
make %{?_smp_mflags}

%install
%make_install

# Rename SDL_config.h to SDL_config-<arch>.h to avoid file conflicts on
# multilib systems and install SDL_config.h wrapper
mv %{buildroot}%{_includedir}/SDL2/SDL_config.h %{buildroot}%{_includedir}/SDL2/SDL_config-%{_arch}.h
install -p -m 644 %{SOURCE1} %{buildroot}%{_includedir}/SDL2/SDL_config.h

# remove libtool .la file
rm -f %{buildroot}%{_libdir}/*.la
# remove static .a file
rm -f %{buildroot}%{_libdir}/*.a

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%files
%doc BUGS.txt CREDITS.txt COPYING.txt README-SDL.txt
%{_libdir}/lib*.so.*

%files devel
%doc README.txt TODO.txt WhatsNew.txt
%{_bindir}/*-config
%{_libdir}/lib*.so
%{_libdir}/pkgconfig/sdl2.pc
%{_includedir}/SDL2
%{_datadir}/aclocal/*

%clean
rm -rf %{buildroot}

%changelog
* Thu Oct 20 2016 Michal DeGuzis <mdeguzis@gmail.com> - 2.0.3-7
- Port over to CentOS for personal use
- Removed Wayland support
