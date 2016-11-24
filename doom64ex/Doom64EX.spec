# Settings used for build from snapshots.
%global commit0		a43c52826bbe1ba274f48f2bcd2b517f68c88ef9
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})

Name:		Doom64EX
Version:	0.0.0
Release:	20161124git%{?dist}
Summary:	Doom64EX is a reverse-engineering project aimed to recreate Doom64 as close as possible with additional modding features.

License:	GPLv2
URL:		https://github.com/svkaiser/Doom64EX
Source0:  	%{url}/archive/%{commit0}.tar.gz#/%{name}-%{shortcommit0}.tar.gz

BuildRequires:  cmake
BuildRequires:	clang
BuildRequires:  gtest-devel
BuildRequires:  mesa-libGL-devel
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
make

%install
cd build
%make_install

# Install and verify desktop file
# %{_bindir}/desktop-file-install other/%{name}.desktop

%files
%license LICENSE
%doc README.md
%{_bindir}/doom64ex
%{_datadir}/games/doom64ex/kex.wad

%changelog

* Thu Nov 24 2016 Michael DeGuzis <mdeguzis@gmail.com> - 0.0.0-1
- Initial upload
