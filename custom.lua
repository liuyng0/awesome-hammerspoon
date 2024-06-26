local logger = hs.logger.new("custom.lua", "debug")

hyper1 = { "ctrl", "shift", "alt" }
hyper2 = "cmd"
hyper3 = { "ctrl", "alt" }
hyper4 = { "ctrl", "cmd" }

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
    "Yabai"
}

-- appM environment keybindings. Bundle `id` is prefered, but application `name` will be ok.
hsapp_list = {
    {
        key = "space",
        func_name = "Emacs(Main)",
        func = function()
            if spoon.Emacs:app() ~= nil then
                spoon.Emacs:switch_to_main_window()
            else
                hs.application.launchOrFocusByBundleID(spoon.Emacs.emacs_bundle)
            end
        end
    },
    { key = "c",             id = "com.google.Chrome" },
    { key = "d",             name = "Dash" },
    { key = "w",             id = "com.apple.ActivityMonitor" },
    { key = { hyper2, "w" }, name = "WeChat" },
    { key = { "ctrl", "c" }, id = "com.apple.iCal" },
    { key = "s",             name = "Slack" },
    { key = "f",             name = "Firefox" },
    { key = "o",             name = "OmniGraffle" },
    {
        key = "t",
        func_name = "Emacs(Vterm)",
        func = function()
            if spoon.Emacs:app() == nil or not spoon.Emacs:switch_to_vterm_window() then
                hs.application.launchOrFocusByBundleID('com.googlecode.iterm2')
            end
        end
    },
    { key = "q",             name = "Quip" },
    { key = "h",             name = "Hammerspoon" },
    { key = ";",             name = "Xcode" },
    { key = "x",             name = "XMind" },
    { key = "b",             name = "iBooks" },
    { key = "n",             name = "GoodNotes" },
    { key = "z",             name = "zoom.us" },
    { key = { hyper2, "p" }, name = "Parallels Desktop" },
    { key = "p",             name = "PyCharm" }
    -- {key = 'a', name = 'Android Studio'},
    -- {key = 'f', name = 'Finder'},
    -- {key = 's', name = 'Visual Studio Code'},
    -- {key = 'k', name = 'KeyCastr'},
    -- {key = 'p', name = 'PDF Professional'},
    -- {key = 'g', name = 'Gapplin'},
}

if hs.fs.pathToAbsolute("/Applications/Android Studio.app") then
    table.insert(hsapp_list, { key = "a", name = "Android Studio" })
else
    table.insert(hsapp_list, { key = "a", name = "Amazon Chime" })
end

if hs.fs.pathToAbsolute("/Applications/Microsoft Outlook.app") then
    table.insert(hsapp_list, { key = "m", name = "Microsoft Outlook" })
else
    table.insert(hsapp_list, { key = "m", name = "Mail" })
end

if hs.fs.pathToAbsolute("/Applications/Amazon Kindle.app") then
    table.insert(hsapp_list, { key = "k", name = "Amazon Kindle" })
end

table.insert(hsapp_list, { key = "i", id = "com.jetbrains.intellij" })

-- Modal supervisor keybinding, which can be used to temporarily disable ALL modal environments.
hsupervisor_keys = { { "shift", "command", "control", "option" }, "1" }

-- Reload Hammerspoon configuration
hsreload_keys = { hyper1, "R" }

-- Toggle help panel of this configuration.
hshelp_keys = { hyper1, "/" }

-- aria2 RPC host address
hsaria2_host = "http://localhost:6800/jsonrpc"
-- aria2 RPC host secret
hsaria2_secret = "token"

----------------------------------------------------------------------------------------------------
-- Those keybindings below could be disabled by setting to {"", ""} or {{}, ""}

-- appM environment keybinding: Application Launcher
-- hsappM_keys = {"alt", "A"}
hsappM_keys = { hyper2, "L" }

-- clipshowM environment keybinding: System clipboard reader
-- hsclipsM_keys = {"alt", "C"}
-- hsclipsM_keys = {hyper1, "C"}

-- Toggle the display of aria2 frontend
-- hsaria2_keys = {"alt", "D"}
hsaria2_keys = { "", "" }

-- Translate
hstranslateM_keys = { hyper2, "O" }

-- Launch Hammerspoon Search
-- hsearch_keys = {"alt", "G"}
hsearch_keys = { hyper2, "I" }

-- Read Hammerspoon and Spoons API manual in default browser
-- hsman_keys = {"alt", "H"}
hsman_keys = { "", "" }

-- countdownM environment keybinding: Visual countdown
-- hscountdM_keys = {hyper2, "N"}
hscountdM_keys = { "", "" }

-- Lock computer's screen
-- hslock_keys = {"alt", "L"}
hslock_keys = { hyper3, "L" }

-- resizeM environment keybinding: Windows manipulation
-- hsresizeM_keys = {"alt", "R"}
hsresizeM_keys = { hyper2, "M" }

-- cheatsheetM environment keybinding: Cheatsheet copycat
-- hscheats_keys = {"alt", "S"}
hscheats_keys = { "", "" }

-- Show digital clock above all windows
-- hsaclock_keys = {"alt", "T"}
hsaclock_keys = { "", "" }

-- Type the URL and title of the frontmost web page open in Google Chrome or Safari.
-- hstype_keys = {"alt", "V"}
hstype_keys = { "", "" }

-- Toggle Hammerspoon console
-- hsconsole_keys = {"alt", "Z"}
hsconsole_keys = { "", "" }

hsscreenM_keys = { hyper2, "J" }

-- hsexpose_keys = {hyper2, ";"}

-- hsstay_keys = {hyper2, "u"}
hssession_keys = { hyper2, "u" }
