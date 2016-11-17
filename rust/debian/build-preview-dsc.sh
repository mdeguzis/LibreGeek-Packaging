#!/bin/sh
# Build a Debian source package out of an existing unpacked rustc deb source,
# and the official rust preview releases.
#
# infinity0 occasionally makes, builds and uploads them here:
# https://launchpad.net/~infinity0/+archive/ubuntu/rust-nightly
# https://launchpad.net/~infinity0/+archive/ubuntu/rust-beta

# You can set these env vars to tweak the behaviour of this script.
CHANNEL="${CHANNEL:-beta}" # either beta or nightly
DIST="${DIST:-experimental}" # which suite to put in debian/changelog
DEBDIR="${DEBDIR:-}" # where is the debian/ directory? defaults to this script
NOREMOTE="${NOREMOTE:-false}" # e.g. if you have already downloaded all necessary files
# note that we already use "wget -N" to avoid redundant downloads
NOCLOBBER="${NOCLOBBER:-true}" # don't rebuild if we already have the .dsc
DPUT_HOST="${DPUT_HOST}" # optional host dput the resulting .dsc to

do_temporary_fixups() {
# patches needed to subsequent versions go here
case "$1" in
"1.8.0-nightly") # assume DEBDIR has 1.6
	dquilt delete wno-error # patch obsolete; applied upstream
	;;
esac
}

abort() { local x="$1"; shift; echo >&2 "$@"; exit "$x"; }

dquilt() {
    QUILT_PATCHES="debian/patches" \
    QUILT_PATCH_OPTS="--reject-format=unified" \
    QUILT_DIFF_ARGS="-p ab --no-timestamps --no-index --color=auto" \
    QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index" \
    quilt "$@"
}

HOST="https://static.rust-lang.org"
BASENAME="rustc-$CHANNEL-src.tar.gz"
JQUERY="https://code.jquery.com/jquery-2.1.4.js"

SCRIPTDIR="$(dirname "$0")"
DEBDIR="$(readlink -f ${DEBDIR:-$SCRIPTDIR})"
echo "using DEBDIR=$DEBDIR as debian tree to copy into upstream tarball"
test "$PWD" = "${PWD#$DEBDIR}" || abort 1 "must run from outside DEBDIR"
test -d "$DEBDIR" || abort 1 "DEBDIR not a directory: $DEBDIR"

set -x
set -e

$NOREMOTE || wget -N "$HOST/dist/$BASENAME"
$NOREMOTE || wget -N "$HOST/dist/$BASENAME.asc"
$NOREMOTE || gpg2 -v "$BASENAME.asc"
$NOREMOTE || wget -N "$HOST/dist/index.txt"
MODDATE1="$(grep "^/dist/$BASENAME," index.txt \
  | cut -d, -f3 | sed -e 's/\(.*\)-\(.*\)-\(.*\)T.*/\1\2\3/')"
MODDATE2="$(TZ=UTC stat "$BASENAME" -c %y | sed -e 's/\(.*\)-\(.*\)-\([0-9]*\) .*$/\1\2\3/')"
$NOREMOTE || test "$MODDATE1" = "$MODDATE2" || abort 2 "file mod times don't match, try again"
$NOREMOTE || wget -N "$JQUERY"

rm -rf "rustc-$CHANNEL"
tar xf "$BASENAME"

cd "rustc-$CHANNEL"
{
	echo "CFG_RELEASE_CHANNEL=$CHANNEL"
	echo "CFG_HASH_COMMAND=md5sum | cut -c1-8"
	sed -n -e '/^CFG_RELEASE/,/^##/{/^CFG_INFO/d;p}' mk/main.mk
	echo "all:"
	echo "	@echo export CFG_RELEASE=\$(CFG_RELEASE)"
} | make -f - > ./envvars
. ./envvars
NEWUPSTR="$(echo "$CFG_RELEASE.$MODDATE2+dfsg1" | sed -e 's/-beta/~beta/' -e 's/-nightly/~~nightly/')"
if $NOCLOBBER && test -f "../rustc_$NEWUPSTR-1.dsc"; then
	cd ..
	rm -rf "rustc-$CHANNEL"
	abort 0 "already have rustc_$NEWUPSTR-1.dsc; set NOCLOBBER=false if you want to force"
fi
cp -a "$DEBDIR" .
mk-origtargz --repack --compression xz -v "$NEWUPSTR" "../$BASENAME"
cd ..

rm -rf "rustc-$CHANNEL" "rustc-$NEWUPSTR"
tar xf "rustc_$NEWUPSTR.orig.tar.xz"
mv "rustc-$CHANNEL" "rustc-$NEWUPSTR"

libstd_ver() {
	dpkg-parsechangelog --show-field Version | sed -re 's/([^.]+)\.([^.]+)\..*/\1.\2/'
}

cd "rustc-$NEWUPSTR"
cp -a "$DEBDIR" .
OLD_LIBVER="$(libstd_ver)"
dch -D "$DIST" -v "$NEWUPSTR-1" "Team upload."
dch -a "Switch to $CHANNEL channel."
NEW_LIBVER="$(libstd_ver)"
$NOREMOTE || debian/make_orig-dl_tarball.py
rm debian/missing-sources/jquery-*
cp "../$(basename "$JQUERY")" debian/missing-sources
sed -i -e "s/$OLD_LIBVER/$NEW_LIBVER/" "debian/control"
sed -i -e 's/\(RELEASE_CHANNEL := \)\(.*\)/\1'"$CHANNEL"'/g' debian/rules
do_temporary_fixups "$CFG_RELEASE"
while dquilt push; do dquilt refresh; done
dquilt pop -a
rm -rf .pc
dpkg-buildpackage -d -S
cd ..

if test -n "$DPUT_HOST"; then
	dput "$DPUT_HOST" "rustc_$NEWUPSTR-1_source.changes"
else
	set +x
	echo "Source package built, but there is NO GUARANTEE THAT IT WORKS!"
	echo "You should now try to build it with \`sudo cowbuilder --build rustc_$NEWUPSTR-1.dsc\`"
fi
