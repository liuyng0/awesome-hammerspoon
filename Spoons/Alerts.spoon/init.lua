--- === Alerts ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Alerts.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Alerts.spoon.zip)

---@class spoon.Alerts
local obj={}
obj.__index = obj

-- Metadata
obj.name = "Alerts"
obj.version = "0.1"
obj.author = "Your Name <your@email.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- Alerts.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('Alerts')

obj.defaultFont = "Fira Code"
obj.defaultHelperStyle = {
  atScreenEdge = 0, -- Bottom edge (default value)
  textStyle = {     -- An hs.styledtext object
    font = {
      name = obj.defaultFont,
      size = 12
    }
  }
}

function obj.showDebug (msg)
  hs.alert.show(msg, obj.defaultHelperStyle)
end

return obj
