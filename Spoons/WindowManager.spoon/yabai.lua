--- === Yabai ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Yabai.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Yabai.spoon.zip)

---@class WM.Yabai
local obj = {}
obj.__index = obj

---@type spoon.Popup
local popup = hs.loadSpoon("Popup")
---@type spoon.Utils
local U = hs.loadSpoon("Utils")
local sk = U.sk
local M = U.moses
local cwrap, execSync = U.command.cwrap, U.command.execSync
local ws = hs.loadSpoon("WindowSelector") --[[@as spoon.WindowSelector]]
---@type YabaiWrapper
local wrapper = dofile(hs.spoons.resourcePath("yabai_wrapper.lua"))

obj.logger = hs.logger.new("Yabai", "info")

---@type ScratchpadsConfig
obj.padsConfig = {
  pads = {}
}

--- @param callback function(focused: hs.window, selected: hs.window)
--- @param options WindowOptions?
function obj.selectRun (callback, options)
  local windows = wrapper.windows()
  local includeSelf = options and (options.onlyOtherWindow == false)
  if not includeSelf then
    windows = M.select(windows, function (win, _) ---@param win Window
        return win["has-focus"] == false
    end)
  end

  if options and options.onlyVisible then
    windows = M.select(windows, function (win, _) ---@param win Window
        return win["is-visible"] == true
    end)
  end

  local focusedWindow = wrapper.singleWindow()
  if options and options.onlyFocusedApp and focusedWindow then
    windows = M.select(windows, function (win, _) ---@param win Window
        return win.app == focusedWindow.app
    end)
  end

  local currentSpace = wrapper.singleSpace()
  if options and options.onlyCurrentSpace and currentSpace then
    windows = M.select(windows, function (win, _) ---@param win Window
        return win.space == currentSpace.index
    end)
  end

  if options and options.onlyOtherSpace and currentSpace then
    windows = M.select(windows, function (win, _) ---@param win Window
        return win.space ~= currentSpace.index
    end)
  end

  local visibleSpaceIndexes = wrapper.visibleSpaceIndexes()
  if options and options.onlyVisibleSpaces and visibleSpaceIndexes then
    windows = M.select(windows, function (win, _) ---@param win Window
        return M.find(visibleSpaceIndexes, win.space)
    end)
  end
  local winIds = M.map(windows, function(win, _) ---@param win Window
                          return win.id
                       end)
  local focusedWindowObj = focusedWindow and hs.window.get(focusedWindow.id)
  ws.selectWindow(winIds, function(selected) cwrap(callback, focusedWindowObj, selected)() end)
end

function obj.swapWithOtherWindowFunc ()
  return cwrap(obj.selectRun, function(a, b) wrapper.swapWindows(a:id(), b:id()) end)
end

function obj.focusOtherWindowFunc (onlyFocusedApp, onlyFocusedSpace)
  ---@type WindowOptions
  local option = {
    onlyFocusedApp = onlyFocusedApp,
    onlyCurrentSpace = onlyFocusedSpace
  }
  return cwrap(obj.selectRun, function(_, b) wrapper.focusWindow(b:id()) end,
               option)
end

--- @return Focus?
function obj.focusedWSD ()
  ---@type Window
  local window = wrapper.singleWindow()
  if window then
    local currentSpace = wrapper.singleSpace()
    return {
      windowId = window.id,
      displayIndex = window.display,
      spaceIndex = window.space,
      frame = window.frame,
      app = window.app,
      title = window.title,
      window = window,
      currentSpace = currentSpace,
    }
  end
end

--- Switch to app window prefer current mission control
--- @return boolean if switched to app, flase if no window with specified app name
function obj.switchToApp (appName)
  local windows = wrapper.appWindows(appName)
  local visibleSpaceIndexes = wrapper.visibleSpaceIndexes()
  local currentSpace = wrapper.singleSpace()
  ---@type Window[]
  local sortedWindows = M.chain(windows)
  :sort(
    ---@param a Window
    ---@param b Window
    function(a, b)
      if a["has-focus"] then return true end
      if a.space == currentSpace.index then return true end
      if b.space == currentSpace.index then return false end
      if a["is-visible"] and (not b["is-visible"]) then
          return true
      end
      if b["is-visible"] and (not a["is-visible"]) then
        return false
      end
      local av = M.find(visibleSpaceIndexes, a.space)
      local bv = M.find(visibleSpaceIndexes, b.space)
      if av and (not bv) then
        return true
      end
      if bv and (not av) then
        return false
      end
      return a.id > b.id
    end)
  :first()
  :value()

  if M.count(sortedWindows) > 0 then
    if visibleSpaceIndexes and M.count(visibleSpaceIndexes) > 0 and M.find(visibleSpaceIndexes, sortedWindows[1].space) == nil then
      wrapper.moveWindowToSpace(sortedWindows[1].id, currentSpace.index, true)
    else
      wrapper.focusWindow(sortedWindows[1].id)
    end
    return true
  else
    return false
  end
