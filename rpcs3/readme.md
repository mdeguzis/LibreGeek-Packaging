# Status:

[**FAILING**]

Build fails at 19% (22% using a Stretch chroot).

* [Upstream issue ticket](https://github.com/RPCS3/rpcs3/issues/1610#issuecomment-199855363)
* [debian files](https://github.com/ProfessorKaos64/LibreGeek-Packaging/tree/brewmaster/rpcs3/debian)
* [build log (full)](https://gist.github.com/ProfessorKaos64/4388f3d844d4cecacf70)

# Code snip of errors

```
build/rpcs3-0.0.0.6+20160322git+bsos/rpcs3/../3rdparty/GSL/include/span.h:1368:21: error: does not match expected signature 'gsl::span<const wchar_t, -1l>& gsl::span<const wchar_t, -1l>::operator=(const gsl::span<const wchar_t, -1l>&)'
CMake Error at cmake_modules/cotire.cmake:1703 (message):
  cotire: error 1 precompiling
  /build/rpcs3-0.0.0.6+20160322git+bsos/obj-x86_64-linux-gnu/rpcs3/cotire/rpcs3_CXX_prefix.hxx.
Call Stack (most recent call first):
  cmake_modules/cotire.cmake:3233 (cotire_precompile_prefix_header)


rpcs3/CMakeFiles/rpcs3.dir/build.make:57: recipe for target 'rpcs3/cotire/rpcs3_CXX_prefix.hxx.gch' failed
make[3]: *** [rpcs3/cotire/rpcs3_CXX_prefix.hxx.gch] Error 1
```
