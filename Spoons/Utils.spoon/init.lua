--- === Utils ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Utils.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Utils.spoon.zip)

---@class spoon.Utils
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Utils"
obj.version = "0.1"
obj.author = "Your Name <your@email.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- Utils.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('Utils')

---@type utils.moses
obj.moses = dofile(hs.spoons.resourcePath("moses.lua"))
---@type utils.F
obj.F = dofile(hs.spoons.resourcePath("F.lua"))
---@type utils.command
obj.command = dofile(hs.spoons.resourcePath("command.lua"))
---@type utils.expose
obj.expose = dofile(hs.spoons.resourcePath("expose.lua"))
---@type utils.hints
obj.hints = dofile(hs.spoons.resourcePath("hints.lua"))

return obj
