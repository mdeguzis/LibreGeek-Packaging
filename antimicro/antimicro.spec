# Conditional for release and snapshot builds. Uncomment for release-builds.
%global rel_build 1

# Settings used for build from snapshots.
%global commit		eb40af7a22b8eac4de1b470c44509e10013c193a
%{!?rel_build:%global commit_date	20160110}
%{!?rel_build:%global shortcommit	%(c=%{commit};echo ${c:0:7})}
%{!?rel_build:%global gitver		git%{commit_date}-%{shortcommit}}
%{!?rel_build:%global gitrel		.git%{commit_date}.%{shortcommit}}

# Proper naming for the tarball from github.
%global gittar %{name}-%{version}%{!?rel_build:-%{gitver}}.tar.gz

Name:		antimicro
Version:	2.22
Release:	1%{?gitrel}%{?dist}
Summary:	Graphical program used to map keyboard buttons and mouse controls to a gamepad

License:	GPLv3+
URL:		https://github.com/AntiMicro/%{name}
Source0:	%{url}/archive/%{commit}/%{gittar}

BuildRequires:	cmake
BuildRequires:	desktop-file-utils
BuildRequires:	gcc
BuildRequires:	gcc-c++
BuildRequires:	libX11-devel
BuildRequires:	libXtst-devel
BuildRequires:	qt5-qtbase-devel
BuildRequires:	qt5-qttools-devel
BuildRequires:	SDL2-devel
# For AppData
BuildRequires:	libappstream-glib
BuildRequires:	itstool
BuildRequires:	gettext

%description
AntiMicro is a graphical program used to map keyboard keys and mouse controls
to a gamepad. This program is useful for playing PC games using a gamepad that
do not have any form of built-in gamepad support. AntiMicro was inspired by
QJoyPad but has additional features.


%prep
%setup -qn %{name}-master

%build
%{__mkdir} -p build-%{name}-%{_target}
pushd build-%{name}-%{_target}
%cmake -DWITH_UINPUT=ON -DAPPDATA=ON ..
%{__make} %{?_smp_mflags} appdata
popd


%install
pushd build-%{name}-%{_target}
%make_install
popd

# Install and verify desktop file
%{_bindir}/desktop-file-install other/%{name}.desktop

# Validate AppData file
%{_bindir}/appstream-util validate-relax --nonet %{buildroot}/%{_datadir}/appdata/%{name}.appdata.xml

%find_lang %{name} --with-qt


%post
%{_bindir}/update-mime-database %{_datadir}/mime &> /dev/null || :
%{_bindir}/update-desktop-database &> /dev/null || :

%postun
%{_bindir}/update-mime-database %{_datadir}/mime &> /dev/null || :
%{_bindir}/update-desktop-database &> /dev/null || :


%files -f %{name}.lang
%license gpl.txt
%doc Changelog README.md
%{_bindir}/%{name}
%dir %{_datadir}/%{name}
%dir %{_datadir}/%{name}/translations
%{_datadir}/%{name}/translations/antimicro.qm
%{_datadir}/applications/%{name}.desktop
%{_datadir}/pixmaps/%{name}.png
%{_datadir}/mime/packages/%{name}.xml
%{_mandir}/man1/%{name}.1*
%{_datadir}/appdata/%{name}.appdata.xml

%changelog

* Wed Oct 12 2016 Michal DeGUzis <mdeguzis@gmail.com> - 2.22-2
- Reupload for testing

