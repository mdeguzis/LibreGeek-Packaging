# File explanations
See: [Chapter 7 - Basics of the Debian package management system](https://www.debian.org/doc/manuals/debian-faq/ch-pkg_basics.en.html)

* src/ - where are your install files can go (can be named something else)
* debian/control - debian control file
* debian/copyright - where you place your copyright file text
* debian/changelog - the latest changes for your package
* debian/postinst - optional file that describes what to do after your package is installed
* debian/preinst - optional file that describes what to do before your package is installed
* debian/rules - describes what needs building and install the files in the right place. If you just need to copy some files and not to compile stuff, just create/edit the file debian/install to specify which files need to be installed where.

# Notes

See the packaging-tutorial written by Lucas Nussbaum, the current Debian Project Leader. You can install it directly from a Debian repository:

```
apt-get install packaging-tutorial
```

Then, open and skim the PDF located at /usr/share/doc/packaging-tutorial/packaging-tutorial.pdf. After skimming it you'll have the basic knowledge needed to understand the structure of a Debian package.

Now let's get our hands dirty. mv your script to a new directory. The name of the directory must follow the nomenclature upstreamname-*version*.

```
#:/tmp/a$ mkdir script-0.1
#:/tmp/a$ mv script.sh script-0.1
````

cd to the directory where your script is and run dh_make --createorig. Choose single binary. You'll now have a debian/ directory with lots of file in it. This files are the ones you need to make your package. In your case, most, if not all, of the *.ex files are safe to be removed. Read and modify when needed the remaining files.

Now let's write the core of our package. You want to install a script in /usr/local/bin. The good news is that there is already a program that does that for you. You just have to specify the file name and where to put it. This program is dh_install. It has a very complete man page. After reading it, you should now understand that you have to create a install file in the debian/ directory.

```
#:/tmp/a/script-0.1$ echo "script.sh usr/local/bin/" > debian/install
```

# Example .install file

```
*py usr/share/themole/
connection/* usr/share/themole/connection/
dbmsmoles/* usr/share/themole/dbmsmoles/
queryfilters/* usr/share/themole/queryfilters/
requestfilters/* usr/share/themole/requestfilters/
responsefilters/* usr/share/themole/responsefilters/
```

# Finish the package steps

Now you have all you need to build your package. cd to the root directory of your package and run dpkg-buildpackage. If all went well, you'll have your fresh new .deb in ../.
