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
obj.program = "/opt/homebrew/bin/yabai"
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
      obj.logger.e(string.format("Failed command command: %s, error: %s", cmd, stderr))
      return ""
    end
  end
  return output
end

--- The program is fixed to spoon.Yabai.program
local function execYabaiSync (args)
  local cmd = obj.program .. " " .. args
  return execSync(cmd)
end

--- Run script under the scriptPath
local function execYabaiScriptSync (script)
  return command.execTaskInShellSync(obj.scriptPath .. script, nil, false)
end

--- @return Window[]
function obj.windows (index)
  ---@type Window[]
  return hs.json.decode(execYabaiSync([[-m query --windows]] .. (index and " --window " .. index or "")))
end

--- @return Space[]
function obj.spaces (index)
  ---@type Space[]
  return hs.json.decode(execYabaiSync([[-m query --spaces]] .. (index and " --space " .. index or "")))
end

--- @return Display[]
function obj.displays (index)
  ---@type Display[]
  return hs.json.decode(execYabaiSync([[-m query --displays]] .. (index and " --display " .. index or "")))
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
function obj.moveWindowToSpace (winId, spaceIndex, follow)
  local focus = obj.focusedWSD()
  local _winId = winId or (focus and focus.windowId)
  local spacesLen = toint(execYabaiSync("-m query --spaces | jq -rj '. | length'"))

  if spacesLen >= spaceIndex then
    -- adding the window selector to move command solves some buggy behavior by yabai when dealing with windows without menubars
    execYabaiSync("-m window " .. _winId .. " --space " .. spaceIndex .. (follow and " --focus " or ""))
  else
    obj.logger.e("spaceIndex exceeded" .. spacesLen .. " " .. spaceIndex)
  end
end

function obj.swapWindows (winId, otherWinId)
  execYabaiSync("-m window " .. winId .. " --swap " .. otherWinId)
end

function obj.stackWindows (winId, otherWinId)
  execYabaiSync("-m window " .. winId .. " --stack " .. otherWinId)
end

function obj.switchLayout (layout)
  execYabaiSync("-m space --layout " .. layout)
end

function obj.gotoSpace (spaceIndex)
  execYabaiSync("-m space --focus " .. spaceIndex)
end

function obj.swapWithOtherWindow ()
  obj.selectOtherWindow(function(focused, selected)
    --- Just run the cwrap since in callback
    cwrap(
      function()
        obj.swapWindows(focused:id(), selected:id())
      end
    )()
  end, false, "all")
end
function obj.swapWithOtherWindowFunc()
  return cwrap(function() obj.swapWithOtherWindow() end)
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

function obj.focusOtherWindow (onlyFocusedApp, onlyFocusedSpace)
  obj.selectOtherWindow(
  -- focusWindowWithHS
    obj.focusWindowWithYabai,
    onlyFocusedApp,
    onlyFocusedSpace
  )
end

function obj.focusOtherWindowFunc(onlyFocusedApp, onlyFocusedSpace)
  return cwrap(
        function() obj.focusOtherWindow(onlyFocusedApp, onlyFocusedSpace) end
    )
end

local function visibleSpaceIndexes ()
  local visibleSpaceIndexs = M.chain(obj.spaces())
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

---@return Space?
function obj.focusedSpace ()
  local spaces = M.chain(obj.spaces())
      :select(
      ---@param s Space
        function(s, _)
          return s["has-focus"]
        end)
     :value()
  local spaceCount = M.count(spaces)
  if spaceCount > 1 then
    obj.logger.e("something wrong, should not have more than 1 focused spaces")
  end
  return spaceCount == 1 and spaces[1] or nil
end

local function visibleSpaces()
  return hs.json.decode(execSync(string.format(
    "%s -m query --spaces | jq -r '.[] | select(.[\"is-visible\"] == true)' | jq -n '[inputs]'",
    obj.program
  )))
end

---@return Space?, Space?
local function twoSpaces()
  local fspace = obj.focusedSpace()
  local currentSpace = fspace or nil
  local spaces = visibleSpaces()
  local otherSpaces = M.chain(spaces)
      :filter(function(s, _) ---@param s Space
        return (not currentSpace) or s.index ~= currentSpace.index
      end)
      :value()
  local otherSpacesCount = M.count(otherSpaces)
  local nextSpace = otherSpacesCount >= 1 and otherSpaces[1] or nil
  return currentSpace, nextSpace
end

--- @return Focus?
function obj.focusedWSD ()
  ---@type string|nil
  local windowJson = execYabaiSync [===[-m query --windows | jq '.[] | select(.["has-focus"] == true)']===]
  if windowJson then
    ---@type Window
    local window = hs.json.decode(windowJson)
    local currentSpace, nextSpace = twoSpaces()
    return {
      windowId = window.id,
      displayIndex = window.display,
      spaceIndex = window.space,
      frame = window.frame,
      app = window.app,
      title = window.title,
      currentSpace = currentSpace,
      nextSpace = nextSpace
    }
  end
end

