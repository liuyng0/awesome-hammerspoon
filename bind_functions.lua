---@class BindFunctions
local obj = {}

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
          local pathName = names[i] .. "." .. name .. " log level: " .. module.logger.getLogLevel() .. "-> 2"
          loggers[pathName] = module.logger
        end
      end
    end
  end
  local function onSelected (choice)
    if choice == nil then return end
    local logger = loggers[choice]
    if logger then
      if logger.__origin_log_level then
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
            text = name
          })
        end
        return tb
      end)()
      ):show()
end

return obj
