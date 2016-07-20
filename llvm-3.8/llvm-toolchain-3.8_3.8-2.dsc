-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

Format: 3.0 (quilt)
Source: llvm-toolchain-3.8
Binary: clang-3.8, clang-format-3.8, clang-tidy-3.8, clang-3.8-doc, libclang1-3.8, libclang1-3.8-dbg, libclang-3.8-dev, libclang-common-3.8-dev, python-clang-3.8, clang-3.8-examples, libllvm3.8, libllvm3.8-dbg, llvm-3.8, llvm-3.8-runtime, llvm-3.8-dev, libllvm-3.8-ocaml-dev, llvm-3.8-doc, llvm-3.8-examples, lldb-3.8, liblldb-3.8, liblldb-3.8-dbg, python-lldb-3.8, liblldb-3.8-dev, lldb-3.8-dev
Architecture: any all
Version: 1:3.8-2
Maintainer: LLVM Packaging Team <pkg-llvm-team@lists.alioth.debian.org>
Uploaders: Sylvestre Ledru <sylvestre@debian.org>
Homepage: http://www.llvm.org/
Standards-Version: 3.9.6
Vcs-Browser: https://svn.debian.org/viewsvn/pkg-llvm/llvm-toolchain/branches/3.8/
Vcs-Svn: svn://anonscm.debian.org/svn/pkg-llvm/llvm-toolchain/branches/3.8/
Build-Depends: debhelper (>= 9.0), flex, bison, dejagnu, tcl, expect, cmake, perl, libtool, chrpath, texinfo, sharutils, libffi-dev (>= 3.0.9), lsb-release, patchutils, diffstat, xz-utils, python-dev, libedit-dev, swig, python-sphinx, ocaml-nox, binutils-dev, libjsoncpp-dev, lcov, procps, help2man, dh-ocaml, zlib1g-dev
Build-Conflicts: libllvm-3.4-ocaml-dev, libllvm-3.5-ocaml-dev, libllvm-3.8-ocaml-dev, ocaml, oprofile
Package-List:
 clang-3.8 deb devel optional arch=any
 clang-3.8-doc deb doc optional arch=all
 clang-3.8-examples deb doc optional arch=any
 clang-format-3.8 deb devel optional arch=any
 clang-tidy-3.8 deb devel optional arch=any
 libclang-3.8-dev deb libdevel optional arch=any
 libclang-common-3.8-dev deb libdevel optional arch=any
 libclang1-3.8 deb devel optional arch=any
 libclang1-3.8-dbg deb debug extra arch=any
 liblldb-3.8 deb libs optional arch=amd64,armel,armhf,i386,kfreebsd-amd64,kfreebsd-i386,s390,sparc,alpha,hppa,m68k,powerpcspe,ppc64,sh4,sparc64,x32,mips,mipsel
 liblldb-3.8-dbg deb debug extra arch=amd64,armel,armhf,i386,kfreebsd-amd64,kfreebsd-i386,s390,sparc,hppa,m68k,powerpcspe,ppc64,sh4,sparc64,x32,mips,mipsel
 liblldb-3.8-dev deb libdevel optional arch=amd64,armel,armhf,i386,kfreebsd-amd64,kfreebsd-i386,s390,sparc,alpha,hppa,m68k,powerpcspe,ppc64,sh4,sparc64,x32,mips,mipsel
 libllvm-3.8-ocaml-dev deb ocaml optional arch=any
 libllvm3.8 deb libs optional arch=any
 libllvm3.8-dbg deb debug extra arch=any
 lldb-3.8 deb devel optional arch=amd64,armel,armhf,i386,kfreebsd-amd64,kfreebsd-i386,s390,sparc,alpha,hppa,m68k,powerpcspe,ppc64,sh4,sparc64,x32,mips,mipsel
 lldb-3.8-dev deb oldlibs optional arch=all
 llvm-3.8 deb devel optional arch=any
 llvm-3.8-dev deb devel optional arch=any
 llvm-3.8-doc deb doc optional arch=all
 llvm-3.8-examples deb doc optional arch=all
 llvm-3.8-runtime deb devel optional arch=any
 python-clang-3.8 deb python optional arch=any
 python-lldb-3.8 deb python optional arch=any
Checksums-Sha1:
 d94c4381b1ea9c196811f806db82a04481bde093 357797 llvm-toolchain-3.8_3.8.orig-clang-tools-extra.tar.bz2
 59a9c6591eb122fb2b04cd855f563061e1e3b3c9 10607483 llvm-toolchain-3.8_3.8.orig-clang.tar.bz2
 99f06ac075cd510c9b3b09e7e324fa95600ab270 1641135 llvm-toolchain-3.8_3.8.orig-compiler-rt.tar.bz2
 aa9526c55cd266865b80294453317092f7e09849 3973673 llvm-toolchain-3.8_3.8.orig-lldb.tar.bz2
 25f1fd33330858dbae41585f240a19b14175b0f4 1995671 llvm-toolchain-3.8_3.8.orig-polly.tar.bz2
 b752bbcc307e2b98aa625201d0175327bb519445 19185811 llvm-toolchain-3.8_3.8.orig.tar.bz2
 edaaf0b43b22e371d2d11e0b756751674e8eb3d2 48444 llvm-toolchain-3.8_3.8-2.debian.tar.xz
