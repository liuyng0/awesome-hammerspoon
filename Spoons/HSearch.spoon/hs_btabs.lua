local obj = {}
obj.__index = obj

obj.name = "browserTabs"
obj.version = "1.0"
obj.author = "ashfinal <ashfinal@gmail.com>"

local logger = hs.logger.new("Chrome Tab Manager", "debug")

-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

obj.spoonPath = script_path()

-- Define the source's overview. A unique `keyword` key should exist, so this source can be found.
obj.overview = {
    text = "Type t ⇥ to search chrome Tabs.",
    image = hs.image.imageFromPath(obj.spoonPath .. "/resources/chrome.png"),
    keyword = "t"
}

-- Define the notice when a long-time request is being executed. It could be `nil`.
obj.notice = {text = "Requesting data, please wait a while …"}

local function chromeTabRequest()
    logger:d("call chromeTabRequest")
    local query_url = "http://localhost:4000/chrome/tabs"
    local status, payload, header = hs.http.get(query_url, nil)
    if status == 200 then
        -- retval, decoded_data = pcall(function() hs.json.decode(payload) end)
        -- logger:d("Finished command: and got output: " .. hs.inspect(decoded_data))
        decoded_data = hs.json.decode(payload)
        if #decoded_data > 0 then
            local chooser_data =
                hs.fnutils.imap(
                decoded_data,
                function(item)
                    return {
                        text = item.title,
                        subText = item.url,
                        id = item.id,
                        winId = item.winId,
                        winIndex = item.winIndex,
                        tabIndex = item.tabIndex,
                        image = hs.image.imageFromPath(obj.spoonPath .. "/resources/chrome.png"),
                        output = "chromeTab"
                    }
                end
            )
            return chooser_data
        end
    end
end

obj.init_func = chromeTabRequest
obj.description = nil

-- As the user is typing, the callback function will be called for every keypress. The returned value is a table.
obj.callback = nil

return obj
