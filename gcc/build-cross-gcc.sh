#!/bin/bash
set -e
trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo FAILED COMMAND: $previous_command' EXIT

#-------------------------------------------------------------------------------------------
# This script will download packages for, configure, build and install a GCC cross-compiler.
# Customize the variables (INSTALL_PATH, TARGET, etc.) to your liking before running.
# If you get an error and need to resume the script from some point in the middle,
# just delete/comment the preceding lines before running it again.
#
# See: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler
# Package versions: https://ftp.gnu.org/gnu/
# ISL/CLOG: ftp://gcc.gnu.org/pub/gcc/infrastructure
#
# Usage ./build_cross_gcc.sh [options]
#-------------------------------------------------------------------------------------------

# Set initial vars
INSTALL_PATH="/opt/cross-gcc"
BUILD_TMP="$HOME/build-cross-gcc"

# Ensure BUILD_TMP exists
if [[ ! -d $BUILD_TMP ]]; then
	mkdir -p $BUILD_TMP
fi

echo -e "\n==> Sourcing any options\n"

# source options
while :; do
	case $1 in
		-i|--install-path)       # Takes an option argument, ensuring it has been specified.
			if [[ -n "$2" ]]; then
				INSTALL_PATH=$2
				echo "INSTALL PATH: $INSTALL_PATH"
				shift
			else
				echo -e "ERROR: --install-path requires an argument.\n" >&2
				exit 1
			fi
		;;

		-r|--rebuild)
			if [[ "$INSTALL_PATH" != "" ]]; then
				echo -e "\n==> Cleaning build dir and install files..."
				sudo rm -rf $INSTALL_PATH
				sudo rm -rf $BUILD_TMP
				mkdir -p $BUILD_TMP
			else
				echo -e "ERROR: no path set to clean. Please use --install-path [PATH] --rebuild--all"
			fi
		;;
		
		--)
		# End of all options.
		shift
		break
		;;

		-?*)
		printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
		;;
  
		*)  # Default case: If no more options then break out of the loop.
		break

	esac

	# shift args
	shift
done

if [[ "$INSTALL_PATH" == "" ]]; then

	INSTALL_PATH=/opt/cross-gcc

fi

TARGET=x86_64-linux-gnu
USE_NEWLIB=0
LINUX_ARCH=x86_64
CONFIGURATION_OPTIONS="--disable-multilib" # --disable-threads --disable-shared
PARALLEL_MAKE=-j4
BINUTILS_VERSION=binutils-2.26
GCC_VERSION=gcc-6.1.0
LINUX_KERNEL_VERSION=linux-$(uname -r | sed 's/-.*//')
KERNEL_SERIES=v$(uname -r | cut -c 1).x
GLIBC_VERSION=glibc-2.23
MPFR_VERSION=mpfr-3.1.4
GMP_VERSION=gmp-6.1.1
MPC_VERSION=mpc-1.0.3
ISL_VERSION=isl-0.16.1
CLOOG_VERSION=cloog-0.18.1
export PATH=$INSTALL_PATH/bin:$PATH

# if the kernel version ends in .0, cut this, as the ftp site will list
# just 3.16 for 3.16.0

if [[ $(echo $LINUX_KERNEL_VERSION | grep ".0" ) != "" ]]; then 

	LINUX_KERNEL_VERSION=linux-$(uname -r | sed 's/-.*//' | sed 's/.0//')

fi

# Enter build dir
cd $BUILD_TMP

echo -e "\n==> Obtaining needed packages\n"
sleep 2s

sudo apt-get install -y --force-yes wget unzip gawk

# Get sources
echo -e "\n==> Obtaining sources\n"

# Download packages
export http_proxy=$HTTP_PROXY https_proxy=$HTTP_PROXY ftp_proxy=$HTTP_PROXY
wget -nc https://ftp.gnu.org/gnu/binutils/$BINUTILS_VERSION.tar.gz
wget -nc https://ftp.gnu.org/gnu/gcc/$GCC_VERSION/$GCC_VERSION.tar.gz

if [ $USE_NEWLIB -ne 0 ]; then
	wget -nc -O newlib-master.zip https://github.com/bminor/newlib/archive/master.zip || true
	unzip -qo newlib-master.zip
else
	wget -nc https://www.kernel.org/pub/linux/kernel/$KERNEL_SERIES/$LINUX_KERNEL_VERSION.tar.xz
	wget -nc https://ftp.gnu.org/gnu/glibc/$GLIBC_VERSION.tar.xz
fi

