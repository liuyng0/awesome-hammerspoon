local logger = hs.logger.new("init.lua", "debug")
--- Always can manual reload
local hsreload_keys = { { "ctrl", "shift", "option" }, "R" }
hs.hotkey.bind(
    hsreload_keys[1],
    hsreload_keys[2],
    "Reload Configuration",
    function()
        hs.reload()
    end
)

--- Global variables
G = {}

--- Utils
U = {
    ---@type Moses
    moses = require("utils/moses"),
    F = require("utils/F"),
    ---@type utils.command
    command = require("utils/command")
}

--- New extensions, actually are overriddens for the extensions
N = {
    ---@type next.expose
    expose = require("next/expose"),
    ---@type next.hints
    hints = require("next/hints")
}

local privatepath = hs.fs.pathToAbsolute(hs.configdir .. "/private")
if not privatepath then
    -- Create `~/.hammerspoon/private` directory if not exists.
    hs.fs.mkdir(hs.configdir .. "/private")
end

require("private-config-default")
privateconf = hs.fs.pathToAbsolute(hs.configdir .. "/private/config.lua")
if privateconf then
    -- Load awesomeconfig file if exists
    -- The private/config will override the default values
    require("private/config")
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

populatePathMaybe()

function executeWithPathPopulated (command)
    populatePathMaybe()
    if __my_path then
        return hs.execute("export PATH=" .. __my_path .. " && " .. command)
    end
end

-- load the spoon list
local hspoon_list = {
    "CountDown",
    "HSearch",
    "WinWin",
    "Screen",
    "Space",
    "Links",
    "SplitView",
    "AppBindings",
    "ChooserStyle",
    "Emacs",
    "Yabai",
    'RecursiveBinder'
}
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

S = {
    ---@type spoon.Yabai
    yabai = spoon.Yabai
}

local APP_GOODNOTES = "Goodnotes"
spoon.AppBindings:bind(
    APP_GOODNOTES,
    {
        { { "ctrl" }, "i", {}, "up" },   -- Scroll message window
        { { "ctrl" }, "k", {}, "down" }, -- Scroll message window
        { { "ctrl" }, "j", {}, "left" }, -- Scroll message window
        { { "ctrl" }, "l", {}, "right" } -- Scroll message window
    }
)

local function launch_app_by_name (appName, crossSpace)
    return function()
        if not crossSpace then
            hs.application.launchOrFocus(appName)
        else
            ---@type spoon.Yabai
            if not spoon.Yabai:switchToApp(appName) then
                hs.application.launchOrFocus(appName)
            end
        end
    end
end

local function launch_app_by_id (app_id)
    return function()
        hs.application.launchOrFocusByBundleID(app_id)
    end
end

--- Launch applications functions
local launch_emacs = function()
    -- launch_app_by_name("Emacs", true)()
    if spoon.Emacs:app() ~= nil then
        spoon.Emacs:switch_to_main_window()
    else
        hs.application.launchOrFocusByBundleID(spoon.Emacs.emacs_bundle)
    end
end

local launch_terminal = function()
    -- launch_app_by_name("iTerm2", true)()
    if spoon.Emacs:app() == nil or not spoon.Emacs:switch_to_vterm_window() then
        hs.application.launchOrFocusByBundleID('com.googlecode.iterm2')
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
    hs.spaces.toggleShowDesktop()
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
local ctrl = function(singleKey, description)
    return { { "control" }, singleKey, description }
end
--- yabai functions
local ybfn = (function()
    local focusSpace = function(spaceIndex)
        --- Yabai has problem to switch focus if the space is empty
        return function()
            hs.eventtap.keyStroke({ "control", "option", "shift" }, string.format("%s", spaceIndex))
        end
    end
    local moveW2S = function(spaceIndex, follow)
        return U.command.cwrap(function()
            S.yabai:moveWindowToSpace(nil, spaceIndex, follow)
        end)
    end
    return {
        focusSpace = focusSpace,
        moveW2S = moveW2S
    }
end)()

