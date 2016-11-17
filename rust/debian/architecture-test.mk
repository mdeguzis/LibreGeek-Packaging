# Used for testing architecture.mk, and for make_orig-dl_tarball.sh.
# Not for end users.
#
# Usage:
# $ make -s --no-print-directory -f debian/architecture-test.mk rust-for-deb_arm64
# arm64 aarch64-unknown-linux-gnu

include debian/architecture.mk

deb_arch_setvars = $(foreach var,ARCH ARCH_OS ARCH_CPU ARCH_BITS ARCH_ENDIAN GNU_CPU GNU_SYSTEM GNU_TYPE MULTIARCH,\
  $(eval DEB_$(1)_$(var) = $(shell dpkg-architecture -a$(1) -qDEB_HOST_$(var) 2>/dev/null)))

rust-for-deb_%:
	$(eval $(call deb_arch_setvars,$*))
	$(eval $(call rust_type_setvar,DEB_$*))
	@echo $(DEB_$(*)_ARCH) $(DEB_$(*)_RUST_TYPE)
