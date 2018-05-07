# About
Branch for working with Flatpak

# Pacakge Development
Flatpak manifests are traditionally written in JSON. However, lengthly JSON manifests can be annoying to track, despite auto-closing/terminating
capabilities of editors such as vim. 

## Build Environment

### Build Files

Remember, if you need to do post-install/modification or use an install prefix,
files should go into /app inside the build directory. This is analagous to `usr/`
as a local folder inside the build area:

From someapp.yaml:
```
post-install:
  - ls /app
```

Result:
```
bin  include  lib  share
```

## Runtimes

Installing a runtime:

Find it:
```
sudo flatpak search org.kde
org.kde.Platform 5.9 flathub Shared libraries used by KDE ...
```

Install it:
```
sudo flatpak install flathub org.kde.Platform//5.9
```

## What about YAML?
YAML is much cleaner and lends it's structured format with labels very well. As of the below pull request, you can use YAML as an alternative!

https://github.com/flatpak/flatpak-builder/pull/127/files

Examples: https://github.com/flatpak/flatpak-builder/tree/master/tests

If your verision of flatpak/flatpak-builder is too old, consider building from source or using a distro that offers bleeding-edge packages.

## Converting Existing JSON to YAML
Until Python 3.7 is more widely available, there is a handy PyPi / GitHub project
called `json2yaml` that converts JSON to YAML, while retaining the dictionary order.
It uses simple methods to cleanly convert the JSON. While it is not 100% perfect,
it does a pretty good job. You can find a copy of the source code in the utils/ folder.

Example:
```
# json2yaml <input_file> <output_file>
# Note that this utility can also generate YAML to JSON
json2yaml test.json test.yaml
```

# Building Notes

## Build systems

* `simple`: use this if you want to run custom commands so that flatpak-builder does not assume a build system

# Examples

* org.supertuxproject.SuperTux (From Flathub)
  * good simple usage of shared modules
  * good tab/formatted JSON

# Links

* [Flatpak FAQ](http://flatpak.org/faq.html)
* [Getting started with flatpak](http://flatpak.org/getting.html)


