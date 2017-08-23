-- Specify Spoons which will be loaded
hspoon_list = {
    "AClock",
    "BingDaily",
    -- "Calendar",
    "CircleClock",
    "ClipShow",
    "CountDown",
    "FnMate",
    "HCalendar",
    "HSaria2",
    "HSearch",
    -- "KSheet",
    "SpeedMenu",
    -- "TimeFlow",
    -- "UnsplashZ",
    "WinWin",
}

-- appM environment keybindings. Bundle `id` is prefered, but application `name` will be ok.
hsapp_list = {
    {key = 'a', name = 'Atom'},
    {key = 'c', id = 'com.google.Chrome'},
    {key = 'd', name = 'ShadowsocksX'},
    {key = 'e', name = 'Emacs'},
    {key = 'f', name = 'Finder'},
    {key = 'i', name = 'iTerm'},
    {key = 'k', name = 'KeyCastr'},
    {key = 'l', name = 'Sublime Text'},
    {key = 'm', name = 'MacVim'},
    {key = 'o', name = 'LibreOffice'},
    {key = 'p', name = 'mpv'},
    {key = 'r', name = 'VimR'},
    {key = 's', name = 'Safari'},
    {key = 't', name = 'Terminal'},
    {key = 'v', id = 'com.apple.ActivityMonitor'},
    {key = 'w', name = 'Mweb'},
    {key = 'y', id = 'com.apple.systempreferences'},
}

-- Modal supervisor keybinding, which can be used to temporarily disable ALL modal environments.
hsupervisor_keys = {{"alt", "shift", "ctrl"}, "Q"}

-- Reload Hammerspoon configuration
hsreload_keys = {{"alt", "shift", "ctrl"}, "R"}

-- Toggle help panel of this configuration.
hshelp_keys = {{"alt", "shift"}, "/"}

-- aria2 RPC host address
hsaria2_host = "http://localhost:6800/jsonrpc"
-- aria2 RPC host secret
hsaria2_secret = "token"

----------------------------------------------------------------------------------------------------
-- Those keybindings below could be disabled by setting to {"", ""} or {{}, ""}

-- Window hints keybinding: Focuse to any window you want
hswhints_keys = {"alt", "tab"}

-- appM environment keybinding: Application Launcher
-- hsappM_keys = {"alt", "A"}
hsappM_keys = {{"alt", "shift", "ctrl"}, "L"}

-- clipshowM environment keybinding: System clipboard reader
-- hsclipsM_keys = {"alt", "C"}
hsclipsM_keys = {"", ""}

-- Toggle the display of aria2 frontend
-- hsaria2_keys = {"alt", "D"}
hsaria2_keys = {"", ""}

-- Launch Hammerspoon Search
-- hsearch_keys = {"alt", "G"}
hsearch_keys = {"", ""}

-- Read Hammerspoon and Spoons API manual in default browser
-- hsman_keys = {"alt", "H"}
hsman_keys = {"", ""}

-- countdownM environment keybinding: Visual countdown
-- hscountdM_keys = {"alt", "I"}
hscountdM_keys = {"", ""}

-- Lock computer's screen
-- hslock_keys = {"alt", "L"}
hslock_keys = {"", ""}

-- resizeM environment keybinding: Windows manipulation
-- hsresizeM_keys = {"alt", "R"}
hsresizeM_keys = {"", ""}

-- cheatsheetM environment keybinding: Cheatsheet copycat
-- hscheats_keys = {"alt", "S"}
hscheats_keys = {"", ""}

-- Show digital clock above all windows
-- hsaclock_keys = {"alt", "T"}
hsaclock_keys = {"", ""}

-- Type the URL and title of the frontmost web page open in Google Chrome or Safari.
-- hstype_keys = {"alt", "V"}
hstype_keys = {"", ""}

-- Toggle Hammerspoon console
-- hsconsole_keys = {"alt", "Z"}
hsconsole_keys = {"", ""}
