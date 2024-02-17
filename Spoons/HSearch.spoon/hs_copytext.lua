local obj = {}
obj.__index = obj

obj.name = "Copy text"
obj.version = "1.0"
obj.author = "chophi <chophi@foxmail.com>"

local logger = hs.logger.new("Copy text Searcher", "debug")

-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

obj.spoonPath = script_path()

-- Define the source's overview. A unique `keyword` key should exist, so this source can be found.
obj.overview = {
    text = "Type cp ⇥ to open links",
    image = hs.image.imageFromPath(obj.spoonPath .. "/resources/justnote.png"),
    keyword = "cp"
}
-- Define the notice when a long-time request is being executed. It could be `nil`.
obj.notice = {text = "Requesting data, please wait a while …"}

obj.init_func = function()
    local orgSourceFeedScript = getScript("org-source-feed.py")

    local command = orgSourceFeedScript .. " " .. "-t links -f " .. privconf.hssearch_copy_texts_filepaths
    -- logger:d("Start to call: " .. command)
    local output, status, exitType, rc = executeWithPathPopulated(command)

    -- logger:d(output, status, exitType, rct)
    local chooser_data = {}
    if status and output ~= "" then
        local snippets = hs.json.decode(output)
        local index = 1
        for _, s in pairs(snippets) do
            -- logger:d("get: " .. hs.inspect.inspect(s))
            table.insert(
                chooser_data,
                {
                    text = s.name,
                    subText = s.type .. "/" .. s.source_file .. ": " .. s.code,
                    output = "browser",
                    arg = s.code,
                    link = s.code,
                    index = index,
                    image = hs.image.imageFromPath(obj.spoonPath .. "/resources/justnote.png")
                }
            )
            index = index + 1
        end
    end

    return chooser_data
end

obj.description = {
    text = "Copy text",
    subText = "Search and select one item to copy the item to clipboard",
    image = hs.image.imageFromPath(obj.spoonPath .. "/resources/justnote.png")
}

-- As the user is typing, the callback function will be called for every keypress. The returned value is a table.
obj.callback = nil

local function writerGenerator(operations)
    local writer = {}
    for _, operation in pairs(operations) do
        table.insert(
            writer,
            {
                operation = operation,
                operator = function(config)
                    config.currentOperation = operation
                end
            }
        )
    end

    return writer
end

obj.config = {
    currentOperation = ":copyToClipboard",
    allOperations = {
        ":copyToClipboard"
    }
}
obj.config_writer = writerGenerator(obj.config.allOperations)

obj.output_method = function(arg)
    local argTable = hs.json.decode(arg)
    logger:d("argTable is: " .. hs.inspect.inspect(argTable))
    if argTable.config.currentOperation == ":openInBrowser" then
        hs.urlevent.openURLWithBundle(argTable.link, "com.google.Chrome")
    elseif argTable.config.currentOperation == ":copyToClipboard" then
        hs.pasteboard.setContents(argTable.link)
    end
end

return obj
