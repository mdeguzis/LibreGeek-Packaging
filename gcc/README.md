# About

Adventures in building the GNU Cross Compiler / Binutils.

# Goals

* Use pbuilder (learn sbuild if required)
* Avoid messy manual hacks if possible
* profit

# Apporaches that don't really work

* Building binutils directly from the .dsc file (seperately), using pbuilder, dist jessie
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
