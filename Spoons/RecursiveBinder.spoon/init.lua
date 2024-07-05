--- === RecursiveBinder ===
---
--- A spoon that let you bind sequential bindings.
--- It also (optionally) shows a bar about current keys bindings.
---
--- [Click to download](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/RecursiveBinder.spoon.zip)

local obj = {}

local eventtap = require("hs.eventtap")
local color = require("hs.drawing.color")
local F = U.F
local M = U.moses

obj.__index = obj

-- Metadata
obj.name = "RecursiveBinder"
obj.version = "0.7"
obj.author = "Yuan Fu <casouri@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- RecursiveBinder.escapeKey
--- Variable
--- key to abort, default to {keyNone, 'escape'}
obj.escapeKeys = { { { "" }, 'escape' } }

--- RecursiveBinder.helperEntryEachLine
--- Variable
--- Number of entries each line of helper. Default to 5.
obj.helperEntryEachLine = 5

--- RecursiveBinder.helperEntryLengthInChar
--- Variable
--- Length of each entry in char. Default to 20.
obj.helperEntryLengthInChar = 20

--- RecursiveBinder.helperFormat
--- Variable
--- format of helper, the helper is just a hs.alert
--- default to {atScreenEdge=2,
---             strokeColor={ white = 0, alpha = 2 },
---             textFont='SF Mono'
---             textSize=20}
obj.helperFormat = {
  atScreenEdge = 2,
  strokeColor = { white = 0, alpha = 2 },
  textFont = 'Courier',
  textSize = 20
}

--- @class BindNode
--- @field isLeaf boolean
--- @field modal hs.hotkey.modal? nil for the leaf node
--- @field children BindNode[] empty for the leaf node
--- @field parent BindNode? nil for the root node
--- @field prefixKeySeq string normalized trigger key, eg: 'root/control-a'
--- @field key string the last normalized key, eg: "control-b"
--- @field action function actual function for leaf node and binding function for non-leaf

--- RecursiveBinder.showBindHelper()
--- Variable
--- whether to show helper, can be true of false
obj.showBindHelper = true

--- RecursiveBinder.helperModifierMapping()
--- Variable
--- The mapping used to display modifiers on helper.
--- Default to {
---  command = '⌘',
---  control = '⌃',
---  option = '⌥',
---  shift = '⇧',
--- }
obj.helperModifierMapping = {
  command = '⌘',
  control = '⌃',
  option = '⌥',
  shift = '⇧',
}

obj.logger = hs.logger.new("RecursiveBinder", "info")

-- used by next model to close previous helper
obj.previousHelperMessage = nil
obj.previousHelperID = nil

-- this function is used by helper to display
-- appropriate 'shift + key' bindings
-- it turns a lower key to the corresponding
-- upper key on keyboard
local function keyboardUpper (key)
  local upperTable = {
    a = 'A',
    b = 'B',
    c = 'C',
    d = 'D',
    e = 'E',
    f = 'F',
    g = 'G',
    h = 'H',
    i = 'I',
    j = 'J',
    k = 'K',
    l = 'L',
    m = 'M',
    n = 'N',
    o = 'O',
    p = 'P',
    q = 'Q',
    r = 'R',
    s = 'S',
    t = 'T',
    u = 'U',
    v = 'V',
    w = 'W',
    x = 'X',
    y = 'Y',
    z = 'Z',
    ['`'] = '~',
    ['1'] = '!',
    ['2'] = '@',
    ['3'] = '#',
    ['4'] = '$',
    ['5'] = '%',
    ['6'] = '^',
    ['7'] = '&',
    ['8'] = '*',
    ['9'] = '(',
    ['0'] = ')',
    ['-'] = '_',
    ['='] = '+',
    ['['] = '}',
    [']'] = '}',
    ['\\'] = '|',
    [';'] = ':',
    ['\''] = '"',
    [','] = '<',
    ['.'] = '>',
    ['/'] = '?'
  }
  uppperKey = upperTable[key]
  if uppperKey then
    return uppperKey
  else
    return key
  end
end

--- RecursiveBinder.singleKey(key, name)
--- Method
--- this function simply return a table with empty modifiers also it translates capital letters to normal letter with shift modifer
---
--- Parameters:
---  * key - a letter
---  * name - the description to pass to the keys binding function
---
--- Returns:
---  * a table of modifiers and keys and names, ready to be used in keymap
---    to pass to RecursiveBinder.recursiveBind()
function obj.singleKey (key, name)
  local mod = {}
  if key == keyboardUpper(key) and string.len(key) == 1 then
    mod = { 'shift' }
    key = string.lower(key)
  end

  if name then
    return { mod, key, name }
  else
    return { mod, key, 'no name' }
  end