wget -nc https://ftp.gnu.org/gnu/mpfr/$MPFR_VERSION.tar.xz
wget -nc https://ftp.gnu.org/gnu/gmp/$GMP_VERSION.tar.xz
wget -nc https://ftp.gnu.org/gnu/mpc/$MPC_VERSION.tar.gz
wget -nc ftp://gcc.gnu.org/pub/gcc/infrastructure/$ISL_VERSION.tar.bz2
wget -nc ftp://gcc.gnu.org/pub/gcc/infrastructure/$CLOOG_VERSION.tar.gz

echo ""

# Extract everything
for f in *.tar*; 
do 
	echo -e "Extracting archive: $f"
	tar xf $f;
done

# Make symbolic links
cd $GCC_VERSION
ln -sf `ls -1d ../mpfr-*/` mpfr
ln -sf `ls -1d ../gawk-*/` gawk
ln -sf `ls -1d ../gmp-*/` gmp
ln -sf `ls -1d ../mpc-*/` mpc
ln -sf `ls -1d ../isl-*/` isl
ln -sf `ls -1d ../cloog-*/` cloog
cd ..

# Step 1. Binutils
echo -e "\n==> Building stage 1: binutils\n" && sleep 2s
mkdir -p build-binutils
cd build-binutils
../$BINUTILS_VERSION/configure --prefix=$INSTALL_PATH --TARGET=$TARGET $CONFIGURATION_OPTIONS
make $PARALLEL_MAKE
sudo make install
cd ..

# Step 2. Linux Kernel Headers
echo -e "\n==> Building stage 2: kernel headers\n" && sleep 2s

if [ $USE_NEWLIB -eq 0 ]; then
	cd $LINUX_KERNEL_VERSION
	# This makefile does a lot of installing to the INSTALL_PATH, elevate privs
	sudo make ARCH=$LINUX_ARCH INSTALL_HDR_PATH=$INSTALL_PATH/$TARGET headers_install
	cd ..
fi

# Step 4. C/C++ Compilers
echo -e "\n==> Building stage 3: C/C++ compilers\n" && sleep 2s
mkdir -p build-gcc
cd build-gcc

if [ $USE_NEWLIB -ne 0 ]; then
	NEWLIB_OPTION=--with-newlib
fi

../$GCC_VERSION/configure --prefix=$INSTALL_PATH --TARGET=$TARGET --enable-languages=c,c++ $CONFIGURATION_OPTIONS $NEWLIB_OPTION
make $PARALLEL_MAKE all-gcc
sudo make install-gcc
cd ..

if [ $USE_NEWLIB -ne 0 ]; then

	# Steps 5-7: Newlib
	echo -e "\n==> Building stage 4-6: newlibs\n" && sleep 2s
	mkdir -p build-newlib
	cd build-newlib
	../newlib-master/configure --prefix=$INSTALL_PATH --TARGET=$TARGET $CONFIGURATION_OPTIONS
	make $PARALLEL_MAKE
	sudo make install
	cd ..

else

	# Step 5. Standard C Library Headers and Startup Files
	echo -e "\n==> Building stage 4: glibc/gcc\n" && sleep 2s
	mkdir -p build-glibc
	cd build-glibc
	../$GLIBC_VERSION/configure --prefix=$INSTALL_PATH/$TARGET --build=$MACHTYPE --host=$TARGET --TARGET=$TARGET --with-headers=$INSTALL_PATH/$TARGET/include $CONFIGURATION_OPTIONS libc_cv_forced_unwind=yes
	sudo make install-bootstrap-headers=yes install-headers
	make $PARALLEL_MAKE csu/subdir_lib
	sudo install csu/crt1.o csu/crti.o csu/crtn.o $INSTALL_PATH/$TARGET/lib
	sudo $TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $INSTALL_PATH/$TARGET/lib/libc.so
	sudo touch $INSTALL_PATH/$TARGET/include/gnu/stubs.h
	cd ..
	
	# Step 6. Compiler Support Library
	echo -e "\n==> Building stage 5: gcc support library\n" && sleep 2s
	cd build-gcc
	sudo make $PARALLEL_MAKE all-TARGET-libgcc
	sudo make install-TARGET-libgcc
	cd ..
	
	# Step 7. Standard C Library & the rest of Glibc
	echo -e "\n==> Building stage 6: C library and rest glibc\n" && sleep 2s
	cd build-glibc
	sudo make $PARALLEL_MAKE
	sudo make install
	cd ..

fi

# Step 8. Standard C++ Library & the rest of GCC
echo -e "\n==> Building stage 7: C++ library and rest glibc\n" && sleep 2s
cd build-gcc
make $PARALLEL_MAKE all
sudo make install
cd ..

trap - EXIT
echo 'Success!'
