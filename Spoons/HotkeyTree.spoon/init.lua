--- === HotkeyTree ===
---
--- Hot key tree like spacemacs
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/HotkeyTree.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/HotkeyTree.spoon.zip)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "HotkeyTree"
obj.version = "0.1"
obj.author = "Your Name <your@email.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("HotkeyTree")

--- Imports
local M = lrks.moses

--- The super_key to start this tree
obj.super_key = { { "shift", "command", "control", "option" }, "1" }

--- The tree is the configs for the keymappings
--- Each node could be below cases:
---   - (key, function, description)
---   - (key, mapping, description)
obj.tree = {}

function _concat (a, b)
    return a .. "-" .. b
end

--- Encode the key to a string, for example
--- * "a" -> "a"
--- * {"control", "a"} -> "control-a"
--- * {"option", "control", "a"} -> "control-option-a"
function obj:_concatKey (keyseq)
    if type(keyseq) == "string" then
        return keyseq
    end
    if type(keyseq) == "table" then
        local modifiers = M.chain(keyseq)
            :initial(1)
            :sort()
            :reduce(_concat)
            :value()
        local key = M.nth(keyseq, #keyseq)
        return _concat(modifiers, key)
    end
end

function obj:_splitKey (keystring)
    local fields = hs.fnutils.split(keystring, "-")
    if fields and #fields == 1 then
        return fields[1]
    end
    local modifiers = M.chain(fields)
        :initial(1)
        :sort()
        :value()
    local key = M.nth(fields, #fields)

    local result = {}
    result[1] = modifiers
    result[2] = key

    return result
end

--- Add a key binding
---
--- Parameters:
---  * keyseq - A key binding sequences, could be:
---   * {"a", "b"}
---   * {"a", {"control", "a"}, {"control", "option", "a"}}
---  * func - function to be called when the key binding pressed
---  * description - The help doc description
function obj:addBinding (keyseq, func, description)
    return nil
end

return obj
