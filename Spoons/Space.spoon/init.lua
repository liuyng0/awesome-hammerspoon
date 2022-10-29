local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Space"
obj.version = "1.0"
obj.author = "Chophi <chophi@foxmail.com>"

obj.logger = hs.logger.new("Space")

local spaces = require('hs.spaces')
local funs = require('hs.fnutils')
local funext = require('hammers.funext')
local colorpicker = require('hammers.colorpicker')

function obj:getSpaceTable()
  local allSpaces = spaces.allSpaces()
  local spaceTable = {}
  local allWindows = hs.window.filter.default:getWindows()
  local windowsById = {}
  funs.map(allWindows, function(win)
             windowsById[win:id()] = win
  end)

  local focusedSpace = spaces.focusedSpace()
  local screenByUUID= {}
  funs.map(hs.screen.allScreens(),
           function(scn)
             screenByUUID[scn:getUUID()] = scn
  end)
  funext.imap(allSpaces, function(screenUUID, spaceIds)
                funs.map(spaceIds, function(spaceId)
                           local validWindows = funs.filter(funs.map(spaces.windowsForSpace(spaceId), function(wid)
                                                                   return windowsById[wid]
                                                                end), function(w)
                                                          return w ~= nil
                           end)

                           local subText = funs.reduce(funs.map(validWindows, function(win)
                                                                  return win:application():name() .. " | " .. win:title()
                                                               end),
                                                       function(titleA, titleB)
                                                         return titleA .. "\n" .. titleB
                           end)

                           table.insert(spaceTable, {
                                          ["spaceId"] = spaceId,
                                          ["screenUUID"] = screenUUID,
                                          ["text"] = "" .. (screenByUUID[screenUUID] and screenByUUID[screenUUID]:name() or screenUUID) .. " | " .. spaceId,
                                          ["subText"] = subText,
                                          ["isFocusedSpace"] = spaceId == focusedSpace
                           })
                end)
  end)

  -- obj.logger.w("Got space table: " .. hs.inspect(spaceTable))
  return spaceTable
end


function obj:switchToScreen()
  local choices = obj:getSpaceTable()
  local chooser = hs.chooser.new(function(choice)
      if choice == nil then
        return
      end
      if choice["isFocusedSpace"] == nil then
        obj.logger.w("Already in this space, do nothing")
        return
      end
      spaces.gotoSpace(choice["spaceId"])
  end)

  colorpicker:setChooserUI(chooser, choices, {grayOutKey="isFocusedSpace", darkStyle=false})
  choices = colorpicker:getReorderedChoices(choices, "isFocusedSpace")

  chooser:choices(choices)
  chooser:searchSubText(true):show()
end
return obj
