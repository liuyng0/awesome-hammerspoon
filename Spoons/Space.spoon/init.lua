local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Space"
obj.version = "1.0"
obj.author = "Chophi <chophi@foxmail.com>"

obj.logger = hs.logger.new("Space")

local spaces = require("hs.spaces")
local funs = require("hs.fnutils")
local M = U.moses
function obj:getSpaceTable ()
    local allSpaces = spaces.allSpaces()
    local spaceTable = {}
    local allWindows = hs.window.filter.default:getWindows()
    local windowsById = {}
    funs.map(
        allWindows,
        function(win)
            windowsById[win:id()] = win
        end
    )

    local focusedSpace = spaces.focusedSpace()
    local screenByUUID = {}
    funs.map(
        hs.screen.allScreens(),
        function(scn)
            screenByUUID[scn:getUUID()] = scn
        end
    )
    M.forEach(
        allSpaces,
        function(screenUUID, spaceIds)
            funs.map(
                spaceIds,
                function(spaceId)
                    local validWindows =
                        funs.filter(
                            funs.map(
                                spaces.windowsForSpace(spaceId),
                                function(wid)
                                    return windowsById[wid]
                                end
                            ),
                            function(w)
                                return w ~= nil
                            end
                        )

                    local subText =
                        funs.reduce(
                            funs.map(
                                validWindows,
                                function(win)
                                    return win:application():name() ..
                                        " | " .. win:title()
                                end
                            ),
                            function(titleA, titleB)
                                return titleA .. "\n" .. titleB
                            end
                        )

                    table.insert(
                        spaceTable,
                        {
                            ["spaceId"] = spaceId,
                            ["screenUUID"] = screenUUID,
                            ["text"] = "" ..
                                (screenByUUID[screenUUID] and screenByUUID[screenUUID]:name() or screenUUID) ..
                                " | " .. spaceId,
                            ["subText"] = subText,
                            ["isFocusedSpace"] = spaceId == focusedSpace
                        }
                    )
                end
            )
        end
    )

    -- obj.logger.w("Got space table: " .. hs.inspect(spaceTable))
    return spaceTable
end

function obj:nextSpace ()
    local allScreens = hs.screen.allScreens()
    local spaceIds = {}
    for i = 1, #allScreens do
        spaceIds[i] = obj:_getNextSpaceId(allScreens[i]:getUUID())
    end
    for i = 1, #allScreens do
        if i ~= 1 then
            hs.timer.usleep(300000)
        end
        obj.logger.w("Goto space:" .. spaceIds[i])
        spaces.gotoSpace(spaceIds[i])
    end
end

function obj:moveCurrentWindowToNextSpace ()
    local focusedWindow = hs.window.focusedWindow()
    local nextSpace = obj:_getNextSpaceId(focusedWindow:screen():getUUID())
    obj.logger.w("Move window " ..
        "[isStandard=" .. tostring(focusedWindow:isStandard()) ..
        "], [isFullScreen=" .. tostring(focusedWindow:isFullScreen()) ..
        "]" .. "title=" ..
        focusedWindow:title() ..
        ", id=" ..
        tostring(focusedWindow:id()) ..
        ", to Space " ..
        nextSpace)
    spaces.moveWindowToSpace(focusedWindow:id(), nextSpace)
end

local function yabai (commands)
    for _, cmd in ipairs(commands) do
        os.execute("/opt/homebrew/bin/yabai -m " .. cmd)
    end
end

function obj:moveCurrentWindowToNextSpaceYabai ()
    yabai({ "window --space next" })
end

function obj:_getNextSpaceId (screenUUID)
    local spaceId = hs.spaces.activeSpaceOnScreen(screenUUID)
    local spaceIds = hs.spaces.allSpaces()[screenUUID]
    local thisSpaceIndex = 1
    local numSpaces = #spaceIds
    for i = 1, numSpaces do
        if spaceId == spaceIds[i] then
            thisSpaceIndex = i
            break
        end
    end
    if thisSpaceIndex == numSpaces then
        return spaceIds[1]
    else
        return spaceIds[thisSpaceIndex + 1]
    end
end

function obj:getAllSpaceIds ()
    local rs = {}
    local mark = {}
    local index = 1
    for _, v in pairs(spaces.allSpaces()) do
        for _, id in pairs(v) do
            if not mark[id] then
                mark[id] = true
                rs[index] = id
                index = index + 1
            end
        end
    end
    table.sort(rs, function(a, b) return a > b end)
    return rs
end

function obj:switchToSpace ()
    local choices = obj:getSpaceTable()
    local chooser =
        hs.chooser.new(
            function(choice)
                if choice == nil then
                    return
                end
                if choice["isFocusedSpace"] == nil then
                    obj.logger.w("Already in this space, do nothing")
                    return
                end
                spaces.gotoSpace(choice["spaceId"])
            end
        )

    spoon.ChooserStyle:setChooserUI(chooser, choices,
        { grayOutKey = "isFocusedSpace", darkStyle = false })
    choices = spoon.ChooserStyle:getReorderedChoices(choices, "isFocusedSpace")

    chooser:choices(choices)
    chooser:searchSubText(true):show()
end

return obj
