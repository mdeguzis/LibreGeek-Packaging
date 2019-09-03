%global gittag 4.8

Name:           mrboom
Version:       	%{gittag} 
Release:        1%{?dist}
Summary:        Mr.Boom is a Bomberman clone for the RetroArch platform and was converted from DOS assembly using asm2c. 

License:        MIT 
URL:           	https://github.com/Javanaise/mrboom-libretro 
Source0:       	https://github.com/Javanaise/mrboom-libretro/archive/%{gittag}/%{name}-%{version}.tar.gz 

BuildRequires:  SDL2-devel 
BuildRequires:  SDL2_mixer-devel
BuildRequires:  minizip-devel 
BuildRequires:  libmodplug-devel 
# Must install this sepearately.. look for upstream repo.
# Installed via Makefile
#BuildRequires:  libopenmpt-modplug-devel

# What are the actual run-time requirements
#Requires:       

%description
Mr.Boom is a Bomberman clone for the RetroArch platform 
and was converted from DOS assembly using asm2c.

It runs on all RetroArch platforms: Android, Linux, 
Mac OS X, Nintendo Gamecube (NGC), Nintendo Switch, 
Nintendo Wii, Raspberry Pi, Sony Playstation 3 (PS3),
Sony Playstation Portable (PSP), Windows, Xbox, Xbox360...

It can also be compiled as a stand-alone version using SDL2.

%prep
#setup -q
# Tar archive folder has a different name that the package
tar xzf %{_sourcedir}/%{name}-%{version}.tar.gz -C %{_topdir}/BUILD

%build
cd %{name}*
%{__make} clean
%{__make} mrboom LIBSDL2=1

%install
rm -rf $RPM_BUILD_ROOT
cd %{name}*
%make_install MANDIR=/share/man/man6 LIBSDL2=1 PREFIX=/usr

%files
%doc
/usr/bin/mrboom
/usr/share/man/man6/mrboom.6.gz

%changelog
