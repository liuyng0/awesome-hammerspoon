local obj = {}
obj.__index = obj

obj.name = "ChooseAlgorithm"
obj.version = "1.0"
obj.author = "LY <liuyng0@outlook.com>"

local hsearch = spoon.HSearch
obj.overview = {
  text = "Type algo ⇥ to choose algorithm.",
  image = hsearch:resourceImage("/resources/tabs.png"),
  keyword = "algo"
}

obj.notice = { text = "Choose algorithm" }
obj.chooseAlgorithm = "chooseAlgorithm"
obj.settingKey = "hs.chooser.algorithm"
obj.algorithms = {
  { "exact",                    "exact match" },
  { "trie",                     "match using trie" },
  { "trie_split",               "match using trie with each character splited" },
  { "ratio",                    "Levenshtein Distance similarity ratio" },
  { "partial_ratio",            "subsections of the string, useful when one string is a substring of another" },
  { "partial_ratio_alignment",  "extends partial_ratio by returning start end of matches" },
  { "token_set_ratio",          "splits the strings into tokens (words) and compares the intersection and remainder of these token sets" },
  { "partial_token_set_ratio",  "uses partial token matching, useful when comparing strings with extra content" },
  { "token_sort_ratio",         "sorts the tokens before comparing them" },
  { "partial_token_sort_ratio", "combination of partial_ratio() and token_sort_ratio(), for sorting and then partially matching" },
  { "token_ratio",              "combines token_sort_ratio() and token_set_ratio() for a comprehensive token-based comparison" },
  { "partial_token_ratio",      "Combines partial_token_sort_ratio() and partial_token_set_ratio() for a detailed partial token comparison" },
  { "WRatio",                   "weighted ratio function that applies different ratios depending on the length of strings." },
  { "QRatio",                   "similar to ratio() but quicker, using a different method for string comparison." }
};
obj.init_func = function()
  return hs.fnutils.imap(obj.algorithms, function(item)
    return {
      text = item[1],
      subText = item[2],
      output = obj.chooseAlgorithm,
      algo = item[1]
    }
  end)
end

--- The callback function after a item selected
--- {
---    name = "command key"
---    func = callback_func
--- }
obj.new_output = {
  name = obj.chooseAlgorithm,
  func = function(item)
    hs.settings.set(obj.settingKey, item.algo)
  end
}

--- The text will be shown in search input as place holder
obj.placeholderGenerator = function()
  return "choose algorithm for search, current: " .. (hs.settings.get(obj.settingKey) or "nil")
end

return obj
