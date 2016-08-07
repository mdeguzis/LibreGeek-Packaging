# About

Next Previous Contents
3. Game Engines


# 3.1 TyrQuake

TyrQuake is a fairly complete project including OpenGL, Software Quake and QuakeWorld clients, and other tools including the popular TyrLite. Tyrann's focus is on a fully featured but minimalist cross-platform engine.
The latest version is 0.60, which now supports the Power PC platform, FreeBSD and per-user configuration files. Other newish features include sophisticated command line completion, and a cool console effect (gl_constretch).
Typing make will build all the clients. To compile only the single player client, after unpacking the source code type: make prepare tyr-glquake . Tyrann has a nice clean build system, but if you wish to see compilation feedback, add V=1 to the command line.

A patched TyrQuake binary is available here.

http://disenchant.net/engine.html


# 3.2 QuakeSpasm

FitzQuake has long been the defacto standard for the Quake mapping community, and this new project is based on the SDL Port of Fitz.

Features

As well as great FitzQuake features such as skyboxes, fog, coloured light, and support for huge maps, QuakeSpasm includes:

64 bit CPU support
Should work with most SDL platforms
Restructured sound driver
Custom console background
SDL CD audio
Tweaked command line completion, and a map name autocomplete
Alt+Enter toggles fullscreen
Tips

scr_sbaralpha .99 - Give a nicer status bar
maps - List available maps
game GAMENAME - On-the-fly change of game
./quakespasm -fitz - Run game in FitzQuake mode
http://quakespasm.sourceforge.net


# 3.3 Darkplaces

Darkplaces is an amazing Quake engine with a great range of visual enhancements and options for colour, effects and sound. It uses the same Doom3 lighting features as Tenebrae and thus requires a more powerful computer than GLQuake and QuakeForge.
It also supports many otherwise incompatible mods including Nehahra and Nexuiz, and has improved support for the official mission packs. Recent changes include improvements to the menuing system, and speed increases, though there also appears to be some mod compatability issues creeping in.
Havoc's file archive can be a little confusing. The large "darkplacesengine" tarballs include precompiled binaries and the game's source code in a second tarball. To compile your own program uncompress the second tarball , type make to see a list of possible targets (programs), and select one. For example - to build the OpenGL engine with ALSA sound type make cl-release, or to build with OSS sound, make cl-release DP_SOUND_API=OSS.
Thanks to LordHavoc for this great project.
http://www.icculus.org/twilight/darkplaces

# 3.4 Quore

From the Quore website:

Quore is an atmospheric Quake engine running on GNU/Linux systems with enhanced graphics, increased limits, configurable HUD and ambiences, and different modes for changing the gameplay. It is based on JoeQuake with additional effects from Qrack, ezQuake and engine's limits tweaking from Fitzquake
This game is great, and probably the most graphically modified Linux engine. But it also has many niggling bugs.
http://quore.free.fr/index.html


# 3.5 QuDos Quake Ports

QuDos has done much work with Quake engines for BSD and Linux. In the past he has ported Nehahra , JoeQuake and others, but currently has only a couple available at his website.
His excellent NehQuake port is still available at LinuxQuake.Org , but those after the source code may try contacting him.

http://qudos.quakedev.com/linux/quake1

3.6 MFCN's GLQuake

Here you'll find some relevant documentation and trouble shooting tips, and a basic version of OpenGL Quake for Linux. Fairly pain free by Linux standards, it supports most Quake mods, but gamma (brightness) support is broken.

http://mfcn.ilo.de/glxquake

# 3.7 Tenebrae

Tenebrae is a gorgeous Quake engine with lighting similar to that in Doom III. It's is an old project requiring a good GPU, and may not be compatible with all... the documentation is a fairly sparse.
There are several points of interest here...

Tenebrae has an "easter egg". In the quit game dialog press "d".
It includes the interesting "bumptest" and "zoo" maps.
A custom Tenebrae-1.0 engine is included with the atmospheric Industri mod.
Tenebrae doesn't run user mods.
The Tenebrae installer will install the shareware Quake levels, and all fancy Tenebrae models and textures, but is a 100 meg download. (Make sure to run the game in 32 bpp mode - see below). Try here for some binaries.

Compilation of the source code may not be straight forward. Firstly:

cd linux ; ln -s Makefile.i386linux Makefile ; make
If compilation fails with "../glquake.h:1137: conflicting types for ....", lines 1137 and 1138 need removing. You may also have to change the gethostname declaration in net_udp.c thus:
- extern int gethostname (char *, int);
+ extern int gethostname (char *, size_t);
After compilation, copy the binary "debugi386.glibc/bin/tenebrae.run" and the Tenebrae data files to your Quake folder. Finally, the game only runs in 32 bpp colours (X11 colour depth 24), so restart X in this mode if you have to, and execute the game with: tenebrae.run -basedir $PWD. Alternatively you can start a new X session with the command:

