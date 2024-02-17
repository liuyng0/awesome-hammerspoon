local obj = {}
obj.__index = obj

obj.name = "chromeManager"
obj.version = "1.0"
obj.author = "LY <liuyng0@foxmail.com>"

local logger = hs.logger.new("Chrome Manager", "debug")

-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

obj.spoonPath = script_path()

-- Define the source's overview. A unique `keyword` key should exist, so this source can be found.
obj.overview = {
    text = "Type c ⇥ to do chrome operations.",
    image = hs.image.imageFromPath(obj.spoonPath .. "/resources/chrome.png"),
    keyword = "c"
}

-- Define the notice when a long-time request is being executed. It could be `nil`.
obj.notice = {text = "Requesting data, please wait a while …"}

local function getChromeTabs()
    local query_url = "http://localhost:4000/chrome/tabs"
    local status, payload, header = hs.http.get(query_url, nil)
    if status == 200 then
        retval, decoded_data =
            pcall(
            function()
                return hs.json.decode(payload)
            end
        )
        if retval and #decoded_data > 0 then
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
                        output = "chromeSwitchTab"
                    }
                end
            )
            return chooser_data
        end
    end
end

local function getChromeBookmarks()
    local query_url = "http://localhost:4000/chrome/bookmarks"
    local status, payload, header = hs.http.get(query_url, nil)
    if status == 200 then
        retval, decoded_data =
            pcall(
            function()
                return hs.json.decode(payload)
            end
        )
        if retval and #decoded_data > 0 then
            local chooser_data =
                hs.fnutils.imap(
                decoded_data,
                function(item)
                    return {
                        text = item.path,
                        subText = item.url,
                        url = item.url,
                        image = hs.image.imageFromPath(obj.spoonPath .. "/resources/chrome.png"),
                        output = "chromeOpenBookmark"
                    }
                end
            )
            return chooser_data
        end
    end
end

local function chromeRequest()
    local data1 = getChromeTabs()
    local data2 = getChromeBookmarks()
    local len = #data2
    for i = 1, len do
        table.insert(data1, data2[i])
    end
    return data1
end

local function chromeSwitchTab(tab)
    hs.http.get("http://localhost:4000/chrome/tab/goto/" .. tab.winIndex .. "/" .. tab.tabIndex)
end

local function chromeOpenBookmark(tab)
    hs.urlevent.openURLWithBundle(tab.url, "com.google.Chrome")
end

obj.init_func = chromeRequest
obj.new_output = {
    [1] = {
        name = "chromeSwitchTab",
        func = chromeSwitchTab
    },
    [2] = {
        name = "chromeOpenBookmark",
        func = chromeOpenBookmark
    }
}
obj.description = nil

-- As the user is typing, the callback function will be called for every keypress. The returned value is a table.
obj.callback = nil

return obj
