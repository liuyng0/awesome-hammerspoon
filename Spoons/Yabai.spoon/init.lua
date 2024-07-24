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
obj.logger = hs.logger.new("Yabai", "info")
obj.yabaiProgram = "/opt/homebrew/bin/yabai"
obj.scriptPath = os.getenv("HOME") .. "/.config/yabai/"
---@type ScratchpadsConfig
obj.padsConfig = {
  spaceIndex = 5,
  pads = {}
}

local M = U.moses
local command = U.command
local cwrap = U.command.cwrap
local ws = hs.loadSpoon("WindowSelector") --[[@as spoon.WindowSelector]]

local function execSync (cmd, ignoreError)
  obj.logger.i("run yabai command: [" .. cmd .. "]")
  local output, ec, stderr = command.execTaskInShellSync(cmd, nil, false)
  if ec and ec ~= 0 then
    if ignoreError then
      obj.logger.w(string.format("Failed command command: %s, error: %s", cmd, stderr))
      return ""
    else
      error(string.format("Failed command command: %s, error: %s", cmd, stderr))
    end
  end
  return output
end

--- The program is fixed to spoon.Yabai.program
local function execYabaiSync (args)
  local cmd = obj.yabaiProgram .. " " .. args
  return execSync(cmd)
end

--- Run script under the scriptPath
local function execYabaiScriptSync (script)
  return command.execTaskInShellSync(obj.scriptPath .. script, nil, false)
end

--- @return Window[]
function obj:windows (index)
  ---@type Window[]
  return hs.json.decode(execYabaiSync([[-m query --windows]] .. (index and " --window " .. index or "")))
end

--- @return Space[]
function obj:spaces (index)
  ---@type Space[]
  return hs.json.decode(execYabaiSync([[-m query --spaces]] .. (index and " --space " .. index or "")))
end

--- @return Display[]
function obj:displays (index)
  ---@type Display[]
  return hs.json.decode(execYabaiSync([[-m query --displays]] .. (index and " --display " .. index or "")))
end

--- @return Focus?
function obj:focusedWSD ()
  ---@type string|nil
  local windowJson = execYabaiSync [===[-m query --windows | jq '.[] | select(.["has-focus"] == true)']===]
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
  local spacesLen = toint(execYabaiSync("-m query --spaces | jq -rj '. | length'"))

  if spacesLen >= spaceIndex then
    -- adding the window selector to move command solves some buggy behavior by yabai when dealing with windows without menubars
    execYabaiSync("-m window " .. _winId .. " --space " .. spaceIndex .. (follow and " --focus " or ""))
  else
    obj.logger.e("spaceIndex exceeded" .. spacesLen .. " " .. spaceIndex)
  end
end

function obj:swapWindows (winId, otherWinId)
  execYabaiSync("-m window " .. winId .. " --swap " .. otherWinId)
end

function obj:stackWindows (winId, otherWinId)
  execYabaiSync("-m window " .. winId .. " --stack " .. otherWinId)
end

function obj:switchLayout (layout)
  execYabaiSync("-m space --layout " .. layout)
end

function obj:gotoSpace (spaceIndex)
  execYabaiSync("-m space --focus " .. spaceIndex)
end

function obj:swapWithOtherWindow ()
  obj:selectOtherWindow(function(focused, selected)
    --- Just run the cwrap since in callback
    cwrap(
      function()
        obj:swapWindows(focused:id(), selected:id())
      end
    )()
  end)
end

---@diagnostic disable: unused-function, unused-local
local function focusWindowWithHS (_, selected)
  selected:unminimize()
  selected:raise()
  selected:focus()
end

function obj.focusWindowWithYabai (_, selected)
  cwrap(function()
    execYabaiSync("-m window " .. selected:id() .. " --focus")
  end)()
end

function obj:focusOtherWindow (onlyFocusedApp, onlyFocusedSpace)
  obj:selectOtherWindow(
  -- focusWindowWithHS
    obj.focusWindowWithYabai,
    onlyFocusedApp,
    onlyFocusedSpace
  )
end

local function visibleSpaces ()
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

  return visibleSpaceIndexs
end

function obj:focusedSpace ()
  local spaceIndexes = M.chain(obj:spaces())
      :select(
      ---@param s Space
        function(s, _)
          return s["has-focus"]
        end)
      :map(
      ---@param s Space
        function(s, _)
          return s.index
        end
      )
      :value()

  return spaceIndexes
