--- === WindowSelector ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WindowSelector.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WindowSelector.spoon.zip)

---@class spoon.WindowSelector
local obj = {}
obj.__index = obj

---@type spoon.Utils
local U = hs.loadSpoon("Utils")
---@type utils.moses
local M = U.moses
local wf = hs.window.filter
--- @type utils.hints
local hints = U.hints

--- Re-order the alphabets
hints.hintChars = {
  "J", "U", "M",
  "H", "Y", "N",
  "K", "L",  "I", "O", "P", "B",
  "A", "C", "D", "E", "F", "G", "Q", "R", "S", "T", "V", "W", "X", "Z" }
hints.hintCharsVimperator = hints.hintChars

--- Show title with more windows
hints.fontSize = 15
hints.showTitleThresh = 16

--- WindowSelector.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('WindowSelector')

--- Replicate the logic from hs.hints
local function isValidWindow (w, allowNonStandard)
  local invalidWindowRoles = {
    AXScrollArea = true, --This excludes the main finder window.
    AXUnknown = true
  }
  if not allowNonStandard then
    return w:isStandard()
  else
    return invalidWindowRoles[w:role()] == nil
  end
end

local function getWindows (winIds, allowNonStandard)
  if not winIds or type(winIds) ~= "table" then
    return {}
  end
  local windows = wf.new(function(w)
    for _, id in pairs(winIds) do
      if id == w:id() then
        return isValidWindow(w, allowNonStandard)
      end
    end
    return false
  end):getWindows()
  obj.logger.d("Select from other windows: " .. hs.inspect(windows))
  return windows
end


function obj.selectWindow (winIds, callback, allowNonStandard)
  if not callback then
    error("callback not provided")
  end
  local windows = getWindows(winIds)
  local windowCounts = M.count(windows)
  if windowCounts < 1 then
    hs.alert.show("Not enough windows, skip", 0.1)
    return
  end
  if windowCounts == 1 then
    obj.logger.w("Single window, just call the callback!")
    local window = M.first(windows)[1]
    callback(window)
    return
  end

  obj.logger.d("Select from other windows: " .. hs.inspect(windows))
  local applicationCount = M.chain(windows)
  :groupBy(
      function (w, _) ---@param w hs.window
        return w:application():title()
      end)
  :count()
  :value()

  if applicationCount > 1 then
    hints.style = "vimperator"
  else
    hints.style = nil
  end
  hints.windowHints(windows, callback, allowNonStandard)

  obj.logger.d("hs.hints.windowHints done!")
end

return obj
