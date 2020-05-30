local obj={}
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
obj.overview = {text="Type t ⇥ to search safari/chrome Tabs.", image=hs.image.imageFromPath(obj.spoonPath .. "/resources/tabs.png"), keyword="t"}
-- Define the notice when a long-time request is being executed. It could be `nil`.
obj.notice = {text="Requesting data, please wait a while …"}

obj.init_func = function ()
    local chromeTabManagerPath = getScript("chromeTabManager.js")
    local arguments = hs.json.encode({
            winId = -1,
            tabTitle = -1,
            operation = ":getTabs",
    })

    local command = chromeTabManagerPath .. " " .. "'" .. arguments .. "'"
    local output, status, exitType, rc = hs.execute(command)

    -- logger:d("Finished command: " .. command .. ", and got output: " .. output)
    local chooser_data = {}
    if status and output ~= "" then
        local windowTabs = hs.json.decode(output)
        local index = 1
        for _, w in pairs(windowTabs) do
            local wid = w.windowId
            for _, tab in pairs(w.tabs) do
                table.insert(chooser_data, {
                                 text = tab.title,
                                 subText = tab.url,
                                 output = "chrome",
                                 windowId = wid,
                                 tabTitle = tab.title,
                                 index = index,
                                 image=hs.image.imageFromPath(obj.spoonPath .. "/resources/chrome.png")
                })
                index = index + 1
            end
        end
    end

    return chooser_data
end

obj.description = {text="Browser Tabs Search", subText="Search and select one item to open in corresponding browser.", image=hs.image.imageFromPath(obj.spoonPath .. "/resources/tabs.png")}

local function writerGenerator(operations)
    local writer = {}
    for _, operation in pairs(operations) do
        table.insert(writer, {
                         operation = operation,
                         operator = function(config)
                             config.currentOperation = operation
        end})
    end

    return writer
end

obj.config = {
    currentOperation = ":switchTo",
    allOperations = {
        ":switchTo",
        ":openInNewTab",
        ":delete",
    },
}
obj.config_writer = writerGenerator(obj.config.allOperations)

-- As the user is typing, the callback function will be called for every keypress. The returned value is a table.
obj.callback = nil

obj.output_method = function(arg)
    local argTable = hs.json.decode(arg)
    local chromeTabManagerPath = getScript("chromeTabManager.js")
    local arguments = hs.json.encode({
            windowId = argTable.windowId,
            tabTitle = argTable.tabTitle,
            operation = argTable.config.currentOperation,
    })
    local command = chromeTabManagerPath .. " " .. "'" .. arguments .. "'"
    local output, status, exitType, rc = hs.execute(command)
    -- logger:d("Run command: " .. command .. ", and got output: " .. output)
end

return obj
