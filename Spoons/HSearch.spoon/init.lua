--- === HSearch ===
---
--- Hammerspoon Search
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/HSearch.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/HSearch.spoon.zip)

local obj={}
obj.__index = obj

-- Metadata
obj.name = "HSearch"
obj.version = "1.0"
obj.author = "ashfinal <ashfinal@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

obj.spoonPath = script_path()

obj.sources = {}
obj.sources_config = {}
obj.sources_overview = {}
obj.search_path = {hs.configdir .. "/private/hsearch_dir", obj.spoonPath}
obj.hotkeys = {}
obj.source_kw = nil

local logger = hs.logger.new("HSearch", 'debug')

function obj:restoreOutput()
    obj.output_pool = {}
    -- Define the built-in output type
    local function openWithBrowser(arg)
        local default_browser = hs.urlevent.getDefaultHandler('http')
        hs.urlevent.openURLWithBundle(arg, default_browser)
    end
    local function openWithSafari(arg)
        hs.urlevent.openURLWithBundle(arg, "com.apple.Safari")
    end
   local function openWithFirefox(arg)
        hs.urlevent.openURLWithBundle(arg, "org.mozilla.firefox")
    end
    local function copyToClipboard(arg)
        hs.pasteboard.setContents(arg)
    end
    local function sendKeyStrokes(arg)
        local cwin = hs.window.orderedWindows()[1]
        cwin:focus()
        hs.eventtap.keyStrokes(arg)
    end
    obj.output_pool["browser"] = openWithBrowser
    obj.output_pool["safari"] = openWithSafari
    obj.output_pool["firefox"] = openWithFirefox
    obj.output_pool["clipboard"] = copyToClipboard
    obj.output_pool["keystrokes"] = sendKeyStrokes
end

function obj:currentSourceMultipleOperationEnabled()
    if obj.source_kw == nil then
        return false
    end
    local source_config = obj.sources_config[obj.source_kw]
    return source_config ~= nil and (type(source_config.config) == 'table' and type(source_config.config_writer) == 'table')
end

function obj:appendOperationData(chooser_data)
    local source_config = obj.sources_config[obj.source_kw]
    for _, writer in ipairs(source_config.config_writer) do
        local operation = writer.operation
        local operator = writer.operator
        table.insert(chooser_data, {
                         text = operation,
                         subText = "This is a operation to manipulate the configuration.",
                         operation = operation,
        })
    end
    table.insert(chooser_data, {
                     text = ":viewConfig",
                     subText = hs.inspect.inspect(source_config.config, {newline="  "}),
                     operation = ":viewConfig",
    })
end

function obj:operateOnMaybe(config, operation)
    local source_config = obj.sources_config[obj.source_kw]
    for _, writer in ipairs(source_config.config_writer) do
        if writer.operation == operation then
            writer.operator(config)
        end
    end
end

function obj:filterParsableFieldsToJson(chosen)
    local newTable = {}
    for index, value in pairs(chosen) do
        if type(value) == 'number' or type(value) == 'nil' or type(value) == 'string' or type(value) == 'table' then
            newTable[index] = value
        end
    end
    return hs.json.encode(newTable)
end

function obj:init()
    obj.chooser = hs.chooser.new(function(chosen)
        obj.trigger:disable()
        -- Disable all hotkeys
        for _,val in pairs(obj.hotkeys) do
            for i=1,#val do
                val[i]:disable()
            end
        end
        if chosen ~= nil then
            if chosen.operation ~= nil and obj:currentSourceMultipleOperationEnabled() then
                obj:operateOnMaybe(obj.sources_config[obj.source_kw].config, chosen.operation)
                -- logger.d("Configuration become: " .. hs.inspect.inspect(obj.sources_config[obj.source_kw].config))
                obj.sources[obj.source_kw]()
                return
            end
            if chosen.output then
                if obj:currentSourceMultipleOperationEnabled() then
                    chosen.config = obj.sources_config[obj.source_kw].config
                    local arguments = obj:filterParsableFieldsToJson(chosen)
                    -- logger.d("Call with parameter: " .. arguments)
                    if obj.sources_config[obj.source_kw].output_method ~= nil then
                        obj.sources_config[obj.source_kw].output_method(arguments)
                    else
                        obj.output_pool[chosen.output](chosen.arg)
                    end
                    obj.sources[obj.source_kw]()
                else
                    obj.output_pool[chosen.output](chosen.arg)
                end
            end
        end
    end)
    obj.chooser:rows(9)
end

--- HSearch:switchSource()
--- Method
--- Tigger new source according to hs.chooser's query string and keyword. Only for debug purpose in usual.
---

