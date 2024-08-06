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
---@type spoon.Utils
U = hs.loadSpoon("Utils")

local sk, ctrl, shift, ctrlshift = U.sk, U.ctrl, U.shift, U.ctrlshift

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
    ---@type spoon.WindowManager
    wm = hs.loadSpoon("WindowManager"),
    ---@type spoon.RecursiveBinder
    recursivebinder = hs.loadSpoon("RecursiveBinder"),
    ---@type spoon.BingDaily
    bingdaily = hs.loadSpoon("BingDaily")
}

local APP_GOODNOTES = "Goodnotes"
S.appbindings:bind(
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


---@type BindFunctions

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
        -- [sk("o", "omniGraffle")] = S.wm.launchAppFunc("OmniGraffle"),
        -- [sk("t", "terminal")] = S.wm.launchAppFunc("iTerm2"),
        -- [sk("s", "slack")] = S.wm.launchAppFunc("Slack"),
        --- end
        [sk("space", "Emacs")] = S.wm.launchAppFunc("Emacs"),
        [sk("c", "chrome")] = S.wm.launchAppFunc("Google Chrome"),
        [sk("t", "iTerm")] = S.wm.launchAppFunc("iTerm2"),
        [sk("s", "slack")] = S.wm.launchAppFunc("Slack"),
        [sk("i", "intellij")] = S.wm.launchAppFunc("IntelliJ IDEA"),
        [sk("m", "activity monitor")] = S.wm.launchAppFunc(
            "Activity Monitor"),
        [sk("d", "dash")] = S.wm.launchAppFunc("Dash"),
        [sk("h", "hammerspoon")] = S.wm.launchAppFunc("Hammerspoon"),
        [sk("a", "android studio")] = S.wm.launchAppFunc("Android Studio"),
        [sk("p", "pyCharm")] = S.wm.launchAppFunc("PyCharm"),
        --- Unused
        --- [sk("q", "quip")] = S.wm.launchAppFunc("Quip"),
    },
    [sk('t', "time/schedule+")] = {
        [sk("p", "pause/resume")] = S.countdown.pauseOrResume,
        [sk("1", "10 minutes")] = countDownMins(10),
        [sk("2", "20 minutes")] = countDownMins(20),
        [sk("3", "30 minutes")] = countDownMins(30),
        [sk("4", "45 minutes")] = countDownMins(45),
        [sk("6", "60 minutes")] = countDownMins(60),
    },
    [sk('r', "resize+")] = S.wm.resizeWindowMapping(),
    [sk('w', 'windows+')] = {
        [sk("1", "move to & focus space 1-8")] = S.wm.moveW2SFunc(1, true),
        [sk("2")] = S.wm.moveW2SFunc(2, true),
        [sk("3")] = S.wm.moveW2SFunc(3, true),
        [sk("4")] = S.wm.moveW2SFunc(4, true),
        [sk("5")] = S.wm.moveW2SFunc(5, true),
        [sk("6")] = S.wm.moveW2SFunc(6, true),
        [sk("7")] = S.wm.moveW2SFunc(7, true),
        [sk("8")] = S.wm.moveW2SFunc(8, true),
        [shift("1", "move to space 1-8")] = S.wm.moveW2SFunc(1, false),
        [shift("2")] = S.wm.moveW2SFunc(2, false),
        [shift("3")] = S.wm.moveW2SFunc(3, false),
        [shift("4")] = S.wm.moveW2SFunc(4, false),
        [shift("5")] = S.wm.moveW2SFunc(5, false),
        [shift("6")] = S.wm.moveW2SFunc(6, false),
        [shift("7")] = S.wm.moveW2SFunc(7, false),
        [shift("8")] = S.wm.moveW2SFunc(8, false),
        -- Other window
        [sk("o", "other window")] = S.wm.focusOtherWindowFunc(),        -- Swap with other window
        [sk("s", "swap-o")] = S.wm.swapWithOtherWindowFunc(),
        [shift("s", "stack(cs)")] = S.wm.stackAppWindowsFunc(true),
        [ctrlshift("s", "stack(all)")] = S.wm.stackAppWindowsFunc(false),
        [ctrl("s", "re-spaces")] = S.wm.reArrangeSpacesFunc(),
        [sk("c", "choose+")] = {
            [sk("c", "Choose Window (Current App)")] = listWindowCurrent,
            [sk("a", "Choose Window (All App)")] = listWindowAll,
        },
        [sk("f", "fullscreen")] = S.wm.toggleZoomFullScreenFunc(),
        [shift("f", "float")] = S.wm.toggleFloatFunc(),
        [ctrl("h", "hideOthers")] = S.wm.moveOthersToHiddenSpaceFunc(),
        [sk("h", "select & hide[R]")] = S.wm.selectVisibleWindowToHideFunc(),
        [sk("p", "pick windows")] = S.wm.pickWindowsFunc(),

        [ctrl("r", "restart")] = S.wm.startOrRestartServiceFunc(),
        [ctrl("x", "stop")] = S.wm.stopServiceFunc(),
        [ctrl("i", "info")] = S.wm.showInfoFunc(),
        [ctrl("b", "restart sketchybar")] = S.wm.restartSketchybar(),
    },
    [shift("s", "switch spaces")] = S.wm.swapVisibleSpacesFunc(),
    [sk("n", "next screen")] = S.wm.focusNextScreenFunc(),
    [sk("k", "ow - vs,vw")] = S.wm.focusVisibleWindowFunc(),
    [sk("i", "ow - cs,vw")] = S.wm.focusVisibleWindowFunc(true),
    -- Other window
    [sk("o", "ow - vs,all")] = S.wm.focusOtherWindowFunc(),
    -- Other window (current app)
    [sk("j", "ow - vs,app")] = S.wm.focusOtherWindowFunc(true),
    -- Other window (current space)
    [sk("u", "ow - cs,all")] = S.wm.focusOtherWindowFunc(false, true),
    -- Swap with other window
    [{ { "control" }, "s", "ow - swap" }] = S.wm.swapWithOtherWindowFunc(),
    [ctrl("l", "layout")] = S.wm.nextLayoutFunc(),

    [sk('s', 'space+')] = {
        [sk("m", "mission control i/o")] = toggleMissionControl,
        [sk("d", "show desktop i/o")] = toggleShowDesktop,
        [sk("b", "bing daily")] = S.bingdaily.bingRequest,
        [sk("1", "focus space (1-8) (AD)")] = S.wm.selectNthSpacesInAllDisplaysFunc(1),
        [sk("2", nil)] = S.wm.selectNthSpacesInAllDisplaysFunc(2),
        [sk("3")] = S.wm.selectNthSpacesInAllDisplaysFunc(3),
        [sk("4")] = S.wm.selectNthSpacesInAllDisplaysFunc(4),
        [sk("5")] = S.wm.selectNthSpacesInAllDisplaysFunc(5),
        [sk("6")] = S.wm.selectNthSpacesInAllDisplaysFunc(6),
        [sk("7")] = S.wm.selectNthSpacesInAllDisplaysFunc(7),
        [sk("8")] = S.wm.selectNthSpacesInAllDisplaysFunc(8),
    },
    --- Spaces
    [sk("1", "focus space (1-8)")] = S.wm.focusSpaceFunc(1),
    [sk("2", nil)] = S.wm.focusSpaceFunc(2),
    [sk("3")] = S.wm.focusSpaceFunc(3),
    [sk("4")] = S.wm.focusSpaceFunc(4),
    [sk("5")] = S.wm.focusSpaceFunc(5),
    [sk("6")] = S.wm.focusSpaceFunc(6),
    [sk("7")] = S.wm.focusSpaceFunc(7),
    [sk("8")] = S.wm.focusSpaceFunc(8),

    --- Exposes
    [sk('e', 'expose')] = (function()
        local exposeAll = U.expose.new(nil,
            {showThumbnails=false, otherSpacesStripWidth=0.35, nonVisibleStripWidth=0.25, textSize = 30,
             fontName="Fira Code"})
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
            U.debug.toggleDebugLogger({ "G", "S", "N", "U" },
                G, S, N, U)
        end
    },
    --- Scratch pad
    [ctrl('h', 'hide pads')] = S.wm.hideAllScratchpadsFunc(),
    [sk('p', "pad+(next space)")] = S.wm.makePadMapFunc(false),
    [ctrl('p', "pad+(this space)")] = S.wm.makePadMapFunc(true),
}
local hyper = { { "shift", "command", "control", "option" }, "1", }
S.recursivebinder.recursiveBind(keyMap, hyper)

--- Bind the space keys separately
G.bindSpaceKeys = function()
    local count = 1
    while count <= 8 do
        local countStr = string.format("%s", count)
        hs.hotkey.bind("ctrl", countStr, "focus space " .. countStr, S.wm.focusSpaceFunc(count))
        count = count + 1
    end
end
G.bindSpaceKeys()

--- Disable the alert key showing
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
