--- === WindowManager ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WindowManager.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WindowManager.spoon.zip)

---@class WindowManager
local obj={}
obj.__index = obj

-- Metadata
obj.name = "WindowManager"
obj.version = "0.1"
obj.author = "Your Name <your@email.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- WindowManager.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('WindowManager')

---@param wm WM.Yabai | WM.AeroSpace
---@param functionName string
local function f(wm, functionName, moduleName, isMappingFunc)
   if wm[functionName] and type(wm[functionName]) == "function" then
      return wm[functionName]
   else
      obj.logger.w(string.format("No function with name %s in %s exist, bind to mock!", functionName, moduleName))
      if isMappingFunc then
         return function(...)
            return {}
         end
      else
         return function(...)
            return function(...)
               error(string.format("Not implemented function in %s", moduleName))
            end
         end
      end
   end
end

---@param wm WM.Yabai | WM.AeroSpace
local function registerWM(wm, fromModule)
   obj.launchAppFunc = f(wm, "launchAppFunc", fromModule)
   obj.moveW2SFunc = f(wm, "moveW2SFunc", fromModule)
   obj.focusOtherWindowFunc = f(wm, "focusOtherWindowFunc", fromModule)
   obj.swapWithOtherWindowFunc = f(wm, "swapWithOtherWindowFunc", fromModule)
   obj.swapVisibleSpacesFunc = f(wm, "swapVisibleSpacesFunc", fromModule)
   obj.focusNextScreenFunc = f(wm, "focusNextScreenFunc", fromModule)
   obj.focusVisibleWindowFunc = f(wm, "focusVisibleWindowFunc", fromModule)
   obj.nextLayoutFunc = f(wm, "nextLayoutFunc", fromModule)
   obj.focusSpaceFunc = f(wm, "focusSpaceFunc", fromModule)
   obj.hideAllScratchpadsFunc = f(wm, "hideAllScratchpadsFunc", fromModule)
   obj.makePadMapFunc = f(wm, "makePadMapFunc", fromModule)
   obj.showInfoFunc = f(wm, "showInfoFunc", fromModule)
   obj.reArrangeSpacesFunc = f(wm, "reArrangeSpacesFunc", fromModule)
   obj.stackAppWindowsFunc = f(wm, "stackAppWindowsFunc", fromModule)
   obj.startOrRestartServiceFunc = f(wm, "startOrRestartServiceFunc", fromModule)
   obj.stopServiceFunc = f(wm, "stopServiceFunc", fromModule)
   obj.toggleZoomFullScreenFunc = f(wm, "toggleZoomFullScreenFunc", fromModule)
   obj.toggleFloatFunc = f(wm, "toggleFloatFunc", fromModule)
   obj.pickWindowsFunc = f(wm, "pickWindowsFunc", fromModule)
   obj.moveOthersToHiddenSpaceFunc = f(wm, "moveOthersToHiddenSpaceFunc", fromModule)
   obj.selectVisibleWindowToHideFunc = f(wm, "selectVisibleWindowToHideFunc", fromModule)
   obj.selectNthSpacesInAllDisplaysFunc = f(wm, "selectNthSpacesInAllDisplaysFunc", fromModule)
   obj.resizeWindowMapping = f(wm, "resizeWindowMapping", fromModule, true)
   obj.restartSketchybar = f(wm, "restartSketchybar", fromModule)
   obj.normalize = f(wm, "normalize", fromModule)
   obj.closeWindow = f(wm, "closeWindow", fromModule)
end

---@type WM.Yabai
local yabai = dofile(hs.spoons.resourcePath("yabai.lua"))
---@type WM.AeroSpace
local aerospace = dofile(hs.spoons.resourcePath("aerospace.lua"))
registerWM(yabai, "yabai")

return obj
