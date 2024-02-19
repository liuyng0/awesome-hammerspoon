#!/usr/bin/env sh
gfind . -maxdepth 1 -name "*.spoon" -exec sh -c 'hs -c "hs.doc.builder.genJSON(\"$PWD/{}\")" | grep -v "^--" > {}/docs.json' \;
hs -c 'hs.loadSpoon("EmmyLua")'
