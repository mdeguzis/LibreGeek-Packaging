# About

Adventures in building the GNU Cross Compiler / Binutils.

# Goals

* Use pbuilder (learn sbuild if required)
* Avoid messy manual hacks if possible
* profit

# Apporaches that don't really work

* ([log](http://sprunge.us/KQXh)) Building binutils directly from the .dsc file (seperately), using pbuilder, dist jessie
* Building gcc-# directly from the .dsc file (seperately), using pbuilder, dist jessie

# Approaches not yet tested

* [MultiarchCrossToolchainBuild (Debian Wiki)](https://wiki.debian.org/MultiarchCrossToolchainBuild)
* [How to build a GCC cross compiler (prishing)](http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/)

# Approaches that work

* TBD

# gcc-5 notes

gcc-5 steps to backport to Jessie:

1. build [binutils 2.26.1-1](https://packages.debian.org/stretch/binutils)
 * SteamOS version a tad too old.  
2. build [gcc-6](https://packages.debian.org/stretch/binutils) (gcc-6-base) required for gcc-5
3. build [gcc-5](https://packages.debian.org/stretch/gcc-5)

# Cross compiling

* [Cross-compiling / Debbootstrap](https://wiki.debian.org/DebianBootstrap)

# General notes

* [Cross-compiling tools package guidelines (Arch Linux)](How to Build a GCC Cross-Compiler)
* [Build profile spec](https://wiki.debian.org/BuildProfileSpec)

The general approach to building a cross compiler is:

1. binutils: Build a cross-binutils, which links and processes for the target architecture
2. headers: Install a set of C library and kernel headers for the target architecture
 1. use linux-api-headers as reference and pass ARCH=target-architecture to make
 2. create libc headers package (process for Glibc is described here)
3. gcc-stage-1: Build a basic (stage 1) gcc cross-compiler. This will be used to compile the C library. It will be unable to build almost anything else (because it can't link against the C library it doesn't have).
4. libc: Build the cross-compiled C library (using the stage 1 cross compiler).
5. gcc-stage-2: Build a full (stage 2) C cross-compiler

# Other alternatives

Apparently (assumming you don't touch gcc-defaults), as of Stretch, you can install binaries:

>If you just just want working binaries, you can now (2014/10/22) get them from the main Debian/unstable repo! Note that they are uninstallable for a while (up to a few days on slow architectures) after a new gcc-4.9, libc or linux upload as the multiarch libraries have to be in sync across architectures, so the cross-toolchains need to be rebuilt against the [sic]" (cuts off).

* [Multiarch Cross-Toolchain Build (Debian wiki)](https://wiki.debian.org/MultiarchCrossToolchainBuild)
* [Automated script](https://gist.github.com/preshing/41d5c7248dea16238b60)