startx $PWD/tenebrae.run -basedir $PWD -- :1 -depth 24
http://tenebrae.sourceforge.net/


# 3.8 QuakeForge

QF is a comprehensive Linux Quake project. It has elegant graphical enhancements, numerous single player and QuakeWorld clients and Quake C tools. Amongst it's features are: an overhauled menuing system, a new "heads up display", and in-game help.
Possibly because of it's size, QuakeForge hasn't been updated in years and it's documentation was never quite finished. The usual "configure && make && make install" will build the whole project, but it does not appear to support a minimal single player build option. QuakeForge's default directory is "/usr/local/share/games/quakeforge", so ensure to link to your "id1" directory from here. (For example ln -s /usr/local/games/quake/id1 /usr/local/share/games/quakeforge/id1).
For information about building QuakeForge on the BSD Unices, see the FreeBSD section.

Kudos to the QuakeForge team for a huge project which has provided much inspiration for other open source games.

http://www.quakeforge.net
http://sourceforge.net/projects/quake/


# 3.9 NPRQuake

Another Quake engine which has been ported to Linux but, as far as I know, hasn't been touched in a few years is NPRQuake. Notably, it has the ability to load different renderers on the fly, which is pretty cool. The Linux port includes support for the cartoon renderer ainpr, and works really well for me.

The SDL version has rewritten mouse and video code, but the sound APIs have not been ported to SDL, and it is not a fully portable engine.

http://www.cs.wisc.edu/graphics/Gallery/NPRQuake/

3.10 Twilight Project

The Twilight Project "is a set of rather minimalist NQ and QW engines that focus on insane rendering speed, it is however a bit unstable at the moment."

This game is ~quick~, with a plain looking, but useful menu system, so users with a slow computer should definitely give this a go. It also has some unique graphical effects and an unusual user interface.

To compile version 0.2.2 of this project, you'll need the python scripting language installed, and perhaps to make this change to src/nq/pr_edict.c , line 1108:

-               if (progs->ofs_strings + pr_stringssize >= com_filesize)
+               if (progs->ofs_strings + pr_stringssize >= (uint)com_filesize)
Executing scons.py will now (hopefully) build the binaries, and after copying the single player client (twilight-nq) to your quake directory, type twilight-nq -basedir $PWD to start the game.
If you're having trouble with compilation, version 0.2.01 uses the traditional "configure && make && make install" method, so you may want to try it.

Game saves are an issue with this engine. There are no game save or load menus, and this can only be done using the "F6" and "F9" keys to quicksave and load. Additionally, this feature often won't work if you started with the "map MAPNAME" command, so make sure you begin games in a normal fashion, through the "Start Game" menu.

http://icculus.org/twilight

# 3.11 Audio Quake

This engine is for visually disabled people, and uses sound to help with navigation. It includes OpenGL and SDL clients.

http://www.agrip.org.uk/


# 3.12 SDL Quake

This basic version of Quake is not really of interest to Linux users as it uses a very old code base, and has few features. It's main feature is the use of the SDL programming API for sound, video and mouse handling, and should run on all SDL supported operating systems without major changes.

SDL Quake does have a bug relating to music: running the game with an audio CD in the drive will limit the game's speed. To avoid this simply remove the CD, or use the -nocdaudio option.

The game runs at a fixed resolution; the width and height can't be changed. To play in fullscreen mode, use the -fullscreen option.

http://www.libsdl.org/projects/quake

# 3.13 wmQuake

WindowMaker is a window manager for X11, and this tiny version of Quake fits in an 64x64 pixel dockable applet. You can test it out even if you don't have WindowMaker, but the game will crash if it gets keyboard focus.

For the curious, this game can be benchmarked with timedemo demo1 after removing the "usleep" commands from sys_linux.c.

http://freshmeat.net/projects/wmquake/

3.14 Software Quake

For a more in-depth treatment of Software Quake, see the previous version of this how-to.

The original WinQuake source also came with two pixelated versions of the game:

X Quake (quake.x11)
Svga Quake (squake)
but compiling them is no longer straight forward. It involves copying Makefile.linux to Makefile, editing this file to remove the extra targets , replacing /usr/X11/lib with /usr/X11R6/lib and typing make build_release.

There are easier options though. TyrQuake and QuakeForge have software clients, and there is also an old SDLQuake written by SDL's author, Sam Lantinga, which should work on all modern platforms.

Next Previous Contents


# Refernces

* [Quaddicted list of engines](https://www.quaddicted.com/quake/recommended_engines)
