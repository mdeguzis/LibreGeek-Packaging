# Current lintian warnings and errors.

This should be fixed if plans for forward to submit to Debian

# Log

+++ lintian output +++

- [x] E: doom64ex changes: bad-distribution-in-changes-file brewmaster (ignore for now, using SteamOS)
- [ ] W: doom64ex source: maintainer-script-lacks-debhelper-token debian/postinst  
- [x] W: doom64ex source: package-needs-versioned-debhelper-build-depends 9  
- [x] W: doom64ex source: no-debian-copyright  
- [x] W: doom64ex source: newer-standards-version 3.9.7 (current is 3.9.6)  
- [ ] I: doom64ex source: debian-watch-file-is-missing  (maybe fix...)
- [RECHECK] E: doom64ex: arch-independent-package-contains-binary-or-object usr/bin/doom64ex
- [ ] I: doom64ex: spelling-error-in-binary usr/bin/doom64ex consistancy consistency  (need to check src-code)
- [ ] I: doom64ex: spelling-error-in-binary usr/bin/doom64ex ang and   (need to check src-code)
- [ ] I: doom64ex: spelling-error-in-binary usr/bin/doom64ex Sucessfully Successfully   (need to check src-code)
- [ ] E: doom64ex: unstripped-binary-or-object usr/bin/doom64ex  
- [RECHECK] E: doom64ex: missing-dependency-on-libc needed by usr/bin/doom64ex  
- [RECHECK] E: doom64ex: debian-changelog-file-missing  
- [RECHECK] E: doom64ex: no-copyright-file  
- [ ] I: doom64ex: description-synopsis-might-not-be-phrased-properly  
- [ ] I: doom64ex: extended-description-is-probably-too-short  
- [ ] E: doom64ex: package-section-games-but-contains-no-game  (need to patch makefile)
- [ ] W: doom64ex: binary-without-manpage usr/bin/doom64ex   (need to create yet)
- [ ] I: doom64ex: desktop-entry-lacks-keywords-entry usr/share/applications/doom64ex.desktop  
- [ ] W: doom64ex: maintainer-script-ignores-errors postinst  

+++ end of lintian output +++
