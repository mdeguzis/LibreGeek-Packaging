#!/bin/bash

# Copyright (C) 2014 Sergio Benjamim

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

mkdir -p "$HOME/.config/dinothawr"
mkdir -p "$HOME/.config/dinothawr/saves"

CONFIG="$HOME/.config/dinothawr/dinothawr.cfg"

if ! [ -f $CONFIG ]; then
  cp /etc/dinothawr.cfg $CONFIG
fi

retroarch -c $CONFIG -L /usr/lib/libretro/dinothawr_libretro.so /usr/share/dinothawr/data/dinothawr.game

exit 0
