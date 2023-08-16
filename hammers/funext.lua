-- Stay replacement: Keep App windows in their places

-- luacheck: globals hs

local fun = require 'luarocks/fun'
local funext = {}
local logger = hs.logger.new('funext')
funext.logger = logger

function funext.imap(xs, fn)
    local rs = {}
    local i = 1
    for k, v in pairs(xs) do
        rs[i] = fn(k, v)
        i = i+1
    end
    return rs
end

function funext.set(t)
    local s = {}
    for _,v in pairs(t) do s[v] = true end
    return s
end

function funext.set_contains(t, e)
    if t == nil or e == nil then
        return false
    end

    return t[e]
end

return funext
