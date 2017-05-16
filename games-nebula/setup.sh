#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo '#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export WINEARCH=win32
python2 "$DIR/games_nebula.py"' > "$DIR/start.sh"
chmod +x "$DIR/start.sh"

mkdir -p $HOME'/.local/share/applications'
echo "[Desktop Entry]
Name=Games Nebula
Comment=Application for managing and playing games
Exec=$DIR/start.sh
Icon=$DIR/images/icon.png
Type=Application
Terminal=false
Categories=Game;" > $HOME'/.local/share/applications/games_nebula.desktop'
chmod +x  $HOME'/.local/share/applications/games_nebula.desktop'
