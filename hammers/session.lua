-- Stay replacement: Keep App windows in their places

-- luacheck: globals hs

local hs_geometry = hs.geometry
local funext = require 'hammers/funext'
local fun = require 'luarocks/fun'

local M = {}

M.session_file = "~/.hs.session.json"

local session_file_path = hs.fs.pathToAbsolute(M.session_file)

M.logger = hs.logger.new('Session')
if session_file_path then
    M.sessions = hs.json.read(M.session_file)
else
    M.sessions = {}
end

local logger = M.logger

local function getVisibleWindows()
    local filteredWindows = fun.filter(hs.window.orderedWindows(),
                                       function(window)
                                           return window:isStandard() and window:isVisible()
    end)

    local rs = {}
    local index = 0
    fun.map(filteredWindows, function(window)
                local interacted = 0
                for i = 1, #rs do
                    -- logger.e(window.frame)
                    -- logger.e(rs[i].frame)
                    local x = window:frame():intersect(rs[i]:frame())
                    if x.w ~= 0 and x.h ~= 0 then
                        interacted = 1
                    end
                end
                if interacted == 0 then
                    rs[index+1] = window
                    index = index + 1
                    return true
                end
                return false
    end)

    local windows = funext.imap(
        rs,
        function(_, window)
            return {
                id = window:id(),
                title = window:title(),
                frame = window:frame().table,
                appBundleId = window:application():bundleID(),
                screenId = window:screen():id(),
            }
        end
    )

    -- logger.e(hs.inspect(windows))
    return windows
end

function M:showCurrentSession()
    local windows = getVisibleWindows()
    -- hs.json.write(windows, "/tmp/windows.json")
    hs.alert.show(hs.inspect(windows))
end

local function saveSessions()
    hs.json.write(M.sessions, M.session_file)
end

function M:saveCurrentSession()
    local windows = getVisibleWindows()
    local ok, text = hs.dialog.textPrompt("Enter a session name:", "the default text is provided", "title - description", "OK", "Cancel")
    if ok == "OK" then
        if M.sessions[text] == nil then
            M.sessions[text] = windows
            saveSessions()
        else
            hs.alert.show("Duplicated title, do nothing")
        end
    end
    logger.e(hs.inspect(M.sessions))
end

function M:switchToSession()
    logger.e(hs.inspect(M.sessions))
    local function choiceFn()
        return funext.imap(
            M.sessions,
            function(text, session)
                return {
                    text = text,
                    subText = text,
                    session = session
                }
            end
        )
    end

    local function callback(choice)
        if choice then
            -- TODO: implement the callback function here
            hs.alert.show("Session selected" .. hs.inspect(choice.session))
        end
    end

    local chooser = hs.chooser.new(callback):
        choices(choiceFn):
        searchSubText(true)

    chooser:show()
end

return M
