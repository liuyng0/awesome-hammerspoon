#!/usr/bin/osascript

function run(cmd_args) {
    var args = JSON.parse(cmd_args);
    let winId = args["windowId"];
    let tabTitle = args["tabTitle"];

	  var chrome = Application('Google Chrome');
	  var wins = chrome.windows;

    for (var i = 0; i < wins.length; i++) {
        var win = wins.at(i);
        if (wins.at(i).id() != winId) {
            continue;
        }

        var tabs = win.tabs;
        for (var j = 0; j < tabs.length; j++) {
            var tab = tabs.at(j);
            if (tab.title() == tabTitle) {
                win.activeTabIndex = j+1;
                chrome.activate();
                return;
            }
        }
    }
}
