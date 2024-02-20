local obj = {}
obj.__index = obj

obj.name = "timeDelta"
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
    text = "Type d ⇥ to format/query Date.",
    image = hs.image.imageFromPath(obj.spoonPath .. "/resources/time.png"),
    keyword = "d"
}
-- Define the notice when a long-time request is being executed. It could be `nil`.
obj.notice = nil

-- Some global objects
obj.exec_args = {
    {
        tz = "Asia/Chongqing",
        format = '+"%Y-%m-%d %H:%M:%S"'
    },
    {
        tz = "UTC",
        format = '+"%Y-%m-%d %H:%M:%S"'
    },
    {
        tz = "America/Los_Angeles",
        format = '+"%Y-%m-%d %H:%M:%S"'
    }
}

obj.clock_time_format = {
    tz = "Asia/Chongqing",
    format = '+"%Y-%m-%d %H:%M:%S"'
}

local function timeRequest()
    local chooser_data =
        hs.fnutils.imap(
            obj.exec_args,
            function(item)
                local command = "TZ=" .. item.tz .. " /bin/date " .. item.format
                local exec_result = hs.execute(command):match("^%s*(.-)%s*$")
                return {
                    text = exec_result,
                    subText = command,
                    image = hs.image.imageFromPath(obj.spoonPath ..
                        "/resources/time.png"),
                    output = "keystrokes",
                    arg = exec_result
                }
            end
        )
    return chooser_data
end
-- Define the function which will be called when the `keyword` triggers a new source. The returned value is a table. Read more: http://www.hammerspoon.org/docs/hs.chooser.html#choices
obj.init_func = timeRequest
-- Insert a friendly tip at the head so users know what to do next.
-- As this source highly relys on queryChangedCallback, we'd better tip users in callback instead of here
obj.description = nil
-- As the user is typing, the callback function will be called for every keypress. The returned value is a table.

local function splitBySpace(str)
    local tmptbl = {}
    local input_type = nil
    for w in string.gmatch(str, "[+-]%d+[ymdwHMS]") do
        table.insert(tmptbl, w)
        input_type = "shift"
    end
    if input_type ~= nil then
        return input_type, tmptbl
    end
    for w in string.gmatch(str, "@[0-9]+") do
        table.insert(tmptbl, w)
        input_type = "epoch"
        return input_type, tmptbl
    end
    for w in string.gmatch(str, "!(%d+)") do
        table.insert(tmptbl, w)
        input_type = "countdown"
        return input_type, tmptbl
    end

    if str == "!t" then
        table.insert(tmptbl, "t")
        input_type = "countdown"
        return input_type, tmptbl
    end

    return tmptbl
end

local function timeDeltaRequest(querystr)
    if string.len(querystr) > 0 then
        local input_type, valid_inputs = splitBySpace(querystr)
        if valid_inputs and #valid_inputs > 0 then
            local addv_before =
                hs.fnutils.imap(
                    valid_inputs,
                    function(item)
                        if input_type == "shift" then
                            return "-v" .. item
                        elseif input_type == "epoch" then
                            return "-d " .. item
                        elseif input_type == "countdown" then
                            return "-v+" .. item .. "M"
                        end
                    end
                )
            local vv_var = table.concat(addv_before, " ")
            local chooser_data = nil
            if input_type == "countdown" then
                local text =
                    valid_inputs[1] == "t" and "Pause/Resume the clock" or
                    "Setup clock in " .. valid_inputs[1] .. " minutes"
                local subText
                if valid_inputs[1] ~= "t" then
                    local command =
                        "TZ=" ..
                        obj.clock_time_format.tz ..
                        " /bin/date " ..
                        "-v" ..
                        valid_inputs[1] .. "M " .. obj.clock_time_format.format
                    subText = "Alarm @ " ..
                        hs.execute(command):match("^%s*(.-)%s*$")
                end
                chooser_data = {
                    [1] = {
                        text = text,
                        subText = subText,
                        image = hs.image.imageFromPath(obj.spoonPath ..
                            "/resources/time.png"),
                        output = "clock",
                        input_text = valid_inputs[1]
                    }
                }
            else
                chooser_data =
                    hs.fnutils.imap(
                        obj.exec_args,
                        function(item)
                            local program = "/bin/date"
                            if input_type == "epoch" then
                                program = "/opt/homebrew/bin/gdate"
                            end
                            local new_exec_command =
                                "TZ=" ..
                                item.tz ..
                                " " ..
                                program .. " " .. vv_var .. " " .. item.format
                            local new_exec_result = hs.execute(new_exec_command)
                                :match("^%s*(.-)%s*$")
                            return {
                                text = new_exec_result,
                                subText = new_exec_command,
                                image = hs.image.imageFromPath(obj.spoonPath ..
                                    "/resources/time.png"),
                                output = "keystrokes",
                                arg = new_exec_result
                            }
                        end
                    )
            end
            if spoon.HSearch then
                -- Make sure HSearch spoon is running now
                spoon.HSearch.chooser:choices(chooser_data)
            end
        end
    else
        local chooser_data = timeRequest()
        if spoon.HSearch then
            -- Make sure HSearch spoon is running now
            spoon.HSearch.chooser:choices(chooser_data)
        end
    end
end

obj.placeholderText = "clock - !(%d+|t), shift - +/-1d, epoch - @0"
obj.callback = timeDeltaRequest
obj.new_output = {
    name = "clock",
    func = function(item)
        if spoon.CountDown then
            if item.input_text == "t" then
                spoon.CountDown:pauseOrResume()
            else
                spoon.CountDown:startFor(tonumber(item.input_text))
            end
        end
    end
}
return obj
