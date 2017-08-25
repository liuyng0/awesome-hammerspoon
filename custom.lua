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
   {key = 'e', name = 'Emacs'},
   {key = 'i', name = 'iTerm'},
   {key = 'c', id = 'com.google.Chrome'},
   {key = 'f', name = 'Finder'},
   {key = 'd', name = 'ShadowsocksX'},
   {key = 'v', id = 'com.apple.ActivityMonitor'},
   {key = 'k', name = 'KeyCastr'},
   {key = 'y', id = 'com.apple.systempreferences'},
}

hyper1 = {"ctrl", "shift", "alt"}
hyper2 = "cmd"

-- Modal supervisor keybinding, which can be used to temporarily disable ALL modal environments.
hsupervisor_keys = {hyper1, "Q"}

-- Reload Hammerspoon configuration
hsreload_keys = {hyper1, "R"}

-- Toggle help panel of this configuration.
hshelp_keys = {hyper1, "/"}

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
hsappM_keys = {hyper2, "L"}

-- clipshowM environment keybinding: System clipboard reader
-- hsclipsM_keys = {"alt", "C"}
hsclipsM_keys = {hyper1, "C"}

-- Toggle the display of aria2 frontend
-- hsaria2_keys = {"alt", "D"}
hsaria2_keys = {"", ""}

-- Launch Hammerspoon Search
-- hsearch_keys = {"alt", "G"}
hsearch_keys = {hyper1, "S"}

-- Read Hammerspoon and Spoons API manual in default browser
-- hsman_keys = {"alt", "H"}
hsman_keys = {hyper1, "H"}

-- countdownM environment keybinding: Visual countdown
-- hscountdM_keys = {"alt", "I"}
hscountdM_keys = {hyper1, "I"}

-- Lock computer's screen
-- hslock_keys = {"alt", "L"}
hslock_keys = {hyper1, "."}

-- resizeM environment keybinding: Windows manipulation
-- hsresizeM_keys = {"alt", "R"}
hsresizeM_keys = {hyper2, "M"}

-- cheatsheetM environment keybinding: Cheatsheet copycat
-- hscheats_keys = {"alt", "S"}
hscheats_keys = {"", ""}

-- Show digital clock above all windows
-- hsaclock_keys = {"alt", "T"}
hsaclock_keys = {hyper1, "T"}

-- Type the URL and title of the frontmost web page open in Google Chrome or Safari.
-- hstype_keys = {"alt", "V"}
hstype_keys = {"", ""}

-- Toggle Hammerspoon console
-- hsconsole_keys = {"alt", "Z"}
hsconsole_keys = {hyper1, "C"}
