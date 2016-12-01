# Notes

Linux doesn't pick up libraries in the same folder unless you've built it with rpath set to the current folder or have used LD_LIBRARY_PATH to override the rpath setting

LD_LIBRARY_PATH isn't something you set in your make file - it's something you add to a launcher script

rpath would be a compiler flag

