#!/bin/sh
ORIG_VERSION=3.7
TARGET_VERSION=3.8
ORIG_VERSION_2=3_7
TARGET_VERSION_2=3_8

LIST=`ls debian/*$ORIG_VERSION*`
for F in $LIST; do
    TARGET=`echo $F|sed -e "s|$ORIG_VERSION|$TARGET_VERSION|g"`
    svn mv $F $TARGET
done
LIST=`ls debian/*$TARGET_VERSION* debian/control debian/*.install debian/*.links debian/orig-tar.sh debian/rules debian/patches/clang-analyzer-force-version.diff debian/patches/clang-format-version.diff debian/patches/lldb-soname.diff debian/patches/python-clangpath.diff debian/patches/scan-build-clang-path.diff`
for F in $LIST; do
    sed -i -e "s|$ORIG_VERSION_2|$TARGET_VERSION_2|g" $F
    sed -i -e "s|$ORIG_VERSION|$TARGET_VERSION|g" $F
done

