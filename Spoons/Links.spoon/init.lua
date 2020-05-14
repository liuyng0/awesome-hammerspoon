local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Links"
obj.version = "1.0"
obj.author = "Chophi <chophi@foxmail.com>"

local json = hs.json

local linksFile = getVifFile("links.json")
local links = nil

-- Link:
-- url: the link url
-- description: the description of the url
-- app: the application to open it
-- groups: comma separated list


function obj:test()
  hs.alert.show("This is a test from Links, linkFile is " .. linksFile)
  local status = "operation"
  local tb = {status=status}
  hs.alert.show(hs.inspect.inspect(tb))
  status = "new operation"
  hs.alert.show(hs.inspect.inspect(tb))
end

function obj:load()
  return json.read(linksFile)
end

function obj:save(links)
  return json.write(links, linksFile, true, true)
end

function obj:validate(link)
  return link.description ~= nil and link.url ~= nil and type(link.url) == "string" and type(link.description) == "string"
end

function obj:update(url, newLink)
  if obj:validate(newLink) then
    if links == nil then
      links = obj:load()
    end
  end

  local found = false
  for i, link in pairs(links) do
    if link.url == url then
      links[i] = newLink
      found = true
      break
    end
  end

  if found ~= true then
    links[#links] = newLink
  end

  obj:save(links)
end

function obj:add()

end

return obj
