local obj = {}
obj.__index = obj

obj.name = "TerminalSearch"
obj.version = "1.0"
obj.author = "LY <liuyng0@outlook.com>"

local hsearch = spoon.HSearch
obj.overview = {
  text = "Type st ⇥ to select terminal.",
  image = hsearch:resourceImage("/resources/tabs.png"),
  keyword = "st"
}

obj.notice = { text = "Select Terminal" }

obj.selectTerminal = "selectTerminal"
obj.init_func = function()
  output, succeed = hs.execute("/opt/homebrew/bin/tmux list-windows")
  choices = {}
  if succeed then
    for line in string.gmatch(output:match("^%s*(.-)%s*$"), '[^\r\n]+') do
      local strip_line = line:match("^%s*(.-)%s*$")
      table.insert(choices, {
        text = strip_line,
        output = obj.selectTerminal,
        terminal_id = string.sub(strip_line, 1, 1)
      })
    end
  end
  return choices
end

--- The callback function after a item selected
--- {
---    name = "command key"
---    func = callback_func
--- }
obj.new_output = {
  name = obj.selectTerminal,
  func = function(item)
    hs.execute("/opt/homebrew/bin/tmux select-window -t " .. item.terminal_id)
    local window = hs.window.filter.new(false):setAppFilter('Emacs', { allowTitles = 'vterminal' }):getWindows()
    if #window > 0 then
      window[1]:unminimize():raise():focus()
    end
  end
}

--- The text will be shown in search input as place holder
obj.placeholderText = "Search Terminals"

return obj
