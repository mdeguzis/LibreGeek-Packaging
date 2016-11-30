# LibreGeek-Packaging
Packaging scripts and files for LibreGeek

# Branches
Note that each branch corresponds to a codename of a GNU/Linux distribution. For instance, the main branch, "brewmaster," is for SteamOS "brewmaster."

# Attempt at getting dnf / mock (>= Fedora 24 releases) working

All prerequisite packages were built.

```
INFO: enabled root cache
INFO: enabled dnf cache
Start: cleaning dnf metadata
Finish: cleaning dnf metadata
Mock Version: 1.2.18
INFO: Mock Version: 1.2.18
Start: dnf install
Last metadata expiration check: 0:00:00 ago on Tue Nov 29 03:01:49 2016 UTC.
Traceback (most recent call last):
  File "/usr/bin/dnf", line 58, in <module>
    main.user_main(sys.argv[1:], exit_code=True)
  File "/usr/lib/python2.7/dist-packages/dnf/cli/main.py", line 170, in user_main
    errcode = main(args)
  File "/usr/lib/python2.7/dist-packages/dnf/cli/main.py", line 60, in main
    return _main(base, args)
  File "/usr/lib/python2.7/dist-packages/dnf/cli/main.py", line 119, in _main
    ret = resolving(cli, base)
  File "/usr/lib/python2.7/dist-packages/dnf/cli/main.py", line 138, in resolving
    base.resolve(cli.demands.allow_erasing)
  File "/usr/lib/python2.7/dist-packages/dnf/base.py", line 564, in resolve
    goal.add_protected(self.sack.query().filter(
AttributeError: 'Goal' object has no attribute 'add_protected'
ERROR: Command failed. See logs for output.
 # /usr/bin/dnf --installroot /var/lib/mock/fedora-24-x86_64/root/ --releasever 24 --disableplugin=local --setopt=deltarpm=false install @buildsys-build
 ```
  