Checksums-Sha256:
 829294015ce07d3f115f5dda2422c9c4efbcb0f3d704df9673b0f3ad238ae390 357797 llvm-toolchain-3.8_3.8.orig-clang-tools-extra.tar.bz2
 c9a786040bbda4f2aa7d26474567bf4d9c9b9a0fa5b0f5fea51c6f4f37fe62d1 10607483 llvm-toolchain-3.8_3.8.orig-clang.tar.bz2
 93e34592b651377ed86d6085e1b71cfad8c4023ded934d5f03ca700eb56a888e 1641135 llvm-toolchain-3.8_3.8.orig-compiler-rt.tar.bz2
 9664e4f349d22de29fd4eb6945c93995c72a4a19aaa176c31ba592c7d4fcf349 3973673 llvm-toolchain-3.8_3.8.orig-lldb.tar.bz2
 c0f408b252685dfb15a7e0818305efacbf56190f128f5f08fea36284f7e4327a 1995671 llvm-toolchain-3.8_3.8.orig-polly.tar.bz2
 e9f28eef0e452efcf03fea2f24e336c126bd63578c9db21bf1544f326bbd8405 19185811 llvm-toolchain-3.8_3.8.orig.tar.bz2
 8866c9f1a82e475e881bb9992d901287b94d510f1ed67a35a8118cf03b039388 48444 llvm-toolchain-3.8_3.8-2.debian.tar.xz
Files:
 4ade7d698406c07ebc9bf4eaad80ac18 357797 llvm-toolchain-3.8_3.8.orig-clang-tools-extra.tar.bz2
 ba42a2f8993de6fa4b6e0dbc34ee038f 10607483 llvm-toolchain-3.8_3.8.orig-clang.tar.bz2
 41d6c49f5c068f37bd35bf7a1f3dde26 1641135 llvm-toolchain-3.8_3.8.orig-compiler-rt.tar.bz2
 9f76e040e786c7ba7a923ec3ee0a695e 3973673 llvm-toolchain-3.8_3.8.orig-lldb.tar.bz2
 b47fda18ec296eab4312d0e3f7c8b0d6 1995671 llvm-toolchain-3.8_3.8.orig-polly.tar.bz2
 3ea400ef66baf94d4fbbb1b24054e479 19185811 llvm-toolchain-3.8_3.8.orig.tar.bz2
 466053daae1e3330a5e39e1d88a382fc 48444 llvm-toolchain-3.8_3.8-2.debian.tar.xz

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2

iQIcBAEBCAAGBQJW3odEAAoJEPNPCXROn13ZqhoP/RpfaTKSlC5RIDywY0TKvp0G
l+yUVbTfenX+TXDjQFt6hmKUd6NkGPjRyOQ4VV9eHNqtLYInq+dwEftDf+V2JWMt
xVWTiRPGw3CUcLOQc5PQ9Kp4RZVXuNSYiBLDK8CRLbLhla4XqhCKj7VRCIcOCAt6
UorWV2z6N6wEdxcbhz4oDOAmzXAllJV/tQQpAuabYvcDxpxw2lBC7YwCiCZdFipH
Ii4u37vaA59RyAG+pSDJnDWNt9WYvl9CqSsn2TepCez7Q6V2ap6/OyQ7bUibAWTa
VZzf/YPgqEDcRzr1L8j7NSpuvUu5vQlR9MsCqiUBvEHom4lJZZO2Qhqih0Rmp/5F
GiINV9hXvIypYCRMC7qhyoFRupevPzkrkjUtbA+b4RlCe2oW5/PAYN/m+/ch3KYM
Q7XGwe6po8+ChiUsH+27TB8iHSJHtbu9ofX+gVpac4KxhimIigbdToLqxf+7I9Rz
gjTnGbmtu4Q0zms2wvGCBqalgSdbgUw6kIEx2d20Uj7rBdXrw45RajjJAIojUQP4
ICRD2HxSDKAEqCvfrt9JQYKvWEzWQorMmfUykdUvGiQMjwzgevqVO0xHH3SwRw9H
d0Nko+SPOYGXT/v3ZxJ5blkblxZRFdfdINgdzYtucB5QmAlTrE6Jenl9ScmD2w/p
VfxTq6HQdFC901cQjqEo
=69RW
-----END PGP SIGNATURE-----
