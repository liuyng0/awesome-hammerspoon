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
obj.scriptPath = os.getenv("HOME") .. "/.config/yabai/"

local M = U.moses
local command = U.command
local wf = hs.window.filter
local cwrap = U.command.cwrap
--- The program is fixed to spoon.Yabai.program
local function execSync (args)
  return command.execTaskInShellSync(obj.program .. " " .. args, nil, false)
end

local function execYabaiScriptSync (script)
  return command.execTaskInShellSync(obj.scriptPath .. script, nil, false)
end

--- @return Window[]
function obj:windows (index)
  ---@type Window[]
  return hs.json.decode(execSync([[-m query --windows]] .. (index and " --window " .. index or "")))
end

--- @return Space[]
function obj:spaces (index)
  ---@type Space[]
  return hs.json.decode(execSync([[-m query --spaces]] .. (index and " --space " .. index or "")))
end

--- @return Display[]
function obj:displays (index)
  ---@type Display[]
  return hs.json.decode(execSync([[-m query --displays]] .. (index and " --display " .. index or "")))
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
  else
    obj.logger.e("spaceIndex exceeded" .. spacesLen .. " " .. spaceIndex)
  end
end

function obj:swapWindows (winId, otherWinId)
  execSync("-m window " .. winId .. " --swap " .. otherWinId)
end

function obj:stackWindows (winId, otherWinId)
  execSync("-m window " .. winId .. " --stack " .. otherWinId)
end

function obj:switchLayout (layout)
  execSync("-m space --layout " .. layout)
end

local function getWindows (winIds)
  if not winIds or type(winIds) ~= "table" then
    return {}
  end
  local windows = wf.new(function(w)
    for _, id in pairs(winIds) do
      if id == w:id() then
        return true
      end
    end
    return false
  end):getWindows()
  obj.logger.d("Select from other windows: " .. hs.inspect(windows))
  return windows
end

local function selectWindow (winIds, callback)
  if #winIds < 1 then
    obj.logger.w("Not enough windows, skip")
  end
  if #winIds == 1 then
    obj.logger.w("Single window, just call the callback!")
    local window = hs.window.get(winIds[1])
    if callback then
      callback(window)
    end
    return
  end
  obj.logger.d("Select from other windows: " .. hs.inspect(winIds))
  N.hints.windowHints(getWindows(winIds), callback)
  obj.logger.d("hs.hints.windowHints done!")
end

function obj:gotoSpace (spaceIndex)
  execSync("-m space --focus " .. spaceIndex)
end

function obj:swapWithOtherWindow ()
  obj:callBackWithOtherWindow(function(focused, selected)
    --- Just run the cwrap since in callback
    cwrap(
      function()
        obj:swapWindows(focused:id(), selected:id())
      end
    )()
  end)
end

function obj:focusOtherWindow ()
  obj:callBackWithOtherWindow(function(_, selected)
    selected:raise()
    selected:focus()
  end)
end

--- callback will be pass into two windows - (focus, selected)
--- both are windows
function obj:callBackWithOtherWindow (callback)
  local focus = obj:focusedWSD()
  if not focus then
    obj.logger.e("no focus, do nothing")
    return
  end
  local visibleSpaceIndexs = M.chain(obj:spaces())
      :select(
      ---@param s Space
        function(s, _)
          return s["is-visible"]
        end)
      :map(
      ---@param s Space
        function(s, _)
          return s.index
        end
      )
      :value()

  if not visibleSpaceIndexs then
    return
  end

  local function spaceSelector (indexes)
    local result = string.format(".space == %d", indexes[1])
    for i = 2, #indexes do
      result = result .. "or" .. string.format(".space == %d", indexes[i])
    end
    return result
  end

  ---@type Window[]?
  local windows = hs.json.decode(
    execSync(
      string.format("-m query --windows | jq -r '.[] | select(%s)' | jq -n '[inputs]'",
        spaceSelector(visibleSpaceIndexs))))
  local winIds = M.chain(windows)
      :select(
      ---@param w Window
        function(w, _) return (not focus or w.id ~= focus.windowId) end)
      :map(function(w, _) return w.id end)
      :value()
  selectWindow(winIds, function(selected)
    callback(hs.window.get(focus.windowId), selected)
  end)
end

--- Switch to app window prefer current mission control
--- @return boolean true if switched to app, flase if no window with specified app name
function obj:switchToApp (appName)
  local focus = obj:focusedWSD()
  local windows = hs.json.decode(execSync(string.format("-m query --windows | jq -r '.[] | select(.app == \"%s\")'",
    appName)))
  if not windows then
    return false
  end
  ---@type Window
  local targetWindow
  ---@type Window
  if type(windows) == 'table' and #windows == 0 then
    windows = { windows }
  end
  for _, win in pairs(windows) do
    if focus and win.space == focus.spaceIndex then
      targetWindow = win
      break
    elseif not targetWindow then
      targetWindow = win
    end
  end
  if targetWindow then
    if not focus or targetWindow.space ~= focus.spaceIndex then
      execSync("-m space --focus " .. targetWindow.space)
    end
    execSync("-m window --focus " .. targetWindow.id)
    return true
  end
  return false
end

function obj:stackAppWindows ()
  local focus = obj:focusedWSD()
  if not focus then
    return
  end
  ---@type Window[]?
  local windows = hs.json.decode(
    execSync(
      string.format("-m query --windows | jq -r '.[] | select(.app == \"%s\" and .space == %d)' | jq -n '[inputs]'",
        focus.app, focus.spaceIndex)))
  M.chain(windows)
      :select(
      ---@param w Window
        function(w, _) return w.id ~= focus.windowId end)
      :each(
      ---@param w Window
        function(w, _)
          obj:stackWindows(focus.windowId, w.id)
        end)
      :value()
end

function obj:reArrangeSpaces ()
  execYabaiScriptSync("keep_fixed_spaces")
end

function obj:bindFunction (commands)
  return cwrap(function()
    for _, cmd in pairs(commands) do
      execSync(cmd)
    end
  end)
end

--- @return spoon.Yabai
return obj
