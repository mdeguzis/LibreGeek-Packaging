# About

LLVM 3.8 seems to be configured wrong. This prevents projects from working fully that seem LLVM via pkgconfig.

See:

https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=819072

# Update

Actually, the 3rd revision seems to have fixed this ([thread](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=819072#85). 

Try building:

http://http.debian.net/debian/pool/main/l/llvm-toolchain-3.8/llvm-toolchain-3.8_3.8.1-3.dsc
