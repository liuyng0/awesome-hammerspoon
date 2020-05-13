#!/usr/bin/osascript

function run() {
	  var chrome = Application('Google Chrome');
	  var wins = chrome.windows;

	  let chrome_tabs = [];
    for (var i = 0; i < wins.length; i++) {
        var win = wins.at(i);
        var tabs = [];
        for (var j = 0; j < win.tabs.length; j++) {
            var tab = win.tabs.at(j);
            tabs.push({"title": tab.title(), "url": tab.url()});
        }
		    chrome_tabs.push({"windowId": win.id(), "tabs": tabs});
    }
	  return JSON.stringify(chrome_tabs);
}
