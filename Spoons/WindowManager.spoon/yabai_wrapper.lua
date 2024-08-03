---@type spoon.Utils
local U = hs.loadSpoon("Utils")
local M = U.moses
local cwrap, execSync, cwrapExec = U.command.cwrap, U.command.execSync, U.command.cwrapExec

---@class YabaiWrapper
local obj = {}

local function execJson (fmt, ...)
  local output = execSync(fmt, ...)
  return hs.json.decode(output)
end

---@return Window[]
function obj.windows ()
  ---@type Window[]
  return execJson("yabai -m query --windows")
end

---@return Window
function obj.singleWindow (windowId)
  ---@type Window
  return execJson("yabai -m query --windows --window %s", windowId or "")
end

--- @return Space[]
function obj.spaces ()
  ---@type Space[]
  return execJson("yabai -m query --spaces")
end

function obj.singleSpace (spaceId)
  ---@type Space
  return execJson("yabai -m query --spaces --space %s", spaceId or "")
end

--- @return Display[]
function obj.displays ()
  ---@type Display[]
  return execJson("yabai -m query --displays")
end

function obj.singleDisplay (displayId)
  ---@type Display
  return execJson("yabai -m query --displays --display %s", displayId or "")
end

function obj.maxSpaceIndexInCurrentDisplay ()
  return tonumber(execSync("yabai -m query --displays --display | jq '.spaces | max'"))
end

function obj.runScript (scriptPath)
  local scriptDir = os.getenv("HOME") .. "/.config/yabai/"
  return execSync(scriptDir .. scriptPath)
end

function obj.moveWindowToSpace (winId, spaceIndex, focus)
  return execSync("yabai -m window %s --space %s %s", winId or "", spaceIndex, (focus and "--focus" or ""))
end

function obj.swapWindows (winId, otherWinId)
  return execSync("yabai -m window %d --swap %d", winId, otherWinId)
end

function obj.stackWindows (winId, otherWinId)
  return execSync("yabai -m window %d --stack %d", winId, otherWinId)
end

function obj.switchLayout (layout)
  return execSync("yabai -m space --layout %s", layout)
end

function obj.focusWindow (windowId)
  return execSync("yabai -m window --focus %s", windowId)
end

function obj.focusSpace (spaceId)
  return execSync("yabai -m space --focus %s", spaceId)
end

function obj.focusDisplay (displayId)
  return execSync("yabai -m display --focus %s", displayId)
end

function obj.visibleSpaces ()
  return M.select(obj.spaces(),
    function(space, _) ---@param space Space
      return space["is-visible"]
    end)
end

function obj.visibleSpaceIndexes ()
  return M.map(obj.visibleSpaces(),
    function(space, _) ---@param space Space
      return space.index
    end)
end

---@param apps string|table
---@return Window[]
function obj.appWindows (apps)
  local appNames = type(apps) == "string" and { apps } or apps
  return M.select(obj.windows(),
    function(window, _) ---@param window Window
      return M.find(appNames, window.app) ~= nil
    end)
end

function obj.windowToggle (windowId, operation)
  return execSync("yabai -m window %s --toggle %s", windowId or "", operation)
end

function obj.restartService ()
  return execSync("yabai --restart-service || yabai --start-service")
end

function obj.stopService ()
  return execSync("yabai --stop-service")
end

function obj.switchSpace (fromSpaceId, toSpaceId)
  return execSync("yabai -m space %s --switch %s", fromSpaceId or "", toSpaceId)
end

function obj.pickWindow (windowId)
  local win = obj.singleWindow(windowId)
  local curSpace = obj.singleSpace()
  local toggleFloat = (not win["is-floating"]) and "" or "--toggle float"
  execSync(string.format("yabai -m window %d --space %d --focus %s",
    windowId, curSpace.index, toggleFloat))
end

function obj.hideOtherWindowsInCurrentSpace()
  local scratchSpaceIndex = obj.maxSpaceIndexInCurrentDisplay()
  execSync(string.format("yabai -m query --windows --space | jq -r '.[] |" ..
      "select(.[\"has-focus\"] == false and .space != %d)'" ..
      "| jq '.id' | xargs -I{} yabai -m window {} --space %d",
      scratchSpaceIndex, scratchSpaceIndex))
end

function obj.showSpaceOnDisplay(displayIndex, spaceIndex)
  execSync("yabai -m display %d --space %d", displayIndex, spaceIndex)
end

---@return Space?, Space?
function obj.twoSpaces()
  local spaces = obj.visibleSpaces()
  local focusedSpace = obj.singleSpace()
  local otherSpace = M.select(spaces, function(space, _) ---@param space Space
                                return focusedSpace.index ~= space.index
                                end)
  return focusedSpace, M.count(otherSpace) > 0 and otherSpace[1] or nil
end

---@param window Window
---@param spaceIndex number?
---@param scratchpad Scratchpad
function obj.showScratchPad(window, spaceIndex, scratchpad)
  local spaceSwitch = (window.space ~= spaceIndex) and "--space " .. spaceIndex or ""
  local toggleFloat = ((not window["is-floating"]) and "" .. "--toggle float" or "")
  local focuseCommand = string.format(
      "yabai -m window %d %s %s --grid %s --opacity %.2f --focus",
       window.id, spaceSwitch, toggleFloat, scratchpad.grid, scratchpad.opacity)
  local gridCommand = string.format(
      "yabai -m window %d --grid %s",
     window.id, scratchpad.grid)
    execSync(focuseCommand .. " && " .. gridCommand)
end

return obj
