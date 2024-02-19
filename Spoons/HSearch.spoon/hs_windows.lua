local obj = {}
obj.__index = obj

obj.name = "WindowSearch"
obj.version = "1.0"
obj.author = "LY <liuyng0@outlook.com>"

local hsearch = spoon.HSearch
local screen = spoon.Screen
obj.overview = {
  text = "Type ws ⇥ to search the windows.",
  image = hsearch:resourceImage("/resources/tabs.png"),
  keyword = "ws"
}

obj.notice = { text = "Search Windows" }

obj.switchToSelectedWindow = "switchToSelectedWindow"
obj.init_func = function()
  local screenChoices = screen:getWindowChoices(hs.window.filter.default:getWindows(), true)
  screenChoices = hs.fnutils.imap(screenChoices, function(item)
    item.image = hsearch:resourceImage("/resources/tabs.png")
    item.output = obj.switchToSelectedWindow
    return item
  end)
  return screenChoices
end

--- The callback function after a item selected
--- {
---    name = "command key"
---    func = callback_func
--- }
obj.new_output = {
  name = obj.switchToSelectedWindow,
  func = screen.selectWindow
}

--- The text will be shown in search input as place holder
obj.placeholderText = "Search Windows"

return obj
