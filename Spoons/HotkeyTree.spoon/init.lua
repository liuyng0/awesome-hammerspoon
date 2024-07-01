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
local F = lrks.F

--- The super_key to start this tree
obj.super_key = { { "shift", "command", "control", "option" }, "1" }

--- The tree is the configs for the keymappings
--- Each node could be below cases:
---   - (key, function, description)
---   - (key, mapping, description)
obj.tree = {}

obj.defaultPrefix = "+prefix"
function _concat (a, b)
    return a .. "-" .. b
end

--- Encode the key to a string, for example
--- * "a" -> "a"
--- * {"control", "a"} -> "control-a"
--- * {"option", "control", "a"} -> "control-option-a"
function obj:_concatKey (keycomb)
    if type(keycomb) == "string" then
        return keycomb
    end
    if type(keycomb) == "table" then
        local modifiers = M.chain(keycomb)
            :initial(1)
            :sort()
            :reduce(_concat)
            :value()
        local key = M.nth(keycomb, #keycomb)
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

function obj:_makeTree (cursor, concatedKeys, index, func, description)
    while index < #concatedKeys do
        local key = concatedKeys[index]
        cursor[key] = { mapping = {}, description = obj.defaultPrefix }
        cursor = cursor[key].mapping
        index = index + 1
    end
    local key = concatedKeys[index]
    cursor[key] = { mapping = func, description = description }
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
    local concatedKeys = M.chain(keyseq)
        :map(function(_, _keycomb) return obj:_concatKey(_keycomb) end)
        :value()
    local cursor = obj.tree
    local index = 0
    while index < #concatedKeys and cursor[concatedKeys[index + 1]] do
        cursor = obj.tree[concatedKeys[index + 1]].mapping
        if type(cursor) ~= "table" then
            obj.logger:w(F "Duplciated prefix {concatedKeys} {cursor.description}")
            return
        end
        index = index + 1
    end
    if index == #concatedKeys then
        obj.logger:w(F "Duplicated binding {concatedKeys}")
        return
    end
    obj:_makeTree(cursor, concatedKeys, index + 1, func, description)
end

return obj
