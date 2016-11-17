#!/bin/bash
update() {
local OLD=$1 ORIG=$2 NEW=$3

sed -i -e "s|libstd-rust-$ORIG|libstd-rust-$NEW|g" \
       -e "s|rustc (<= $ORIG|rustc (<= $NEW|g" \
       -e "s|rustc (>= $OLD|rustc (>= $ORIG|g" control

git mv libstd-rust-$ORIG.lintian-overrides libstd-rust-$NEW.lintian-overrides
sed -i -e "s|libstd-rust-$ORIG|libstd-rust-$NEW|g" libstd-rust-$NEW.lintian-overrides
sed -i -e "s|libstd-rust-$ORIG|libstd-rust-$NEW|g" source/lintian-overrides
}

update 1.8 1.9 1.10
