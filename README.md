# DEPRECATED !!!!!!

Hammerspoon configuration, fork from [https://github.com/ashfinal/awesome-hammerspoon].

## File structure
### custom.lua
- Set hot configuration keys
- preloading some packages
### init.lua
- binding the prefixes to modal functions

## Include luarocks libarary
https://github.com/Hammerspoon/hammerspoon/issues/363

- Find the lua version used with
```
grep LUA_VERSION_MAJOR -A 10  /Applications/Hammerspoon.app/Contents/Frameworks/LuaSkin.framework/Versions/A/Headers/lua.h
```

- Install the lua and luarocks
```
brew install lua@5.4
brew install luarocks
```

- Install luarocks library

``` shell
ln -sf /usr/local/share/lua/5.4/luarocks ~/.hammerspoon/
# or
ln -sf /opt/homebrew/share/lua/5.4/luarocks ~/.hammerspoon
```

## Self compile projects
### ~/repo/standalone/hammerspoon
- Use the chooser schema to built the dylib and nib
- Override the dylib and nib with script in ~/vif-bin/hs/
  + First use base/back.sh to backup
  + Override with override/copy-built.sh
