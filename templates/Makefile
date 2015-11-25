###################################################################################
# About:
#
# Below is an example simple Makefile from the Lutris project.
# Some elements are changed from examples in the GNU make manual
# See: https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents
###################################################################################
VERSION="0.3.7"

###################################################################################
# Explations and manual notes from GNU only*:
# All sections refer to a page in the GNU make manual
###################################################################################

# Section 2.1 - target syntax for rules

targets : prerequisites
        recipe
        …
# or like this: #

targets : prerequisites ; recipe
        recipe
        …

# Section 3 - Writing Makefiles

# The include directive tells make to suspend reading the current makefile and read one or more other makefiles 
# before continuing. The directive is a line in the makefile that looks like this:

	include filenames…

###################################################################################
# Simple file/directory install Makefile 
###################################################################################

build:

installdirs:
	mkdir -p ~/dir1/dir2

install:
	install -m 644 file.conf $(DESTDIR)/etc/dir/plugins/
	install -m 644 file $(DESTDIR)/etc/default/

clean:
	rm -f *.junk
###################################################################################
# Example section below from Lutris
# Augmented with other example commands and sections
###################################################################################

cover:
	rm tests/fixtures/pga.db -f
	rm tests/coverage/ -rf
	nosetests --with-coverage --cover-package=lutris --cover-html --cover-html-dir=tests/coverage

test:
	rm tests/fixtures/pga.db -f
	nosetests

deb-source:
	debuild -S

deb:
	gbp buildpackage
	mv ../lutris_0* build

changelog-add:
	dch -i

changelog-edit:
	dch -e

upload-ppa:
	dput ppa:strycore/ppa ../lutris_${VERSION}_i386.changes

clean:
	rm -rf build
	debclean

build-all: deb

upload:
	scp build/lutris_${VERSION}_all.deb lutris.net:/srv/releases/
	scp build/lutris_${VERSION}.tar.gz lutris.net:/srv/releases/
