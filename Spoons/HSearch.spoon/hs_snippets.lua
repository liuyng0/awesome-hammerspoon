local obj={}
obj.__index = obj

obj.name = "Code Snippets"
obj.version = "1.0"
obj.author = "chophi <chophi@foxmail.com>"

local logger = hs.logger.new("Code Snippets Searcher", "debug")

-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

obj.spoonPath = script_path()

-- Define the source's overview. A unique `keyword` key should exist, so this source can be found.
obj.overview = {text="Type c ⇥ to view/copy code snippets.", image=hs.image.imageFromPath(obj.spoonPath .. "/resources/justnote.png"), keyword="c"}
-- Define the notice when a long-time request is being executed. It could be `nil`.
obj.notice = {text="Requesting data, please wait a while …"}

obj.init_func = function ()
    local orgSourceFeedScript = getScript("org-source-feed.py")

    local command = orgSourceFeedScript .. " " .. "-t source-code -o get-sources"
    -- logger:d("Start to call: " .. command)
    local output, status, exitType, rc = hs.execute(command, true)

    -- logger:d(output, status, exitType, rct)
    local chooser_data = {}
    if status and output ~= "" then
        output = hs.fnutils.split(output, "\n")
        output = output[#output-1]
        local snippets = hs.json.decode(output)
        local index = 1
        for _, s in pairs(snippets) do
            -- logger:d("get: " .. hs.inspect.inspect(s))
            table.insert(chooser_data, {
                             text = s.name,
                             subText = s.type .. "/" .. s.source_file,
                             output = "clipboard",
                             arg = s.code,
                             index = index,
                             image=hs.image.imageFromPath(obj.spoonPath .. "/resources/justnote.png")
            })
            index = index + 1
        end
    end

    return chooser_data
end

obj.description = {text="Code Snippets Searcher", subText="Search and select one item to copy the source code to clipboard", image=hs.image.imageFromPath(obj.spoonPath .. "/resources/justnote.png")}

-- As the user is typing, the callback function will be called for every keypress. The returned value is a table.
obj.callback = nil

return obj
