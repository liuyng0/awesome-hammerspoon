---@class utils.command
local obj = {}
obj.logger = hs.logger.new("U.command")
obj._PATH_VARIABLE = nil

---@class CommandResult
---@field exitcode number
---@field stdout string
---@field stderr string

function obj.cwrap (func, ...)
  local x = {...}
  return function()
    coroutine.wrap(func)(table.unpack(x))
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

--- execTaskInShellSync runs a command and waits for the output. All commands executed with a path environment variable that mirrors a logged in shell
--- @param cmdWithArgs - a string with the bash commands to runs
--- @param callback - a callback function to trigger once the command completes. Parrams for the callback fn should be exitCode, stdOut, and stdErr
--- @param withLogin - whether to run the command in a shell that has logged in resulting in common profile and env variable settings getting applied
--- @type fun(cmdWithArgs: string, callback: function?, withLogin: Current)
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
    local out, ec, error

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
      out = stdOut
      ec = exitCode
      err = stdErr
      done = true
    end, cmd)

    t:start()

    while done == false do
      coroutine.applicationYield()
    end

    return out, ec, err
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

function obj.execSync(fmt, ...)
  local cmd = string.format(fmt, ...)
  obj.logger.i("run command: [" .. cmd .. "]")
  local output, ec, stderr = obj.execTaskInShellSync(cmd, nil, false)
  if ec and ec ~= 0 then
      obj.logger.e(string.format("Failed command command: %s, error: %s", cmd, stderr))
      return ""
  end
  return output
end

function obj.cwrapExec (fmt, ...)
   local x = table.unpack({...})
   return obj.cwrap(function()
         obj.execSync(fmt, x)
   end)
end

return obj
