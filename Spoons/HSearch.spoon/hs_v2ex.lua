local obj = {}
obj.__index = obj

obj.name = "v2exPosts"
obj.version = "1.0"
obj.author = "LY <liuyng0@outlook.com>"

local hsearch = spoon.HSearch

obj.overview = {
  text = "Type v ⇥ to fetch v2ex posts.",
  image = hsearch:resourceImage("/resources/v2ex.png"),
  keyword = "v"
}

obj.query_url = "https://www.v2ex.com/api/topics/latest.json"

return spoon.HSearch:makeRequestSource {
  overview = obj.overview,
  query_url = obj.query_url,
  item_mapping_func = function(item)
    return {
      text = item.title,
      subText = item.url,
      image = hsearch:resourceImage("/resources/v2ex.png"),
      output = "browser",
      arg = item.url
    }
  end,
  output = nil,
  placeholderText = "search v2ex posts ..."
}
