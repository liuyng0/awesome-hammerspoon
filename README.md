Hammerspoon configuration, fork from [https://github.com/ashfinal/awesome-hammerspoon].


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
```
ln -sf /usr/local/share/lua/5.4/luarocks ~/.hammerspoon/
```
