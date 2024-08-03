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

---@type WM.Yabai
local yabai = dofile(hs.spoons.resourcePath("yabai/yabai.lua"))
---@type WM.AeroSpace
local aerospace = dofile(hs.spoons.resourcePath("aerospace/aerospace.lua"))

local function registerWM()
   local wm = yabai
   obj.launchAppFunc = wm.launchAppFunc
   obj.moveW2SFunc = wm.moveW2SFunc
   obj.focusOtherWindowFunc = wm.focusOtherWindowFunc
   obj.swapWithOtherWindowFunc = wm.swapWithOtherWindowFunc
   obj.swapVisibleSpacesFunc = wm.swapVisibleSpacesFunc
   obj.focusNextScreenFunc = wm.focusNextScreenFunc
   obj.focusVisibleWindowFunc = wm.focusVisibleWindowFunc
   obj.nextLayoutFunc = wm.nextLayoutFunc
   obj.focusSpaceFunc = wm.focusSpaceFunc
   obj.hideAllScratchpadsFunc = wm.hideAllScratchpadsFunc
   obj.makePadMapFunc = wm.makePadMapFunc
   obj.showInfoFunc = wm.showInfoFunc
   obj.reArrangeSpacesFunc = wm.reArrangeSpacesFunc
   obj.stackAppWindowsFunc = wm.stackAppWindowsFunc
   obj.startOrRestartServiceFunc = wm.startOrRestartServiceFunc
   obj.stopServiceFunc = wm.stopServiceFunc
   obj.toggleZoomFullScreenFunc = wm.toggleZoomFullScreenFunc
   obj.toggleFloatFunc = wm.toggleFloatFunc
   obj.pickWindowsFunc = wm.pickWindowsFunc
   obj.moveOthersToHiddenSpaceFunc = wm.moveOthersToHiddenSpaceFunc
   obj.selectVisibleWindowToHideFunc = wm.selectVisibleWindowToHideFunc
   obj.selectNthSpacesInAllDisplaysFunc = wm.selectNthSpacesInAllDisplaysFunc
   obj.resizeWindowMapping = wm.resizeWindowMapping
end

registerWM()

return obj