end

local function getscratchPadYabaiAppNames ()
  return M.chain(obj.padsConfig.pads)
      :map(function(pad, _)
        return pad.yabaiAppName
      end)
      :value()
end

--- @param callback function(focused: hs.window, selected: hs.window)
function obj:selectOtherWindow (callback, onlyFocusedApp, onlyFocusedSpace)
  ---@as Focus
  local focus = obj:focusedWSD()
  if not focus then
    obj.logger.e("no focus, do nothing")
    return
  end
  local visibleSpaceIndexes = visibleSpaces()
  if not visibleSpaceIndexes then
    return
  end

  local function spaceSelector (indexes)
    if onlyFocusedSpace then
      return string.format(".space == %d", focus.spaceIndex)
    end
    local result = string.format(".space == %d", indexes[1])
    for i = 2, #indexes do
      result = result .. " or " .. string.format(".space == %d", indexes[i])
    end
    return result
  end

  local queryString = onlyFocusedApp
    and string.format("(%s) and %s", spaceSelector(visibleSpaceIndexes), ".app == \"" .. focus.app .. "\"")
    or spaceSelector(visibleSpaceIndexes)
  local cmd = string.format("%s -m query --windows | jq -r '.[] | select(%s)' | jq -n '[inputs]'",
    obj.yabaiProgram,
    queryString)
  ---@type Window[]?
  local windows = hs.json.decode(execSync(cmd))
  local scratchPads = getscratchPadYabaiAppNames()
  local winIds = M.chain(windows)
      :select(
      ---@param w Window
        function(w, _)
          -- filter out focused window
          if focus and w.id == focus.windowId then
            return false
          end
          -- filter out scratch pads
          if M.contains(scratchPads, w.app) then
            return false
          end
          return true
        end)
      :map(function(w, _) return w.id end)
      :value()
  ws.selectWindow(winIds, function(selected)
    callback(hs.window.get(focus.windowId), selected)
  end)
end

--- Switch to app window prefer current mission control
--- @return boolean true if switched to app, flase if no window with specified app name
function obj:switchToApp (appName)
  local focus = obj:focusedWSD()
  local currentSpace = obj:focusedSpace()[1]
  local windows = hs.json.decode(execYabaiSync(string.format(
    "-m query --windows | jq -r '.[] | select(.app == \"%s\")' | jq -n '[inputs]'",
    appName)))
  if not windows then
    return false
  end
  ---@type Window
  local targetWindow
  ---@type Window
  if type(windows) == 'table' and #windows == 0 then
    return false
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
    if targetWindow.space ~= currentSpace then
      execYabaiSync("-m space --focus " .. targetWindow.space)
    end
    execYabaiSync("-m window --focus " .. targetWindow.id)
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
    execYabaiSync(
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
      execYabaiSync(cmd)
    end
  end)
end

function obj:restartYabaiService ()
  return cwrap(function()
    execSync(string.format("%s --restart-service || %s --start-service", obj.yabaiProgram, obj.yabaiProgram))
  end)
end

function obj:stopYabaiService ()
  return cwrap(function()
    execSync(string.format("%s --stop-service", obj.yabaiProgram))
  end)
end

function obj:swapVisibleSpaces ()
  local spaces = visibleSpaces()
  local focus = obj:focusedWSD()
  if not spaces or #spaces ~= 2 then
    obj.logger.w("Only support swap two spaces")
    return
  end
  local other = focus and spaces[1] == focus.spaceIndex and spaces[2] or spaces[1]
  execYabaiSync(string.format("-m space --switch %d", other))
end

---@param padsConfig ScratchpadsConfig
function obj.configPads (padsConfig)
  obj.padsConfig = padsConfig
end

---@param yabaiAppNames string[]
---@return Window[]
local function getPadWindows (yabaiAppNames)
  if #yabaiAppNames == 0 then
    return {}
  end
  local selectStr = ""
  for i, padName in pairs(yabaiAppNames) do
    local condition = ".app == " .. "\"" .. padName .. "\""
    if i == 1 then
      selectStr = selectStr .. condition
    else
      selectStr = selectStr .. " or " .. condition
    end
  end
  local windowsQuery = string.format("%s -m query --windows | jq -r '.[] | select(%s)' | jq -n '[inputs]'",
    obj.yabaiProgram,
    selectStr)
  ---@diagnostic disable
  return hs.json.decode(execSync(windowsQuery))
