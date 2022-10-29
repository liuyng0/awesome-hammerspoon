-- Stay replacement: Keep App windows in their places

-- luacheck: globals hs

local fun = require 'luarocks/fun'
local m = {}
m.logger = hs.logger.new('colorpicker')

local st = require('hs.styledtext')
local color = require('hs.drawing.color')
local funs = require('hs.fnutils')

function m:chooserWithLightstyle()
  return {
    fontSize = {text = 18, subText = 14},
    default = {text = color.x11.blue,
               subText = color.x11.royalblue},
    grayOut =  {text = color.x11.steelblue,
                subText = color.x11.dodgerblue}
  }
end

function m:chooserWithDarkstyle()
  return {
    fontSize = {text = 18, subText = 14},
    default = {text = color.x11.dodgerblue,
               subText = color.x11.royalblue},
    grayOut =  {text = color.x11.lightsteelblue,
                subText = color.x11.steelblue}
  }
end

-- options.darStyle: true or false
-- options.textKey, default "text"
-- options.subTextKey, default "subText"
-- options.grayOutKey, default "grayOut"
function m:setChooserUI(chooser, choices, options)
  local style = m:chooserWithLightstyle()
  if options ~= nil and options.darkStyle then
    chooser:bgDark(true)
    style = m:chooserWithDarkstyle()
  end

  local textKey = "text"
  local subTextKey = "subText"
  local grayOutKey = "grayOut"
  if options ~= nil and options.textKey ~= nil then
    textKey = options.textKey
  end

  if options ~= nil and options.subTextKey ~= nil then
    subTextKey = options.subTextKey
  end

  if options ~= nil and options.grayOutKey ~= nil then
    grayOutKey = options.grayOutKey
  end

  local isGrayOut = function(a) return (a[grayOutKey] ~= nil and a[grayOutKey] == true) end
  choices = funs.map(choices, function(choice)
                       local fgColor
                       if isGrayOut(choice) then
                         fgColor = style.grayOut
                       else
                         fgColor = style.default
                       end

                       if choice[textKey] ~= nil then
                         choice["text"] = st.new(choice[textKey], {
                                                   font={size=style.fontSize.text},
                                                   color=fgColor.text
                         })
                       end

                       if choice[subTextKey] ~= nil then
                         choice["subText"] = st.new(choice[subTextKey], {
                                                      font={size=style.fontSize.subText},
                                                      color=fgColor.subText
                         })
                       end
                       return choice
  end)

  -- m.logger.w("Choices after converted " .. hs.inspect(choices))
end

function m:getReorderedChoices(choices, grayOutKey)
  local isGrayOut = function(a) return (a[grayOutKey] ~= nil and a[grayOutKey] == true) end

  local grayOutChoices = funs.filter(choices, isGrayOut)
  local notGrayOutChoices = funs.filter(choices, function(a) return not isGrayOut(a) end)

  funs.map(grayOutChoices, function(c) table.insert(notGrayOutChoices, c) end)

  return notGrayOutChoices
end

return m
