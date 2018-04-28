# About
A bunch of modules for inclusion in flatpak build recipes                                                                           

# Credits and Authors

* https://github.com/casept/flatpak-modules

# Notes    
These modules are only compatible with flatpak-builder 0.9.3 and later due to some backwards-incompatible changes.     

# Using a module
And add whichever module you need to your main .json under the modules key, for example:    
```
json
"modules": [
  "modules/ffmpeg-3.2.4.json",    
  your-own-stuff-here
```

