---@class utils.command
local obj = {}
obj.module = "utils.command"
obj.logger = hs.logger.new(obj.module)
obj._PATH_VARIABLE = nil

---@class CommandResult
---@field exitcode number
---@field stdout string
---@field stderr string

local function append (source, ...)
  for k, v in ipairs({ ... }) do
    table.insert(source, v)
  end
  return source
end

-- execTaskInShellSync runs a command and waits for the output. All commands executed with a path environment variable that mirrors a logged in shell
-- @param commandWithArgs string a string with the bash commands to runs
-- @param callback function a callback function to trigger once the command completes. Parrams for the callback fn should be exitCode, stdOut, and stdErr
-- @param pathEnv string if set will set to PATH
-- @return CommandResult
local execTaskInShellSync = (function()
  local fn = function(commandWithArgs, callback, pathEnv)
    if not coroutine.isyieldable() then
      obj.logger.i("this function cannot be invoked on the main Lua thread")
    end

    local cmd = {}
    if type(pathEnv) == "string" then
      append(cmd, "-c")
      table.insert(cmd, "export PATH=\"" .. pathEnv .. "\" && " .. commandWithArgs)
    else
      if type(pathEnv) == "boolean" and pathEnv then
        append(cmd, "-l", "-i", "-c")
      else
        append(cmd, "-c")
      end
      table.insert(cmd, commandWithArgs)
    end

    local done = false
    local t = hs.task.new(os.getenv("SHELL"), function(exitCode, stdOut, stdErr)
      if callback ~= nil then
        callback({
          exitcode = exitCode,
          stdout = stdOut,
          stderr = stdErr
        })
      end
      done = true
    end, cmd)

    t:start()

    while done == false do
      coroutine.yield()
    end
  end
  return function(cmdWithArgs, callback, withEnv)
    return fn(cmdWithArgs, callback, withEnv)
  end
end)()

function obj.init ()
  if not obj._PATH_VARIABLE then
    coroutine.wrap(function()
      execTaskInShellSync("echo -n $" .. "PATH", function(commandResult)
        obj._PATH_VARIABLE = commandResult.stdout
      end, true)
    end)()
  end
end

function obj.cwrap (func)
  return function()
    coroutine.wrap(func)()
  end
end

function obj.execTaskInShellAsync (cmdWithArgs, callback)
  coroutine.wrap(function()
    execTaskInShellSync(cmdWithArgs, callback, true)
  end)()
end

return obj
