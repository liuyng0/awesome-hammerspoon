local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Screen"
obj.version = "1.0"
obj.author = "Chophi <chophi@foxmail.com>"

obj.windowHighlightMode = false
obj.logger = hs.logger.new("Screen")
local M = U.moses

function obj:focusWindowOnNextScreen (nextCount)
    local screens = hs.screen.allScreens()
    local currentScreen = hs.screen.mainScreen()
    local screenAngle = {}
    for _, s in pairs(screens) do
        local frame = s:frame()
        local angle = math.atan(-(frame.y + frame.h), (frame.w + frame.x))
        -- hs.alert.show(string.format("%f, %s", angle, w:title()))
        table.insert(
            screenAngle,
            {
                screen = s,
                clockwise_angle = angle
            }
        )
    end
    table.sort(
        screenAngle,
        function(a, b)
            return a["clockwise_angle"] > b["clockwise_angle"]
        end
    )

    local thisScreenIndex = 1
    local numScreens = #screenAngle
    for i = 1, numScreens do
        -- hs.alert.show(string.format("The loop window is %s", windowAngle[i]["window"]:title()))
        if currentScreen == screenAngle[i]["screen"] then
            thisScreenIndex = i
            break
        end
    end
    local nextIndex = ((thisScreenIndex - 1 + numScreens + nextCount) % numScreens) +
        1
    local nextScreen = screenAngle[nextIndex]["screen"]

    local raiseAndFocusedWindow = false
    for _, w in pairs(hs.window.orderedWindows()) do
        if w:screen() == nextScreen and w:title() and string.len(w:title()) > 0 then
            -- hs.alert.show(string.format("found Window:%s", w:title()))
            if not obj.windowHighlightMode then
                hs.alert.closeAll()
                local alertUUid =
                    hs.alert.show(
                        string.format("Current Screen: %s, window: %s",
                            nextScreen:name(), w:title()),
                        hs.alert.defaultStyle,
                        nextScreen,
                        0.5
                    )
            end
            w:unminimize()
            w:raise()
            w:focus()
            raiseAndFocusedWindow = true
            break
        end
    end

    if not raiseAndFocusedWindow then
        local alertUUid =
            hs.alert.show(
                string.format("Current Screen: %s, no Window", nextScreen:name()),
                hs.alert.defaultStyle,
                nextScreen,
                2
            )
    end
end

function obj:sortedWindows (wins)
    local windowAngle = obj:_sortedWindows(wins)
    local windows = {}
    for _, w in pairs(windowAngle) do
        table.insert(windows, w["window"])
    end

    -- for _, w in pairs(windows) do
    --    hs.alert.show(string.format("window:%s", w:title()))
    -- end

    return windows
end

local function _frameClockWiseAngle (frame)
    return math.atan(-(frame.y + frame.h), (frame.w + frame.x))
end

function obj:_sortedWindows (wins)
    local windowAngle = {}

    for _, w in pairs(wins) do
        local frame = w:frame()
        local angle = _frameClockWiseAngle(frame)
        -- hs.alert.show(string.format("%f, %s", angle, w:title()))
        table.insert(
            windowAngle,
            {
                window = w,
                clockwise_angle = angle
            }
        )
    end

    -- for _, w in pairs(windowAngle) do
    --    hs.alert.show(string.format("before: %s, %f", w["window"]:title(), w["clockwise_angle"]))
    -- end
    table.sort(
        windowAngle,
        function(a, b)
            return (a["clockwise_angle"] > b["clockwise_angle"]) or
                (a["clockwise_angle"] == b["clockwise_angle"] and a["window"]:title() > b["window"]:title())
        end
    )

    return windowAngle
end

function getWindowNameFromCache (windowId, defaultWindowName)
    -- TODO: maybe add a cache to set window name overrides
    return defaultWindowName
end

function obj.selectWindow (choice)
    if choice == nil then
        return
    end
    local chosenWindow = choice["windowObject"]
    chosenWindow:unminimize()
    chosenWindow:raise()
    chosenWindow:focus()
end

