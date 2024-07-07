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

local M = U.moses
local F = U.F

--- @class Frame
--- @field x number
--- @field y number
--- @field w number
--- @field h number

--- @class Space
--- @field id number
--- @field uuid string
--- @field index number
--- @field label string
--- @field type string
--- @field display number
--- @field windows number[]
--- @field first-window number
--- @field last-window number
--- @field has-focus boolean
--- @field is-visible boolean
--- @field is-native-fullscreen boolean

--- @class Display
--- @field id number
--- @field uuid string
--- @field index number
--- @field label string
--- @field frame Frame
--- @field spaces number[]
--- @field has-focus boolean

--- @class Window
--- @field id number
--- @field pid number
--- @field app string
--- @field title string
--- @field scratchpad string
--- @field frame Frame
--- @field role string
--- @field subrole string
--- @field root-window boolean
--- @field display number
--- @field space number
--- @field level number
--- @field sub-level number
--- @field layer string
--- @field sub-layer string
--- @field opacity number
--- @field split-type string
--- @field split-child string
--- @field stack-index number
--- @field can-move boolean
--- @field can-resize boolean
--- @field has-focus boolean
--- @field has-shadow boolean
--- @field has-parent-zoom boolean
--- @field has-fullscreen-zoom boolean
--- @field has-ax-reference boolean
--- @field is-native-fullscreen boolean
--- @field is-visible boolean
--- @field is-minimized boolean
--- @field is-hidden boolean
--- @field is-floating boolean
--- @field is-sticky boolean
--- @field is-grabbed boolean

function obj.pipe (command)
  -- obj.logger.wf("Run yabai command: %s", command)
  local output, status, _type, rc = hs.execute(command)
  if status then
    return output
  else
    error("Command failed with error return code, command: "
      .. command .. " rc: " .. rc .. ", output: " .. output)
  end
end

function obj.yabai (method, extra_params)
  return obj.pipe("/opt/homebrew/bin/yabai" .. " -m " .. method .. " " .. extra_params .. " 2>&1")
end

--- @return Window[]
function obj:windows ()
  local windows = hs.json.decode(obj.yabai("query", "--windows"))
  ---@cast windows Window[]
  return windows
end

--- @return Space[]
function obj:spaces ()
  local spaces = hs.json.decode(obj.yabai("query", "--spaces"))
  ---@cast spaces Space[]
  return spaces
end

--- @return Display[]
function obj:displays ()
  local displays = hs.json.decode(obj.yabai("query", "--displays"))
  ---@cast displays Display[]
  return displays
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
        obj.logger.e("win is " .. hs.inspect(win))
        obj.logger.e("equality is " .. win.app == appName)
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

return obj
