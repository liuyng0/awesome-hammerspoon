---@class utils.debug
local obj = {}
local function color (hex, alpha)
  return { hex = hex, alpha = alpha }
end

obj.defaultFont = "Fira Code"
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

return obj
