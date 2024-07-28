local logger = hs.logger.new("init.lua", "debug")
--- Always can manual reload
local hsreload_keys = { { "ctrl", "shift", "option" }, "R" }
logger.i("Bind reload key to " .. hs.inspect(hsreload_keys))
hs.hotkey.bind(
    hsreload_keys[1],
    hsreload_keys[2],
    "Reload Configuration",
    function()
        hs.reload()
    end
)

--- Setup libraries
logger.i("Setup libraries")
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

logger.i("Setup private path")
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

logger.i("Load Spoons")
-- load the spoon list
---@diagnostic disable
S = {
    ---@type spoon.CountDown
    countdown = hs.loadSpoon("CountDown"),
    ---@type spoon.HSearch
    hsearch = hs.loadSpoon("HSearch"),
    ---@type spoon.Links
    links = hs.loadSpoon("Links"),
    ---@type spoon.AppBindings
    appbindings = hs.loadSpoon("AppBindings"),
    ---@type spoon.ChooserStyle
    chooserstyle = hs.loadSpoon("ChooserStyle"),
    ---@type spoon.Emacs
    emacs = hs.loadSpoon("Emacs"),
    ---@type spoon.Yabai
    yabai = hs.loadSpoon("Yabai"),
    ---@type spoon.RecursiveBinder
    recursivebinder = hs.loadSpoon("RecursiveBinder"),
    ---@type spoon.BingDaily
    bingdaily = hs.loadSpoon("BingDaily")
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

--- Countdown
local function countDownMins (mins)
    return function()
        S.countdown:startFor(mins)
    end
end

local moveToNextSpace = function(follow)
    return function()
        S.yabai:moveFocusedWindowToNextSpace(follow)
    end
end
--- Space Map
local gotoNextSpace = function()
    S.yabai:gotoNextSpaces()
end
local toggleMissionControl = function()
    hs.spaces.toggleMissionControl()
end
local toggleShowDesktop = function()
    hs.spaces.toggleShowDesktop()
end

--- Recursive Binder

S.recursivebinder.escapeKeys = {
    { {},            'escape' },
    { { 'control' }, 'q' }
}
S.recursivebinder.helperFormat = {
    atScreenEdge = 2, -- Bottom edge (default value)
    textStyle = {     -- An hs.styledtext object
        font = {
            name = "Fira Code",
            size = 14
        }
    }
}

local sk = S.recursivebinder.singleKey
local ctrl = function(singleKey, description)
    return { { "control" }, singleKey, description }
end
local cwrap = U.command.cwrap

---@type BindFunctions
local bfn = require("bind_functions")

--- Make console not always on top
hs.consoleOnTop(false)

local keyMap = {
    --- Search with HSearch
    [sk('/', 'hsearch')] = function() S.hsearch:toggleShow() end,
    [sk('c', 'control+')] = {
        [sk('l', 'lock screen')] = function() hs.caffeinate.lockScreen() end,
        [sk("c", "toggle console")] = function() hs.toggleConsole() end,
    },
    --- Launch Applications
    --- NOTE: don't try to launch by id
    --- The name get from bundle id might not much the name from yabai
    [sk('l', 'launch+')] = {
        --- begin
        --- NOTE: define in the scratchpad
        -- [sk("o", "omniGraffle")] = S.yabai:launchAppFunc("OmniGraffle"),
        -- [sk("t", "terminal")] = S.yabai:launchAppFunc("iTerm2"),
        -- [sk("s", "slack")] = S.yabai:launchAppFunc("Slack"),
        --- end
        [sk("space", "Emacs")] = S.yabai:launchAppFunc("Emacs"),
        [sk("c", "chrome")] = S.yabai:launchAppFunc("Google Chrome"),
        [sk("i", "intellij")] = S.yabai:launchAppFunc("IntelliJ IDEA"),
        [sk("m", "activity monitor")] = S.yabai:launchAppFunc(
            "Activity Monitor"),
        [sk("d", "dash")] = S.yabai:launchAppFunc("Dash"),
        [sk("h", "hammerspoon")] = S.yabai:launchAppFunc("Hammerspoon"),
        [sk("a", "android studio")] = S.yabai:launchAppFunc("Android Studio"),
        [sk("p", "pyCharm")] = S.yabai:launchAppFunc("PyCharm"),
        --- Unused
        --- [sk("q", "quip")] = S.yabai:launchAppFunc("Quip"),
    },
    [sk('t', "time/schedule+")] = {
        [sk("p", "pause/resume")] = S.countdown.pauseOrResume,
        [sk("1", "10 minutes")] = countDownMins(10),
        [sk("2", "20 minutes")] = countDownMins(20),
        [sk("3", "30 minutes")] = countDownMins(30),
        [sk("4", "45 minutes")] = countDownMins(45),
        [sk("6", "60 minutes")] = countDownMins(60),
    },
    [sk('w', 'windows+')] = {
        [sk("1", "move to & focus space 1-8")] = S.yabai.moveW2SFunc(1, true),
        [sk("2")] = S.yabai.moveW2SFunc(2, true),
        [sk("3")] = S.yabai.moveW2SFunc(3, true),
        [sk("4")] = S.yabai.moveW2SFunc(4, true),
        [sk("5")] = S.yabai.moveW2SFunc(5, true),
        [sk("6")] = S.yabai.moveW2SFunc(6, true),
        [sk("7")] = S.yabai.moveW2SFunc(7, true),
        [sk("8")] = S.yabai.moveW2SFunc(8, true),
        [ctrl("1", "move to space 1-8")] = S.yabai.moveW2SFunc(1, false),
        [ctrl("2")] = S.yabai.moveW2SFunc(2, false),
        [ctrl("3")] = S.yabai.moveW2SFunc(3, false),
        [ctrl("4")] = S.yabai.moveW2SFunc(4, false),
        [ctrl("5")] = S.yabai.moveW2SFunc(5, false),
        [ctrl("6")] = S.yabai.moveW2SFunc(6, false),
        [ctrl("7")] = S.yabai.moveW2SFunc(7, false),
        [ctrl("8")] = S.yabai.moveW2SFunc(8, false),

        -- Other window
        [sk("o", "other window")] = cwrap(
            function() S.yabai:focusOtherWindow() end
        ),
        -- Swap with other window
        [{ { "control" }, "s", "swap-o" }] = cwrap(function() S.yabai:swapWithOtherWindow() end),
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
    [sk("S", "switch spaces")] = cwrap(function() S.yabai:swapVisibleSpaces() end),
    [sk("n", "next screen")] = cwrap(function() S.yabai:focusNextScreen() end),
    [sk("k", "other window(visible)")] = cwrap(function() S.yabai:focusVisibleWindow() end),
    [sk("i", "other window(visible,cs)")] = cwrap(function() S.yabai:focusVisibleWindow(true) end),
    -- Other window
    [sk("o", "other window")] = cwrap(
        function() S.yabai:focusOtherWindow() end
    ),
    -- Other window (current app)
    [sk("j", "other window(app)")] = cwrap(
        function() S.yabai:focusOtherWindow(true) end
    ),
    -- Other window (current space)
    [sk("u", "other window(space)")] = cwrap(
        function() S.yabai:focusOtherWindow(false, true) end
    ),

    -- Toggle Float window
    -- TODO: currently this causing issues - windows under the floating window cannot be raised and focused
    -- [sk("f", "toggle float window")] = S.yabai:bindFunction({
    --     "-m window --toggle float",
    --     "-m window --grid 24:24:1:1:22:22",
    -- }),

    -- Swap with other window
    [{ { "control" }, "s", "swap-o" }] = cwrap(function() S.yabai:swapWithOtherWindow() end),
    [ctrl("l", "layout")] = cwrap(
        (function()
            local layouts = { [1] = "bsp", [2] = "stack" }
            local now = 1
            return function()
                local next = now + 1
                if next == 3 then next = 1 end
                S.yabai:switchLayout(layouts[next])
                now = next
            end
        end)()
    ),

    [sk('s', 'space+')] = {
        [sk("n", "next space(s)")] = gotoNextSpace,
        [sk("m", "mission control i/o")] = toggleMissionControl,
        [sk("d", "show desktop i/o")] = toggleShowDesktop,
        [sk("b", "bing daily")] = S.bingdaily.bingRequest
    },
    --- Spaces
    [sk("1", "focus space (1-8)")] = S.yabai.focusSpaceFunc(1),
    [sk("2", nil)] = S.yabai.focusSpaceFunc(2),
    [sk("3")] = S.yabai.focusSpaceFunc(3),
    [sk("4")] = S.yabai.focusSpaceFunc(4),
    [sk("5")] = S.yabai.focusSpaceFunc(5),
    [sk("6")] = S.yabai.focusSpaceFunc(6),
    [sk("7")] = S.yabai.focusSpaceFunc(7),
    [sk("8")] = S.yabai.focusSpaceFunc(8),

    --- Exposes
    [sk('e', 'expose')] = (function()
        local exposeAll = N.expose.new{ "Emacs", "Chrome", "Intellij", "iTerm2" }
        exposeAll:setCallback(
        ---@param win hs.window
            function(win)
                logger.w("focus on window: " .. win:id())
                win:focus()
            end)
        return function()
            logger.w("Start expose")
            exposeAll:toggleShow()
        end
    end)(),
    --- Variable Toggles
    [sk('v', "variable on/off")] = {
       [sk('d', 'toggle debug')] = function()
            bfn.toggleDebugLogger({ "G", "S", "N", "U" },
                G, S, N, U)
        end
    },
    --- Yabai
    [sk('y', "yabai+")] = {
        [ctrl("r", "restart")] = S.yabai:restartYabaiService(),
        [ctrl("x", "stop")] = S.yabai:stopYabaiService(),
        [sk("s", "stack")] = {
            [sk('a', 'application')] = cwrap(function() S.yabai:stackAppWindows() end),
        },
        [sk("i", "info")] = cwrap(
            function()
                local info = S.yabai:focusedWSD()
                bfn.showDebug(hs.inspect(info))
            end
        ),
        [sk("r", "re-spaces")] = cwrap(
            function()
                S.yabai:reArrangeSpaces()
            end
        ),
    },
    --- Scratch pad
    [ctrl('h', 'hide pads')] = S.yabai:hideAllScratchpads(),
    [sk('p', "pad+(next space)")] = bfn.makePadMap(false),
    [ctrl('p', "pad+(this space)")] = bfn.makePadMap(true),
}
local hyper = { { "shift", "command", "control", "option" }, "1", }
spoon.RecursiveBinder.recursiveBind(keyMap, hyper)

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
hs.alert.show("Hammerspoon config loaded, path loaded.")
