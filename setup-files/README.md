# Packaging notes
To setup machine for packaging:

```
./pbuilder-wrapper.sh [OPTS]
```
Using no options will show you the command list.

# Creating pbuilder environment

See `create-pbuilder-env.sh` 

# Hooks

##Classes	Description

**A**	Is for --build target. It is executed before build starts; after unpacking the build system, and unpacking the source, and satisfying the build-dependency.
**B**	s executed after build system finishes building, successfully, before copying back the build result.
**C**	Is executed after build failure, before cleanup.
**D**	Is executed before unpacking the source inside the chroot, after setting up the chroot environment.
