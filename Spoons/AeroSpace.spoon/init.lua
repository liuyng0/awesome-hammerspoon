--- === AeroSpace ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/AeroSpace.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/AeroSpace.spoon.zip)

---@class spoon.AeroSpace
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AeroSpace"
obj.version = "0.1"
obj.author = "Your Name <your@email.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- AeroSpace.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new("AeroSpace", "info")
obj.program = "aerospace"

local M = U.moses
local command = U.command
local cwrap = U.command.cwrap
local ws = hs.loadSpoon("WindowSelector") --[[@as spoon.WindowSelector]]
local rb = hs.loadSpoon("RecursiveBinder")
local sk = rb.singleKey

local function execSync (fmt, ...)
  local cmd = string.format(fmt, ...)
  obj.logger.i("run command: [" .. cmd .. "]")
  local output, ec, stderr = command.execTaskInShellSync(cmd, nil, false)
  if ec and ec ~= 0 then
      obj.logger.e(string.format("Failed command command: %s, error: %s", cmd, stderr))
  end
  return output, ec, stderr
end

local function cwrapExec (fmt, ...)
   local x = table.unpack({...})
   return cwrap(function()
         execSync(fmt, x)
   end)
end

local function aerospace(fmt, ...)
   return execSync("%s " .. fmt, obj.program, ...)
end

local function cwrapAspace(fmt, ...)
   local x = table.unpack({...})
   return cwrap(function()
         aerospace(fmt, x)
   end)
end


function obj.launchAppFunc (appName, currentSpace)
   return cwrapExec("open -a \"%s\"", appName)
end

function obj.moveW2SFunc(spaceIndex, follow)
   return cwrap(function()
      aerospace("move-node-to-workspace %d", spaceIndex)
      if follow then
         aerospace("workspace %d", spaceIndex)
      end
   end)
end

function obj.swapWithOtherWindowFunc()
   return function()
      error("doesn't support yet!")
   end
end

function obj.focusNextScreenFunc()
   return function()
      error("doesn't support yet!")
   end
end

function obj.stackAppWindowsFunc()
   return function()
      error("doesn't support yet!")
   end
end

function obj.reArrangeSpacesFunc ()
   return function()
      error("doesn't support yet!")
   end
end

function obj.startOrRestartServiceFunc ()
   return cwrapExec("open -a AeroSpace && aerospace reload-config")
end

function obj.stopServiceFunc ()
   return function()
      error("doesn't support yet!")
   end
end

function obj.swapVisibleSpacesFunc()
   return function()
      error("doesn't support yet!")
   end
end

function obj.hideAllScratchpadsFunc ()
   return function()
      error("doesn't support yet!")
   end
end

function obj.focusVisibleWindowFunc(onlyCurrentSpace)
   return function()
      error("doesn't support yet!")
   end

end

function obj.focusSpaceFunc(spaceIndex)
   return cwrapAspace("workspace %d", spaceIndex)
end


function obj.focusOtherWindowFunc (onlyFocusedApp, onlyFocusedSpace)
 return function()
      error("doesn't support yet!")
   end

end
function obj.makePadMapFunc (curSpace)
   return function()
      error("doesn't support yet!")
   end

end

function obj.nextLayoutFunc()
   return {
        [sk('t', 'tiles(h/v)')] = cwrapAspace('layout tiles horizontal vertical'),
        [sk("a", "accordion(h/v)")] = cwrapAspace('layout accordion horizontal vertical'),
   }
end

function obj.showInfoFunc()
   return function()
      error("doesn't support yet!")
   end

end

return obj
