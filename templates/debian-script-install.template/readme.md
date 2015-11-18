# Notes

See the packaging-tutorial written by Lucas Nussbaum, the current Debian Project Leader. You can install it directly from a Debian repository:

# apt-get install packaging-tutorial

Then, open and skim the PDF located at /usr/share/doc/packaging-tutorial/packaging-tutorial.pdf. After skimming it you'll have the basic knowledge needed to understand the structure of a Debian package.

Now let's get our hands dirty. mv your script to a new directory. The name of the directory must follow the nomenclature upstreamname-*version*.
```
rul@helicon:/tmp/a$ mkdir script-0.1
rul@helicon:/tmp/a$ mv script.sh script-0.1
````
cd to the directory where your script is and run dh_make --createorig. Choose single binary. You'll now have a debian/ directory with lots of file in it. This files are the ones you need to make your package. In your case, most, if not all, of the *.ex files are safe to be removed. Read and modify when needed the remaining files.

Now let's write the core of our package. You want to install a script in /usr/local/bin. The good news is that there is already a program that does that for you. You just have to specify the file name and where to put it. This program is dh_install. It has a very complete man page. After reading it, you should now understand that you have to create a install file in the debian/ directory.
