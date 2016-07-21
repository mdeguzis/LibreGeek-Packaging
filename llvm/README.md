# About

This is a simple script to do a backport of [llvm](https://packages.debian.org/sid/llvm-3.8). A [bug](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=819072) in the 
Stretch version of this package indicates the Sid revision (3) or higher should be used. Typically, the `generic-building/backport-debian-package.sh` script
would be used here, but this contains several archives, not just an `orig.tar.gz` archive.

At some point, this may transition to the main backporting script.

# Progress

(currently building on VPS)

There is a bug with setting "BUILD_DIR" and how it used later

* [bug report](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=819072)
 
It appears that with 3.8.1-4, there is an issue with help2man and how BUILD_DIR is handled.

"help2man: can't get `--help' info from build-llvm//bin/llvm-mc"

```
The following code sets this early on:
ifeq (${AUTOCONF_BUILD},yes)
BUILD_DIR=Release
endif
```

However, later on, this is referenced during man page generation:

```
LD_LIBRARY_PATH=$(DEB_INST)/usr/lib/llvm-$(LLVM_VERSION)/lib/:/usr/lib/*/libfakeroot help2man --no-discard-stderr --version-string=$(LLVM_VERSION) $(TARGET_BUILD)/$(BUILD_DIR)/bin/$$f > debian/man/$$f-$(LLVM_VERSION).1; 
```

What this does then, is just mess up this process, adding two slashes. The path should be be corrected here, maybe:

Adjust the setting of BUILD_DIR, accounting for both cases (yes and no)

```
ifeq (${AUTOCONF_BUILD},yes)
VERSION_STRING=$(LLVM_VERSION) $(TARGET_BUILD)/$(BUILD_DIR)
else
VERSION_STRING=$(LLVM_VERSION) $(TARGET_BUILD)
endif
```

Then later:

```
LD_LIBRARY_PATH=$(DEB_INST)/usr/lib/llvm-$(LLVM_VERSION)/lib/:/usr/lib/*/libfakeroot help2man --no-discard-stderr --version-string=$(VERSION_STRING)/bin/$$f > debian/man/$$f-$(LLVM_VERSION).1; 
```

Going to test this out myself, but the build takes quite a while.

# Logs

TBD