function obj:getWindowChoices (allWindows, showAppNameAsPrefix)
    local chooserChoices = {}
    for _, w in pairs(allWindows) do
        table.insert(
            chooserChoices,
            {
                ["text"] = getWindowNameFromCache(w:id(), w:title()),
                ["visible"] = w:isVisible(),
                ["windowObject"] = w,
                ["application"] = w:application():name(),
                ["bundleID"] = w:application():bundleID()
            }
        )
    end
    table.sort(
        chooserChoices,
        function(a, b)
            if a["application"] ~= b["application"] then
                return a["application"] < b["application"]
            end

            if a["visible"] == b["visible"] then
                return a["text"] < b["text"]
            else
                return a["visible"]
            end
        end
    )

    for _, c in pairs(chooserChoices) do
        if showAppNameAsPrefix then
            c["subText"] = c["application"] .. " | " .. c["text"]
            c["text"] = c["application"]
        else
            c["subText"] = c["application"]
        end
    end
    return chooserChoices
end

-- Except the focused window
function selectWindowInList (allWindows, showAppNameAsPrefix)
    local chooser = hs.chooser.new(obj.selectWindow)
    local chooserChoices = obj:getWindowChoices(allWindows, showAppNameAsPrefix)
    spoon.ChooserStyle:setChooserUI(chooser, chooserChoices)
    chooser:choices(chooserChoices)
    chooser:searchSubText(true):show()
end

obj.crossSpaces = false
function obj:toggleCrossSpaces ()
    obj.crossSpaces = not obj.crossSpaces
end

function obj:selectWindowFromAllWindows ()
    local allWindows
    if obj.crossSpaces then
        allWindows =
            hs.fnutils.filter(
                hs.window.filter.default:getWindows(),
                function(win)
                    return win ~= hs.window.focusedWindow()
                end
            )
    else
        allWindows = hs.window.allWindows()
    end
    selectWindowInList(allWindows, true)
end

function obj:_sameAppWindowsWithFocused ()
    local focusedWindow = hs.window.focusedWindow()
    local focusedApp = focusedWindow:application()
    -- hs.alert.show(string.format("This app is:%s", focusedApp:name()))

    if obj.crossSpaces then
        return hs.window.filter.new { focusedApp:name() }:getWindows()
    else
        return focusedApp:allWindows()
    end
end

function obj:_sameAppWindowsWithFocusedExceptFocused ()
    local allWindows = obj:_sameAppWindowsWithFocused()

    return hs.fnutils.filter(
        allWindows,
        function(win)
            return win ~= hs.window.focusedWindow()
        end
    )
end

function obj:_switchFocusIfOnlyOneChoice ()
    local windows = obj:_sameAppWindowsWithFocusedExceptFocused()
    if #windows == 0 then
        hs.alert.show("No other windows", 0.5)

        return nil
    end
    if #windows == 1 then
        hs.alert.show("Only one window, switched", 0.5)

        windows[1]:unminimize()
        windows[1]:raise()
        windows[1]:focus()
        return nil
    end

    return windows
end

function obj:selectWindowFromFocusedApp ()
    local windows = obj:_switchFocusIfOnlyOneChoice()
    if windows ~= nil then
        selectWindowInList(windows, false)
    end
end

function obj:sameAppWindowInNextScreen (nextCount)
    local allWindows = obj:_switchFocusIfOnlyOneChoice()
    local focusedWindow = hs.window.focusedWindow()
    if allWindows == nil then
        return
    end
    -- add the current window back for index
    table.insert(allWindows, focusedWindow)

    local windowAngle = obj:_sortedWindows(allWindows)
    local thisWindowIndex = 1
    local numWindows = #windowAngle
    for i = 1, numWindows do
        -- hs.alert.show(string.format("The loop window is %s", windowAngle[i]["window"]:title()))
        if focusedWindow == windowAngle[i]["window"] then
            thisWindowIndex = i
            break
        end
    end
    local nextIndex = ((thisWindowIndex - 1 + numWindows + nextCount) % numWindows) +
        1
    local nextWindow = windowAngle[nextIndex]["window"]
    -- hs.alert.show(string.format("The next window is:%s", windowAngle[nextIndex]["window"]:title()))
    if not obj.windowHighlightMode then
        hs.alert.closeAll()
        local alertUUid = hs.alert.show("Current Screen", hs.alert.defaultStyle,
            nextWindow:screen(), 0.5)
    end
    nextWindow:unminimize()
    nextWindow:raise()
    nextWindow:focus()
    -- hs.alert.closeSpecific(alertUUid, 2)
