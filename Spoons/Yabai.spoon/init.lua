--- === Yabai ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Yabai.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Yabai.spoon.zip)

---@class spoon.Yabai
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Yabai"
obj.version = "0.1"
obj.author = "Your Name <your@email.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- Yabai.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new("Yabai")
obj.program = "/opt/homebrew/bin/yabai"

local M = U.moses
local F = U.F
local command = U.command

local function execSync (args)
  return command.execTaskInShellSync(obj.program .. " " .. args, nil, false)
end

--- @return Window[]
function obj:windows (index)
  ---@type Window[]
  return hs.json.decode(execSync([[-m query --windows]] .. index and " --window " .. index or ""))
end

--- @return Space[]
function obj:spaces (index)
  ---@type Space[]
  return hs.json.decode(execSync([[-m query --spaces]] .. index and " --space " .. index or ""))
end

--- @return Display[]
function obj:displays (index)
  ---@type Display[]
  return hs.json.decode(execSync([[-m query --displays]] .. index and " --display " .. index or ""))
end

--- @return Focus?
function obj:focusedWSD ()
  ---@type string|nil
  local windowJson = execSync [===[-m query --windows | jq '.[] | select(.["has-focus"] == true)']===]
  if windowJson then
    ---@type Window
    local window = hs.json.decode(windowJson)
    return {
      windowId = window.id,
      displayIndex = window.display,
      spaceIndex = window.space,
      frame = window.frame,
      app = window.app,
      title = window.title
    }
  end
end

local function toint (val)
  if val == nil then
    return nil
  end
  local num = tonumber(val)
  if num == nil then
    return nil
  end
  return math.floor(tonumber(val))
end

--- move window to space
function obj:moveWindowToSpace (winId, spaceIndex, follow)
  local focus = obj:focusedWSD()
  local _winId = winId or (focus and focus.windowId)
  local spacesLen = toint(execSync("-m query --spaces | jq -rj '. | length'"))

  if spacesLen >= spaceIndex then
    -- adding the window selector to move command solves some buggy behavior by yabai when dealing with windows without menubars
    execSync("-m window " .. _winId .. " --space " .. spaceIndex .. (follow and " --focus " or ""))
  end
end

function obj:moveWindowToDisplay (winId, display, follow)

end

function obj:swapWindow (winId, otherWinId, focus)

end

function obj:moveFocusedWindowToNextSpace (follow)
  local nextSpace = obj:getNextSpaces(true)[1]
  local follow_param
  if follow and follow == true then
    follow_param = " --focus"
  else
    follow_param = ""
  end
  obj.yabai("window", "--space " .. nextSpace .. follow_param)
end

function obj:getFocusedWindow ()
  return M.chain(obj:windows()):
  select( --- @param window Window
    function(window, _)
      return window["has-focus"]
    end
  ):value()[1]
end

function obj:focusedSpace ()
  return M.chain(obj:spaces()):
  select( --- @param space Space
    function(space, _)
      return space["has-focus"] == true
    end
  ):value()[1]
end

--- @param spaces Space[] | number[]
function obj:focusSpace (spaces)
  M.chain(spaces):each(
  --- @param space Space | number
    function(space, _)
      local spaceIndex = type(space) == "number" and space or space.index
      obj.yabai("space", "--focus " .. spaceIndex)
    end
  ):value()
end

function obj:gotoNextSpaces ()
  obj:focusSpace(obj:getNextSpaces())
end

function obj:getCurrentSpaces ()
  return M.chain(obj:spaces()):
  select(
  --- @param space Space
    function(space, _)
      return space["is-visible"] == true
    end
  ): --- @param space Space
  groupBy(
    function(space, _)
      return space.display
    end
  ):map(
    function(displayIds, _)
      return displayIds[1]
    end
  ):value()
end

--- @return number[] spaceIndex
function obj:getNextSpaces (onlyCurrentDisplay)
  local spacesMap = obj:getCurrentSpaces()
  obj.logger.w("spacesMap" .. hs.inspect(spacesMap))
  local cycleNext = function(ids, current)
    -- obj.logger.e("ids" ..
    --    hs.inspect(ids) .. " current: " .. hs.inspect(current))
    local sorted = M.sort(ids)
    local index = M.detect(sorted, current)
    local count = 1
    for v, _ in M.cycle(sorted, 2) do
      if count == index + 1 then
        return v
      end
      count = count + 1
    end
  end

  local displays = obj:displays()
  if onlyCurrentDisplay then
    displays =
        M.chain(displays):
        select(
        --- @param display Display
          function(display, _)
            return display["has-focus"] == true
          end
        ):value()
  end
  return M.chain(displays):sort(
  --- @param a Display
  --- @param b Display
    function(a, b)
      if (a["has-focus"] == true) then
        return true
      end
      if (b["has-focus"] == true) then
        return false
      end
      return a.index < b.index
    end
  ):
  map(
  --- @param a Display
    function(a, _)
      return cycleNext(a.spaces, spacesMap[a.index].index)
    end
  ):value()
end

--- Switch to app window prefer current mission control
--- @return boolean true if switched to app, flase if no window with specified app name
function obj:switchToApp (appName)
  local wins = obj:windows()
  ---@type Space
  local space = obj:focusedSpace()
  obj.logger.e("space is " .. hs.inspect(space))
  local win
  M.chain(wins)
      :select(function(win, _)
        -- obj.logger.e("win is " .. hs.inspect(win))
        obj.logger.e("win.app", win.app == appName)
        return win.app == appName
      end)
      :groupBy(
        function(win, _)
          if win.space ~= space.index then
            return 1
          else
            return 2
          end
        end)
      :flatten()
      :value()
  obj.logger.e("win is " .. hs.inspect(win))
  if win and #win >= 1 then
    local command = string.format(
      "/opt/homebrew/bin/yabai -m window --focus %d 2>&1", win[1].id)
    obj.logger.e(string.format("start to run %s", command))
    -- obj.pipe(command)
    return true
  end
  return false
end

---@return spoon.Yabai
return obj