function obj:switchSource()
    local querystr = obj.chooser:query()
    if string.len(querystr) > 0 then
        local matchstr = string.match(querystr, "^%w+")
        if matchstr == querystr then
            -- First we try to switch source according to the querystr
            if obj.sources[querystr] then
                obj.source_kw = querystr
                obj.chooser:query('')
                obj.chooser:choices(nil)
                obj.chooser:queryChangedCallback()
                obj.sources[querystr]()
            else
                local row_content = obj.chooser:selectedRowContents()
                local row_kw = row_content.keyword
                -- Then try to switch source according to selected row
                if obj.sources[row_kw] then
                    obj.source_kw = row_kw
                    obj.chooser:query('')
                    obj.chooser:choices(nil)
                    obj.chooser:queryChangedCallback()
                    obj.sources[row_kw]()
                else
                    obj.source_kw = nil
                    local chooser_data = {
                        {text="No source found!", subText="Maybe misspelled the keyword?"},
                        {text="Want to add your own source?", subText="Feel free to read the code and open PRs. :)"}
                    }
                    obj.chooser:choices(chooser_data)
                    obj.chooser:queryChangedCallback()
                    hs.eventtap.keyStroke({"cmd"}, "a")
                end
            end
        else
            obj.source_kw = nil
            local chooser_data = {
                {text="Invalid Keyword", subText="Trigger keyword must only consist of alphanumeric characters."}
            }
            obj.chooser:choices(chooser_data)
            obj.chooser:queryChangedCallback()
            hs.eventtap.keyStroke({"cmd"}, "a")
        end
    else
        local row_content = obj.chooser:selectedRowContents()
        local row_kw = row_content.keyword
        if obj.sources[row_kw] then
            obj.source_kw = row_kw
            obj.chooser:query('')
            obj.chooser:choices(nil)
            obj.chooser:queryChangedCallback()
            obj.sources[row_kw]()
        else
            obj.source_kw = nil
            -- If no matching source then show sources overview
            local chooser_data = obj.sources_overview
            obj.chooser:choices(chooser_data)
            obj.chooser:queryChangedCallback()
        end
    end
    if obj.source_kw then
        for key,val in pairs(obj.hotkeys) do
            if key == obj.source_kw then
                for i=1,#val do
                    val[i]:enable()
                end
            else
                for i=1,#val do
                    val[i]:disable()
                end
            end
        end
    else
        for _,val in pairs(obj.hotkeys) do
            for i=1,#val do
                val[i]:disable()
            end
        end
    end
end

--- HSearch:loadSources()
--- Method
--- Load new sources from `HSearch.search_path`, the search_path defaults to `~/.hammerspoon/private/hsearch_dir` and the HSearch Spoon directory. Only for debug purpose in usual.
---

function obj:loadSources()
    obj.sources = {}
    obj.sources_overview = {}
    obj:restoreOutput()
    for _,dir in ipairs(obj.search_path) do
        local file_list = io.popen("find " .. dir .. " -type f -name '*.lua'")
        for file in file_list:lines() do
            -- Exclude self
            if file ~= obj.spoonPath .. "/init.lua" then
                local f = loadfile(file)
                if f then
                    logger.i("Loading " .. file .. " successfully")
                    local source = f()
                    local output = source.new_output
                    if output then obj.output_pool[output.name] = output.func end
                    local overview = source.overview
                    -- Gather souces overview from files
                    table.insert(obj.sources_overview, overview)
                    local hotkey = source.hotkeys
                    if hotkey then obj.hotkeys[overview.keyword] = hotkey end
                    if source.config ~= nil and source.config_writer ~= nil then
                        if source.output_method ~= nil then
                            obj.sources_config[overview.keyword] = {
                                config = source.config,
                                config_writer = source.config_writer,
                                output_method = source.output_method,
                            }
                        else
                            obj.sources_config[overview.keyword] = {
                                config = source.config,
                                config_writer = source.config_writer,
                            }
                        end
                    end
                    local function sourceFunc()
                        local notice = source.notice
                        if notice then obj.chooser:choices({notice}) end
                        local request = source.init_func
                        if request then
                            local chooser_data = request()
                            if chooser_data then
                                local desc = source.description
                                if desc then table.insert(chooser_data, 1, desc) end
                            end
                            if obj:currentSourceMultipleOperationEnabled() then
                                obj:appendOperationData(chooser_data)
                            end
                            obj.chooser:choices(chooser_data)
                        else
                            obj.chooser:choices(nil)
                        end
                        if source.callback then
                            obj.chooser:queryChangedCallback(source.callback)
                        else
                            obj.chooser:queryChangedCallback()
                        end
                        obj.chooser:searchSubText(true)
                    end
                    -- Add this source to sources pool, so it can found and triggered.
                    obj.sources[overview.keyword] = sourceFunc
                else
                    logger.e("Load fail: " .. file)
                end
            end
        end
    end
end

--- HSearch:toggleShow()
--- Method
--- Toggle the display of HSearch
---

function obj:toggleShow()
    if #obj.sources_overview == 0 then
        -- If it's the first time HSearch shows itself, then load all sources from files
        obj:loadSources()
        -- Show sources overview, so users know what to do next.
        obj.chooser:choices(obj.sources_overview)
    end
    if obj.chooser:isVisible() then
        obj.chooser:hide()
        obj.trigger:disable()
        for _,val in pairs(obj.hotkeys) do
            for i=1,#val do
                val[i]:disable()
            end
        end
    else
        if obj.trigger == nil then
            obj.trigger = hs.hotkey.bind("", "tab", nil, function() obj:switchSource() end)
        else
            obj.trigger:enable()
        end
        for key,val in pairs(obj.hotkeys) do
            if key == obj.source_kw then
                for i=1,#val do
                    val[i]:enable()
                end
            end
        end
        obj.chooser:show()
    end
end

return obj