end

function obj.stackAppWindows (onlyFocusedSpace)
  local focusedWindow = wrapper.singleWindow()
  if not focusedWindow then
    popup.instantAlert("No window focused, do nothing!")
    return
  end
  ---@type Window[]?
  local windows = wrapper.appWindows(focusedWindow.app)

  M.chain(windows)
      :select(
      ---@param w Window
        function(w, _)
          if onlyFocusedSpace and w.space ~= focusedWindow.space then
            return false
          end
          return w.id ~= focusedWindow.id
        end)
      :each(
      ---@param w Window
        function(w, _)
          wrapper.stackWindows(focusedWindow.id, w.id)
        end)
      :value()
end

function obj.stackAppWindowsFunc (onlyFocusedSpace)
  return cwrap(obj.stackAppWindows, onlyFocusedSpace)
end

function obj.reArrangeSpacesFunc ()
  return cwrap(wrapper.runScript, "keep_fixed_spaces")
end

function obj.toggleZoomFullScreenFunc ()
  return cwrap(wrapper.windowToggle, nil, "zoom-fullscreen")
end

function obj.toggleFloatFunc ()
  return cwrap(wrapper.windowToggle, nil, "float")
end

function obj.startOrRestartServiceFunc ()
  return cwrap(wrapper.restartService)
end

function obj.stopServiceFunc ()
  return cwrap(wrapper.stopService)
end

function obj.swapVisibleSpaces ()
  local spaces = wrapper.visibleSpaceIndexes()
  local focus = obj.focusedWSD()
  if not spaces or #spaces ~= 2 then
    popup.instantAlert("Only support swap two spaces")
    return
  end
  local other = focus and spaces[1] == focus.spaceIndex and spaces[2] or spaces[1]
  wrapper.switchSpace(nil, other)
end

function obj.swapVisibleSpacesFunc ()
  return cwrap(obj.swapVisibleSpaces);
end

---@param padsConfig ScratchpadsConfig
function obj.configPads (padsConfig)
  obj.padsConfig = padsConfig
end

--- @excludeYabaiAppName excluded app name
function obj.hideScratchpadsNowrap (excludeYabaiAppName)
  local toSpaceIndex = wrapper.maxSpaceIndexInCurrentDisplay()
  local padsToHide = M.chain(obj.padsConfig.pads)
      :map(function(pad, _)
        return pad.yabaiAppName
      end)
      :filter(function(name, _)
        return name ~= excludeYabaiAppName
      end)
      :value()
  M.chain(wrapper.appWindows(padsToHide))
      :filter(
      --- @param w Window
        function(w, _)
          return w.space ~= toSpaceIndex
        end)
      :each(
      ---@param w Window
        function(w, _)
          wrapper.moveWindowToSpace(w.id, toSpaceIndex)
        end
      ):value()
end

function obj.hideAllScratchpadsFunc ()
  return cwrap(obj.hideScratchpadsNowrap)
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
    local currentSpace, nextSpace = wrapper.twoSpaces()
    local targetSpace = onCurrentSpace and currentSpace or nextSpace or currentSpace
    local targetSpaceIndex = targetSpace and targetSpace.index
    local thisAppWindows = wrapper.appWindows({ yabaiAppName })
    if M.count(thisAppWindows) == 0 then
      obj.logger.d("No appWindow found for " .. yabaiAppName)
      return
    end
    obj.hideScratchpadsNowrap(yabaiAppName)
    local chosenWindow = thisAppWindows[1]
    obj.logger.d("chosenWindow type:" .. type(chosenWindow) .. " " .. hs.inspect(chosenWindow))
    wrapper.showScratchPad(chosenWindow, targetSpaceIndex, scratchPad)
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

  return M.chain(wrapper.appWindows(allPads))
      :filter(function(win, _) ---@param win Window
        return win.space == spaceIndex and win["is-visible"]
      end)
      :value()
end

--- Currently only work for two screen
function obj.focusNextScreen ()
  local targetWindow = nil
  local _, nextSpace = wrapper.twoSpaces()
  if not nextSpace then
    popup.instantAlert("Only single space, do nothing")
    return
  end
  local visiblePads = getVisiblePads(nextSpace.index)
  if M.count(visiblePads) > 0 then
    targetWindow = visiblePads[1].id
    obj.logger.wf("Focus on visible pads %d, %s", visiblePads[1].id, visiblePads[1].app)
  elseif nextSpace["first-window"] ~= 0 then
    targetWindow = nextSpace["first-window"]
  end
  if targetWindow then
    wrapper.focusWindow(targetWindow)
  else
    wrapper.focusDisplay(nextSpace.display)
  end
