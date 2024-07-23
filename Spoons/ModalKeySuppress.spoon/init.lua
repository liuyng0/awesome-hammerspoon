--- === ModalKeySuppress ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/ModalKeySuppress.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/ModalKeySuppress.spoon.zip)

---@class spoon.ModalKeySuppress
local obj={}
obj.__index = obj

-- Metadata
obj.name = "ModalKeySuppress"
obj.version = "0.1"
obj.author = "Your Name <your@email.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- ModalKeySuppress.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('ModalKeySuppress')

local eventtap = require("hs.eventtap")
local M = U.moses

---@return hs.eventtap
function obj.suppress (modal, onSuppress)
  local passThroughKeys = {}

  -- this is annoying because the event's raw flag bitmasks differ from the bitmasks used by hotkey, so
  -- we have to convert here for the lookup

  for _, v in pairs(modal.keys) do
    -- parse for flags, get keycode for each
    local kc, mods = tostring(v._hk):match("keycode: (%d+), mods: (0x[^ ]+)")
    local hkFlags = tonumber(mods)
    local flags = 0
    if (hkFlags & 256) == 256 then
      hkFlags, flags = hkFlags - 256, flags | eventtap.event.rawFlagMasks
          .command
    end
    if (hkFlags & 512) == 512 then
      hkFlags, flags = hkFlags - 512, flags | eventtap.event.rawFlagMasks.shift
    end
    if (hkFlags & 2048) == 2048 then
      hkFlags, flags = hkFlags - 2048,
          flags | eventtap.event.rawFlagMasks.alternate
    end
    if (hkFlags & 4096) == 4096 then
      hkFlags, flags = hkFlags - 4096,
          flags | eventtap.event.rawFlagMasks.control
    end
    if hkFlags ~= 0 then
      obj.logger.d("unexpected flag pattern detected for " .. tostring(v._hk))
    end
    if passThroughKeys[tonumber(kc)] ~= nil then
      table.insert(passThroughKeys[tonumber(kc)], flags)
    else
      passThroughKeys[tonumber(kc)] = { flags }
    end
  end

  local eventtap = eventtap.new(
    {
      eventtap.event.types.keyDown,
      eventtap.event.types.keyUp
    },
    function(event)
      -- check only the flags we care about and filter the rest
      local flags =
          event:getRawEventData().CGEventData.flags &
          (eventtap.event.rawFlagMasks.command | eventtap.event.rawFlagMasks.control |
            eventtap.event.rawFlagMasks.alternate |
            eventtap.event.rawFlagMasks.shift)
      local eventType
      if (event:getType() & eventtap.event.types.keyUp) == eventtap.event.types.keyUp then
        eventType = "keyUp"
      else
        eventType = "keyDown"
      end
      local pid = event:getProperty(hs.eventtap.event.properties
        .eventSourceUnixProcessID)
      local keys = passThroughKeys[event:getKeyCode()]
      if keys ~= nil and M.contains(keys, flags) then
        obj.logger.df("passing:     %3d 0x%08x pid=%d, eventType=%s, eventType(string)=%s",
          event:getKeyCode(), flags,
          pid, event:getType(), eventType)
        return false -- pass it through so hotkey can catch it
      else
        if onSuppress then
          onSuppress(event)
        end
        -- hs.printf("suppressing: %3d 0x%08x pid=%d, eventType=%s",
        --   event:getKeyCode(), flags,
        --   pid, event:getType())
        return true -- delete it if we got this far -- it's a key that we want suppressed
      end
    end
  )
  return eventtap
end

return obj
