--- === Hints ===
---
--- Switch focus with a transient per-application keyboard shortcut

local obj = require "hs.hints.internal"
obj.__index = obj

-- Metadata
obj.name = "Hints"
obj.version = "1.0"
obj.author = "Chophi <chophi@foxmail.com>"
local screen = require "hs.screen"
local window = require "hs.window"
local hotkey = require "hs.hotkey"
local modal_hotkey = hotkey.modal

--- Hints.hintChars
--- Variable
--- This controls the set of characters that will be used for window obj. They must be characters found in hs.keycodes.map
--- The default is the letters A-Z. Note that if `obj.style` is set to "vimperator", this variable will be ignored.
obj.hintChars = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}

-- vimperator mode requires to use full set of alphabet to represent applications.
obj.hintCharsVimperator = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}

--- Hints.style
--- Variable
--- If this is set to "vimperator", every window hints starts with the first character
--- of the parent application's title
obj.style = "default"

--- Hints.fontName
--- Variable
--- A fully specified family-face name, preferrably the PostScript name, such as Helvetica-BoldOblique or Times-Roman. (The Font Book app displays PostScript names of fonts in the Font Info panel.)
--- The default value is the system font
obj.fontName = nil

--- Hints.fontSize
--- Variable
--- The size of font that should be used. A value of 0.0 will use the default size.
obj.fontSize = 0.0

--- Hints.showTitleThresh
--- Variable
--- If there are less than or equal to this many windows on screen their titles will be shown in the obj.
--- The default is 4. Setting to 0 will disable this feature.
obj.showTitleThresh = 4

--- Hints.titleMaxSize
--- Variable
--- If the title is longer than maxSize, the string is truncated, -1 to disable, valid value is >= 6
obj.titleMaxSize = -1

local openHints = {}
local takenPositions = {}
local hintsDict = {}
local hintChars = nil
local modalKey = nil
local selectionCallback = nil

local bumpThresh = 40^2
local bumpMove = 80

local invalidWindowRoles = {
   AXScrollArea = true, --This excludes the main finder window.
   AXUnknown = true
}

local function isValidWindow(win, allowNonStandard)
   if not allowNonStandard then
      return win:isStandard()
   else
      return invalidWindowRoles[win:role()] == nil
   end
end

function obj:bumpPos(x,y)
   for i, pos in ipairs(takenPositions) do
      if ((pos.x-x)^2 + (pos.y-y)^2) < bumpThresh then
         return obj:bumpPos(x,y+bumpMove)
      end
   end
   return {x = x,y = y}
end

