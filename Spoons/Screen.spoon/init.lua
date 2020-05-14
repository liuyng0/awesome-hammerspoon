local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Screen"
obj.version = "1.0"
obj.author = "Chophi <chophi@foxmail.com>"

obj.windowHighlightMode = false

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

function obj:sortedWindows()
   local windowAngle = obj:_sortedWindows(hs.window.allWindows())
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
                 return a["clockwise_angle"] > b["clockwise_angle"]
   end)

   return windowAngle
end

function getWindowNameFromCache(windowId, defaultWindowName)
  -- TODO: maybe add a cache to set window name overrides
  return defaultWindowName
end

function selectWindowInList(allWindows, showAppNameAsPrefix)
  local chooser = hs.chooser.new(function(choice)
      if choice == nil then
        return;
      end
      local chosenWindow = hs.window.get(choice["id"])
      chosenWindow:raise()
      chosenWindow:focus()
  end)
  local chooserChoices = {}
  for _, w in pairs(allWindows) do
    table.insert(chooserChoices, {
                   ["text"] = getWindowNameFromCache(w:id(), w:title()),
                   ["visible"] = w:isVisible(),
                   ["id"] = w:id(),
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
      c["text"] = c["application"] .. " >> " .. c["text"]
    end
  end
  chooser:choices(chooserChoices)
  chooser:show()
end

function obj:selectWindowFromAllWindows()
  local allWindows = hs.window.filter.default:getWindows()
  selectWindowInList(allWindows, true)
end

function obj:selectWindowFromFocusedApp()
  local focusedWindow = hs.window.focusedWindow()
  local focusedApp = focusedWindow:application()
  -- hs.alert.show(string.format("This app is:%s", focusedApp:name()))

  local allWindows = focusedApp:allWindows()
  selectWindowInList(allWindows, false)
end

function obj:sameAppWindowInNextScreen(nextCount)
   local focusedWindow = hs.window.focusedWindow()
   local focusedApp = focusedWindow:application()
   -- hs.alert.show(string.format("This app is:%s", focusedApp:name()))

   local windowAngle = obj:_sortedWindows(focusedApp:allWindows())
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


return obj
