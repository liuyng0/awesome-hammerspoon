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

local function registerToYabai()
   ---@type spoon.Yabai
   ---@diagnostic disable
   local yabai = hs.loadSpoon("Yabai")
   obj.launchAppFunc = yabai.launchAppFunc
   obj.moveW2SFunc = yabai.moveW2SFunc
   obj.focusOtherWindowFunc = yabai.focusOtherWindowFunc
   obj.swapWithOtherWindowFunc = yabai.swapWithOtherWindowFunc
   obj.swapVisibleSpacesFunc = yabai.swapVisibleSpacesFunc
   obj.focusNextScreenFunc = yabai.focusNextScreenFunc
   obj.focusVisibleWindowFunc = yabai.focusVisibleWindowFunc
   obj.nextLayoutFunc = yabai.nextLayoutFunc
   obj.focusSpaceFunc = yabai.focusSpaceFunc
   obj.hideAllScratchpadsFunc = yabai.hideAllScratchpadsFunc
   obj.makePadMapFunc = yabai.makePadMapFunc
   obj.showInfoFunc = yabai.showInfoFunc
   obj.reArrangeSpacesFunc = yabai.reArrangeSpacesFunc
   obj.stackAppWindowsFunc = yabai.stackAppWindowsFunc
   obj.startOrRestartServiceFunc = yabai.startOrRestartServiceFunc
   obj.stopServiceFunc = yabai.stopServiceFunc
end

registerToYabai()

return obj
