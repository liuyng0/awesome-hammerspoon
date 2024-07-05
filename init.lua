local privatepath = hs.fs.pathToAbsolute(hs.configdir .. "/private")

local logger = hs.logger.new("init.lua", "debug")
local color = require("hs.drawing.color")

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
    moses = require("moses"),
    F = require("F")
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

-- Specify Spoons which will be loaded
hspoon_list = {
    "CountDown",
    "HSearch",
    "WinWin",
    "Screen",
    "Space",
    "Links",
    "PopupTranslateSelection",
    "SplitView",
    "AppBindings",
    "ChooserStyle",
    "Emacs",
    "Yabai",
    'RecursiveBinder'
}

-- ModalMgr Spoon must be loaded explicitly, because this repository heavily relies upon it.
hs.loadSpoon("ModalMgr")

-- Load those Spoons
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
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
            cwin:application():selectMenuItem(
                {
                    "Window",
                    "Tile Window to Left of Screen"
                }
            )
        end
    },
    {
        key = { "cmd", "L" },
        description = "Tile Window to Right of Screen",
        action = function()
            local cwin = hs.window.focusedWindow()
            cwin:application():selectMenuItem(
                {
                    "Window",
                    "Tile Window to Right of Screen"
                }
            )
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
                    itemApp:selectMenuItem(
                        {
                            "Shell",
                            "New Tab with Current Profile"
                        }
                    )
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

--- Launch applications functions
local launch_emacs = function()
    if spoon.Emacs:app() ~= nil then
        spoon.Emacs:switch_to_main_window()
    else
        hs.application.launchOrFocusByBundleID(spoon.Emacs.emacs_bundle)
    end
end
local launch_terminal = function()
    if spoon.Emacs:app() == nil or not spoon.Emacs:switch_to_vterm_window() then
        hs.application.launchOrFocusByBundleID('com.googlecode.iterm2')
    end
end
local function launch_app_by_name (app_name)
    return function()
        hs.application.launchOrFocus(app_name)
    end
end
local function launch_app_by_id (app_id)
    return function()
        hs.application.launchOrFocusByBundleID(app_id)
    end
end

--- Countdown
local function countDownMins (mins)
    return function()
        spoon.CountDown:startFor(mins)
    end
end

--- Windows Map
local moveAndResize = function(method)
    return function()
        spoon.WinWin:moveAndResize(method)
    end
end
local moveToScreen = function(direction)
    return function()
        spoon.WinWin:moveToScreen(direction)
    end
end
local moveToNextSpace = function(follow)
    return function()
        spoon.Yabai:moveFocusedWindowToNextSpace(follow)
    end
end
local listWindowCurrent = function()
    spoon.Screen:selectWindowFromFocusedApp()
end
local listWindowAll = function()
    spoon.Screen:selectWindowFromAllWindows()
end

--- Space Map
local gotoNextSpace = function()
    spoon.Yabai:gotoNextSpaces()
end
local toggleMissionControl = function()
    hs.spaces.toggleMissionControl()
end
local toggleShowDesktop = function()
    hs.spaces.toggleMissionControl()
end

--- Recursive Binder

spoon.RecursiveBinder.escapeKeys = {
    { {},            'escape' },
    { { 'control' }, 'q' }
}
spoon.RecursiveBinder.helperFormat = {
    atScreenEdge = 2, -- Bottom edge (default value)
    textStyle = {     -- An hs.styledtext object
        font = {
            name = "Fira Code",
            size = 16
        }
    }
}

local sk = spoon.RecursiveBinder.singleKey
local keyMap = {
    --- Search with HSearch
    [sk('/', 'search+')] = {
        [sk('h', 'h-search')] = function() spoon.HSearch:toggleShow() end,
    },
    [sk('c', 'control+')] = {
        [sk('l', 'lock screen')] = function() hs.caffeinate.lockScreen() end
    },
    --- Launch Applications
    [sk('l', 'launch+')] = {
        [sk("space", "Emacs")] = launch_emacs,
        [sk("t", "terminal")] = launch_terminal,
        [sk("c", "chrome")] = launch_app_by_id("com.google.Chrome"),
        [sk("i", "intellij")] = launch_app_by_id("com.jetbrains.intellij"),
        [sk("m", "activity monitor")] = launch_app_by_id(
            "com.apple.ActivityMonitor"),
        [sk("d", "dash")] = launch_app_by_name("Dash"),
        [sk("w", "weChat")] = launch_app_by_name("WeChat"),
        [sk("s", "slack")] = launch_app_by_name("Slack"),
        [sk("f", "firefox")] = launch_app_by_name("Firefox"),
        [sk("o", "omniGraffle")] = launch_app_by_name("OmniGraffle"),
        [sk("q", "quip")] = launch_app_by_name("Quip"),
        [sk("h", "hammerspoon")] = launch_app_by_name("Hammerspoon"),
        [sk("a", "android studio")] = launch_app_by_name("Android Studio"),
        [sk("p", "pyCharm")] = launch_app_by_name("PyCharm"),
    },
    [sk('t', "time/schedule+")] = {
        [sk('c', 'count down')] = {
            [sk("p", "pause/resume")] = spoon.CountDown.pauseOrResume,
            [sk("1", "10 minutes")] = countDownMins(10),
            [sk("2", "20 minutes")] = countDownMins(20),
            [sk("3", "30 minutes")] = countDownMins(30),
            [sk("4", "45 minutes")] = countDownMins(45),
            [sk("6", "60 minutes")] = countDownMins(60),
        }
    },
    [sk('w', 'windows+')] = {
        [sk("h", "MoveAndResize to halfleft")] = moveAndResize("halfleft"),
        [sk("l", "MoveAndResize to halfright")] = moveAndResize("halfright"),
        [sk("k", "MoveAndResize to halfup")] = moveAndResize("halfup"),
        [sk("j", "MoveAndResize to halfdown")] = moveAndResize("halfdown"),
        -- to screen
        [sk("n", "Move to Next Screen")] = moveToScreen("next"),
        [sk("p", "Move to Previous Screen")] = moveToScreen("previous"),
        -- undo
        [sk("u", "Undo Window Manipulation")] = function() spoon.WinWin:undo() end,
        -- Triple Window
        [sk("a", "Triple Left")] = moveAndResize("tripleLeft"),
        [sk("s", "Triple Center")] = moveAndResize("centerHalfWidth"),
        [sk("d", "Triple Right")] = moveAndResize("tripleRight"),
        -- undo/redo
        [sk("f", "Fullscreen")] = moveAndResize("fullscreen"),
        [sk("m", "Maximize")] = moveAndResize("maximize"),
        -- Rotate
        [sk("r", "Rotate Visible Windows")] = function()
            spoon.Screen
                :rotateVisibleWindows()
        end,
        -- Other window
        [sk("o", "other window+")] = {
            [sk("f", "focus")] = function() spoon.Screen:focusOtherWindow() end,
            [sk("s", "swap")] = function() spoon.Screen:swapWithOther() end,
            [sk("o", "open")] = function() spoon.Screen:selectFromCoveredWindow() end
        },
        -- to Space
        [sk("S", "space+")] = {
            [sk("n", "Move to Next Space(not follow)")] = moveToNextSpace(false),
            [sk("f", "Move to Next Space(follow)")] = moveToNextSpace(true),
        },
        [sk("c", "choose+")] = {
            [sk("c", "Choose Window (Current App)")] = listWindowCurrent,
            [sk("a", "Choose Window (All App)")] = listWindowAll,
        },
    },
    [sk('s', 'space+')] = {
        [sk("n", "goto next spaces")] = gotoNextSpace,
        [sk("m", "toggle mission control")] = toggleMissionControl,
        [sk("d", "toggle show desktop")] = toggleShowDesktop,
    },
    --- Variable Toggles
    [sk('v', "variable on/off")] = {
        [sk('w', 'window toggle')] = {
            [sk("h", "highlight mode")] = function()
                spoon.Screen
                    :toggleWindowHighlightMode()
            end,
            [sk("i", "isolation mode (space)")] = function()
                spoon.Screen
                    :toggleCrossSpaces()
            end,
        }
    },
}

local hyper = { { "shift", "command", "control", "option" }, "1", }
spoon.RecursiveBinder.recursiveBind(keyMap, hyper)

-- Disable the alert key showing
hs.hotkey.alertDuration = 0

require("hs.ipc")

-- NOTE: Keep this the last.
if __my_path then
    hs.alert.show("Hammerspoon config loaded, path loaded.")
else
    hs.alert.show("Hammerspoon config loaded, load PATH failure")
end
