-- Stay replacement: Keep App windows in their places

-- luacheck: globals hs

local fun = require 'luarocks/fun'
local m = {}
m.logger = hs.logger.new('colorpicker')

local st = require('hs.styledtext')
local color = require('hs.drawing.color')
local funs = require('hs.fnutils')

m.textSize = 16
m.subTextSize = 14

function m:x11Alpha(color, alpha)
  return {
    red = color.red,
    green = color.green,
    blue = color.blue,
    alpha = alpha
  }
end

m.lightStyle = {
    default = {
      text = {
        font = {
          name='SF Pro Bold',
          size=m.textSize
        },
        color = m:x11Alpha(color.x11.brown, 1.0)
      },
      subText = {
        font = {
          name='SF Pro',
          size=m.subTextSize
        },
        color=m:x11Alpha(color.x11.blue, 0.9)
      }
    },
    grayOut = {
      text = {
        font = {
          name='SF Pro Bold',
          size=m.textSize
        },
        color=color.x11.steelblue
      },
      subText = {
        font = {
          name='SF Pro',
          size=m.subTextSize
        },
        color=color.x11.dodgerblue
      }
    }
}

m.darkStyle = {
  default = {
    text = {
      font = {
        size=m.textSize
      },
      color=color.x11.dodgerblue
    },
    subText = {
      font = {
        size=m.subTextSize
      },
      color=color.x11.royalblue
    }
  },
  grayOut = {
    text = {
      font = {
        size=m.textSize
      },
      color=color.x11.lightsteelblue
    },
    subText = {
      font = {
        size=m.subTextSize
      },
      color=color.x11.steelblue
    }
  }
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
                         local textStyle
                         if isGrayOut(choice) then
                           textStyle = style.grayOut
                         else
                           textStyle = style.default
                         end

                         if choice[textKey] ~= nil then
                           choice["text"] = m:styledTextCompatible(choice[textKey], textStyle.text)
                         end

                         if choice[subTextKey] ~= nil then
                           choice["subText"] = m:styledTextCompatible(choice[subTextKey], textStyle.subText)
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
