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
-- @param onComplete function takes (exitcode, stdout, stderr) as input
-- @param pathEnv string if set will set to PATH
-- @return CommandResult
local execute = function(commandWithArgs, onComplete, pathEnv)
  local done = false
  local longRunningTask = coroutine.wrap(function(commandWithArgs, onComplete, pathEnv)
    if not coroutine.isyieldable() then
      obj.logger.i("this function cannot be invoked on the main Lua thread")
    end

    local cmd = {}
    if type(pathEnv) == "string" then
      append(cmd, "-c")
      table.insert(cmd, "export PATH=\"" .. pathEnv .. "\" && " .. commandWithArgs)
    else
      if type(pathEnv) == "boolean" and pathEnv then
        append(cmd, "-i", "-c")
      else
        append(cmd, "-c")
      end
      table.insert(cmd, commandWithArgs)
    end

    done = false
    local t = hs.task.new(os.getenv("SHELL"), function(_exitcode, _stdout, _stderr)
      print("_exitcode: " .. _exitcode)
      print("_stdout: " .. _stdout)
      print("_stderr: " .. _stderr)
      --- TODO: fix the code here, looks like it's not executed sequentially
      onComplete(_exitcode, _stdout, _stderr)
      done = true
    end, cmd):start()

    while t:isRunning() or done == false do
      coroutine.applicationYield()
    end

    t:terminate()
    longRunningTask = nil -- by referencing longTask within the coroutine function
    done = false
    -- it becomes an up-value so it won't be collected
  end)
  longRunningTask(commandWithArgs, onComplete, pathEnv)
end

function obj.init ()
  if not obj._PATH_VARIABLE then
    execute("echo -n $" .. "PATH", function(_, stdout, stderr)
      obj._PATH_VARIABLE = stdout
    end, true)
  end
end

function obj.execTaskInShellAsync (cmdWithArgs, callback)
  local result
  execute(cmdWithArgs, callback,
    obj._PATH_VARIABLE)
end

return obj
