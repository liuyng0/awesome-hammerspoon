-- Stay replacement: Keep App windows in their places

-- luacheck: globals hs

local fun = require 'luarocks/fun'
local appmodal = {}
local logger = hs.logger.new('appmodal')
appmodal.logger = logger

function appmodal.bind(key1, key2, app_name, action_map)
    local modal_name = app_name .. 'AppModal'
    local modal_mgr = spoon.ModalMgr:new(modal_name)
    local cmodal = spoon.ModalMgr.modal_list[modal_name]
    for _, m in ipairs(action_map) do
        cmodal:bind('', m.key, m.description,
                    function()
                        spoon.ModalMgr:deactivate({modal_name})
                        m.action()
        end)
    end

    cmodal:bind('', 'escape', 'Deactivate ' .. modal_name, function() spoon.ModalMgr:deactivate({modal_name}) end)
    cmodal:bind('', 'Q', 'Deactivate ' .. modal_name, function() spoon.ModalMgr:deactivate({modal_name}) end)

    local modal = hs.hotkey.modal.new()
    modal:bind(key1, key2, function()
                   spoon.ModalMgr:deactivateAll()
                   spoon.ModalMgr:activate({modal_name}, "#FF6347", true)
    end)

    hs.window.filter.new(app_name)
        :subscribe(hs.window.filter.windowFocused,function()
                       logger.d("enter " .. app_name .. " local mode")
                       modal:enter()
                  end)
        :subscribe(hs.window.filter.windowUnfocused,function()
                       modal:exit()
                       spoon.ModalMgr:deactivateAll()
                  end)
    return modal_mgr
end

return appmodal
