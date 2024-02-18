--- === ChooserStyle ===
---
--- A new Sample Spoon
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/ChooserStyle.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/ChooserStyle.spoon.zip)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ChooserStyle"
obj.version = "0.1"
obj.author = "liuyng0 <liuyng0@outlook.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local fun = require "luarocks/fun"
local st = require("hs.styledtext")
local color = require("hs.drawing.color")
local funs = require("hs.fnutils")

obj.logger = hs.logger.new("ChooserStyle")
obj.textSize = 15
obj.subTextSize = 13

function obj:x11Alpha(color, alpha)
    return {
        red = color.red,
        green = color.green,
        blue = color.blue,
        alpha = alpha
    }
end

function obj:hexAlpha(hex, alpha)
    return {hex = hex, alpha = alpha}
end

obj.lightStyle = {
    default = {
        text = {
            font = {
                name = "SF Pro Bold",
                size = obj.textSize
            },
            color = obj:hexAlpha("#525868", 1.0),
            paragraphStyle = {
                lineBreak = "truncateTail"
            }
        },
        subText = {
            font = {
                name = "SF Pro",
                size = obj.subTextSize
            },
            color = obj:hexAlpha("#3c4353", 1.0),
            paragraphStyle = {
                lineBreak = "truncateTail"
            }
        }
    },
    grayOut = {
        text = {
            font = {
                name = "SF Pro Bold",
                size = obj.textSize
            },
            color = color.x11.steelblue,
            paragraphStyle = {
                lineBreak = "truncateTail"
            }
        },
        subText = {
            font = {
                name = "SF Pro",
                size = obj.subTextSize
            },
            color = color.x11.dodgerblue,
            paragraphStyle = {
                lineBreak = "truncateTail"
            }
        }
    }
}

obj.darkStyle = {
    default = {
        text = {
            font = {
                size = obj.textSize
            },
            color = color.x11.dodgerblue
        },
        subText = {
            font = {
                size = obj.subTextSize
            },
            color = color.x11.royalblue
        }
    },
    grayOut = {
        text = {
            font = {
                size = obj.textSize
            },
            color = color.x11.lightsteelblue
        },
        subText = {
            font = {
                size = obj.subTextSize
            },
            color = color.x11.steelblue
        }
    }
}

-- options.darStyle: true or false
-- options.textKey, default "text"
-- options.subTextKey, default "subText"
-- options.grayOutKey, default "grayOut"
-- Use private parameter __colorpicker_style to define whether need to reset
function obj:setChooserUI(chooser, choices, options)
    local style = obj.lightStyle
    if options ~= nil and options.darkStyle then
        chooser:bgDark(true)
        style = obj.darkStyle
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

    local isGrayOut = function(a)
        return (a[grayOutKey] ~= nil and a[grayOutKey] == true)
    end
    if obj:needRecolor(choices, style) then
        obj.logger.w("Need to recolor")
        choices =
            funs.map(
            choices,
            function(choice)
                choice.__colorpicker_style = style
                local textStyle
                if isGrayOut(choice) then
                    textStyle = style.grayOut
                else
                    textStyle = style.default
                end

                if choice[textKey] ~= nil then
                    choice["text"] = obj:styledTextCompatible(choice[textKey], textStyle.text)
                end

                if choice[subTextKey] ~= nil then
                    choice["subText"] = obj:styledTextCompatible(choice[subTextKey], textStyle.subText)
                end
                return choice
            end
        )
    end
    -- obj.logger.w("Choices after converted " .. hs.inspect(choices))
end

function obj:needRecolor(choices, style)
    return choices ~= nil and
        not funs.every(
            choices,
            function(choice)
                return choice.__colorpicker_style == style
            end
        )
end

function obj:styledTextCompatible(text, style)
    if type(text) == "userdata" and text.__name == "hs.styledtext" then
        text:setStyle(style)

        return text
    elseif type(text) == "string" then
        return st.new(text, style)
    else
        return text
    end
end

function obj:getReorderedChoices(choices, grayOutKey)
    local isGrayOut = function(a)
        return (a[grayOutKey] ~= nil and a[grayOutKey] == true)
    end

    local grayOutChoices = funs.filter(choices, isGrayOut)
    local notGrayOutChoices =
        funs.filter(
        choices,
        function(a)
            return not isGrayOut(a)
        end
    )

    funs.map(
        grayOutChoices,
        function(c)
            table.insert(notGrayOutChoices, c)
        end
    )

    return notGrayOutChoices
end

return obj
