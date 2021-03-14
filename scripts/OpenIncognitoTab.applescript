#!/usr/bin/osascript

on run {input}
    do shell script "echo the URL:" & input & ">>/tmp/input.log"

    set AppleScript's text item delimiters to ","
    set urls to every text item of the input
    set AppleScript's text item delimiters to ""

    tell application "Google Chrome"
        activate

        set theWindow to make new window with properties {mode:"incognito"}

        repeat with targetUrl in urls
            set theUrl to my remove_http(targetUrl)

            set found to false
            set theTabIndex to -1

            repeat with theTab in every tab of theWindow
                set theTabIndex to theTabIndex + 1
                set theTabUrl to my remove_http(theTab's URL as string)

                if (theTabUrl contains theUrl) then
                    set found to true
                    exit repeat
                end if

            end repeat


            if found then
                tell theTab to reload
                set theWindow's active tab index to theTabIndex
                set index of theWindow to 1
            else
                tell window 1 to make new tab with properties {URL:targetUrl}
            end if

        end repeat

        tell theWindow to close (every tab whose URL is equal to "chrome://newtab/")

        -- repeat with theTab in every tab of theWindow
        --     set theURL to URL of theTab
        --     -- do shell script "echo the URL:" & theURL & ">>/tmp/test.log"
        --     if theURL as string is equal to "chrome://newtab/" then
        --         tell theWindow to close theTab
        --     end if
        -- end repeat
    end tell
end run

on remove_http(input_url)
    if (input_url contains "https://") then
         return trim_line(input_url, "https://")
    else
         return trim_line(input_url, "http://")
    end if
    return input_url
end remove_http

-- Taken from: http://www.macosxautomation.com/applescript/sbrt/sbrt-06.html --
on trim_line(this_text, trim_chars)
    set x to the length of the trim_chars
    -- TRIM BEGINNING
    repeat while this_text begins with the trim_chars
        try
            set this_text to characters (x + 1) thru -1 of this_text as string
        on error
            -- the text contains nothing but the trim characters
            return ""
        end try
    end repeat
    return this_text
end trim_line
