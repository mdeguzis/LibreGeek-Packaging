# Audio issues
* http://forums.thedarkmod.com/topic/15299-solved-audio-lag-linux-mint-15-64bit/

# TODO list

- [ ] Game folder location (get away from hack in debian/rules)
- [X] Updater issues?
  - [X] run the updater outside the package-manager, because it take to long to download 2.7 gb files (from some slow mirrors)
  - [X] Make optional after package install? (Yes)
- [X] Missing a menu-shortcut for the tdm-updater and a uninstall script.
- [X] Named your tdm-package "thedarkmod". It's not compliant with the debian package policy, and tdm-mappers doesnt like it. (changed to darkmod)
- [X] forgot the "www" in the website.
- [X] postinst:
  - [X] add the parameter "--noselfupdate" to the tdm-updater (because the updater doesn't restart when its updated himself). 
