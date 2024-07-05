-- -*- lua-indent-level:4 -*-
--- === Emacs ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Emacs.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Emacs.spoon.zip)

---@class spoon.Emacs
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Emacs"
obj.version = "0.1"
obj.author = "Your Name <your@email.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- Emacs.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('Emacs')
obj.emacs_bundle = "org.gnu.Emacs"

function obj:app ()
    return hs.application.applicationsForBundleID(obj.emacs_bundle)[1]
end

function obj:vterm_window ()
    return obj:app():findWindow(privconf.emacs_vterm_frame_title)
end

function obj:main_window ()
    local vterm_window = obj:vterm_window()
    return hs.fnutils.find(obj:app():allWindows(), function(win)
        return win ~= vterm_window
    end)
end

function obj:switch_to_vterm_window ()
    local vterm_window = obj:vterm_window()
    if vterm_window ~= nil then
        vterm_window:unminimize():raise():focus()
        return true
    else
        return false
    end
end

function obj:switch_to_main_window ()
    local main_window = obj:main_window()
    if main_window ~= nil then
        main_window:unminimize():raise():focus()
    end
end

return obj
