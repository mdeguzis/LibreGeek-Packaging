# Build list
1. dcadec, platform, crossguid, giflib
2. Sync packages from #1 to pool, or manually installed
3. kodi
4. Sync kodi to pool, or manually install it
 * kodi-addon-dev is built from kodi
 * Other packages below rely on kodi-addon-dev, such as kodi-platform
  * kodi-platform
  * libcec
  * afpfs-ng
  * taglib
  * shairplay
4. Sync packages from #3 to pool, or manually installed

7. Build the rest of the PVR packages
