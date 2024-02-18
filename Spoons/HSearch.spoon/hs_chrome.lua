local obj = {}
obj.__index = obj

obj.name = "chromeManager"
obj.version = "1.0"
obj.author = "LY <liuyng0@foxmail.com>"

local hsearch = spoon.HSearch
local function chromeSwitchTab(tab)
    hs.http.get("http://localhost:4000/chrome/tab/goto/" .. tab.winIndex .. "/" .. tab.tabIndex)
end

local function chromeOpenBookmark(tab)
    hs.urlevent.openURLWithBundle(tab.url, "com.google.Chrome")
end

obj.chromeTabs =
    spoon.HSearch:makeRequestSource {
    overview = {
        text = "Type ct ⇥ to select chrome tab",
        image = hsearch:resourceImage("/resources/og/chrome-switch.png"),
        keyword = "ct"
    },
    query_url = "http://localhost:4000/chrome/tabs",
    item_mapping_func = function(item)
        return {
            text = item.title,
            subText = item.url,
            id = item.id,
            winId = item.winId,
            winIndex = item.winIndex,
            tabIndex = item.tabIndex,
            image = hsearch:resourceImage("/resources/og/chrome-switch.png"),
            output = "chromeSwitchTab"
        }
    end,
    output = {
        name = "chromeSwitchTab",
        func = chromeSwitchTab
    },
    placeholderText = "switch to chrome tab..."
}

obj.chromeBookmarks =
    spoon.HSearch:makeRequestSource {
    overview = {
        text = "Type cb ⇥ to open chrome bookmark",
        image = hsearch:resourceImage("/resources/og/chrome-new.png"),
        keyword = "cb"
    },
    query_url = "http://localhost:4000/chrome/bookmarks",
    item_mapping_func = function(item)
        return {
            text = item.path,
            subText = item.url,
            url = item.url,
            image = hsearch:resourceImage("/resources/og/chrome-new.png"),
            output = "chromeOpenBookmark"
        }
    end,
    output = {
        name = "chromeOpenBookmark",
        func = chromeOpenBookmark
    },
    placeholderText = "open chrome bookmark..."
}

return {
    [1] = obj.chromeTabs,
    [2] = obj.chromeBookmarks
}
