--- === Yabai ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Yabai.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Yabai.spoon.zip)

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

local pipe = function(command)
  local output, status, _type, rc = hs.execute(command)
  if status then
    return output
  else
    error("Command failed with error return code, command: "
      .. command .. " rc: " .. rc .. ", output: " .. output)
  end
end

local yabai = function(method, extra_params)
  return pipe("/opt/homebrew/bin/yabai" .. " -m " .. method .. " " .. extra_params .. " 2>&1")
end

--- @return Window[]
function obj:windows ()
  local windows = hs.json.decode(yabai("query", "--windows"))
  ---@cast windows Window[]
  return windows
end

--- @return Space[]
function obj:spaces ()
  local spaces = hs.json.decode(yabai("query", "--spaces"))
  ---@cast spaces Space[]
  return spaces
end

--- @return Display[]
function obj:displays ()
  local displays = hs.json.decode(yabai("query", "--displays"))
  ---@cast displays Display[]
  return displays
end

--- @param space Space
function obj:moveFocusedWindowToNextSpace (follow)
  local nextSpace = obj:getNextSpaces(true)[1]
  local follow_param
  if follow and follow == true then
    follow_param = " --focus"
  else
    follow_param = ""
  end
  yabai("window", "--space " .. nextSpace .. follow_param)
end

function obj:getFocusedWindow ()
  return M.chain(obj:windows()): --- @param window Window
  select(
    function(window, _)
      return window["has-focus"]
    end
  ):value()[1]
end

--- @param spaces Space[] | number[]
function obj:focusSpace (spaces)
  M.chain(spaces):each(
  --- @param space Space | number
    function(space, _)
      local spaceIndex = type(space) == "number" and space or space.index
      yabai("space", "--focus " .. spaceIndex)
    end
  ):value()
end

function obj:gotoNextSpaces ()
  obj:focusSpace(obj:getNextSpaces())
end

function obj:getCurrentSpaces ()
  return M.chain(obj:spaces()): --- @param space Space
  select(
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
        M.chain(displays): --- @param display Display
        select(
          function(display, _)
            return display["has-focus"] == true
          end
        ):value()
  end
  return M.chain(displays): --- @param a Display
  --- @param b Display
  sort(
    function(a, b)
      if (a["has-focus"] == true) then
        return true
      end
      if (b["has-focus"] == true) then
        return false
      end
      return a.index < b.index
    end
  ): --- @param a Display
  map(
    function(a, _)
      return cycleNext(a.spaces, spacesMap[a.index].index)
    end
  ):value()
end

return obj
