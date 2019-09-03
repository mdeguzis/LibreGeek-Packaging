PKG=mrboom

all: build
 
build: clean
	# Use current dir so a user's home doesn't fill up
	rm -rf BUILD RPMS SOURCES SPECS SRPMS
	mkdir BUILD RPMS SOURCES SPECS SRPMS
	spectool -g -R $(PKG).spec -C SOURCES
	# Install build requirements
	yum-builddep -y $(PKG).spec
	# build just a binary for this (JAR files)
	# Use current dir for work dir
	rpmbuild \
		--define "_topdir `pwd`" \
		-bb $(PKG).spec
 
list:
	# list rpm files
	rpm -qlp RPMS/x86_64/$(PKG)*.rpm
 
install: build
	sudo rpm -i RPMS/x86_64/$(PKG)*.rpm
 
uninstall:
	sudo rpm -e $(PKG)
clean:
	rm -rf BUILD RPMS SOURCES SPECS SRPMS
	-sudo yum remove $(PKG)
