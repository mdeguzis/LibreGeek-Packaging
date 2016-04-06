#
# spec file for package libqt5-qtwebchannel
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


%define qt5_snapshot 1
%define libname libQt5WebChannel5
%define base_name libqt5
%define real_version 5.6.1
%define so_version 5.6.1
%define tar_version qtwebchannel-opensource-src-%{real_version}
Name:           libqt5-qtwebchannel
Version:        5.6.1
Release:        2.1
Summary:        Qt 5 WebChannel Addon
License:        SUSE-LGPL-2.1-with-digia-exception-1.1 or GPL-3.0
Group:          Development/Libraries/X11
Url:            http://qt.digia.com
Source:         %{tar_version}.tar.xz
Source1:        baselibs.conf
BuildRequires:  fdupes
BuildRequires:  libqt5-qtbase-private-headers-devel >= %{version}
BuildRequires:  libqt5-qtdeclarative-devel >= %{version}
BuildRequires:  libqt5-qtwebsockets-devel >= %{version}
BuildRequires:  xz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
%if %{qt5_snapshot}
#to create the forwarding headers
BuildRequires:  perl
%endif

%description
Qt is a set of libraries for developing applications.

%prep
%setup -q -n qtwebchannel-opensource-src-%{real_version}

%package -n %{libname}
Summary:        Qt 5 WebChannel Addon
Group:          Development/Libraries/X11
%requires_ge libQtQuick5

%description -n %{libname}
Qt is a set of libraries for developing applications.

%package -n %{libname}-imports
Summary:        Qt 5 WebSockets Library - QML imports
Group:          Development/Libraries/X11
Supplements:    packageand(%{libname}:libQtQuick5)
# imports splited with 5.4.1
Conflicts:      %{libname} < 5.4.1
%requires_ge libQtQuick5

%description -n %{libname}-imports
Qt is a set of libraries for developing applications.

This package contains base tools, like string, xml, and network
handling.

%package devel
Summary:        Qt Development Kit
Group:          Development/Libraries/X11
Requires:       %{libname} = %{version}

%description devel
You need this package, if you want to compile programs with qtwebchannel.

%package private-headers-devel
Summary:        Non-ABI stable experimental API
Group:          Development/Libraries/C and C++
Requires:       %{name}-devel = %{version}
Requires:       libQt5Core-private-headers-devel >= %{version}
BuildArch:      noarch

%description private-headers-devel
This package provides private headers of libqt5-qtwebchannel that are normally
not used by application development and that do not have any ABI or
API guarantees. The packages that build against these have to require
the exact Qt version.

%package examples
Summary:        Qt5 sensors examples
Group:          Development/Libraries/X11
Recommends:     %{name}-devel

%description examples
Examples for libqt5-qtwebchannel module.

%post -n %{libname} -p /sbin/ldconfig

%postun -n %{libname} -p /sbin/ldconfig

%build
%if %{qt5_snapshot}
#force the configure script to generate the forwarding headers (it checks whether .git directory exists)
mkdir .git
%endif
%{qmake5}
%{make_jobs}

%install
%{qmake5_install}

# kill .la files
rm -f %{buildroot}%{_libqt5_libdir}/lib*.la

%files -n %{libname}
%defattr(-,root,root,755)
%doc LGPL_EXCEPTION.txt LICENSE.*
%{_libqt5_libdir}/libQt5WebChannel.so.*

%files -n %{libname}-imports
%defattr(-,root,root,755)
%doc LGPL_EXCEPTION.txt LICENSE.*
%{_libqt5_archdatadir}/qml/QtWebChannel/

%files private-headers-devel
%defattr(-,root,root,755)
%doc LGPL_EXCEPTION.txt LICENSE.*
%{_libqt5_includedir}/QtWebChannel/%{so_version}

%files devel
%defattr(-,root,root,755)
%doc LGPL_EXCEPTION.txt LICENSE.*
%exclude %{_libqt5_includedir}/QtWebChannel/%{so_version}
%{_libqt5_includedir}/QtWebChannel
%{_libqt5_libdir}/cmake/Qt5WebChannel
%{_libqt5_libdir}/libQt5WebChannel.prl
%{_libqt5_libdir}/libQt5WebChannel.so
%{_libqt5_libdir}/pkgconfig/Qt5WebChannel.pc
%{_libqt5_libdir}/qt5/mkspecs/modules/qt_lib_*.pri

%files examples
%defattr(-,root,root,755)
%doc LGPL_EXCEPTION.txt LICENSE.*
%{_libqt5_examplesdir}/

%changelog
* Fri Mar 18 2016 hrvoje.senjan@gmail.com
- Update to 5.6.0
  * For more details please see:
    http://blog.qt.io/blog/2016/03/16/qt-5-6-released/
    and https://wiki.qt.io/New_Features_in_Qt_5.6
* Fri Oct 16 2015 hrvoje.senjan@gmail.com
- Update to 5.5.1
  * For more details please see:
    http://blog.qt.io/blog/2015/10/15/qt-5-5-1-released/
* Sun Aug 16 2015 hrvoje.senjan@gmail.com
- Update to 5.5.0
  * For more details please see:
    http://blog.qt.io/blog/2015/07/01/qt-5-5-released/
    and https://wiki.qt.io/New_Features_in_Qt_5.5
* Wed Jun  3 2015 hrvoje.senjan@gmail.com
- Update to 5.4.2
  * Bugfix release, for more details please see:
    http://blog.qt.io/blog/2015/06/02/qt-5-4-2-released/
* Tue Feb 24 2015 hrvoje.senjan@gmail.com
- Update to 5.4.1
  * For more details please see:
    http://blog.qt.io/blog/2015/02/24/qt-5-4-1-released/
- Split the imports into separate package
- Add minimal requires on libQtQuick5
* Wed Dec 10 2014 hrvoje.senjan@gmail.com
- Update to 5.4 Final
  * For more details please see:
    http://blog.qt.digia.com/blog/2014/12/10/qt-5-4-released/
    and http://qt-project.org/wiki/New-Features-in-Qt-5.4
* Thu Nov 27 2014 hrvoje.senjan@gmail.com
- Update to 5.4 RC
  * For more details please see:
    http://blog.qt.digia.com/blog/2014/11/27/qt-5-4-release-candidate-available/
    and http://qt-project.org/wiki/New-Features-in-Qt-5.4
* Fri Oct 17 2014 hrvoje.senjan@gmail.com
- Update to 5.4.0 beta
  * New feature release, please see
  http://blog.qt.digia.com/blog/2014/10/17/qt-5-4-beta-available/
  and http://qt-project.org/wiki/New-Features-in-Qt-5.4
* Wed Aug 13 2014 hrvoje.senjan@gmail.com
- Activate libqt5-qtwebchannel package
