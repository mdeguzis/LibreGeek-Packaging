# https://github.com/mdeguzis/libregeek-repo
GPG_KEYID := 57655DD5
REPO := repo/
BUILD_DIR := ./build
OPTIONS += --ccache 
OPTIONS += --force-clean 
OPTIONS += --rebuild-on-sdk-change 
OPTIONS += --require-changes 
OPTIONS += --gpg-sign=$(GPG_KEYID) 
OPTIONS += --repo=$(REPO) $(BUILD_DIR)
BUILD_CMD = flatpak-builder $(OPTIONS)

check:
	$(info $$BUILD_DIR is [${BUILD_DIR}])
	$(info $$GPG_KEYID is [${GPG_KEYID}])
	$(info $$OPTIONS are [${OPTIONS}])

citra:
	cd org.citra_emu.Citra.json && $(BUILD_CMD)

plex: 
	cd tv.plex.PlexMediaPlayer && $(BUILD_CMD)

sync: $(REPO)
	cd /mnt/server_media_y/packaging/flatpak && ./sync-flatpak-repo.sh