end

-- generate a string representation of a key spec
-- {{'shift', 'command'}, 'a} -> 'shift+command+a'
local function createKeyName (key)
  -- key is in the form {{modifers}, key, (optional) name}
  -- create proper key name for helper
  local modifierTable = M.sort(key[1])
  local keyString = key[2]
  -- add a little mapping for space
  if keyString == 'space' then keyString = 'SPC' end
  if #modifierTable == 1 and modifierTable[1] == 'shift' and string.len(keyString) == 1 then
    -- shift + key map to Uppercase key
    -- shift + d --> D
    -- if key is not on letter(space), don't do it.
    return keyboardUpper(keyString)
  else
    -- append each modifiers together
    local keyName = ''
    if #modifierTable >= 1 then
      for count = 1, #modifierTable do
        local modifier = modifierTable[count]
        if count == 1 then
          keyName = obj.helperModifierMapping[modifier] .. ' + '
        else
          keyName = keyName .. obj.helperModifierMapping[modifier] .. ' + '
        end
      end
    end
    -- finally append key, e.g. 'f', after modifers
    return keyName .. keyString
  end
end

-- Function to compare two letters
-- It sorts according to the ASCII code, and for letters, it will be alphabetical
-- However, for capital letters (65-90), I'm adding 32.5 (this came from 97 - 65 + 0.5, where 97 is a and 65 is A) to the ASCII code before comparing
-- This way, each capital letter comes after the corresponding simple letter but before letters that come after it in the alphabetical order
local function compareLetters (a, b)
  asciiA = string.byte(a)
  asciiB = string.byte(b)
  if asciiA >= 65 and asciiA <= 90 then
    asciiA = asciiA + 32.5
  end
  if asciiB >= 65 and asciiB <= 90 then
    asciiB = asciiB + 32.5
  end
  return asciiA < asciiB
end

-- Here I am adding a bit of code to sort before showing
-- Only the part between START and END changes
local function showHelper (keyFuncNameTable)
  local helper = ''
  local separator = ''
  local lastLine = ''
  local count = 0

  -- START
  local sortedKeyFuncNameTable = {}
  for keyName, funcName in pairs(keyFuncNameTable) do
    table.insert(sortedKeyFuncNameTable,
      { keyName = keyName, funcName = funcName })
  end
  table.sort(sortedKeyFuncNameTable,
    function(a, b) return compareLetters(a.keyName, b.keyName) end)

  for _, value in ipairs(sortedKeyFuncNameTable) do
    local keyName = value.keyName
    local funcName = value.funcName
    -- END
    count = count + 1
    local newEntry = keyName .. ' -> ' .. funcName
    -- make sure each entry is of the same length
    if string.len(newEntry) > obj.helperEntryLengthInChar then
      newEntry =
          string.sub(newEntry, 1, obj.helperEntryLengthInChar - 2) .. '..'
    elseif string.len(newEntry) < obj.helperEntryLengthInChar then
      newEntry = newEntry ..
          string.rep(' ', obj.helperEntryLengthInChar - string.len(newEntry))
    end
    -- create new line for every helperEntryEachLine entries
    if count % (obj.helperEntryEachLine + 1) == 0 then
      separator = '\n '
    elseif count == 1 then
      separator = ' '
    else
      separator = '  '
    end
    helper = helper .. separator .. newEntry
  end
  helper = string.match(helper, '[^\n].+$')
  obj.previousHelperMessage = helper
  obj.previousHelperID = hs.alert.show(helper, obj.helperFormat, true)
end

local function killHelper ()
  hs.alert.closeSpecific(obj.previousHelperID)
end


-- Create an eventtap to surpress the unbinded keys
local function suppressKeysOtherThenOurs (modal, onSuppress)
  local passThroughKeys = {}

  -- this is annoying because the event's raw flag bitmasks differ from the bitmasks used by hotkey, so
  -- we have to convert here for the lookup

  for _, v in pairs(modal.keys) do
    -- parse for flags, get keycode for each
    local kc, mods = tostring(v._hk):match("keycode: (%d+), mods: (0x[^ ]+)")
    local hkFlags = tonumber(mods)
    local hkOriginal = hkFlags
    local flags = 0
    if (hkFlags & 256) == 256 then
      hkFlags, flags = hkFlags - 256, flags | eventtap.event.rawFlagMasks
          .command
    end
    if (hkFlags & 512) == 512 then
      hkFlags, flags = hkFlags - 512, flags | eventtap.event.rawFlagMasks.shift
    end
    if (hkFlags & 2048) == 2048 then
      hkFlags, flags = hkFlags - 2048,
          flags | eventtap.event.rawFlagMasks.alternate
    end
    if (hkFlags & 4096) == 4096 then
      hkFlags, flags = hkFlags - 4096,
          flags | eventtap.event.rawFlagMasks.control
    end
    if hkFlags ~= 0 then
      obj.logger.d("unexpected flag pattern detected for " .. tostring(v._hk))
    end
    passThroughKeys[tonumber(kc)] = flags
  end

  local eventtap = eventtap.new(
    {
      eventtap.event.types.keyDown,
      eventtap.event.types.keyUp
    },
    function(event)
      -- check only the flags we care about and filter the rest
      local flags =
          event:getRawEventData().CGEventData.flags &
          (eventtap.event.rawFlagMasks.command | eventtap.event.rawFlagMasks.control |
            eventtap.event.rawFlagMasks.alternate |
            eventtap.event.rawFlagMasks.shift)
      local eventType
      if (flags & eventtap.event.types.keyDown) ~= 0 then
        eventType = "keyDown"
      else
        eventType = "keyUp"
      end
      local pid = event:getProperty(hs.eventtap.event.properties
        .eventSourceUnixProcessID)
      if passThroughKeys[event:getKeyCode()] == flags then
        -- hs.printf("passing:     %3d 0x%08x pid=%d, eventType=%s",
        --   event:getKeyCode(), flags,
        --   pid, event:getType())
        return false -- pass it through so hotkey can catch it
      else
        if onSuppress then
          onSuppress(event)
        end
        -- hs.printf("suppressing: %3d 0x%08x pid=%d, eventType=%s",
        --   event:getKeyCode(), flags,
        --   pid, event:getType())
        return true -- delete it if we got this far -- it's a key that we want suppressed
      end
    end
  )
  return eventtap
end

--- Decorate the modal with eventtap to suppress non-binded keys
--- @param rootNode BindNode
local function decorateRoot (rootNode)
  local copyTable = function(t)
    local t2 = {}
    for k, v in pairs(t) do
      t2[k] = v
    end
    return t2
  end

  local function complementColor (color)
    --- @type {}
    local colorRGB = hs.drawing.color.asRGB(color)
    local r, g, b, a = colorRGB.red, colorRGB.green, colorRGB.blue,
        colorRGB.alpha
    local compColor = hs.drawing.color.asRGB({
      red = 1 - r,
      green = 1 - g,
      blue = 1 - b,
      alpha = a
    })
    return compColor
  end

  local function calculateFlesh (style)
    -- https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/alert/alert.lua#L17
    local fillColor = hs.alert.defaultStyle.fillColor
    local textColor = hs.alert.defaultStyle.textColor
    if style.fillColor then
      fillColor = style.fillColor
    end
    if style.textColor then
      textColor = style.textColor
    end
    local copiedStyle = copyTable(style)
    copiedStyle.textColor = complementColor(textColor)
    copiedStyle.fillColor = complementColor(fillColor)
    return copiedStyle
  end

  local freshHelper = function()
    killHelper()
    hs.alert.show(obj.previousHelperMessage, calculateFlesh(obj.helperFormat),
      0.1)
    obj.previousHelperID = hs.alert.show(obj.previousHelperMessage,
      obj.helperFormat, true)
  end

  ---@param curNode BindNode
  ---@return hs.eventtap
  local function registerEventTaps (curNode)
    if curNode.isLeaf then
      return {}
    end
    local onSuppress = function(event)
      if event:getType() == 11 then
        freshHelper()
      end
    end
    local thisTap = suppressKeysOtherThenOurs(curNode.modal, onSuppress)
    local eventTaps = {}
    table.insert(eventTaps, thisTap)
    for _, childNode in pairs(curNode.children) do
      local childrenTaps = registerEventTaps(childNode)
      for _, tap in pairs(childrenTaps) do
        table.insert(eventTaps, tap)
      end
    end
    --- @param self hs.hotkey.modal
    --- @diagnostic disable: duplicate-set-field
    curNode.modal.entered = function(self)
      -- obj.logger.i(
      --   F(
      --     "Enter eventtap for modal with [{curNode.prefixKeySeq}]+[{curNode.key}]",
      --     curNode))
      thisTap:start()
    end
    return eventTaps
  end

  ---@param curNode BindNode
  ---@param exitCallback function
  ---@return nil
  local function deRegisterEventTaps (curNode, exitCallback)
    if curNode.isLeaf then
      return
    end
    --- @param self hs.hotkey.modal
    --- @diagnostic disable: duplicate-set-field
    curNode.modal.exited = function(self)
      exitCallback(curNode)
    end
    for _, childNode in pairs(curNode.children) do
      deRegisterEventTaps(childNode, exitCallback)
    end
  end

  local eventTaps = registerEventTaps(rootNode)
  --- @param curNode BindNode trigger from which node
  local stopAllEventTaps = function(curNode)
    local count = 0
    for _, tap in pairs(eventTaps) do
      tap:stop()
      count = count + 1
    end
    -- obj.logger.i(
    --   F(
    --     "Stopped {count} eventtaps for modal triggerred from [{curNode.prefixKeySeq}] + [{curNode.key}]",
    --     count, curNode))
  end
  deRegisterEventTaps(rootNode, stopAllEventTaps)

  return stopAllEventTaps
end


--- RecursiveBinder.recursiveBind(keymap)
--- Method
--- Bind sequential keys by a nested keymap.
---
--- Parameters:
---  * keymap - A table that specifies the mapping.
---
--- Returns:
---  * A function to start. Bind it to a initial key binding.
---
--- Note:
--- Spec of keymap:
--- Every key is of format {{modifers}, key, (optional) description}
--- The first two element is what you usually pass into a hs.hotkey.bind() function.
---
--- Each value of key can be in two form:
--- 1. A function. Then pressing the key invokes the function
--- 2. A table. Then pressing the key bring to another layer of keybindings.
---    And the table have the same format of top table: keys to keys, value to table or function

-- the actual binding function
--- @return BindNode
function obj.buildModals (keymap, parent, prefixKeySeq, lastKey)
  if type(keymap) == 'function' then
    -- in this case "keymap" is actuall a function
    --- @type BindNode
    return {
      isLeaf = true,
      modal = nil,
      children = {},
      parent = parent,
      prefixKeySeq = prefixKeySeq,
      key = lastKey,
      action = keymap
    }
  end
  --- @type BindNode
  local thisNode = {
    modal = hs.hotkey.modal.new(),
    isLeaf = false,
    children = {},
    parent = parent,
    prefixKeySeq = prefixKeySeq,
    key = lastKey
  }
  local keyFuncNameTable = {}
  for key, map in pairs(keymap) do
    local child = obj.buildModals(map, thisNode,
      prefixKeySeq .. "/" .. lastKey, createKeyName(key))
    table.insert(thisNode.children, child)
    -- key[1] is modifiers, i.e. {'shift'}, key[2] is key, i.e. 'f'
    --- NOTE: This has to be bind to releaseFn, so the eventTap won't suppress the release key
    thisNode.modal:bind(key[1], key[2], nil, function()
      thisNode.modal:exit()
      killHelper()
      child.action()
    end)
    if #key >= 3 then
      keyFuncNameTable[createKeyName(key)] = key[3]
    end
  end
  for _, escKey in pairs(obj.escapeKeys) do
    --- NOTE: This has to be bind to releaseFn, so the eventTap won't suppress the release key
    thisNode.modal:bind(escKey[1], escKey[2], nil, function()
      thisNode.modal:exit()
      killHelper()
    end)
  end

  thisNode.action = function()
    thisNode.modal:enter()
    killHelper()
    if obj.showBindHelper then
      showHelper(keyFuncNameTable)
    end
  end
  return thisNode
end

function obj.recursiveBind (keymap, rootKey)
  local root = obj.buildModals(keymap, nil, "/",
    createKeyName(rootKey))
  decorateRoot(root)
  --- NOTE: This has to be bind to releaseFn, so the eventTap won't suppress the release key
  hs.hotkey.bind(rootKey[1], rootKey[2], nil, root.action)
end

-- function testrecursiveModal(keymap)
--    print(keymap)
--    if type(keymap) == 'number' then
--       return keymap
--    end
--    print('make new modal')
--    for key, map in pairs(keymap) do
--       print('key', key, 'map', testrecursiveModal(map))
--    end
--    return 0
-- end

-- mymap = {f = { r = 1, m = 2}, s = {r = 3, m = 4}, m = 5}
-- testrecursiveModal(mymap)

return obj
