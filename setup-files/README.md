# Packaging notes
To setup machine for packaging:

```
./pbuilder-wrapper.sh [OPTS]
```
Using no options will show you the command list.

# Creating pbuilder environment

See `create-pbuilder-env.sh` 

# Post-configuration

Here are some tasks you may want to run after configuration setup:

Creating a pbuilder chroot setup

```
sudo -E DIST=[DIST] ARCH=[ARCH] pbuilder create
```

Creating a sbuild basic setup:

```
sudo sbuild-createchroot --include=eatmydata,ccache,gnupg [DIST] \
/srv/chroot/[DIST]-[ARCH] [URL_TO_DIST_POOL]
```

Creating RPM package:

```
fedpkg --dist f24 local
fedpkg --dist f24 mockbuild
rpmbuild [options] <PKG.spec>
```

Other:

* See other specific branches in the LibreGeek Packaging repo for more.

# Hooks

See: [documents/hooks](https://github.com/ProfessorKaos64/documents/tree/master/pbuilder)
