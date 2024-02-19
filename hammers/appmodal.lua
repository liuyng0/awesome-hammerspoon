-- Stay replacement: Keep App windows in their places

-- luacheck: globals hs

local fun = require "luarocks/fun"
local appmodal = {}
local logger = hs.logger.new("appmodal")
appmodal.logger = logger
appmodal.global_keys = nil

function appmodal:set_global_keys(keys_map)
    appmodal.global_keys_map = keys_map

    return appmodal
end

function appmodal.bind(key1, key2, app_name, action_map)
    local modal_name = app_name .. "AppModal"
    local modal_mgr = spoon.ModalMgr:new(modal_name)
    local cmodal = spoon.ModalMgr.modal_list[modal_name]
    for _, m in ipairs(action_map) do
        if type(m.key) == "table" then
            cmodal:bind(
                m.key[1],
                m.key[2],
                m.description,
                function()
                    spoon.ModalMgr:deactivate({modal_name})
                    m.action()
                end
            )
        else
            cmodal:bind(
                "",
                m.key,
                m.description,
                function()
                    spoon.ModalMgr:deactivate({modal_name})
                    m.action()
                end
            )
        end
    end

    if appmodal.global_keys_map ~= nil then
        for _, m in ipairs(appmodal.global_keys_map) do
            cmodal:bind(
                m.key[1],
                m.key[2],
                m.description,
                function()
                    spoon.ModalMgr:deactivate({modal_name})
                    m.action()
                end
            )
        end
    end

    cmodal:bind(
        "",
        "escape",
        "Deactivate " .. modal_name,
        function()
            spoon.ModalMgr:deactivate({modal_name})
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate " .. modal_name,
        function()
            spoon.ModalMgr:deactivate({modal_name})
        end
    )

    local modal = hs.hotkey.modal.new()
    modal:bind(
        key1,
        key2,
        function()
            spoon.ModalMgr:deactivateAll()
            spoon.ModalMgr:activate({modal_name}, "#FF6347", true)
        end
    )

    hs.window.filter.new(app_name):subscribe(
        hs.window.filter.windowFocused,
        function()
            logger.d("enter " .. app_name .. " local mode")
            modal:enter()
        end
    ):subscribe(
        hs.window.filter.windowUnfocused,
        function()
            modal:exit()
            spoon.ModalMgr:deactivateAll()
        end
    )
    return modal_mgr
end

return appmodal
