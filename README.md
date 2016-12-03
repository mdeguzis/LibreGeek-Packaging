# LibreGeek-Packaging
Packaging scripts and files for LibreGeek

# Branches
Note that each branch corresponds to a codename of a GNU/Linux distribution. For instance, the main branch, "brewmaster," is for SteamOS "brewmaster."

# Attempt at getting dnf / mock (>= Fedora 24 releases) working

To backport yet (in order)

1. libhif (still has issues picking up libsolv0-dev components)

```
--   Found gio-unix-2.0, version 2.50.2

CMake Error at CMakeLists.txt:31 (find_package):
  Could not find a configuration file for package "LibSolv" that is
  compatible with requested version "0.6.21".

  The following configuration files were considered but not accepted:

    /usr/lib/x86_64-linux-gnu/cmake/LibSolv/LibSolvConfig.cmake, version: unknown



-- Configuring incomplete, errors occurred!
See also "/build/libhif-0.2.3/build/CMakeFiles/CMakeOutput.log".
```
