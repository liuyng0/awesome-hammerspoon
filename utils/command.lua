---@class utils.command
local obj = {}
obj.module = "utils.command"
obj.logger = hs.logger.new(obj.module, 'info')
obj._PATH_VARIABLE = nil

---@class CommandResult
---@field exitcode number
---@field stdout string
---@field stderr string

function obj.cwrap (func)
  return function()
    coroutine.wrap(func)()
  end
end

function obj.execTaskInShellAsync (cmdWithArgs, callback, withEnv)
  coroutine.wrap(function()
    obj.execTaskInShellSync(cmdWithArgs, callback, withEnv)
  end)()
end

local function append (source, ...)
  for k, v in ipairs({ ... }) do
    table.insert(source, v)
  end
  return source
end

-- execTaskInShellSync runs a command and waits for the output. All commands executed with a path environment variable that mirrors a logged in shell
-- @param cmdWithArgs - a string with the bash commands to runs
-- @param callback - a callback function to trigger once the command completes. Parrams for the callback fn should be exitCode, stdOut, and stdErr
-- @param withLogin - whether to run the command in a shell that has logged in resulting in common profile and env variable settings getting applied
obj.execTaskInShellSync = (function()
  local pathEnv = ""
  local fn = function(cmdWithArgs, callback, withLogin)
    if not coroutine.isyieldable() then
      obj.logger.i("this function cannot be invoked on the main Lua thread")
    end

    if callback == nil then
      callback = function(exitCode, stdOut, stdErr)
      end
    end

    local done = false
    local out = nil

    local cmd = {}
    if withLogin == true then
      append(cmd, "-l", "-i", "-c")
    else
      append(cmd, "-c")
    end

    if pathEnv ~= "" then
      table.insert(cmd, "export PATH=\"" .. pathEnv .. "\";" .. cmdWithArgs)
    else
      table.insert(cmd, cmdWithArgs)
    end

    local t = hs.task.new(os.getenv("SHELL"), function(exitCode, stdOut, stdErr)
      callback(exitCode, stdOut, stdErr)
      obj.logger.d("cmd: ", cmdWithArgs)
      obj.logger.d("out: ", stdOut)
      obj.logger.d("err: ", stdErr)
      out = stdOut
      done = true
    end, cmd)

    t:start()

    while done == false do
      coroutine.applicationYield()
    end

    return out
  end

  return function(cmdWithArgs, callback, withEnv)
    if pathEnv == "" then
      -- we are safe to call fn here because it should already be in a coroutine
      pathEnv = fn("echo -n $PATH", nil, true)
    end
    return fn(cmdWithArgs, callback, withEnv)
  end
end)()

function obj.getenv (name)
  local val = os.getenv(name)
  if val == nil then
    val = obj.execTaskInShellSync("echo -n $" .. name, nil, true)
  end
  if val == nil then
    val = ""
  end
  return val
end

return obj
