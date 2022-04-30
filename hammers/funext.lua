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

return funext
