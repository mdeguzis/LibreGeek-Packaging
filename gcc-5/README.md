# Build notes

gcc-5 steps to backport to Jessie:

1. build [binutils 2.26.1-1](https://packages.debian.org/stretch/binutils)
 * SteamOS version a tad too old.  
2. build [gcc-6](https://packages.debian.org/stretch/binutils) (gcc-6-base) required for gcc-5
3. build [gcc-5](https://packages.debian.org/stretch/gcc-5)

# Cross compiling

* [Cross-compiling / Debbootstrap](https://wiki.debian.org/DebianBootstrap)
