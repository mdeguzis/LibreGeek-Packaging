# Settings used for build from snapshots.
%global commit0		a43c52826bbe1ba274f48f2bcd2b517f68c88ef9
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})

Name:		Doom64EX
Version:	0.0.0
Release:	1%{?dist}
Summary:	Doom64EX is a reverse-engineering project aimed to recreate Doom64 as close as possible with additional modding features.

License:	GPLv2
URL:		https://github.com/svkaiser/Doom64EX
Source0:  	%{url}/archive/%{commit0}.tar.gz#/%{name}-%{shortcommit0}.tar.gz

BuildRequires:  cmake
BuildRequires:	clang
BuildRequires:  gtest-devel
BuildRequires:	SDL2-devel
BuildRequires:  SDL2_net-devel
BuildRequires:  zlib-devel
BuildRequires:  libpng-devel
BuildRequires:  fluidsynth-devel

Requires:  SDL2_net

%description
Doom64EX is a reverse-engineering project aimed to recreate Doom64 as close 
as possible with additional modding features.

%prep
%autosetup -n %{name}-%{commit0}

%build
rm -rf build && mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
%make

%install
%make_install

# Install and verify desktop file
# %{_bindir}/desktop-file-install other/%{name}.desktop

%post
%{_bindir}/update-mime-database %{_datadir}/mime &> /dev/null || :
%{_bindir}/update-desktop-database &> /dev/null || :

%postun
%{_bindir}/update-mime-database %{_datadir}/mime &> /dev/null || :
%{_bindir}/update-desktop-database &> /dev/null || :

%license LICENSE
%doc README.md
%{_bindir}/%{name}

build/src/engine/doom64ex     /usr/bin
build/kex.wad                 /usr/share/games/doom64ex
README.md                     /usr/share/games/doom64ex
debian/doom64ex.desktop       /usr/share/applications
doom64ex.png                  /usr/share/pixmaps

%{_datadir}/%{name}/translations/antimicro.qm
%{_datadir}/applications/%{name}.desktop
%{_datadir}/pixmaps/%{name}.png
%{_datadir}/mime/packages/%{name}.xml
%{_mandir}/man1/%{name}.1*
%{_datadir}/appdata/%{name}.appdata.xml

%changelog

* Wed Nov 24 2016 Michal DeGUzis <mdeguzis@gmail.com> - 2.22-2
- Initial upload