end

--- @excludeYabaiAppName excluded app name
function obj.hideScratchpadsNowrap (excludeYabaiAppName)
  local otherPads = M.chain(obj.padsConfig.pads)
      :map(function(pad, _)
        return pad.yabaiAppName
      end)
      :filter(function(name, _)
        return name ~= excludeYabaiAppName
      end)
      :value()
  M.chain(getPadWindows(otherPads))
      :filter(
      --- @param w Window
        function(w, _)
          return w.space ~= obj.padsConfig.spaceIndex
        end)
      :each(
      ---@param w Window
        function(w, _)
          execSync(string.format("%s -m window %d --space %d", obj.yabaiProgram, w.id, obj.padsConfig.spaceIndex))
        end
      ):value()
end

function obj:hideAllScratchpads ()
  return cwrap(function() obj.hideScratchpadsNowrap() end)
end

function obj:showScratchpad (yabaiAppName)
  local fn = function()
    ---@type Scratchpad
    local scratchPad = M.chain(obj.padsConfig.pads)
        :filter(function(pad, _)
          return pad.yabaiAppName == yabaiAppName
        end)
        :value()
    if #scratchPad == 0 then
      obj.logger.d("No scratchPad found " .. yabaiAppName .. ", config: " .. hs.inspect(obj.padsConfig.pads))
      return
    end
    scratchPad = scratchPad[1]
    ---@type Window[]
    local currentWorkspace = obj:focusedSpace()[1]
    local thisAppWindows = getPadWindows({ yabaiAppName })
    if #thisAppWindows == 0 then
      obj.logger.d("No appWindow found for " .. yabaiAppName)
      return
    end
    obj.hideScratchpadsNowrap(yabaiAppName)
    local chosenWindow = thisAppWindows[1]
    obj.logger.d("chosenWindow type:" .. type(chosenWindow) .. " " .. hs.inspect(chosenWindow))
    local spaceSwitch = (chosenWindow.space ~= currentWorkspace) and "--space " .. currentWorkspace or ""
    local toggleFloat = ((not chosenWindow["is-floating"]) and "" .. "--toggle float" or "")
    local focuseCommand = string.format(
      "%s -m window %d %s %s --grid %s --opacity %.2f --focus",
      obj.yabaiProgram, chosenWindow.id, spaceSwitch, toggleFloat, scratchPad.grid, scratchPad.opacity)
    local gridCommand = string.format(
      "%s -m window %d --grid %s",
      obj.yabaiProgram, chosenWindow.id, scratchPad.grid)
    execSync(focuseCommand .. " && " .. gridCommand)
  end
  return cwrap(fn)
end

---@return Window[]
local function getVisiblePads (spaceIndex)
  local allPads = M.chain(obj.padsConfig.pads)
      :map(function(pad, _)
        return pad.yabaiAppName
      end)
      :value()

  return M.chain(getPadWindows(allPads))
      :filter(function(win, _) ---@param win Window
        return win.space == spaceIndex
      end)
      :value()
end

local function visibleSpaces()
  return hs.json.decode(execSync(string.format(
    "%s -m query --spaces | jq -r '.[] | select(.[\"is-visible\"] == true)' | jq -n '[inputs]'",
    obj.yabaiProgram
  )))
end
--- Currently only work for two screen
function obj:focusNextScreen ()
  local currentSpaceIndex = obj:focusedSpace()[1]
  local spaces = visibleSpaces()
  local otherSpaces = M.chain(spaces)
      :filter(function(s, _) ---@param s Space
        return s.index ~= currentSpaceIndex
      end)
      :value()
  if M.count(otherSpaces) == 0 then
    obj.logger.w("No next space, do nothing!")
  end
  ---@type Space
  local nextSpace = otherSpaces[1]
  local targetWindow = nil
  local visiblePads = getVisiblePads(nextSpace.index)
  if M.count(visiblePads) > 0 then
    targetWindow = visiblePads[1].id
  elseif nextSpace["first-window"] ~= 0 then
    targetWindow = nextSpace["first-window"]
  end

  if targetWindow then
    execSync(string.format("%s -m window --focus %d", obj.yabaiProgram, targetWindow))
  else
    execSync(string.format(
      "%s -m display --focus %d",
      obj.yabaiProgram,
      nextSpace.display
    ))
  end
end

--- @return spoon.Yabai
return obj