end

function obj:toggleWindowHighlightMode ()
    if not obj.windowHighlightMode then
        obj.windowHighlightMode = true
        hs.window.highlight.ui.overlay = true
        hs.window.highlight.ui.flashDuration = 0.3
        hs.window.highlight.start()
        hs.alert.show("Window Highlight Mode is enabled")
    else
        obj.windowHighlightMode = false
        hs.window.highlight.stop()
        hs.alert.show("Window Highlight Mode is disabled")
    end
end

function obj:rotateVisibleWindows ()
    local wins = obj:windowsClockWise()
    if #wins < 2 then
        obj.logger.w("Not enough windows, skip")
        return
    end
    for i = 1, #wins do
        local curWinId, nextWinFrame
        curWinId = wins[i].id
        if i == #wins then
            nextWinFrame = wins[1].frame
        else
            nextWinFrame = wins[i + 1].frame
        end
        hs.window.get(curWinId):setFrame(nextWinFrame)
    end
end

function obj:otherVisibleWindows ()
    local focusedWindow = hs.window.focusedWindow()
    local wins = obj:windowsClockWise()
    return M.chain(wins)
        :select(function(win, _)
            return win.id ~= focusedWindow:id()
        end)
        :value()
end

local function selectOtherWindow (wins, callback)
    if #wins < 1 then
        obj.logger.w("Not enough windows, skip")
    end
    if #wins == 1 then
        local window = hs.window.get(wins[1].id)
        window:focus()
        if callback then
            callback(window)
        end
        return
    end
    local windows = M.chain(wins)
        :map(function(win, _)
            return hs.window.get(win.id)
        end)
        :value()
    hs.hints.windowHints(windows, callback)
end

function obj:focusOtherWindow (callback)
    local wins = obj:otherVisibleWindows()
    selectOtherWindow(wins, callback)
end

local function swapWindows (from, to)
    local fromFrame = from:frame()
    local toFrame = to:frame()
    from:setFrame(toFrame)
    to:setFrame(fromFrame)
end

function obj:swapWithOther ()
    local focusedWindow = hs.window.focusedWindow()
    obj:focusOtherWindow(function(win)
        swapWindows(focusedWindow, win)
        focusedWindow:focus()
    end)
end

function obj:selectFromCoveredWindow ()
    local wins = obj:windowsClockWise(true)
    local focusedWindow = hs.window.focusedWindow()
    selectOtherWindow(wins, function(win) win:setFrame(focusedWindow:frame()) end)
end

function obj:windowsClockWise (coveredWindow)
    local wins = obj:getWindowsGroupByScreens(coveredWindow)
    obj.logger.w(hs.inspect(wins))
    return M.chain(wins)
        :flatten(true)
        :sort(function(a, b)
            return _frameClockWiseAngle(a.frame) <
                _frameClockWiseAngle(b.frame)
        end)
        :value()
end

function obj:getWindowsGroupByScreens (coveredWindow)
    local windows = M.chain(obj:getVisibleWindowsForAllScreens())
        :sort(function(a, b)
            return a.order < b.order
        end)
        :groupBy(function(win, _)
            return win.screen:id()
        end)
        :map(function(wins, _)
            local canSeeWins = {}
            local coveredWins = {}
            for _, win in pairs(wins) do
                local visible = true
                for _, vwin in pairs(canSeeWins) do
                    local intersect = vwin.frame:intersect(win.frame)
                    obj.logger.w(hs.inspect(intersect.area))
                    if intersect.area ~= 0 then
                        visible = false
                        break
                    end
                end
                if visible == true then
                    table.insert(canSeeWins, win)
                else
                    table.insert(coveredWins, win)
                end
            end
            if coveredWindow then
                return coveredWins
            else
                return canSeeWins
            end
        end)
        :value()
    return windows
end

function obj:getVisibleWindowsForAllScreens ()
    local all_windows = hs.window.filter.default:getWindows()
    local wins = {}
    for i, w in pairs(all_windows) do
        local w_info = {
            id = w:id(),
            title = w:title(),
            screen = w:screen(),
            frame = w:frame(),
            application = w:application(),
            order = i
        }
        -- print(hs.inspect.inspect(w_info))
        table.insert(wins, w_info)
    end
    return wins
end

return obj
