-- Stay replacement: Keep App windows in their places

-- luacheck: globals hs

local fun = require 'luarocks/fun'
local m = {}
m.logger = hs.logger.new('colorpicker')

local st = require('hs.styledtext')
local color = require('hs.drawing.color')
local funs = require('hs.fnutils')

m.lightStyle = {
    fontSize = {text = 18, subText = 14},
    default = {text = color.x11.blue,
               subText = color.x11.royalblue},
    grayOut =  {text = color.x11.steelblue,
                subText = color.x11.dodgerblue}
}

m.darkStyle = {
    fontSize = {text = 18, subText = 14},
    default = {text = color.x11.dodgerblue,
               subText = color.x11.royalblue},
    grayOut =  {text = color.x11.lightsteelblue,
                subText = color.x11.steelblue}
}


-- options.darStyle: true or false
-- options.textKey, default "text"
-- options.subTextKey, default "subText"
-- options.grayOutKey, default "grayOut"
-- Use private parameter __colorpicker_style to define whether need to reset
function m:setChooserUI(chooser, choices, options)
  local style = m.lightStyle
  if options ~= nil and options.darkStyle then
    chooser:bgDark(true)
    style = m.darkStyle
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
  if m:needRecolor(choices, style) then
    m.logger.w("Need to recolor")
    choices = funs.map(choices, function(choice)
                         choice.__colorpicker_style = style
                         local fgColor
                         if isGrayOut(choice) then
                           fgColor = style.grayOut
                         else
                           fgColor = style.default
                         end

                         if choice[textKey] ~= nil then
                           choice["text"] = m:styledTextCompatible(choice[textKey], {
                                                                     font={size=style.fontSize.text},
                                                                     color=fgColor.text
                           })
                         end

                         if choice[subTextKey] ~= nil then
                           choice["subText"] = m:styledTextCompatible(choice[subTextKey], {
                                                                        font={size=style.fontSize.subText},
                                                                        color=fgColor.subText
                           })
                         end
                         return choice
    end)
  end
  -- m.logger.w("Choices after converted " .. hs.inspect(choices))
end

function m:needRecolor(choices, style)
  return choices ~= nil and
  not funs.every(choices, function(choice) return choice.__colorpicker_style == style end)
end

function m:styledTextCompatible(text, style)
  if type(text) == 'userdata' and text.__name == 'hs.styledtext' then
    text:setStyle(style)

    return text
  elseif type(text) == 'string' then
    return st.new(text, style)
  else
    return text
  end
end

function m:getReorderedChoices(choices, grayOutKey)
  local isGrayOut = function(a) return (a[grayOutKey] ~= nil and a[grayOutKey] == true) end

  local grayOutChoices = funs.filter(choices, isGrayOut)
  local notGrayOutChoices = funs.filter(choices, function(a) return not isGrayOut(a) end)

  funs.map(grayOutChoices, function(c) table.insert(notGrayOutChoices, c) end)

  return notGrayOutChoices
end

return m
