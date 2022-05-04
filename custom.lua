local logger = hs.logger.new("custom.lua", 'debug')
-- Specify Spoons which will be loaded
hspoon_list = {
    -- "AClock",
    -- "BingDaily",
    -- "Calendar",
    -- "CircleClock",
    -- "ClipShow",
    "CountDown",
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
    {key = 's', name = 'Slack'},
    {key = 'p', name = 'Preview'},
    {key = 'f', name = 'Firefox'},
    {key = 'o', name = 'OmniGraffle'},
    {key = 't', name = 'iTerm'},
    {key = 'q', name = "Quip"},
    -- {key = 'a', name = 'Android Studio'},
    -- {key = 'e', name = 'emacs'},
    -- {key = 'f', name = 'Finder'},
    -- {key = 's', name = 'Visual Studio Code'},
    -- {key = 'x', name = 'XMind'},
    -- {key = 'k', name = 'KeyCastr'},
    -- {key = 'o', name = 'Xcode'},
    -- {key = 'p', name = 'PDF Professional'},
    -- {key = 'g', name = 'Gapplin'},
}

if hs.fs.pathToAbsolute("/Applications/Android Studio.app") then
    table.insert(hsapp_list, {key = 'a', name = 'Android Studio'})
else
    table.insert(hsapp_list, {key = 'a', name = 'Amazon Chime'})
end

if hs.fs.pathToAbsolute("/Applications/Microsoft Outlook.app") then
    table.insert(hsapp_list, {key = 'm', name = 'Microsoft Outlook'})
else
    table.insert(hsapp_list, {key = 'm', name = 'Mail'})
end

if hs.fs.pathToAbsolute("/Applications/Kindle.app") then
    table.insert(hsapp_list, {key = 'k', name = 'Kindle'})
end


if hs.fs.pathToAbsolute("/Applications/IntelliJ IDEA.app") then
    table.insert(hsapp_list, {key = 'i', name = 'IntelliJ IDEA'})
elseif hs.fs.pathToAbsolute("/Applications/IntelliJ IDEA CE.app") then
    table.insert(hsapp_list, {key = "i", name = "IntelliJ IDEA CE"})
elseif hs.fs.pathToAbsolute("/Applications/IntelliJ IDEA 2021.1 CE EAP.app") then
    table.insert(hsapp_list, {key = "i", name = "IntelliJ IDEA 2021.1 CE EAP.app"})
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
hscountdM_keys = {hyper2, "N"}

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

hsexpose_keys = {hyper2, ";"}

hsstay_keys = {hyper2, "u"}
