---@class BindFunctions
local obj = {}
local sk = hs.loadSpoon("RecursiveBinder").singleKey
local function ctrl (singleKey, description)
  return { { "control" }, singleKey, description }
end

local function color (hex, alpha)
  return { hex = hex, alpha = alpha }
end
obj.defaultFont = "Fira Code"
obj.defaultHelperStyle = {
  atScreenEdge = 0, -- Bottom edge (default value)
  textStyle = {     -- An hs.styledtext object
    font = {
      name = obj.defaultFont,
      size = 12
    }
  }
}
obj.defaultStyledTextStle = {
  text = {
    font = {
      name = obj.defaultFont,
      size = 12
    },
    color = color("#525868", 1.0),
    paragraphStyle = {
      lineBreak = "truncateTail"
    }
  },
  subText = {
    font = {
      name = obj.defaultFont,
      size = 10
    },
    color = color("#3c4353", 1.0),
    paragraphStyle = {
      lineBreak = "truncateTail"
    }
  }
}

---@param names table the descriptions for the pass in modules
---@param ... table[] the modules
function obj.toggleDebugLogger (names, ...)
  local args = table.pack(...)
  local n = #args
  local loggers = {}
  for i = 1, n do
    if args[i] then
      for name, module in pairs(args[i]) do
        if module and module.logger then
          local pathName = names[i] .. "." .. name .. " log level: " .. module.logger.getLogLevel() .. "-> 4"
          loggers[pathName] = module.logger
        end
      end
    end
  end
  local function onSelected (choice)
    if choice == nil then return end
    local logger = loggers[choice.key]
    if logger then
      if logger.__origin_log_level ~= nil then
        local origin = logger.__origin_log_level
        logger.setLogLevel(origin)
        logger.__origin_log_level = nil
      else
        logger.__origin_log_level = logger.getLogLevel()
        --- set log level to 4
        logger.setLogLevel(4)
      end
    end
  end
  hs.chooser.new(onSelected)
      :choices((function()
        local tb = {}
        for name, _ in pairs(loggers) do
          table.insert(tb, {
            text = hs.styledtext.new(name, obj.defaultStyledTextStle),
            key = name
          })
        end
        return tb
      end)()
      ):show()
end

function obj.showDebug (msg)
  hs.alert.show(msg, obj.defaultHelperStyle)
end

function obj.makePadMap (curSpace)
  ---@type ScratchpadConfig
  local defaultGrid = "24:24:1:1:22:22"
  local defaultOpacity = 1.0
  local function pad (key, yabaiAppName, appName, grid, opacity)
    return {
      key = sk(key, yabaiAppName),
      appName = appName or yabaiAppName,
      yabaiAppName = yabaiAppName,
      grid = grid or defaultGrid,
      opacity = opacity or defaultOpacity
    }
  end
  local configuration = {
    spaceIndex = 5,
    pads = {
      pad('t', "iTerm2", "iTerm", nil, 0.9),
      pad('s', "Slack", "Slack"),
      pad('o', "OmniGraffle", "OmniGraffle"),
      pad('m', "Music", "Music"),
      pad('a', "Activity Monitor", "Activity Monitor"),
    }
  }
  S.yabai.configPads(configuration)
  local result = {
    [sk('h', "hideAll")] = S.yabai:hideAllScratchpads(),
  }
  ---@param p Scratchpad
  for _, p in pairs(configuration.pads) do
    result[p.key] = S.yabai:showScratchpad(p.yabaiAppName, curSpace)
  end
  return result
end

return obj
