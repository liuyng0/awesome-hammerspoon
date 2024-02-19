--- === HSearch ===
---
--- Hammerspoon Search
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/HSearch.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/HSearch.spoon.zip)

local obj = {}
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
obj.sources_overview = {}
obj.search_path = { hs.configdir .. "/private/hsearch_dir", obj.spoonPath }
obj.hotkeys = {}
obj.source_kw = nil
obj.searchSettingKey = "hs.chooser.algorithm"
obj.placeholderGenerator = function()
    return "algorithm: " .. (hs.settings.get(obj.searchSettingKey) or "default") .. ", @: text only, # subtext only"
end

local logger = hs.logger.new("HSearch", "debug")

function obj:resourceImage(path)
    return hs.image.imageFromPath(obj.spoonPath .. path)
end

function obj:setChoices(choices)
    -- render choice
    if obj.chooser ~= nil and choices ~= nil then
        spoon.ChooserStyle:setChooserUI(obj.chooser, choices)
    end
    if obj.chooser ~= nil then
        obj.chooser:choices(choices)
    end
end

function obj:restoreOutput()
    obj.output_pool = {}
    -- Define the built-in output type
    local function openWithBrowser(arg)
        local default_browser = hs.urlevent.getDefaultHandler("http")
        hs.urlevent.openURLWithBundle(arg, default_browser)
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
    obj.output_pool["clipboard"] = copyToClipboard
    obj.output_pool["keystrokes"] = sendKeyStrokes
end

function obj:init()
    obj.chooser =
        hs.chooser.new(
            function(chosen)
                obj.trigger:disable()
                -- Disable all hotkeys
                for _, val in pairs(obj.hotkeys) do
                    for i = 1, #val do
                        val[i]:disable()
                    end
                end
                if chosen ~= nil then
                    if chosen.arg ~= nil then
                        obj.output_pool[chosen.output](chosen.arg)
                    else
                        obj.output_pool[chosen.output](chosen)
                    end
                end
            end
        )
    obj.chooser:searchSubText(true)
    obj.chooser:rows(12)
end

--- HSearch:switchSource()
--- Method
--- Tigger new source according to hs.chooser's query string and keyword. Only for debug purpose in usual.
---

function obj:switchSource()
    local querystr = obj.chooser:query()
    if string.len(querystr) > 0 then
        -- First we try to switch source according to the querystr
        if obj.sources[querystr] then
            obj.source_kw = querystr
            obj.chooser:query("")
            obj:setChoices(nil)
            obj.chooser:queryChangedCallback()
            obj.sources[querystr]()
        else
            local row_content = obj.chooser:selectedRowContents()
            local row_kw = row_content.keyword
            -- Then try to switch source according to selected row
            if obj.sources[row_kw] then
                obj.source_kw = row_kw
                obj.chooser:query("")
                obj:setChoices(nil)
                obj.chooser:queryChangedCallback()
                obj.sources[row_kw]()
            else
                obj.source_kw = nil
                local chooser_data = {
                    { text = "No source found!",             subText = "Maybe misspelled the keyword?" },
                    { text = "Want to add your own source?", subText = "Feel free to read the code and open PRs. :)" }
                }
                obj:setChoices(chooser_data)
                obj.chooser:queryChangedCallback()
                hs.eventtap.keyStroke({ "cmd" }, "a")
            end
        end
    else
        local row_content = obj.chooser:selectedRowContents()
        local row_kw = row_content.keyword
        if obj.sources[row_kw] then
            obj.source_kw = row_kw
            obj.chooser:query("")
            obj:setChoices(nil)
            obj.chooser:queryChangedCallback()
            obj.sources[row_kw]()
        else
            obj.source_kw = nil
            -- If no matching source then show sources overview
            local chooser_data = obj.sources_overview
            obj.chooser:placeholderText(obj.placeholderGenerator())
            obj:setChoices(chooser_data)
            obj.chooser:queryChangedCallback()
        end
    end
    if obj.source_kw then
        for key, val in pairs(obj.hotkeys) do
            if key == obj.source_kw then
                for i = 1, #val do
                    val[i]:enable()
                end
            else
                for i = 1, #val do
                    val[i]:disable()
                end
            end
        end
    else
        for _, val in pairs(obj.hotkeys) do
            for i = 1, #val do
                val[i]:disable()
            end
        end
    end
end

