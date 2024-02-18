local obj = {}
obj.__index = obj

obj.name = "MLemoji"
obj.version = "1.0"
obj.author = "ashfinal <ashfinal@gmail.com>"

-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

obj.spoonPath = script_path()

-- Define the source's overview. A unique `keyword` key should exist, so this source can be found.
obj.overview = {
    text = "Type e ⇥ to find relevant Emoji.",
    image = hs.image.imageFromPath(obj.spoonPath .. "/resources/emoji.png"),
    keyword = "e"
}
-- Define the notice when a long-time request is being executed. It could be `nil`.
obj.notice = nil

obj.choices = {}

local function emojiTips()
    if next(obj.choices) ~= nil then
        return obj.choices
    end

    for _, emoji in ipairs(hs.json.decode(io.open(obj.spoonPath .. "/emojis/emojis.json"):read())) do
        table.insert(
            obj.choices,
            {
                text = emoji["name"],
                subText = table.concat(emoji["kwds"], ", "),
                image = hs.image.imageFromPath(obj.spoonPath .. "/emojis/" .. emoji["id"] .. ".png"),
                output = "keystrokes",
                arg = emoji["chars"]
            }
        )
    end
    return obj.choices
end

-- Define the function which will be called when the `keyword` triggers a new source. The returned value is a table. Read more: http://www.hammerspoon.org/docs/hs.chooser.html#choices
obj.init_func = emojiTips
-- Insert a friendly tip at the head so users know what to do next.
-- As this source highly relys on queryChangedCallback, we'd better tip users in callback instead of here
obj.description = nil

-- As the user is typing, the callback function will be called for every keypress. The returned value is a table.
obj.canvas = hs.canvas.new({x = 0, y = 0, w = 96, h = 96})

return obj