end

function obj.focusNextScreenFunc ()
  return cwrap(obj.focusNextScreen)
end

--- Currently only work for two screen
function obj.selectVisibleWindowToHideFunc (onlyCurrentSpace)
  ---@type WindowOptions
  local option = {
    onlyCurrentSpace = onlyCurrentSpace,
    onlyVisible = true,
    onlyOtherWindow = false,
  }
  return cwrap(function()
    if wrapper.inMaxSpace() then
      popup.instantAlert("Already in the max space, hide nothing")
      return
    end
    obj.selectRun(function(_, b)
      obj.moveWindowToHiddenSpace(b)
    end, option)
  end)
end

function obj.focusVisibleWindowFunc (onlyCurrentSpace)
  ---@type WindowOptions
  local option = {
    onlyCurrentSpace = onlyCurrentSpace,
    onlyVisible = true
  }
  return cwrap(obj.selectRun, function(_, b)
                 wrapper.focusWindow(b:id())
  end, option)
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

function obj.focusSpaceFunc (spaceIndex)
  return cwrap(wrapper.focusSpace, spaceIndex)
end

function obj.moveW2SFunc (spaceIndex, follow)
  return cwrap(wrapper.moveWindowToSpace, nil, spaceIndex, follow)
end

function obj.makePadMapFunc (curSpace)
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

function obj.resizeWindowMapping ()
  local function c (cmd)
    return cwrap(function()
      execSync(cmd)
    end)
  end
  return {
    [sk("h", "r,-20,l,-20[R]")] = c("yabai -m window --resize right:-20:0  || yabai -m window --resize left:-20:0"),
    [sk("j", "b,+20,t,+20[R]")] = c("yabai -m window --resize bottom:0:20  || yabai -m window --resize top:0:20"),
    [sk("k", "b,-20,t,-20[R]")] = c("yabai -m window --resize bottom:0:-20 || yabai -m window --resize top:0:-20"),
    [sk("l", "r,+20,l,+20[R]")] = c("yabai -m window --resize right:20:0   || yabai -m window --resize left:20:0"),
  }
end

function obj.nextLayoutFunc ()
  local layouts = { [1] = "bsp", [2] = "stack" }
  local now = 1
  return cwrap(
    function()
      local next = now + 1
      if next == 3 then next = 1 end
      wrapper.switchLayout(layouts[next])
      wrapper.signalLayoutChanged()
      now = next
    end)
end

function obj.showInfoFunc ()
  return cwrap(
    function()
      local info = obj.focusedWSD()
      popup.showDebug(hs.inspect(info))
    end
  )
end

function obj.moveOthersToHiddenSpaceFunc ()
  return cwrap(wrapper.hideOtherWindowsInCurrentSpace)
end

function obj.moveWindowToHiddenSpace (window)
  local scratchSpaceIndex = wrapper.maxSpaceIndexInCurrentDisplay()
  return wrapper.moveWindowToSpace(window:id(), scratchSpaceIndex)
end

function obj.pickWindowsFunc ()
  ---@type WindowOptions
  local option = {
    onlyOtherSpace = true
  }
  return cwrap(obj.selectRun, function(_, b)
                 wrapper.pickWindow(b:id())
  end, option)
end

function obj.selectNthSpacesInAllDisplaysFunc (n)
  return cwrap(function()
    --- Display[]
    local displays = wrapper.displays()
    M.chain(displays)
        :each(function(d, _) ---@param d Display
          if M.count(d.spaces) < n then
            popup.instantAlert("Not enough spaces, do nothing!")
            return
          end
          wrapper.showSpaceOnDisplay(d.index, d.spaces[n])
        end)
        :value()
  end)
end


function obj.restartSketchybar()
  return wrapper.restartSketchybar()
end

function obj.normalize ()
  return cwrap(function()
      local currentSpace = wrapper.singleSpace()
      if not currentSpace then
        popup.instantAlert("No focused space, do nothing!")
      end
      local windows = M.select(wrapper.windows(),
      function(w, _) ---@param w Window
        return w.space == currentSpace.index
      end);

      M.each(windows, function(w, _) ---@param w Window
        if w["is-floating"] then
          wrapper.windowToggle(w.id, "float")
        end
        if w["is-native-fullscreen"] then
          wrapper.windowToggle(w.id, "native-fullscreen")
        end
        if w["has-fullscreen-zoom"] then
          wrapper.windowToggle(w.id, "zoom-fullscreen")
        end
      end)
  end)
end

function obj.closeWindow()
  return cwrap(function()
      wrapper.closeWindow()
  end)
end

--- @return WM.Yabai
return obj
