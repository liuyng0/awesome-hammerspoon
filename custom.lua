-- Specify Spoons which will be loaded
hspoon_list = {
    -- "AClock",
    -- "BingDaily",
    -- "Calendar",
    -- "CircleClock",
    -- "ClipShow",
    -- "CountDown",
    -- "FnMate",
    -- "HCalendar",
    -- "HSaria2",
    "HSearch",
    -- "KSheet",
    -- "SpeedMenu",
    -- "TimeFlow",
    -- "UnsplashZ",
    "WinWin",
    'Screen',
    'Links',
    'Hints',
    'PopupTranslateSelection',
}

-- appM environment keybindings. Bundle `id` is prefered, but application `name` will be ok.
hsapp_list = {
    {key = 'space', name = 'Emacs'},
    {key = 'c', id = 'com.google.Chrome'},
    {key = 'd', name = 'Dash'},
    {key = 'w', id = 'com.apple.ActivityMonitor'},
    {key = 'p', id = 'com.apple.systempreferences'},
    {key = 'f', name = 'Firefox'},
    {key = 'a', name = 'Amazon Chime'},
    {key = 'o', name = 'OmniGraffle'},
    -- {key = 'a', name = 'Android Studio'},
    -- {key = 'e', name = 'emacs'},
    -- {key = 't', name = 'iTerm'},
    -- {key = 'f', name = 'Finder'},
    -- {key = 's', name = 'Visual Studio Code'},
    -- {key = 'x', name = 'XMind'},
    -- {key = 'k', name = 'KeyCastr'},
    -- {key = 'v', name = 'Preview'},
    -- {key = 'o', name = 'Xcode'},
    -- {key = 'p', name = 'PDF Professional'},
    -- {key = 'g', name = 'Gapplin'},
}

if hs.fs.pathToAbsolute("/Applications/Microsoft Outlook.appm") then
    table.insert(hsapp_list, {key = 'm', name = 'Microsoft Outlook'})
else
    table.insert(hsapp_list, {key = 'm', name = 'Mail'})
end

if hs.fs.pathToAbsolute("/Applications/IntelliJ IDEA.app") then
    table.insert(hsapp_list, {key = 'i', name = 'IntelliJ IDEA'})
else
    table.insert(hsapp_list, {key = "i", name = "IntelliJ IDEA CE"})
end

hyper1 = {"ctrl", "shift", "alt"}
hyper2 = "cmd"
hyper3 = {"ctrl", "alt"}
hyper4 = {"ctrl", "cmd"}

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
-- hswhints_keys = {hyper2, ";"}
hswhints_keys = {"", ""}

-- appM environment keybinding: Application Launcher
-- hsappM_keys = {"alt", "A"}
hsappM_keys = {hyper2, "L"}

-- clipshowM environment keybinding: System clipboard reader
-- hsclipsM_keys = {"alt", "C"}
-- hsclipsM_keys = {hyper1, "C"}

-- Toggle the display of aria2 frontend
-- hsaria2_keys = {"alt", "D"}
hsaria2_keys = {"", ""}

-- Translate
hstranslateM_keys = {hyper2, "O"}

-- Launch Hammerspoon Search
-- hsearch_keys = {"alt", "G"}
hsearch_keys = {hyper2, "I"}

-- Read Hammerspoon and Spoons API manual in default browser
-- hsman_keys = {"alt", "H"}
hsman_keys = {"", ""}

-- countdownM environment keybinding: Visual countdown
-- hscountdM_keys = {"alt", "I"}
-- hscountdM_keys = {hyper1, "I"}

-- Lock computer's screen
-- hslock_keys = {"alt", "L"}
hslock_keys = {hyper3, "L"}

-- resizeM environment keybinding: Windows manipulation
-- hsresizeM_keys = {"alt", "R"}
hsresizeM_keys = {hyper2, "M"}

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

hsscreenM_keys = {hyper2, "J"}
