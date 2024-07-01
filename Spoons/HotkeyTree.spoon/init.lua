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
local modalMgr = spoon.ModalMgr
--- The super_key to start this tree
obj.super_key = { { "shift", "command", "control", "option" }, "1" }
obj.quit_keys = { { "control", "q" } }
obj.show_which_key = true

--- The tree is the configs for the keymappings
--- Each node could be below cases:
---   - (key, function, description)
---   - (key, mapping, description)
obj.tree = {}
obj.modals = {}
obj.leaf_functions = {}
obj.modal_inited = false

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
        return { "", fields[1] }
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

function obj:_makeTree (cursor, concatedKeys, index, description, func)
    while index < #concatedKeys do
        local key = concatedKeys[index]
        cursor[key] = { mapping = {}, description = obj.defaultPrefix }
        cursor = cursor[key].mapping
        index = index + 1
    end
    local key = concatedKeys[index]
    if not func then
        cursor[key] = { mapping = {}, description = description }
    else
        local fmap = { mapping = func, description = description }
        table.insert(obj.leaf_functions, fmap)
        cursor[key] = fmap
    end
end

--- Add a key binding
---
--- Parameters:
---  * keyseq - A key binding sequences, could be:
---   * {"a", "b"}
---   * {"a", {"control", "a"}, {"control", "option", "a"}}
---  * description - The help doc description
---  * func - function to be called when the key binding pressed
---    * if func is nil, means adding a prefix
function obj:addBinding (keyseq, description, func)
    local concatedKeys = M.chain(keyseq)
        :map(function(_, _keycomb) return obj:_concatKey(_keycomb) end)
        :value()
    local cursor = obj.tree
    local index = 0
    while index < #concatedKeys and cursor[concatedKeys[index + 1]] do
        cursor = cursor[concatedKeys[index + 1]].mapping
        if type(cursor) ~= "table" then
            obj.logger:w(F "Duplciated prefix {hs.inspect(concatedKeys)}")
            return
        end
        index = index + 1
    end
    if index == #concatedKeys then
        obj.logger:w(F "Duplicated binding {hs.inspect(concatedKeys)}")
        return
    end
    obj:_makeTree(cursor, concatedKeys, index + 1, description, func)
end

function obj:searchAndRun ()
    if #obj.leaf_functions < 1 then
        return
    end
    local choices = {}
    for _, funcs in pairs(obj.leaf_functions) do
        table.insert(choices,
            {
                ["text"] = funcs.description,
                ["subText"] = funcs.description
            })
    end
    local callback = function(choice)
        if choice == nil then
            return
        end
        for _, funcs in pairs(obj.leaf_functions) do
            if funcs.description == choice["text"] then
                funcs.mapping()
                return
            end
        end
    end
    local chooser = hs.chooser.new(callback)
    chooser:choices(choices)
    chooser:searchSubText(true):show()
end

--- Add a key binding
---
--- Parameters:
---  * prefixKeySeq - A key binding sequences as keystroke prefix:
---  * prefixDescription - The help doc description
---  * funcMap - table of the mapping it should contains below for each item
---    * key - relative key sequences exclude the prefixKeySeq
---    * func - function to call
---    * description - the description for the function
function obj:addMapping (prefixKeySeq, prefixDescription, funcMap)
    obj:addBinding(prefixKeySeq, prefixDescription, nil)
    for _, v in pairs(funcMap) do
        local key, func, description
        if v.key then
            key = v.key
            func = v.func
            description = v.description
        else
            key = v[1]
            func = v[2]
            description = v[3]
        end
        obj:addBinding(M.append(prefixKeySeq, key), description, func)
    end
end

function obj:_dfs (root, modalPath)
    if not modalMgr.modal_list[modalPath] then
        modalMgr:new(modalPath)
        obj.modals[modalPath] = modalMgr.modal_list[modalPath]
    end
    local curModal = modalMgr.modal_list[modalPath]
    for key, v in pairs(root) do
        local splitKey = obj:_splitKey(key)
        if type(v.mapping) == "table" then
            local childModalPath
            if modalPath == "/" then
                childModalPath = "/" .. key
            else
                childModalPath = modalPath .. "/" .. key
            end
            local childModal = obj:_dfs(v.mapping, childModalPath)
            curModal:bind(splitKey[1], splitKey[2], v.description, function()
                spoon.ModalMgr:deactivateAll()
                spoon.ModalMgr:activate({ childModalPath }, "#FF6347",
                    obj.show_which_key)
            end)
        else
            curModal:bind(splitKey[1], splitKey[2], v.description, function()
                spoon.ModalMgr:deactivateAll()
                v.mapping()
            end)
        end
    end
    return curModal
end

function obj:toggleShowWhichKey ()
    obj.show_which_key = not obj.show_which_key
    obj.logger:w(F "Toggle show which key -> {obj.show_which_key}")
end

function obj:initModals ()
    if obj.modal_inited then
        return
    end
    obj:_dfs(obj.tree, "/")
    obj.modal_inited = true
    --- The super key is also the key to deactive modal
    for _, modal in pairs(obj.modals) do
        modal:bind(obj.super_key[1], obj.super_key[2],
            "Deactive modals",
            function()
                spoon.ModalMgr:deactivateAll()
            end)
    end
end

return obj
