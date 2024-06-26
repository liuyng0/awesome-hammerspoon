local privatepath = hs.fs.pathToAbsolute(hs.configdir .. "/private")

local logger = hs.logger.new("init.lua", "debug")
if not privatepath then
    -- Create `~/.hammerspoon/private` directory if not exists.
    hs.fs.mkdir(hs.configdir .. "/private")
end

local funext = require "hammers/funext"
require("private-config-default")
privateconf = hs.fs.pathToAbsolute(hs.configdir .. "/private/config.lua")
if privateconf then
    -- Load awesomeconfig file if exists
    require("private/config")
end

customconf = hs.fs.pathToAbsolute(hs.configdir .. "/custom.lua")
if customconf then
    require("custom")
end

lrks = {
    loader = require("luarocks.loader"),
    moses = require("moses")
}

function pathInfo (path)
    local len = string.len(path)
    local pos = len
    local extpos = len + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 and extpos ~= len + 1 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then                   -- 47 = char "/"
            break
        end
        pos = pos - 1
    end
    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

function getScript (filename)
    return os.getenv("HOME") .. "/.hammerspoon/scripts/" .. filename
end

function getVifFile (filename)
    return os.getenv("HOME") .. "/vif/" .. filename
end

__my_path = nil
function populatePathMaybe ()
    if not __my_path then
        local output, status, exitType, rc = hs.execute("echo \\$PATH", true)
        if status and output ~= "" then
            output = hs.fnutils.split(output, "\n")
            __my_path = output[#output - 1]
        end
    end
end

function executeWithPathPopulated (command)
    populatePathMaybe()
    if __my_path then
        return hs.execute("export PATH=" .. __my_path .. " && " .. command)
    end
end

-- ModalMgr Spoon must be loaded explicitly, because this repository heavily relies upon it.
hs.loadSpoon("ModalMgr")

-- Define default Spoons which will be loaded later
if not hspoon_list then
    hspoon_list = {
        "AClock",
        "BingDaily",
        "CircleClock",
        "ClipShow",
        "CountDown",
        "HCalendar",
        "HSaria2",
        "HSearch",
        "SpeedMenu",
        "WinWin",
        "FnMate",
        "ChooserStyle"
    }
end

-- Load those Spoons
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

----------------------------------------------------------------------------------------------------
-- appM modal environment
spoon.ModalMgr:new("appM")
local cmodal = spoon.ModalMgr.modal_list["appM"]
cmodal:bind(
    "",
    "escape",
    "Deactivate appM",
    function()
        spoon.ModalMgr:deactivate({ "appM" })
    end
)
cmodal:bind(
    "",
    "tab",
    "Deactivate appM",
    function()
        spoon.ModalMgr:deactivate({ "appM" })
    end
)
if not hsapp_list then
    hsapp_list = {
        { key = "f", name = "Finder" },
        { key = "s", name = "Safari" },
        { key = "t", name = "Terminal" },
        { key = "v", id = "com.apple.ActivityMonitor" },
        { key = "y", id = "com.apple.systempreferences" }
    }
end

function hideWebviewIfPresent ()
    local t = spoon.PopupTranslateSelection
    if t ~= nil and t.webview ~= nil and t.webview:hswindow() ~= nil and t.webview:hswindow():isVisible() then
        t.webview:hide()
    end
end

for _, v in ipairs(hsapp_list) do
    if funext.set_contains(privconf.hsapp_ignored_apps, v.id or v.name) then
        -- do nothing
    elseif v.id then
        local located_name = hs.application.nameForBundleID(v.id)
        if located_name then
            -- logger.d("bind " .. hs.inspect(v.key) .. " to bundle id: " .. v.id)
            cmodal:bind(
                type(v.key) == "table" and v.key[1] or "",
                type(v.key) == "table" and v.key[2] or v.key,
                located_name,
                function()
                    -- logger.d("launch by bundle id " .. v.id)
                    hideWebviewIfPresent()
                    hs.application.launchOrFocusByBundleID(v.id)
                    spoon.ModalMgr:deactivate({ "appM" })
                end
            )
        end
    elseif v.name then
        logger.d("bind " .. hs.inspect(v.key) .. " to app name: " .. v.name)
        cmodal:bind(
            type(v.key) == "table" and v.key[1] or "",
            type(v.key) == "table" and v.key[2] or v.key,
            v.name,
            function()
                -- logger.d("launch by name " .. v.name)
                hideWebviewIfPresent()
                hs.application.launchOrFocus(v.name)
                spoon.ModalMgr:deactivate({ "appM" })
            end
        )
    elseif v.func then
        cmodal:bind(
            type(v.key) == "table" and v.key[1] or "",
            type(v.key) == "table" and v.key[2] or v.key,
            v.func_name,
            function()
                -- logger.d("launch by name " .. v.name)
                hideWebviewIfPresent()
                v.func()
                spoon.ModalMgr:deactivate({ "appM" })
            end
        )
    end
end

-- Then we register some keybindings with modal supervisor
hsappM_keys = hsappM_keys or { "alt", "A" }
if string.len(hsappM_keys[2]) > 0 then
    cmodal:bind(
        hsappM_keys[1],
        hsappM_keys[2],
        "Deactivate appM",
        function()
            spoon.ModalMgr:deactivate({ "appM" })
        end
    )
    spoon.ModalMgr.supervisor:bind(
        hsappM_keys[1],
        hsappM_keys[2],
        "Enter AppM Environment",
        function()
            spoon.ModalMgr:deactivateAll()
            -- Show the keybindings cheatsheet once appM is activated
            spoon.ModalMgr:activate({ "appM" }, "#FFBD2E", true)
        end
    )
end

----------------------------------------------------------------------------------------------------
-- clipshowM modal environment
if spoon.ClipShow then
    spoon.ModalMgr:new("clipshowM")
    local cmodal = spoon.ModalMgr.modal_list["clipshowM"]
    cmodal:bind(
        "",
        "escape",
        "Deactivate clipshowM",
        function()
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate clipshowM",
        function()
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )
    cmodal:bind(
        "",
        "N",
        "Save this Session",
        function()
            spoon.ClipShow:saveToSession()
        end
    )
    cmodal:bind(
        "",
        "R",
        "Restore last Session",
        function()
            spoon.ClipShow:restoreLastSession()
        end
    )
    cmodal:bind(
        "",
        "B",
        "Open in Browser",
        function()
            spoon.ClipShow:openInBrowserWithRef()
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )
    cmodal:bind(
        "",
        "S",
        "Search with Bing",
        function()
            spoon.ClipShow:openInBrowserWithRef("https://www.bing.com/search?q=")
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )
    cmodal:bind(
        "",
        "M",
        "Open in MacVim",
        function()
            spoon.ClipShow:openWithCommand("/usr/local/bin/mvim")
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )
    cmodal:bind(
        "",
        "F",
        "Save to Desktop",
        function()
            spoon.ClipShow:saveToFile()
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )
    cmodal:bind(
        "",
        "H",
        "Search in Github",
        function()
            spoon.ClipShow:openInBrowserWithRef("https://github.com/search?q=")
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )
    cmodal:bind(
        "",
        "G",
        "Search with Google",
        function()
            spoon.ClipShow:openInBrowserWithRef(
                "https://www.google.com/search?q=")
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )
    cmodal:bind(
        "",
        "L",
        "Open in Sublime Text",
        function()
            spoon.ClipShow:openWithCommand("/usr/local/bin/subl")
            spoon.ClipShow:toggleShow()
            spoon.ModalMgr:deactivate({ "clipshowM" })
        end
    )

    -- Register clipshowM with modal supervisor
    hsclipsM_keys = hsclipsM_keys or { "alt", "C" }
    if string.len(hsclipsM_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(
            hsclipsM_keys[1],
            hsclipsM_keys[2],
            "Enter clipshowM Environment",
            function()
                -- We need to take action upon hsclipsM_keys is pressed, since pressing another key to showing ClipShow panel is redundant.
                spoon.ClipShow:toggleShow()
                -- Need a little trick here. Since the content type of system clipboard may be "URL", in which case we don't need to activate clipshowM.
                if spoon.ClipShow.canvas:isShowing() then
                    spoon.ModalMgr:deactivateAll()
                    spoon.ModalMgr:activate({ "clipshowM" })
                end
            end
        )
    end
end

----------------------------------------------------------------------------------------------------
-- Register HSaria2
if spoon.HSaria2 then
    -- First we need to connect to aria2 rpc host
    hsaria2_host = hsaria2_host or "http://localhost:6800/jsonrpc"
    hsaria2_secret = hsaria2_secret or "token"
    spoon.HSaria2:connectToHost(hsaria2_host, hsaria2_secret)

    hsaria2_keys = hsaria2_keys or { "alt", "D" }
    if string.len(hsaria2_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(
            hsaria2_keys[1],
            hsaria2_keys[2],
            "Toggle aria2 Panel",
            function()
                spoon.HSaria2:togglePanel()
            end
        )
    end
end

----------------------------------------------------------------------------------------------------
-- Register Hammerspoon Search
if spoon.HSearch then
    hsearch_keys = hsearch_keys or { "alt", "G" }
    if string.len(hsearch_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(
            hsearch_keys[1],
            hsearch_keys[2],
            "Launch Hammerspoon Search",
            function()
                spoon.HSearch:toggleShow()
            end
        )
    end
end

----------------------------------------------------------------------------------------------------
-- Register Hammerspoon API manual: Open Hammerspoon manual in default browser
hsman_keys = hsman_keys or { "alt", "H" }
if string.len(hsman_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(
        hsman_keys[1],
        hsman_keys[2],
        "Read Hammerspoon Manual",
        function()
            hs.doc.hsdocs.forceExternalBrowser(true)
            hs.doc.hsdocs.moduleEntitiesInSidebar(true)
            hs.doc.hsdocs.help()
        end
    )
end

----------------------------------------------------------------------------------------------------
-- countdownM modal environment
if spoon.CountDown then
    spoon.ModalMgr:new("countdownM")
    local cmodal = spoon.ModalMgr.modal_list["countdownM"]
    cmodal:bind(
        "",
        "escape",
        "Deactivate countdownM",
        function()
            spoon.ModalMgr:deactivate({ "countdownM" })
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate countdownM",
        function()
            spoon.ModalMgr:deactivate({ "countdownM" })
        end
    )
    cmodal:bind(
        "",
        "tab",
        "Toggle Cheatsheet",
        function()
            spoon.ModalMgr:toggleCheatsheet()
        end
    )
    cmodal:bind(
        "",
        "0",
        "5 Minutes Countdown",
        function()
            spoon.CountDown:startFor(5)
            spoon.ModalMgr:deactivate({ "countdownM" })
        end
    )
    for i = 1, 9 do
        cmodal:bind(
            "",
            tostring(i),
            string.format("%s Minutes Countdown", 10 * i),
            function()
                spoon.CountDown:startFor(10 * i)
                spoon.ModalMgr:deactivate({ "countdownM" })
            end
        )
    end
    cmodal:bind(
        "",
        "return",
        "25 Minutes Countdown",
        function()
            spoon.CountDown:startFor(25)
            spoon.ModalMgr:deactivate({ "countdownM" })
        end
    )
    cmodal:bind(
        "",
        "space",
        "Pause/Resume CountDown",
        function()
            spoon.CountDown:pauseOrResume()
            spoon.ModalMgr:deactivate({ "countdownM" })
        end
    )

    cmodal:bind(
        "",
        "-",
        "0.1 Minutes - 6 seconds Countdown",
        function()
            spoon.CountDown:startFor(0.1)
            spoon.ModalMgr:deactivate({ "countdownM" })
        end
    )
    -- Register countdownM with modal supervisor
    hscountdM_keys = hscountdM_keys or { "alt", "I" }
    if string.len(hscountdM_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(
            hscountdM_keys[1],
            hscountdM_keys[2],
            "Enter countdownM Environment",
            function()
                spoon.ModalMgr:deactivateAll()
                -- Show the keybindings cheatsheet once countdownM is activated
                spoon.ModalMgr:activate({ "countdownM" }, "#FF6347", true)
            end
        )
    end
end

----------------------------------------------------------------------------------------------------
-- Register lock screen
hslock_keys = hslock_keys or { "alt", "L" }
if string.len(hslock_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(
        hslock_keys[1],
        hslock_keys[2],
        "Lock Screen",
        function()
            hs.caffeinate.lockScreen()
        end
    )
end

----------------------------------------------------------------------------------------------------
-- resizeM modal environment
if spoon.WinWin then
    spoon.ModalMgr:new("resizeM")
    local cmodal = spoon.ModalMgr.modal_list["resizeM"]
    cmodal:bind(
        "",
        "escape",
        "Deactivate resizeM",
        function()
            spoon.ModalMgr:deactivate({ "resizeM" })
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate resizeM",
        function()
            spoon.ModalMgr:deactivate({ "resizeM" })
        end
    )
    cmodal:bind(
        "",
        "tab",
        "Toggle Cheatsheet",
        function()
            spoon.ModalMgr:toggleCheatsheet()
        end
    )
    cmodal:bind(
        "",
        "A",
        "Move Leftward",
        function()
            spoon.WinWin:stepMove("left")
        end,
        nil,
        function()
            spoon.WinWin:stepMove("left")
        end
    )
    cmodal:bind(
        "",
        "D",
        "Move Rightward",
        function()
            spoon.WinWin:stepMove("right")
        end,
        nil,
        function()
            spoon.WinWin:stepMove("right")
        end
    )
    cmodal:bind(
        "",
        "W",
        "Move Upward",
        function()
            spoon.WinWin:stepMove("up")
        end,
        nil,
        function()
            spoon.WinWin:stepMove("up")
        end
    )
    cmodal:bind(
        "",
        "S",
        "Move Downward",
        function()
            spoon.WinWin:stepMove("down")
        end,
        nil,
        function()
            spoon.WinWin:stepMove("down")
        end
    )
    cmodal:bind(
        "",
        "H",
        "Lefthalf of Screen",
        function()
            spoon.WinWin:moveAndResize("halfleft")
        end
    )
    cmodal:bind(
        "",
        "L",
        "Righthalf of Screen",
        function()
            spoon.WinWin:moveAndResize("halfright")
        end
    )
    cmodal:bind(
        "",
        "K",
        "Uphalf of Screen",
        function()
            spoon.WinWin:moveAndResize("halfup")
        end
    )
    cmodal:bind(
        "",
        "J",
        "Downhalf of Screen",
        function()
            spoon.WinWin:moveAndResize("halfdown")
        end
    )
    cmodal:bind(
        "",
        "Y",
        "NorthWest Corner",
        function()
            spoon.WinWin:moveAndResize("cornerNW")
        end
    )
    cmodal:bind(
        "",
        "O",
        "NorthEast Corner",
        function()
            spoon.WinWin:moveAndResize("cornerNE")
        end
    )
    cmodal:bind(
        "",
        "U",
        "SouthWest Corner",
        function()
            spoon.WinWin:moveAndResize("cornerSW")
        end
    )
    cmodal:bind(
        "",
        "I",
        "SouthEast Corner",
        function()
            spoon.WinWin:moveAndResize("cornerSE")
        end
    )
    cmodal:bind(
        "",
        "F",
        "Fullscreen",
        function()
            spoon.WinWin:moveAndResize("maximize")
        end
    )
    cmodal:bind(
        hyper2,
        "F",
        "Enter full screen",
        function()
            spoon.WinWin:moveAndResize("fullscreen")
        end
    )
    cmodal:bind(
        "",
        "C",
        "Center Window",
        function()
            spoon.WinWin:moveAndResize("center")
        end
    )
    cmodal:bind(
        hyper2,
        "M",
        "Center Half Width",
        function()
            spoon.WinWin:moveAndResize("centerHalfWidth")
        end
    )
    cmodal:bind(
        "",
        "=",
        "Stretch Outward",
        function()
            spoon.WinWin:moveAndResize("expand")
        end,
        nil,
        function()
            spoon.WinWin:moveAndResize("expand")
        end
    )
    cmodal:bind(
        "",
        "-",
        "Shrink Inward",
        function()
            spoon.WinWin:moveAndResize("shrink")
        end,
        nil,
        function()
            spoon.WinWin:moveAndResize("shrink")
        end
    )
    cmodal:bind(
        "shift",
        "H",
        "Move Leftward",
        function()
            spoon.WinWin:stepResize("left")
        end,
        nil,
        function()
            spoon.WinWin:stepResize("left")
        end
    )
    cmodal:bind(
        "shift",
        "L",
        "Move Rightward",
        function()
            spoon.WinWin:stepResize("right")
        end,
        nil,
        function()
            spoon.WinWin:stepResize("right")
        end
    )
    cmodal:bind(
        "shift",
        "K",
        "Move Upward",
        function()
            spoon.WinWin:stepResize("up")
        end,
        nil,
        function()
            spoon.WinWin:stepResize("up")
        end
    )
    cmodal:bind(
        "shift",
        "J",
        "Move Downward",
        function()
            spoon.WinWin:stepResize("down")
        end,
        nil,
        function()
            spoon.WinWin:stepResize("down")
        end
    )
    cmodal:bind(
        "",
        "left",
        "Move to Left Monitor",
        function()
            spoon.WinWin:moveToScreen("left")
        end
    )
    cmodal:bind(
        "",
        "right",
        "Move to Right Monitor",
        function()
            spoon.WinWin:moveToScreen("right")
        end
    )
    cmodal:bind(
        "",
        "up",
        "Move to Above Monitor",
        function()
            spoon.WinWin:moveToScreen("up")
        end
    )
    cmodal:bind(
        "",
        "down",
        "Move to Below Monitor",
        function()
            spoon.WinWin:moveToScreen("down")
        end
    )
    cmodal:bind(
        "",
        "space",
        "Move to Next Monitor",
        function()
            spoon.WinWin:moveToScreen("next")
        end
    )
    cmodal:bind(
        "",
        "M",
        "Move to Next Monitor",
        function()
            spoon.WinWin:moveToScreen("next")
        end
    )
    cmodal:bind(
        "",
        "[",
        "Undo Window Manipulation",
        function()
            spoon.WinWin:undo()
        end
    )
    cmodal:bind(
        "",
        "]",
        "Redo Window Manipulation",
        function()
            spoon.WinWin:redo()
        end
    )
    cmodal:bind(
        "",
        "`",
        "Center Cursor",
        function()
            spoon.WinWin:centerCursor()
        end
    )

    -- Register resizeM with modal supervisor
    hsresizeM_keys = hsresizeM_keys or { "alt", "R" }
    if string.len(hsresizeM_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(
            hsresizeM_keys[1],
            hsresizeM_keys[2],
            "Enter resizeM Environment",
            function()
                -- Deactivate some modal environments or not before activating a new one
                spoon.ModalMgr:deactivateAll()
                -- Show an status indicator so we know we're in some modal environment now
                spoon.ModalMgr:activate({ "resizeM" }, "#B22222")
            end
        )
    end
end

----------------------------------------------------------------------------------------------------
-- cheatsheetM modal environment (Because KSheet Spoon is NOT loaded, cheatsheetM will NOT be activated)
if spoon.KSheet then
    spoon.ModalMgr:new("cheatsheetM")
    local cmodal = spoon.ModalMgr.modal_list["cheatsheetM"]
    cmodal:bind(
        "",
        "escape",
        "Deactivate cheatsheetM",
        function()
            spoon.KSheet:hide()
            spoon.ModalMgr:deactivate({ "cheatsheetM" })
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate cheatsheetM",
        function()
            spoon.KSheet:hide()
            spoon.ModalMgr:deactivate({ "cheatsheetM" })
        end
    )

    -- Register cheatsheetM with modal supervisor
    hscheats_keys = hscheats_keys or { "alt", "S" }
    if string.len(hscheats_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(
            hscheats_keys[1],
            hscheats_keys[2],
            "Enter cheatsheetM Environment",
            function()
                spoon.KSheet:show()
                spoon.ModalMgr:deactivateAll()
                spoon.ModalMgr:activate({ "cheatsheetM" })
            end
        )
    end
end

----------------------------------------------------------------------------------------------------
-- Register AClock
if spoon.AClock then
    hsaclock_keys = hsaclock_keys or { "alt", "T" }
    if string.len(hsaclock_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(
            hsaclock_keys[1],
            hsaclock_keys[2],
            "Toggle Floating Clock",
            function()
                spoon.AClock:toggleShow()
            end
        )
    end
end

----------------------------------------------------------------------------------------------------
-- Register browser tab typist: Type URL of current tab of running browser in markdown format. i.e. [title](link)
hstype_keys = hstype_keys or { "alt", "V" }
if string.len(hstype_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(
        hstype_keys[1],
        hstype_keys[2],
        "Type Browser Link",
        function()
            local safari_running = hs.application.applicationsForBundleID(
                "com.apple.Safari")
            local chrome_running = hs.application.applicationsForBundleID(
                "com.google.Chrome")
            if #safari_running > 0 then
                local stat, data =
                    hs.applescript(
                        'tell application "Safari" to get {URL, name} of current tab of window 1')
                if stat then
                    hs.eventtap.keyStrokes("[" ..
                        data[2] .. "](" .. data[1] .. ")")
                end
            elseif #chrome_running > 0 then
                local stat, data =
                    hs.applescript(
                        'tell application "Google Chrome" to get {URL, title} of active tab of window 1')
                if stat then
                    hs.eventtap.keyStrokes("[" ..
                        data[2] .. "](" .. data[1] .. ")")
                end
            end
        end
    )
end

----------------------------------------------------------------------------------------------------
-- Register Hammerspoon console
hsconsole_keys = hsconsole_keys or { "alt", "Z" }
if string.len(hsconsole_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(
        hsconsole_keys[1],
        hsconsole_keys[2],
        "Toggle Hammerspoon Console",
        function()
            hs.toggleConsole()
        end
    )
end

if spoon.Screen then
    spoon.ModalMgr:new("screenM")
    local cmodal = spoon.ModalMgr.modal_list["screenM"]
    cmodal:bind(
        "",
        "escape",
        "Deactivate screenM",
        function()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate screenM",
        function()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )

    cmodal:bind(
        "",
        "L",
        "select window from focused App",
        function()
            spoon.Screen:selectWindowFromFocusedApp()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        "",
        "A",
        "select window from all Windows",
        function()
            spoon.Screen:selectWindowFromAllWindows()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )

    cmodal:bind(
        "",
        "N",
        "Switch to the same app window in next Screen (Clockwise)",
        function()
            spoon.Screen:sameAppWindowInNextScreen(1)
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        "",
        "P",
        "Switch to the same app Window in previous Screen (Clockwise)",
        function()
            spoon.Screen:sameAppWindowInNextScreen(-1)
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        "",
        "J",
        "Switch to the focused app in next Screen (Clockwise)",
        function()
            spoon.Screen:focusWindowOnNextScreen(1)
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        "",
        "K",
        "Switch to the focused app in previous Screen (Clockwise)",
        function()
            spoon.Screen:focusWindowOnNextScreen(-1)
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )

    cmodal:bind(
        "",
        "H",
        "Toggle Window Highlight Mode",
        function()
            spoon.Screen:toggleWindowHighlightMode()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        "",
        "I",
        "Toggle Window Isolate Mode",
        function()
            spoon.Screen:toggleCrossSpaces()
            -- hs.window.highlight.toggleIsolate()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        "",
        "S",
        "Swap Windows with next Screen",
        function()
            spoon.Screen:swapWithNext()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        hsscreenM_keys[1],
        "S",
        "Switch to Screen",
        function()
            spoon.Space:switchToSpace()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        hsscreenM_keys[1],
        "N",
        "Next Space",
        function()
            -- spoon.Space:nextSpace()
            spoon.ModalMgr:deactivate({ "screenM" })
            spoon.Yabai:gotoNextSpaces()
        end
    )
    cmodal:bind(
        hsscreenM_keys[1],
        "W",
        "Move focused window to Next Space",
        function()
            -- spoon.Space:moveCurrentWindowToNextSpace()
            spoon.ModalMgr:deactivate({ "screenM" })
            spoon.Yabai:moveFocusedWindowToNextSpace()
        end
    )
    cmodal:bind(
        hsscreenM_keys[1],
        "E",
        "Move focused window to Next Space",
        function()
            spoon.Space:moveCurrentWindowToNextSpaceYabai()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        hsscreenM_keys[1],
        "J",
        "Choose tile with SplitView",
        function()
            spoon.SplitView:choose()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        hsscreenM_keys[1],
        "K",
        "Swap windows with SplitView",
        function()
            spoon.SplitView:swapWindows()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        hsscreenM_keys[1],
        "L",
        "Switch Focus with SplitView",
        function()
            spoon.SplitView:switchFocus()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    cmodal:bind(
        hsscreenM_keys[1],
        ";",
        "Removal desktop with SplitView",
        function()
            spoon.SplitView:removeCurrentFullScreenDesktop()
            spoon.ModalMgr:deactivate({ "screenM" })
        end
    )
    -- Register screenM with modal supervisor
    hsscreenM_keys = hsscreenM_keys or { "cmd", "J" }
    if string.len(hsscreenM_keys[2]) > 0 then
        ---- Try to use hs.window.switcher, but seems not work well
        -- local nextWindow = function()
        --     spoon.ModalMgr:deactivate({"screenM"})
        --     local focusedWindow = hs.window.focusedWindow()
        --     local focusedApp = focusedWindow:application()
        --     -- hs.alert.show(string.format("This app is:%s", focusedApp:name()))

        --     hs.window.switcher.new(hs.window.filter.new{focusedApp:name()}):next()
        -- end
        -- local previousWindow = function()
        --     spoon.ModalMgr:deactivate({"screenM"})
        --     local focusedWindow = hs.window.focusedWindow()
        --     local focusedApp = focusedWindow:application()
        --     -- hs.alert.show(string.format("This app is:%s", focusedApp:name()))

        --     hs.window.switcher.new(hs.window.filter.new{focusedApp:name()}):previous()
        -- end
        -- cmodal:bind(hsscreenM_keys[1], 'N', "Next Window", nextWindow, nil, nextWindow)
        -- cmodal:bind(hsscreenM_keys[1], 'P', "Previous Window", previousWindow, nil, previousWindow)
        spoon.ModalMgr.supervisor:bind(
            hsscreenM_keys[1],
            hsscreenM_keys[2],
            "Enter screenM Environment",
            function()
                spoon.ModalMgr:deactivateAll()
                -- Show the keybindings cheatsheet once screenM is activated
                spoon.ModalMgr:activate({ "screenM" }, "#FF6347", true)
            end
        )
    end
end

if spoon.PopupTranslateSelection then
    -- Register translateM with modal supervisor
    hstranslateM_keys = hstranslateM_keys or { "cmd", "]" }

    spoon.ModalMgr:new("translateM")
    local cmodal = spoon.ModalMgr.modal_list["translateM"]
    cmodal:bind(
        "",
        "escape",
        "Deactivate translateM",
        function()
            spoon.PopupTranslateSelection:hide()
            spoon.ModalMgr:deactivate({ "translateM" })
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate translateM",
        function()
            spoon.PopupTranslateSelection:hide()
            spoon.ModalMgr:deactivate({ "translateM" })
        end
    )
    if spoon.PopupTranslateSelection:translateShellEnabled() then
        cmodal:bind(
            "",
            "E",
            "Translate Shell (to English)",
            function()
                spoon.ModalMgr:deactivate({ "translateM" })
                local text = spoon.PopupTranslateSelection:selectionOrInput()
                spoon.ModalMgr:activate({ "translateM" })
                spoon.PopupTranslateSelection:translateShell("en", text)
            end
        )
        cmodal:bind(
            "",
            "C",
            "Translate Shell (to Chinese)",
            function()
                spoon.ModalMgr:deactivate({ "translateM" })
                local text = spoon.PopupTranslateSelection:selectionOrInput()
                spoon.ModalMgr:activate({ "translateM" })
                spoon.PopupTranslateSelection:translateShell("zh", text)
            end
        )
    end

    cmodal:bind(
        "",
        "O",
        "Toggle showing Eudic LightPeek",
        function()
            if hs.window "^取词 $":isVisible() then
                hs.window "^取词 $":application():hide()
            else
                hs.window "^取词 $":raise()
            end
            spoon.ModalMgr:deactivate({ "translateM" })
        end
    )
    cmodal:bind(
        "",
        "I",
        "Open 画词翻译",
        function()
            if not hs.application("^Eudic$"):findMenuItem({ "功能", "划词翻译" })["ticked"] then
                hs.application("^Eudic$"):selectMenuItem({ "功能", "划词翻译" })
                hs.timer.doAfter(
                    1,
                    function()
                        hs.window "^取词 $":raise()
                    end
                )
            else
                hs.alert("欧路词典划词翻译已经打开")
            end
            spoon.ModalMgr:deactivate({ "translateM" })
        end
    )
    cmodal:bind(
        "",
        "P",
        "Close 画词翻译",
        function()
            if hs.application("^Eudic$"):findMenuItem({ "功能", "划词翻译" })["ticked"] then
                hs.application("^Eudic$"):selectMenuItem({ "功能", "划词翻译" })
                hs.timer.doAfter(
                    1,
                    function()
                        hs.window "^取词 $":application():hide()
                    end
                )
            else
                hs.alert("欧路词典划词翻译已经关闭")
            end
            spoon.ModalMgr:deactivate({ "translateM" })
        end
    )
    if string.len(hstranslateM_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(
            hstranslateM_keys[1],
            hstranslateM_keys[2],
            "Enter translateM Environment",
            function()
                spoon.ModalMgr:deactivateAll()
                -- Show the keybindings cheatsheet once translateM is activated
                spoon.ModalMgr:activate({ "translateM" }, "#FF6347", true)
            end
        )
    end
end

hs.hotkey.bind(
    hyper2,
    "'",
    function()
        spoon.PopupTranslateSelection:toggleTranslatePopup("zh", "en")
        spoon.ModalMgr:deactivate({ "translateM" })
    end
)

-- Begin MissionControlWithExpose
local settingAll = {
    includeNonVisible = true,
    includeOtherSpaces = true,
    -- highlightThumbnailStrokeWidth = 0,
    -- backgroundColor = {0, 128, 255, 0.3},
    showTitles = true,
    onlyActiveApplication = false
    -- fitWindowsInBackground = false,
}

if hsexpose_keys then
    local hsExposeInstanceDefaultAllSpaces = hs.expose.new(nil, settingAll)
    spoon.ModalMgr:new("MCExpose")
    local cmodal = spoon.ModalMgr.modal_list["MCExpose"]
    cmodal:bind(
        "",
        "escape",
        "Deactivate MCExpose",
        function()
            spoon.ModalMgr:deactivate({ "MCExpose" })
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate MCExpose",
        function()
            spoon.ModalMgr:deactivate({ "MCExpose" })
        end
    )
    cmodal:bind(
        "",
        "A",
        "Show all",
        function()
            spoon.ModalMgr:deactivate({ "MCExpose" })
            hsExposeInstanceDefaultAllSpaces:toggleShow(false)
        end
    )
    cmodal:bind(
        "",
        "C",
        "Only current application",
        function()
            spoon.ModalMgr:deactivate({ "MCExpose" })
            hsExposeInstanceDefaultAllSpaces:toggleShow(true)
        end
    )

    cmodal:bind(
        "",
        "E",
        "Toggle App Expose Using Spaces",
        function()
            spoon.ModalMgr:deactivate({ "MCExpose" })
            hs.spaces.toggleAppExpose()
        end
    )

    cmodal:bind(
        "",
        "D",
        "Toggle Show Desktop Using Spaces",
        function()
            spoon.ModalMgr:deactivate({ "MCExpose" })
            hs.spaces.toggleShowDesktop()
        end
    )

    cmodal:bind(
        "",
        "M",
        "Toggle Mission Control Using Spaces",
        function()
            spoon.ModalMgr:deactivate({ "MCExpose" })
            hs.spaces.toggleMissionControl()
        end
    )

    cmodal:bind(
        "",
        "L",
        "Toggle Launch Pad",
        function()
            spoon.ModalMgr:deactivate({ "MCExpose" })
            hs.spaces.toggleLaunchPad()
        end
    )

    -- Register countdownM with modal supervisor
    spoon.ModalMgr.supervisor:bind(
        hsexpose_keys[1],
        hsexpose_keys[2],
        "Enter MCExpose Environment",
        function()
            spoon.ModalMgr:deactivateAll()
            -- Show the keybindings cheatsheet once countdownM is activated
            spoon.ModalMgr:activate({ "MCExpose" }, "#FF6347", true)
        end
    )
end
-- End MissionControlWithExpose

if hsstay_keys then
    local stay = require("hammers/stay")
    stay.hotkey =
        hs.hotkey.new(
            hsstay_keys[1],
            hsstay_keys[2],
            function()
                stay:toggle_or_choose()
            end
        )
    stay:start()
end

if hssession_keys then
    local session = require("hammers/session")
    spoon.ModalMgr:new("HSSession")
    local cmodal = spoon.ModalMgr.modal_list["HSSession"]
    cmodal:bind(
        "",
        "escape",
        "Deactivate HSSession",
        function()
            spoon.ModalMgr:deactivate({ "HSSession" })
        end
    )
    cmodal:bind(
        "",
        "Q",
        "Deactivate HSSession",
        function()
            spoon.ModalMgr:deactivate({ "HSSession" })
        end
    )
    cmodal:bind(
        "",
        "S",
        "Save current application",
        function()
            spoon.ModalMgr:deactivate({ "HSSession" })
            session:saveCurrentSession()
        end
    )
    cmodal:bind(
        "",
        "G",
        "Switch to session",
        function()
            spoon.ModalMgr:deactivate({ "HSSession" })
            session:switchToSession()
        end
    )
    cmodal:bind(
        "",
        "L",
        "[Debug] Show Current Session",
        function()
            spoon.ModalMgr:deactivate({ "HSSession" })
            session:showCurrentSession()
        end
    )
    -- Register session module with modal supervisor
    spoon.ModalMgr.supervisor:bind(
        hssession_keys[1],
        hssession_keys[2],
        "Enter HSSession Environment",
        function()
            spoon.ModalMgr:deactivateAll()
            -- Show the keybindings cheatsheet once countdownM is activated
            spoon.ModalMgr:activate({ "HSSession" }, "#FF6347", true)
        end
    )

    hs.hotkey.bind(
        hyper2,
        "T",
        function()
            session:saveCurrentSession()
        end
    )
end

-- Change the test function to test
function test ()
    hs.alert.show("this is a test")
end

function testEmacs28 ()
    hs.execute("open /Applications/Emacs28.app")
end

-- hs.hotkey.bind(hyper2, "T", function() test() end)

function copyEmailLink ()
    status, data =
        hs.osascript.applescript(
            [[tell application "Microsoft Outlook"
        set theMessages to selected objects
        repeat with theMessage in theMessages
        set toOpen to id of theMessage
        set the clipboard to toOpen
        end repeat
        end tell]]
        )
    hs.alert.show("email link is copied")
end

hs.hotkey.bind(
    hyper4,
    "L",
    function()
        copyEmailLink()
    end
)
populatePathMaybe()

---------------------------------------------------------------------------------------------------
-- Application specific hot keys
local appmodal = require "hammers/appmodal"
local APP_OMNI_GRAFFLE_NAME = "OmniGraffle"
local APP_ITERM_NAME = "iTerm2"
local APP_CHROME = "Google Chrome"
local APP_GOODNOTES = "GoodNotes"

local app_model_global_actions = {
    {
        key = { "cmd", "J" },
        description = "Tile Window to Left of Screen",
        action = function()
            local cwin = hs.window.focusedWindow()
            cwin:application():selectMenuItem({ "Window",
                "Tile Window to Left of Screen" })
        end
    },
    {
        key = { "cmd", "L" },
        description = "Tile Window to Right of Screen",
        action = function()
            local cwin = hs.window.focusedWindow()
            cwin:application():selectMenuItem({ "Window",
                "Tile Window to Right of Screen" })
        end
    }
}

appmodal:set_global_keys(app_model_global_actions)

---- OmniGraffle
local omnigraffle_modal =
    appmodal.bind(
        "cmd",
        "P",
        APP_OMNI_GRAFFLE_NAME,
        {
            {
                key = "T",
                description = "Toggle all Side bars",
                action = function()
                    hs.eventtap.keyStroke({ "cmd", "alt" }, "1")
                    hs.eventtap.keyStroke({ "cmd", "shift" }, "I")
                end
            },
            {
                key = "L",
                description = "Toggle left Side bars",
                action = function()
                    hs.eventtap.keyStroke({ "cmd", "alt" }, "1")
                end
            },
            {
                key = "R",
                description = "Toggle right Side bars",
                action = function()
                    hs.eventtap.keyStroke({ "cmd", "shift" }, "I")
                end
            },
            {
                key = "E",
                description = "Export to SVGs",
                action = function()
                    local itemApp = hs.application.find(APP_OMNI_GRAFFLE_NAME)
                    itemApp:selectMenuItem({ "File", "Export…" })
                end
            }
        }
    )

---- iTerm2
local iterm_modal =
    appmodal.bind(
        "cmd",
        "P",
        APP_ITERM_NAME,
        {
            {
                key = "P",
                description = "Select Previous Tab",
                action = function()
                    local itemApp = hs.application.find(APP_ITERM_NAME)
                    itemApp:selectMenuItem({ "Window", "Select Previous Tab" })
                end
            },
            {
                key = "N",
                description = "Select Next Tab",
                action = function()
                    local itemApp = hs.application.find(APP_ITERM_NAME)
                    itemApp:selectMenuItem({ "Window", "Select Next Tab" })
                end
            },
            {
                key = "C",
                description = "New Tab with Current Profile",
                action = function()
                    local itemApp = hs.application.find(APP_ITERM_NAME)
                    itemApp:selectMenuItem({ "Shell",
                        "New Tab with Current Profile" })
                end
            },
            {
                key = "X",
                description = "Close",
                action = function()
                    local itemApp = hs.application.find(APP_ITERM_NAME)
                    itemApp:selectMenuItem({ "Shell", "Close" })
                end
            }
        }
    )

---- Chrome
local chrome_modal =
    appmodal.bind(
        "cmd",
        "P",
        APP_CHROME,
        {
            {
                key = "P",
                description = "Select Previous Tab",
                action = function()
                    local itemApp = hs.application.find(APP_CHROME)
                    itemApp:selectMenuItem({ "Tab", "Select Previous Tab" })
                end
            },
            {
                key = "N",
                description = "Select Next Tab",
                action = function()
                    local itemApp = hs.application.find(APP_CHROME)
                    itemApp:selectMenuItem({ "Tab", "Select Next Tab" })
                end
            },
            {
                key = { "cmd", "P" },
                description = "Search Tabs",
                action = function()
                    local itemApp = hs.application.find(APP_CHROME)
                    itemApp:selectMenuItem({ "Tab", "Search Tabs…" })
                end
            },
            {
                key = "M",
                description = "Task Manager",
                action = function()
                    local itemApp = hs.application.find(APP_CHROME)
                    itemApp:selectMenuItem({ "Window", "Task Manager" })
                end
            }
        }
    )

-- Finally we initialize ModalMgr supervisor
spoon.ModalMgr.supervisor:enter()

spoon.AppBindings:bind(
    APP_GOODNOTES,
    {
        { { "ctrl" }, "i", {}, "up" },   -- Scroll message window
        { { "ctrl" }, "k", {}, "down" }, -- Scroll message window
        { { "ctrl" }, "j", {}, "left" }, -- Scroll message window
        { { "ctrl" }, "l", {}, "right" } -- Scroll message window
    }
)

spoon.AppBindings:bind(
    "Kindle",
    {
        { { "ctrl" }, "i", {}, "up" },   -- Scroll message window
        { { "ctrl" }, "k", {}, "down" }, -- Scroll message window
        { { "ctrl" }, "j", {}, "left" }, -- Scroll message window
        { { "ctrl" }, "l", {}, "right" } -- Scroll message window
    }
)

spoon.AppBindings:bind(
    "Preview",
    {
        { { "ctrl" }, "i", {}, "up" },   -- Scroll message window
        { { "ctrl" }, "k", {}, "down" }, -- Scroll message window
        { { "ctrl" }, "j", {}, "left" }, -- Scroll message window
        { { "ctrl" }, "l", {}, "right" } -- Scroll message window
    }
)

function anyNotIgnored (files)
    local command = "cd ~/.hammerspoon && git check-ignore " ..
        table.concat(files, " ") .. " | wc -l"
    local output, rc = hs.execute(command)
    local not_ignored_exists = rc and tonumber(output) < #files
    if not_ignored_exists then
        logger.d("At least one file changed and not git ignored: " ..
            hs.inspect(files))
    else
        logger.d("All ignored: " .. hs.inspect(files))
    end

    return not_ignored_exists
end

function reloadConfig (files)
    local mayReload = {}
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" and pathInfo(file)["basename"]:sub(0, 2) ~= ".#" then
            table.insert(mayReload, file)
        end
    end
    if #mayReload > 0 and anyNotIgnored(mayReload) then
        myWatcher:stop()
        hs.reload()
    end
end

-- Watch the configuration change.
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/",
    reloadConfig)
myWatcher:start()

hsreload_keys = hsreload_keys or { { "cmd", "shift", "ctrl" }, "R" }
if string.len(hsreload_keys[2]) > 0 then
    hs.hotkey.bind(
        hsreload_keys[1],
        hsreload_keys[2],
        "Reload Configuration",
        function()
            hs.reload()
        end
    )
end
-- Disable the alert key showing
hs.hotkey.alertDuration = 0

require("hs.ipc")

-- NOTE: Keep this the last.
if __my_path then
    hs.alert.show("Hammerspoon config loaded, path loaded.")
else
    hs.alert.show("Hammerspoon config loaded, load PATH failure")
end