* Sat Jul 30 2016 Jeff Backus <jeff.backus@gmail.com> - 2.22-1
- updated homepage (#1334535)
- new upstream release v2.22 (#1361803)

* Wed Feb 03 2016 Fedora Release Engineering <releng@fedoraproject.org> - 2.21-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Wed Jan 13 2016 Jeff Backus <jeff.backus@gmail.com> - 2.21-1
- new upstream release v2.21 (#1297245)

* Thu Oct 29 2015 Jeff Backus <jeff.backus@gmail.com> - 2.20.2-1
- new upstream release v2.20.2 (#1267415)

* Sun Oct 11 2015 Jeff Backus <jeff.backus@gmail.com> - 2.20-1
- new upstream release v2.20 (#1267415)

* Sat Oct 3 2015 Jeff Backus <jeff.backus@gmail.com> - 2.19.3-1
- new upstream release v2.19.3 (#1267415)

* Wed Sep 16 2015 Jeff Backus <jeff.backus@gmail.com> - 2.19.2-1
- new upstream release v2.19.2 (#1263686)

* Sun Sep 6 2015 Jeff Backus <jeff.backus@gmail.com> - 2.19.1-1
- new upstream release v2.19.1 (#1258674)

* Tue Aug 25 2015 Jeff Backus <jeff.backus@gmail.com> - 2.18.2-1
- new upstream release v2.18.2 (#1256773)

* Wed Aug 19 2015 Jeff Backus <jeff.backus@gmail.com> - 2.18.1-1
- new upstream release v2.18.1

* Sat Aug 15 2015 Jeff Backus <jeff.backus@gmail.com> - 2.18-1
- new upstream release v2.18 (#1253911)

* Sun Aug 02 2015 Jeff Backus <jeff.backus@gmail.com> - 2.17-1
- new upstream release v2.17 (#1249393)

* Fri Jul 24 2015 Jeff Backus <jeff.backus@gmail.com> - 2.16-1
- new upstream release v2.16 (#1246074)

* Sun Jun 28 2015 Jeff Backus <jeff.backus@gmail.com> - 2.15-1
- Added requisite calls to update-desktop-database.
- Marked license file with license macro.
- Removed references to F20.
- New upstream release v2.15 (#1236301)

* Tue Jun 16 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.14-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Fri May 01 2015 BjÃ¶rn Esser <bjoern.esser@gmail.com> - 2.14-1
- new upstream release v2.14 (#1217760)

* Wed Apr 1 2015 Jeff Backus <jeff.backus@gmail.com> - 2.13-1
- new upstream release v2.13 (#1204553)

* Fri Feb 27 2015 Jeff Backus <jeff.backus@gmail.com> - 2.12-1
- new upstream release v2.12 (#1202803)

* Fri Feb 13 2015 Jeff Backus <jeff.backus@gmail.com> - 2.11-1
- new upstream release v2.11
- removed appdata patch, since it has been incorporated by upstream
- modified source URL to reference tarball by commit
- updated for Qt5

* Sat Jan 3 2015 Jeff Backus <jeff.backus@gmail.com> - 2.10.1-2
- added appdata support

* Mon Dec 29 2014 Jeff Backus <jeff.backus@gmail.com> - 2.10.1-1
- new upstream release v2.10.1

* Thu Dec 11 2014 BjÃ¶rn Esser <bjoern.esser@gmail.com> - 2.10-2
- enabled uinput support for simulating events

* Thu Dec 11 2014 BjÃ¶rn Esser <bjoern.esser@gmail.com> - 2.10-1
- new upstream release v2.10 (#1159472)
- added options and conditionals for release and snapshot builds
- improved readability

* Sat Oct 18 2014 Jeff Backus <jeff.backus@gmail.com> - 2.7-1
- new upstream release (#1126553)

* Sat Sep 20 2014 Jeff Backus <jeff.backus@gmail.com> - 2.6-1
- Updated version
- Updated URL

* Fri Aug 15 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.5-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_22_Mass_Rebuild

* Sat Aug 09 2014 Jeff Backus <jeff.backus@gmail.com> - 2.5-1
- Updated version

* Sat Jun 07 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.4-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Sun Jun 01 2014 BjÃ¶rn Esser <bjoern.esser@gmail.com> - 2.4-1
- new upstream release (#1103432)

* Sat May 24 2014 Jeff Backus <jeff.backus@gmail.com> - 2.3.3-1
- Initial package
- Fixed license issue found in review.
- Removed use of desktop-file-validate as it was redundant.
- Modified to use find_lang instead of lang macro.
- Made "man glob" less greedy.
- Removed icon scriplets as they aren't meant for pixbuf directory.
- Changed cmake to use . to better follow convention.
- Removed name info from setup macro as it was redundant.