function obj:loadSource(source)
    local output = source.new_output
    if output then
        if #output == 0 then
            obj.output_pool[output.name] = output.func
        else
            hs.fnutils.imap(
                output,
                function(nout)
                    obj.output_pool[nout.name] = nout.func
                end
            )
        end
    end
    local overview = source.overview
    -- Gather souces overview from files
    table.insert(obj.sources_overview, overview)
    local hotkey = source.hotkeys
    if hotkey then
        obj.hotkeys[overview.keyword] = hotkey
    end
    local function sourceFunc()
        local notice = source.notice
        if notice then
            obj:setChoices({ notice })
        end
        local request = source.init_func
        if request then
            local chooser_data = request()
            if chooser_data then
                local desc = source.description
                if desc then
                    table.insert(chooser_data, 1, desc)
                end
            end
            obj:setChoices(chooser_data)
        else
            obj:setChoices(nil)
        end
        if source.callback then
            obj.chooser:queryChangedCallback(source.callback)
        else
            obj.chooser:queryChangedCallback()
        end
        if source.placeholderGenerator then
            obj.chooser:placeholderText(source.placeholderGenerator())
        elseif source.placeholderText then
            obj.chooser:placeholderText(source.placeholderText)
        else
            obj.chooser:placeholderText(nil)
        end
    end
    -- Add this source to sources pool, so it can found and triggered.
    obj.sources[overview.keyword] = sourceFunc
end

--- HSearch:loadSources()
--- Method
--- Load new sources from `HSearch.search_path`, the search_path defaults to `~/.hammerspoon/private/hsearch_dir` and the HSearch Spoon directory. Only for debug purpose in usual.
---

function obj:loadSources()
    obj.sources = {}
    obj.sources_overview = {}
    obj:restoreOutput()
    for _, dir in ipairs(obj.search_path) do
        local file_list = io.popen("find " .. dir .. " -type f -name 'hs_*.lua'")
        for file in file_list:lines() do
            -- Exclude self
            local f, error_message = loadfile(file)
            if f then
                logger.i("Loading " .. file .. " successfully")
                local source = f()
                if source and source.disabled ~= true then
                    if #source == 0 then
                        obj:loadSource(source)
                    else
                        hs.fnutils.imap(
                            source,
                            function(singleSource)
                                obj:loadSource(singleSource)
                            end
                        )
                    end
                end
            else
                logger.e("Load fail: " .. file .. error_message)
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

        obj:setChoices(obj.sources_overview)
    end
    if obj.chooser:isVisible() then
        obj.chooser:hide()
        obj.trigger:disable()
        for _, val in pairs(obj.hotkeys) do
            for i = 1, #val do
                val[i]:disable()
            end
        end
    else
        if obj.trigger == nil then
            obj.trigger =
                hs.hotkey.bind(
                    "",
                    "tab",
                    nil,
                    function()
                        obj:switchSource()
                    end
                )
        else
            obj.trigger:enable()
        end
        for key, val in pairs(obj.hotkeys) do
            if key == obj.source_kw then
                for i = 1, #val do
                    val[i]:enable()
                end
            end
        end
        obj.chooser:show()
    end
end

--- HSearch:makeRequestSource(options)
--- Method
--- Make chooser source based on http request
---
--- Parameters:
---  * overview - {text="Type v ⇥ to ...", image=hsearch:resourceImage("path"), keyword="v"}
---  * query_url -  http get url
---  * item_mapping_func - convert item from post response
---  * output - the new output method {name, function(selectedItem)}
---  * placeholderText - the placeholderText show when no input
---
--- Return:
---  * A chooser source which can feed to HSearch
function obj:makeRequestSource(options)
    return {
        overview = options.overview,
        notice = { text = "Requesting data, please wait a while …" },
        init_func = function()
            hs.http.asyncGet(
                options.query_url,
                nil,
                function(status, data)
                    if status == 200 then
                        local retval, decoded_data =
                            pcall(
                                function()
                                    return hs.json.decode(data)
                                end
                            )
                        if retval and #decoded_data > 0 then
                            local chooser_data = hs.fnutils.imap(decoded_data, options.item_mapping_func)
                            -- Make sure HSearch spoon is running now
                            obj:setChoices(chooser_data)
                            obj.chooser:refreshChoicesCallback()
                        end
                    end
                end
            )
        end,
        new_output = options.output,
        placeholderText = options.placeholderText
    }
end

return obj