local function getscratchPadYabaiAppNames ()
  return M.chain(obj.padsConfig.pads)
      :map(function(pad, _)
        return pad.yabaiAppName
      end)
      :value()
end

--- @param callback function(focused: hs.window, selected: hs.window)
function obj.selectOtherWindow (callback, onlyFocusedApp, onlyFocusedSpace)
  ---@as Focus
  local focus = obj.focusedWSD()
  if not focus then
    obj.logger.e("no focus, do nothing")
    return
  end
  local spaceIndexes = visibleSpaceIndexes()
  if not spaceIndexes then
    return
  end

  local function spaceSelector (indexes)
    if type(onlyFocusedSpace) == "string" and onlyFocusedSpace == "all" then
      return ""
    end
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
    and string.format("(%s) and %s", spaceSelector(spaceIndexes), ".app == \"" .. focus.app .. "\"")
    or spaceSelector(spaceIndexes)
  if queryString ~= "" then
    queryString = string.format(" | select(%s)", queryString)
  end
  local cmd = string.format("%s -m query --windows | jq -r '.[] %s' | jq -n '[inputs]'",
    obj.program,
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
function obj.switchToApp (appName)
  local focus = obj.focusedWSD()
  local fspace = obj.focusedSpace()
  local currentSpace = fspace and fspace.index or nil
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

function obj.stackAppWindows ()
  local focus = obj.focusedWSD()
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
          obj.stackWindows(focus.windowId, w.id)
        end)
      :value()
end

function obj.stackAppWindowsFunc()
  return cwrap(function() obj.stackAppWindows() end)
end

function obj.reArrangeSpacesFunc ()
  return cwrap(function() execYabaiScriptSync("keep_fixed_spaces") end)
end

function obj.bindFunction (commands)
  return cwrap(function()
    for _, cmd in pairs(commands) do
      execYabaiSync(cmd)
    end
  end)
end

function obj.toggleZoomFullScreenFunc()
  return obj.bindFunction({string.format("-m window --toggle zoom-fullscreen")})
end

function obj.toggleFloatFunc()
  return obj.bindFunction({string.format("-m window --toggle zoom-fullscreen")})
end

function obj.startOrRestartServiceFunc ()
  return cwrap(function()
    execSync(string.format("%s --restart-service || %s --start-service", obj.program, obj.program))
  end)
end

function obj.stopServiceFunc ()
  return cwrap(function()
    execSync(string.format("%s --stop-service", obj.program))
  end)
end


function obj.swapVisibleSpaces ()
  local spaces = visibleSpaceIndexes()
  local focus = obj.focusedWSD()
  if not spaces or #spaces ~= 2 then
    obj.logger.w("Only support swap two spaces")
    return
  end
  local other = focus and spaces[1] == focus.spaceIndex and spaces[2] or spaces[1]
  execYabaiSync(string.format("-m space --switch %d", other))
end

function obj.swapVisibleSpacesFunc()
  return cwrap(function() obj.swapVisibleSpaces() end);
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
    obj.program,
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
          execSync(string.format("%s -m window %d --space %d && %s -m window %d --minimize",
                                 obj.program, w.id, obj.padsConfig.spaceIndex,
          obj.program, w.id))
        end
      ):value()
end

function obj.hideAllScratchpadsFunc ()
  return cwrap(function() obj.hideScratchpadsNowrap() end)
end

function obj.showScratchpad (yabaiAppName, onCurrentSpace)
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
    local currentSpace, nextSpace= twoSpaces()
    local targetSpace = onCurrentSpace and currentSpace or nextSpace or currentSpace
    local targetSpaceIndex = targetSpace.index
    local thisAppWindows = getPadWindows({ yabaiAppName })
    if #thisAppWindows == 0 then
      obj.logger.d("No appWindow found for " .. yabaiAppName)
      return
    end
    obj.hideScratchpadsNowrap(yabaiAppName)
    local chosenWindow = thisAppWindows[1]
    obj.logger.d("chosenWindow type:" .. type(chosenWindow) .. " " .. hs.inspect(chosenWindow))
    local spaceSwitch = (chosenWindow.space ~= targetSpaceIndex) and "--space " .. targetSpaceIndex or ""
    local toggleFloat = ((not chosenWindow["is-floating"]) and "" .. "--toggle float" or "")
    local focuseCommand = string.format(
      "%s -m window %d %s %s --grid %s --opacity %.2f --focus",
      obj.program, chosenWindow.id, spaceSwitch, toggleFloat, scratchPad.grid, scratchPad.opacity)
    local gridCommand = string.format(
      "%s -m window %d --grid %s",
      obj.program, chosenWindow.id, scratchPad.grid)
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
        return win.space == spaceIndex and win["is-visible"]
      end)
      :value()
end