U.command.cwrap(function()
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
            [sk("s", "slack")] = launch_app_by_name("Slack"),
            [sk("o", "omniGraffle")] = launch_app_by_name("OmniGraffle"),
            [sk("q", "quip")] = launch_app_by_name("Quip"),
            [sk("h", "hammerspoon")] = launch_app_by_name("Hammerspoon"),
            [sk("a", "android studio")] = launch_app_by_name("Android Studio"),
            [sk("p", "pyCharm")] = launch_app_by_name("PyCharm"),
        },
        [sk('t', "time/schedule+")] = {
            [sk("p", "pause/resume")] = spoon.CountDown.pauseOrResume,
            [sk("1", "10 minutes")] = countDownMins(10),
            [sk("2", "20 minutes")] = countDownMins(20),
            [sk("3", "30 minutes")] = countDownMins(30),
            [sk("4", "45 minutes")] = countDownMins(45),
            [sk("6", "60 minutes")] = countDownMins(60),
        },
        [sk('w', 'windows+')] = {
            [sk("1", "move to & focus space 1-8")] = ybfn.moveW2S(1, true),
            [sk("2")] = ybfn.moveW2S(2, true),
            [sk("3")] = ybfn.moveW2S(3, true),
            [sk("4")] = ybfn.moveW2S(4, true),
            [sk("5")] = ybfn.moveW2S(5, true),
            [sk("6")] = ybfn.moveW2S(6, true),
            [sk("7")] = ybfn.moveW2S(7, true),
            [sk("8")] = ybfn.moveW2S(8, true),
            [ctrl("1", "move to space 1-8")] = ybfn.moveW2S(1, true),
            [ctrl("2")] = ybfn.moveW2S(2, true),
            [ctrl("3")] = ybfn.moveW2S(3, true),
            [ctrl("4")] = ybfn.moveW2S(4, true),
            [ctrl("5")] = ybfn.moveW2S(5, true),
            [ctrl("6")] = ybfn.moveW2S(6, true),
            [ctrl("7")] = ybfn.moveW2S(7, true),
            [ctrl("8")] = ybfn.moveW2S(8, true),

            [sk("h", "Halfleft")] = moveAndResize("halfleft"),
            [sk("l", "Halfright")] = moveAndResize("halfright"),
            [sk("k", "Halfup")] = moveAndResize("halfup"),
            [sk("j", "Halfdown")] = moveAndResize("halfdown"),
            -- to screen
            [sk("n", "Next Screen")] = moveToScreen("next"),
            [sk("p", "Previous Screen")] = moveToScreen("previous"),
            -- undo
            [sk("u", "Undo")] = function() spoon.WinWin:undo() end,
            -- Triple Window
            [sk("a", "3-Left")] = moveAndResize("tripleLeft"),
            [sk("s", "3-Center")] = moveAndResize("centerHalfWidth"),
            [sk("d", "3-Right")] = moveAndResize("tripleRight"),
            -- undo/redo
            [sk("f", "Fullscreen")] = moveAndResize("fullscreen"),
            [sk("m", "Maximize")] = moveAndResize("maximize"),
            -- Rotate
            [sk("r", "Rotate")] = function()
                spoon.Screen
                    :rotateVisibleWindows()
            end,
            -- Other window
            [sk("O", "open")] = function() spoon.Screen:selectFromCoveredWindow() end,
            [sk("o", "other window+")] = function() spoon.Screen:focusOtherWindow() end,
            [{ { "control" }, "o", "swap-o" }] = function() spoon.Screen:swapWithOther() end,

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
        --- Spaces
        [sk("1", "focus space (1-8)")] = ybfn.focusSpace(1),
        [sk("2", nil)] = ybfn.focusSpace(2),
        [sk("3")] = ybfn.focusSpace(3),
        [sk("4")] = ybfn.focusSpace(4),
        [sk("5")] = ybfn.focusSpace(5),
        [sk("6")] = ybfn.focusSpace(6),
        [sk("7")] = ybfn.focusSpace(7),
        [sk("8")] = ybfn.focusSpace(8),

        --- Exposes
        [sk('e', 'expose+')] = (function()
            local exposeAll = N.expose.new({ "Emacs", "Chrome", "Intellij", "iTerm2" },
                { showThumbnails = true })
            exposeAll:setCallback(
            ---@param win hs.window
                function(win)
                    logger.w("focus on window: " .. win:id())
                    win:focus()
                end)
            return {
                [sk("f", "focus")] = function() exposeAll:toggleShow() end
            }
        end)(),
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
        --- Hammerspoon
        [sk('h', "hammerspoon")] = {
            [sk("c", "toggle console")] = function()
                hs.toggleConsole()
            end
        },
        [sk('y', "yabai+")] = {
            [sk("c", "current")] = U.command.cwrap(
                function()
                    local info = S.yabai:focusedWSD()
                    hs.alert.show(hs.inspect(info))
                end
            )
        }
    }
    local hyper = { { "shift", "command", "control", "option" }, "1", }
    spoon.RecursiveBinder.recursiveBind(keyMap, hyper)
end)()

-- Disable the alert key showing
hs.hotkey.alertDuration = 0

local function autoReload (files)
    local function pathInfo (path)
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

    local function containsNotIgnored (files)
        local command = "cd ~/.hammerspoon && git check-ignore " ..
            table.concat(files, " ") .. " | wc -l"
        local output, rc = hs.execute(command)
        local result = rc and tonumber(output) < #files
        if result then
            logger.d("At least one file changed and not git ignored: " ..
                hs.inspect(files))
        else
            logger.d("All ignored: " .. hs.inspect(files))
        end
        return result
    end

    local updatedLuaFiles = {}
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" and pathInfo(file)["basename"]:sub(0, 2) ~= ".#" then
            table.insert(updatedLuaFiles, file)
        end
    end
    if #updatedLuaFiles > 0 and containsNotIgnored(updatedLuaFiles) then
        G.autoReloadWatcher:stop()
        hs.reload()
    end
end
-- Watch the configuration change.
G.autoReloadWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", autoReload)
G.autoReloadWatcher:start()


require("hs.ipc")

-- NOTE: Keep this the last.
if __my_path then
    hs.alert.show("Hammerspoon config loaded, path loaded.")
else
    hs.alert.show("Hammerspoon config loaded, load PATH failure")
end
