local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Screen"
obj.version = "1.0"
obj.author = "Chophi <chophi@foxmail.com>"

obj.windowHighlightMode = false

function obj:screenOperation(nextCount)
   local focusedWindow = hs.window.focusedWindow()
   local focusedApp = focusedWindow:application()
   -- hs.alert.show(string.format("This app is:%s", focusedApp:name()))
   local thisAppWindows = focusedApp:allWindows()
   local windowAngle = {}

   for _, w in pairs(thisAppWindows) do
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
   -- for _, w in pairs(windowAngle) do
   --    hs.alert.show(string.format("after: %s, %f", w["window"]:title(), w["clockwise_angle"]))
   -- end

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
   -- hs.alert.show(string.format("The next window is:%s", windowAngle[nextIndex]["window"]:title()))
   if not obj.windowHighlightMode then
      hs.alert.closeAll()
      local alertUUid = hs.alert.show("Current Screen", hs.alert.defaultStyle, windowAngle[nextIndex]["window"]:screen(), 0.5)
   end
   windowAngle[nextIndex]["window"]:focus()
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
