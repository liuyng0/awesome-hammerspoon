local funext = require "hammers/funext"
privconf = {}

-- Configure filepaths to search links
privconf.hssearch_links_filepaths = string.gsub([[
~/org/database/useful-links.md
]], "\n", " ")

-- Configure filepaths to search code snippets
privconf.hssearch_code_snippets_filepaths = string.gsub([[
~/org/database/source-code.org
]], "\n", " ")

privconf.hssearch_copy_texts_filepaths = string.gsub([[
~/org/database/useful-ids.md
]], "\n", " ")

privconf.default_loaded = "true"
privconf.last_loaded = "default"
privconf.emacs_vterm_frame_title = "*Emacs VTerm*"