--- Currently only work for two screen
function obj.focusNextScreen ()
  local targetWindow = nil
  local _, nextSpace = twoSpaces()
  local visiblePads = getVisiblePads(nextSpace.index)
  if M.count(visiblePads) > 0 then
    targetWindow = visiblePads[1].id
    obj.logger.wf("Focus on visible pads %d, %s", visiblePads[1].id, visiblePads[1].app)
  elseif nextSpace["first-window"] ~= 0 then
    targetWindow = nextSpace["first-window"]
  end
  if targetWindow then
    execSync(string.format("%s -m window --focus %d", obj.program, targetWindow))
  else
    execSync(string.format(
      "%s -m display --focus %d",
      obj.program,
      nextSpace.display
    ))
  end
end

function obj.focusNextScreenFunc()
  return cwrap(function() obj.focusNextScreen() end)
end

--- Currently only work for two screen
function obj.focusVisibleWindow(onlyCurrentSpace)
  ---@type Window[]
  local windows = obj.windows()
  local currentSpace, _ = twoSpaces()
  obj.logger.wf("current space is %d", currentSpace.index)
  local winIds = M.chain(windows)
  :filter(function(w, _) ---@param w Window
        return w["is-visible"] and w.app ~= "Hammerspoon" and (not w["has-focus"])
          and ((onlyCurrentSpace == nil) or (currentSpace == nil) or (currentSpace.index== w.space))
  end)
  :map(function(w, _) ---@param w Window
      return w.id
      end)
  :value()
  ws.selectWindow(winIds, function(selected)
                    obj.focusWindowWithYabai(nil, selected)
                    end)
end

function obj.focusVisibleWindowFunc(onlyCurrentSpace)
  return cwrap(function() obj.focusVisibleWindow(onlyCurrentSpace) end)
end

function obj.launchAppFunc (appName, currentSpace)
    return cwrap(function()
        if currentSpace then
            hs.application.launchOrFocus(appName)
        else
            if not obj.switchToApp(appName) then
                hs.application.launchOrFocus(appName)
            end
        end
    end)
end

function obj.focusSpaceFunc(spaceIndex)
       return cwrap(function()
            obj.gotoSpace(spaceIndex)
        end)
end

function obj.moveW2SFunc(spaceIndex, follow)
        return cwrap(function()
            obj.moveWindowToSpace(nil, spaceIndex, follow)
        end)
    end

local sk = hs.loadSpoon("RecursiveBinder").singleKey
local function ctrl (singleKey, description)
  return { { "control" }, singleKey, description }
end

function obj.makePadMapFunc (curSpace)
  ---@type ScratchpadConfig
  local defaultGrid = "24:24:1:1:22:22"
  local defaultOpacity = 1.0
  local function pad (key, yabaiAppName, appName, grid, opacity)
    return {
      key = sk(key, yabaiAppName),
      appName = appName or yabaiAppName,
      yabaiAppName = yabaiAppName,
      grid = grid or defaultGrid,
      opacity = opacity or defaultOpacity
    }
  end
  local configuration = {
    spaceIndex = 5,
    pads = {
      pad('t', "iTerm2", "iTerm", nil, 0.9),
      pad('s', "Slack", "Slack"),
      pad('o', "OmniGraffle", "OmniGraffle"),
      pad('m', "Music", "Music"),
      pad('a', "Activity Monitor", "Activity Monitor"),
    }
  }
  obj.configPads(configuration)
  local result = {
    [sk('h', "hideAll")] = obj.hideAllScratchpadsFunc(),
  }
  ---@param p Scratchpad
  for _, p in pairs(configuration.pads) do
    result[p.key] = obj.showScratchpad(p.yabaiAppName, curSpace)
  end
  return result
end

function obj.nextLayoutFunc()
            local layouts = { [1] = "bsp", [2] = "stack" }
            local now = 1
   return cwrap(
            function()
                local next = now + 1
                if next == 3 then next = 1 end
                obj.switchLayout(layouts[next])
                now = next
                end)
end

---@type spoon.Alerts
alerts = hs.loadSpoon("Alerts")

function obj.showInfoFunc()
  return cwrap(
            function()
                local info = obj.focusedWSD()
                alerts.showDebug(hs.inspect(info))
            end
        )
end

function obj.moveOthersToHiddenSpace()
  return cwrap(function()
      execSync(string.format("yabai -m query --windows --space | jq -r '.[] |" ..
                             "select(.[\"has-focus\"] == false and .space != %d)'" ..
                             "| jq '.id' | xargs -I{} yabai -m window {} --space %d",
                             obj.padsConfig.spaceIndex, obj.padsConfig.spaceIndex))
  end)
end

function obj.pickWindowsFunc()
  return cwrap(function()
    ---@type focus Space
    local focus, _ = twoSpaces()
    local winIds = M.chain(obj.windows())
        :filter(function(w, _) ---@param w Window
          return w.space ~= focus.index
        end)
        :map(function(w, _) ---@param w Window
          return w.id
        end)
        :value()
    ws.selectWindow(winIds, function(selected) ---@param selected hs.window
      cwrap(function()
        local win = obj.windows(selected:id())
        local toggleFloat = (not win["is-floating"]) and "" or "--toggle float"
        execSync(string.format("yabai -m window %d --space %d --focus %s",
          selected:id(), focus.index, toggleFloat))
      end)()
    end)
  end)
end

--- @return spoon.Yabai
return obj