function obj:addWindow(dict, win)
   local n = dict['count']
   if n == nil then
      dict['count'] = 0
      n = 0
   end
   local m = (n % #hintChars) + 1
   local char = hintChars[m]
   if n < #hintChars then
      dict[char] = win
   else
      if type(dict[char]) == "userdata" then
         -- dict[m] is already occupied by another window
         -- which me must convert into a new dictionary
         local otherWindow = dict[char]
         dict[char] = {}
         obj:addWindow(dict, otherWindow)
      end
      obj:addWindow(dict[char], win)
   end
   dict['count'] = dict['count'] + 1
end

-- Private helper to recursively find the total number of Hints in a dict
function obj:_dictSize(t)
   if type(t) == "userdata" and t:screen() then -- onscreen window
      return 1
   elseif type(t) == "table" then
      local count = 0
      for _,v in pairs(t) do count = count + obj:_dictSize(v) end
      return count
   end
   return 0 -- screenless window or something else
end

function obj:displayHintsForDict(dict, prefixstring, showTitles, allowNonStandard)
   if showTitles == nil then
      showTitles = obj:_dictSize(hintsDict) <= obj.showTitleThresh
   end
   for key, val in pairs(dict) do
      if type(val) == "userdata" and val:screen() then -- this is an onscreen window
         local win = val
         local app = win:application()
         local fr = win:frame()
         local sfr = win:screen():frame()
         if app and app:bundleID() and isValidWindow(win, allowNonStandard) then
            local c = {x = fr.x + (fr.w/2) - sfr.x, y = fr.y + (fr.h/2) - sfr.y}
            local d = obj:bumpPos(c.x, c.y)
            if d.y > (sfr.y + sfr.h - bumpMove) then
               d.x = d.x + bumpMove
               d.y = fr.y + (fr.h/2) - sfr.y
               d = obj:bumpPos(d.x, d.y)
            end
            c = d
            if c.y < 0 then
               print("Hints: Skipping offscreen window: "..win:title())
            else
               local suffixString = ""
               if showTitles then
                  local win_title = win:title()
                  if obj.titleMaxSize > 1 and #win_title > obj.titleMaxSize then
                     local end_idx = math.max(0, obj.titleMaxSize-3)
                     win_title = string.sub(win_title, 1, end_idx) .. "..."
                  end
                  suffixString = ": "..win_title
               end
               -- print(win:title().." x:"..c.x.." y:"..c.y) -- debugging
               local hints = obj.new(c.x, c.y, prefixstring .. key .. suffixString, app:bundleID(), win:screen(), obj.fontName, obj.fontSize)
               table.insert(takenPositions, c)
               table.insert(openHints, hints)
            end
         end
      elseif type(val) == "table" then -- this is another window dict
         obj:displayHintsForDict(val, prefixstring .. key, showTitles, allowNonStandard)
      end
   end
end

function obj:processChar(char)
   local toFocus = nil

   if hintsDict[char] ~= nil then
      obj:closeHints()
      if type(hintsDict[char]) == "userdata" then
         if hintsDict[char] then
            toFocus = hintsDict[char]
         end
      elseif type(hintsDict[char]) == "table" then
         hintsDict = hintsDict[char]
         if hintsDict.count == 1 then
            toFocus = hintsDict[hintChars[1]]
         else
            takenPositions = {}
            obj:displayHintsForDict(hintsDict, "")
         end
      end
   end

   if toFocus then
      -- hs.alert.show("toFocus is not nil")
      modalKey:exit()
      if selectionCallback then
         selectionCallback(toFocus)
      else
         toFocus:focus()
      end
   else
      -- hs.alert.show("toFocus is nil")
   end
end

function obj:setupModal()
   k = modal_hotkey.new(nil, nil)
   k:bind({}, 'escape', function() obj:closeHints(); k:exit() end)

   for _, c in ipairs(hintChars) do
      k:bind({}, c, function() obj:processChar(c) end)
   end
   return k
end

--- Hints:windowHints([windows, callback, allowNonStandard])
--- Function
--- Displays a keyboard hints for switching focus to each window
---
--- Parameters:
---  * windows - An optional table containing some `hs.window` objects. If this value is nil, all windows will be hintsed
---  * callback - An optional function that will be called when a window has been selected by the user. The function will be called with a single argument containing the `hs.window` object of the window chosen by the user
---  * allowNonStandard - An optional boolean.  If true, all windows will be included, not just standard windows
---
--- Returns:
---  * None
---
--- Notes:
---  * If there are more windows open than there are characters available in Hints.hintChars, multiple characters will be used
---  * If Hints.style is set to "vimperator", every window hints is prefixed with the first character of the parent application's name
---  * To display Hints only for the currently focused application, try something like:
---   * `Hints:windowHints(hs.window.focusedWindow():application():allWindows())`
function obj:windowHints(windows, callback, allowNonStandard)
   if obj.style == "vimperator" then
      hintChars = obj.hintCharsVimperator
   else
      hintChars = obj.hintChars
   end

   windows = windows or window.allWindows()
   selectionCallback = callback

   if (modalKey == nil) then
      modalKey = obj:setupModal()
   end
   obj:closeHints()
   hintsDict = {}
   for i, win in ipairs(windows) do
      local app = win:application()
      if app and app:bundleID() and isValidWindow(win, allowNonStandard) then
         if obj.style == "vimperator" then
            local appchar = string.upper(string.sub(app:title(), 1, 1))
            if hintsDict[appchar] == nil then
               hintsDict[appchar] = {}
            end
            obj:addWindow(hintsDict[appchar], win)
         else
            obj:addWindow(hintsDict, win)
         end
      end
   end
   takenPositions = {}

   if next(hintsDict) ~= nil then
      obj:displayHintsForDict(hintsDict, "", nil, allowNonStandard)
      modalKey:enter()
   end
end

function obj:closeHints()
   for _, hints in ipairs(openHints) do
      hints:close()
   end
   openHints = {}
   takenPositions = {}
end

return obj
