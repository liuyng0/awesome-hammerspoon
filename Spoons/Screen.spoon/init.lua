local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Screen"
obj.version = "1.0"
obj.author = "Chophi <chophi@foxmail.com>"

obj.windowHighlightMode = false
obj.logger = hs.logger.new("Screen")

function obj:focusWindowOnNextScreen(nextCount)
  local screens = hs.screen.allScreens()
  local currentScreen = hs.screen.mainScreen()
  local screenAngle = {}
  for _, s in pairs(screens) do
    local frame = s:frame()
    local angle = math.atan(-(frame.y+frame.h), (frame.w+frame.x))
    -- hs.alert.show(string.format("%f, %s", angle, w:title()))
    table.insert(screenAngle, {
                   screen = s,
                   clockwise_angle = angle
    })
  end
  table.sort(screenAngle, function(a, b)
               return a["clockwise_angle"] > b["clockwise_angle"]
  end)

  local thisScreenIndex = 1
  local numScreens=#screenAngle
  for i = 1, numScreens do
    -- hs.alert.show(string.format("The loop window is %s", windowAngle[i]["window"]:title()))
    if currentScreen == screenAngle[i]["screen"] then
      thisScreenIndex = i
      break
    end
  end
  local nextIndex = ((thisScreenIndex - 1 + numScreens + nextCount) % numScreens) + 1
  local nextScreen = screenAngle[nextIndex]["screen"]

  local raiseAndFocusedWindow = false
  for _, w in pairs(hs.window.orderedWindows()) do
    if w:screen() == nextScreen and w:title() and string.len(w:title()) > 0 then
      -- hs.alert.show(string.format("found Window:%s", w:title()))
      if not obj.windowHighlightMode then
        hs.alert.closeAll()
        local alertUUid = hs.alert.show(
          string.format("Current Screen: %s, window: %s", nextScreen:name(), w:title()),
          hs.alert.defaultStyle, nextScreen, 0.5
        )
      end
      w:unminimize()
      w:raise()
      w:focus()
      raiseAndFocusedWindow = true
      break
    end
  end

  if not raiseAndFocusedWindow then
    local alertUUid = hs.alert.show(
      string.format("Current Screen: %s, no Window", nextScreen:name()),
      hs.alert.defaultStyle, nextScreen, 2
    )
  end
end

function obj:sortedWindows(wins)
  local windowAngle = obj:_sortedWindows(wins)
  local windows = {}
  for _, w in pairs(windowAngle) do
    table.insert(windows, w["window"])
  end

  -- for _, w in pairs(windows) do
  --    hs.alert.show(string.format("window:%s", w:title()))
  -- end

  return windows
end

function obj:_sortedWindows(wins)
  local windowAngle = {}

  for _, w in pairs(wins) do
    local frame = w:frame()
    local angle = math.atan(-(frame.y+frame.h), (frame.w+frame.x))
    -- hs.alert.show(string.format("%f, %s", angle, w:title()))
    table.insert(windowAngle, {
                   window = w,
                   clockwise_angle = angle
    })
  end

  -- for _, w in pairs(windowAngle) do
  --    hs.alert.show(string.format("before: %s, %f", w["window"]:title(), w["clockwise_angle"]))
  -- end
  table.sort(windowAngle, function(a, b)
               return (a["clockwise_angle"] > b["clockwise_angle"]) or
                 (a["clockwise_angle"] == b["clockwise_angle"] and a["window"]:title() > b["window"]:title())
  end)

  return windowAngle
end

function getWindowNameFromCache(windowId, defaultWindowName)
  -- TODO: maybe add a cache to set window name overrides
  return defaultWindowName
end

-- Except the focused window
function selectWindowInList(allWindows, showAppNameAsPrefix)
  local chooser = hs.chooser.new(function(choice)
      if choice == nil then
        return;
      end
      local chosenWindow = choice["windowObject"]
      chosenWindow:unminimize()
      chosenWindow:raise()
      chosenWindow:focus()
  end)
  local chooserChoices = {}
  for _, w in pairs(allWindows) do
    table.insert(chooserChoices, {
                   ["text"] = getWindowNameFromCache(w:id(), w:title()),
                   ["visible"] = w:isVisible(),
                   ["windowObject"] = w,
                   ["application"] = w:application():name(),
    })
  end
  table.sort(chooserChoices, function(a, b)
               if a["application"] ~= b["application"] then
                 return a["application"] < b["application"]
               end

               if a["visible"] == b["visible"] then
                 return a["text"] < b["text"]
               else
                 return a["visible"]
               end
  end)

  if showAppNameAsPrefix then
    for _, c in pairs(chooserChoices) do
      c["subText"] = c["application"] .. " | " .. c["text"]
      c["text"] = c["application"]
    end
  end
  chooser:choices(chooserChoices)
  chooser:searchSubText(true):show()
