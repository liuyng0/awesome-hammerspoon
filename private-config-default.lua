local funext = require 'hammers/funext'
privconf = {}

-- Configure the ignored apps
privconf.hsapp_ignored_apps = funext.set({
--    "Microsoft Outlook",
})

-- Configure filepaths to search links
privconf.hssearch_links_filepaths = string.gsub([[
~/org/database/useful-links.md
]],
"\n", " ")

-- Configure filepaths to search code snippets
privconf.hssearch_code_snippets_filepaths = string.gsub([[
~/org/database/source-code.org
]],
"\n", " ")

privconf.default_loaded = "true"
privconf.last_loaded = "default"
