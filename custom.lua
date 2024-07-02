local logger = hs.logger.new("custom.lua", "debug")

hyper1 = { "ctrl", "shift", "alt" }
hyper2 = "cmd"
hyper3 = { "ctrl", "alt" }
hyper4 = { "ctrl", "cmd" }


-- Modal supervisor keybinding, which can be used to temporarily disable ALL modal environments.
-- hsupervisor_keys = { { "shift", "command", "control", "option" }, "1" }

-- Reload Hammerspoon configuration
hsreload_keys = { hyper1, "R" }

-- Toggle help panel of this configuration.
hshelp_keys = { hyper1, "/" }

-- Translate
hstranslateM_keys = { hyper2, "O" }


hsscreenM_keys = { hyper2, "J" }

-- hsexpose_keys = {hyper2, ";"}

-- hsstay_keys = {hyper2, "u"}
hssession_keys = { hyper2, "u" }