end

function obj:selectWindowFromAllWindows()
  local allWindows = hs.fnutils.filter(hs.window.filter.default:getWindows(),
                                       function(win) return win ~= hs.window.focusedWindow() end)
  selectWindowInList(allWindows, true)
end

function obj:_sameAppWindowsWithFocused()
  local focusedWindow = hs.window.focusedWindow()
  local focusedApp = focusedWindow:application()
  -- hs.alert.show(string.format("This app is:%s", focusedApp:name()))

  return hs.window.filter.new{focusedApp:name()}:getWindows() -- focusedApp:allWindows()
end

function obj:_sameAppWindowsWithFocusedExceptFocused()
  local allWindows = obj:_sameAppWindowsWithFocused()

  return hs.fnutils.filter(allWindows, function(win)
                             return win ~= hs.window.focusedWindow()
  end)
end

function obj:_switchFocusIfOnlyOneChoice()
  local windows = obj:_sameAppWindowsWithFocusedExceptFocused()
  if #windows == 0 then
    obj.logger.w("No other windows")

    return nil
  end
  if #windows == 1 then
    obj.logger.w("Only one other window, simply switch to")

    windows[1]:unminimize()
    windows[1]:raise()
    windows[1]:focus()
    return nil
  end

  return windows
end

function obj:selectWindowFromFocusedApp()
  local windows = obj:_switchFocusIfOnlyOneChoice()
  if windows ~= nil then
    selectWindowInList(windows, false)
  end
end

function obj:sameAppWindowInNextScreen(nextCount)
  local allWindows = obj:_switchFocusIfOnlyOneChoice()
  local focusedWindow = hs.window.focusedWindow()
  if allWindows == nil then
    return
  end
  -- add the current window back for index
  table.insert(allWindows, focusedWindow)

  local windowAngle = obj:_sortedWindows(allWindows)
  local thisWindowIndex = 1
  local numWindows=#windowAngle
  for i = 1, numWindows do
    -- hs.alert.show(string.format("The loop window is %s", windowAngle[i]["window"]:title()))
    if focusedWindow == windowAngle[i]["window"] then
      thisWindowIndex = i
      break
    end
  end
  local nextIndex = ((thisWindowIndex - 1 + numWindows + nextCount) % numWindows) + 1
  local nextWindow = windowAngle[nextIndex]["window"]
  -- hs.alert.show(string.format("The next window is:%s", windowAngle[nextIndex]["window"]:title()))
  if not obj.windowHighlightMode then
    hs.alert.closeAll()
    local alertUUid = hs.alert.show("Current Screen", hs.alert.defaultStyle, nextWindow:screen(), 0.5)
  end
  nextWindow:unminimize()
  nextWindow:raise()
  nextWindow:focus()
  -- hs.alert.closeSpecific(alertUUid, 2)
end

function obj:toggleWindowHighlightMode()
  if not obj.windowHighlightMode then
    obj.windowHighlightMode = true
    hs.window.highlight.ui.overlay=true
    hs.window.highlight.ui.flashDuration=0.3
    hs.window.highlight.start()
    hs.alert.show("Window Highlight Mode is enabled")
  else
    obj.windowHighlightMode = false
    hs.window.highlight.stop()
    hs.alert.show("Window Highlight Mode is disabled")
  end
end

function obj:getVisibleWindowsForAllScreens()
  local all_windows = hs.window.orderedWindows()
  local flattened_windows = {}
  for _, w in pairs(all_windows) do
    local w_info = {
      id = w:id(),
      title = w:title(),
      screen = w:screen(),
      frame = w:frame(),
      application = w:application(),
    }
    print(hs.inspect.inspect(w_info))
    table.insert(flattened_windows, w_info)
  end
end

return obj
